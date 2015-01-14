Function Set-Permission {

    <#
    .SYNOPSYS
        Allow you to easily change permissions on files or folders
    .PARAMETER Path
        Path to the folder or file you want to modify (ex: C:\Temp)
    .PARAMETER User
        One or more user names (ex: BUILTIN\Users, DOMAIN\Admin)
    .PARAMETER Permission
        To remove permission use: None, to see all the possible permissions go to 'http://technet.microsoft.com/fr-fr/library/ff730951.aspx'
    .PARAMETER Recurse
        If you use this switch, permissions will be recursive on folder and file children
    .EXAMPLE
        Will grant FullControl permissions to 'John' and 'Users' on 'C:\Temp' and it's files and folders children.
        PS C:\>Set-Permission -Path "C:\Temp" -User "DOMAIN\John", "BUILTIN\Utilisateurs" -Permission FullControl -Recurse
    .EXAMPLE
        Will grant Read permissions to 'John' on 'C:\Temp\pic.png'
        PS C:\>Set-Permission -Path "C:\Temp\pic.png" -User "DOMAIN\John" -Permission Read
    .EXAMPLE
        Will remove all permissions to 'John' on 'C:\Temp\Private'
        PS C:\>Set-Permission -Path "C:\Temp\Private" -User "DOMAIN\John" -Permission None

        Conditions : John need to have explicit existing permissions on the Path or File
    .NOTE
        Author : Julian DA CUNHA - dacunha.julian@gmail.com
    #>

    [CmdletBinding()]
    Param (
        [Parameter( Mandatory=$True, 
                    Position=0,
                    HelpMessage = "Path to the folder or file you want to modify (ex: C:\Temp)" )]
        [ValidateScript({Test-Path $_})]
        [Alias('File', 'Folder')]
        [String] $Path,

        [Parameter( Mandatory=$True, 
                    Position=1,
                    HelpMessage = "One or more user names (ex: BUILTIN\Users, DOMAIN\Admin)" )]
        [Alias('Username', 'Users')]
        [String[]] $User,

        [Parameter( Mandatory=$True,
                    Position=2,
                    HelpMessage = "To remove permission use: None, to see all the possible permissions go to 'http://technet.microsoft.com/fr-fr/library/ff730951.aspx'")]
        [Alias('Acl', 'Grant')]
        [ValidateSet("AppendData", "ChangePermissions", "CreateDirectories", "CreateFiles", "Delete", `
                     "DeleteSubdirectoriesAndFiles", "ExecuteFile", "FullControl", "ListDirectory", "Modify",`
                     "Read", "ReadAndExecute", "ReadAttributes", "ReadData", "ReadExtendedAttributes", "ReadPermissions",`
                     "Synchronize", "TakeOwnership", "Traverse", "Write", "WriteAttributes", "WriteData", "WriteExtendedAttributes", "None")]
        [String] $Permission,

        [Parameter( Mandatory=$False, 
                    HelpMessage = "If you use this switch, permissions will be recursive on folder and file children" )]
        [Switch] $Recurse
    )

    Begin {

        # Test run as Administrator
        $IsAdmin = [Bool] ((Whoami /All) -match "S-1-16-12288")
        If (!$IsAdmin){
            Write-Error -Message "Insufficient privileges. Try to run it as Administrator." -Category PermissionDenied
            Break
        }

        # Set permissions
        If ($Permission -ne "None"){
            $Permission = [System.Security.AccessControl.FileSystemRights]$Permission
        }

        # Enable recursive permissions
        If ($Recurse){
            $InheritanceFlag = [System.Security.AccessControl.InheritanceFlags]
            $InheritanceFlag = [System.Security.AccessControl.InheritanceFlags]($InheritanceFlag::ContainerInherit -bor $InheritanceFlag::ObjectInherit)
        } Else { 
            $InheritanceFlag = [System.Security.AccessControl.InheritanceFlags]::None
        }

        # Set Propagation
        $PropagationFlag = [System.Security.AccessControl.PropagationFlags]::None

        # Allow Object access
        $Allow = [System.Security.AccessControl.AccessControlType]::Allow

        # Set permissions for special accounts
        $ObjSID = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
        $AdminsSID = $ObjSID.Translate( [System.Security.Principal.NTAccount])
        $AdminsAccountName = $AdminsSID.Value

        $ObjSID = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-18")
        $SystemSID = $ObjSID.Translate( [System.Security.Principal.NTAccount])
        $SystemAccountName = $SystemSID.Value
        
        $Admin = New-Object System.Security.Principal.NTAccount($AdminsAccountName)
        $System = New-Object System.Security.Principal.NTAccount($SystemAccountName)
    }

    Process {

        # Get object acls
        $Acl = Get-Acl $Path
        # Disable inherance, Preserve inherited permissions
        $Acl.SetAccessRuleProtection($True, $False)

        # Set Permissions for Administrators and System
        $SpecialPermission = [System.Security.AccessControl.FileSystemRights]::FullControl
        $Rule = New-Object System.Security.AccessControl.FileSystemAccessRule($Admin, $SpecialPermission, $InheritanceFlag, $PropagationFlag, $Allow)
        $Acl.AddAccessRule($Rule)
        $Rule = New-Object System.Security.AccessControl.FileSystemAccessRule($System, $SpecialPermission, $InheritanceFlag, $PropagationFlag, $Allow)
        $Acl.AddAccessRule($Rule)
        $null = Set-Acl -Path $Path -AclObject $Acl

        # Apply permissions on Users
        Foreach ($U in $User){

            # Set Username
            $Username = New-Object System.Security.Principal.NTAccount($U)

            # Set or Remove permissions
            If ($Permission -ne "None"){

                $Rule = New-Object System.Security.AccessControl.FileSystemAccessRule($Username, $Permission, $InheritanceFlag, $PropagationFlag, $Allow)
                $Acl.AddAccessRule($Rule)
                Write-Verbose "ACL - Add($Username, $Permission, $InheritanceFlag, $PropagationFlag, $Allow)"

            } Else {

                # Check If user is in security descriptor
                $Remove = $Acl.Access | Where { $_.IdentityReference -eq $U }

                If ($Remove){

                    $RemoveRule = New-Object System.Security.AccessControl.FileSystemAccessRule($Remove.IdentityReference, $Remove.FileSystemRights, $Remove.InheritanceFlags, $Remove.PropagationFlags, $Remove.AccessControlType)
                    $Acl.RemoveAccessRuleAll($RemoveRule)
                    Write-Verbose "ACL - RemoveAll($($Remove.IdentityReference), $($Remove.FileSystemRights), $($Remove.InheritanceFlags), $($Remove.PropagationFlags), $($Remove.AccessControlType))"

                }
            }
        }
    }

    End {
        $null = Set-Acl -Path $Path -AclObject $Acl
    }
}