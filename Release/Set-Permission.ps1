Function Set-Permission {

    [CmdletBinding()]
    Param (
        [Parameter( Mandatory=$True, 
                    ValueFromPipeline=$True, 
                    ValueFromPipelineByPropertyName=$False, 
                    Position=0,
                    HelpMessage = "Path to the folder or file you want to modify (ex: C:\Temp" )]
        [ValidateScript({Test-Path $_})]
        [String] $Path,

        [Parameter( Mandatory=$True, 
                    Position=1,
                    HelpMessage = "One or more user names (ex: BUILTIN\Users, DOMAIN\Admin)" )]
        [Alias('Username')]
        [String[]] $User,

        [Parameter( Mandatory=$True,
                    Position=2,
                    HelpMessage = "Use the following permissions: FullControl, Modify, Read, ReadAndExecute, Write, ListDirectory")]
        [Alias('Acl')]
        [ValidateSet("FullControl", "Modify", "Read", "ReadAndExecute", "Write", "ListDirectory")]
        [String] $Permission,

        [Parameter( Mandatory=$False, 
                    Position=3,
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
        If ($Recurse){
            $InheritanceFlags = "ContainerInherit, ObjectInherit"
        } Else {
            $InheritanceFlags = "None"
        }
    }

    Process {
        $Acl = Get-Acl $Path
        $Acl.SetAccessRuleProtection($True, $False)
        Foreach ($U in $User){
            # Remove user permissions if he already have it
            $RemoveAcl = $Acl.Access | Where { $_.IdentityReference -eq $U }
            If ($RemoveAcl){
                $RemoveRule = New-Object System.Security.AccessControl.FileSystemAccessRule($RemoveAcl.IdentityReference, $RemoveAcl.FileSystemRights, $RemoveAcl.InheritanceFlags, $RemoveAcl.PropagationFlags, $RemoveAcl.AccessControlType)
                $null = $Acl.RemoveAccessRule($RemoveRule)
                Set-Acl -Path $Path -AclObject $Acl
                Write-Verbose "Remove ($($RemoveAcl.IdentityReference), $($RemoveAcl.FileSystemRights), $($RemoveAcl.InheritanceFlags), $($RemoveAcl.PropagationFlags), $($RemoveAcl.AccessControlType))"
            }
            # Set new user permissions
            $AddRule = New-Object System.Security.AccessControl.FileSystemAccessRule($U,$Permission, $InheritanceFlags, "None", "Allow")
            $Acl.AddAccessRule($AddRule)
            Write-Verbose "Add ($($U), $($Permission), $($InheritanceFlags), None, Allow)`n"
        }
    }

    End {
        Set-Acl -Path $Path -AclObject $Acl
    }
}

##################################################

Cls
Set-Permission -Path "C:\Temp\TEST" -User $("CARLINTL\JCU", "BUILTIN\Utilisateurs") -Permission "FullControl" -Recurse -Verbose