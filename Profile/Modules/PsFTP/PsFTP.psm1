<#

  	.NOTES
======================================================================
	Created on:   	04/08/2014
 	Created by:   	JCU
	Organization: 	CARL Software
	Script name:	PsFTP
	Description:	Allow to send, receive, remove, files and 
                    directories from FTP
======================================================================

#>


#== Ftp Functions ====================================================
#=====================================================================

Function Get-FtpFileList {

    <#
    .SYNOPSIS
        List Ftp files
    .PARAMETER FtpUrl
        Complete path of file to upload (ex: C:\Temp\Rapport.txt)
    .PARAMETER Username
        Username for Ftp user
    .PARAMETER Password
        Password for Ftp user
    .EXAMPLE
        PS C:\> Get-FtpFileList -FtpUrl "ftp://ftp.contoso.com/" -Username "Anonymous" -Password $Null
    .NOTES
        Version:  0.1
    #>

    [CmdletBinding()]
    Param (

        [Parameter( Mandatory = $true, Position = 0 )]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $FtpUrl,

        [Parameter( Mandatory = $true, Position = 1 )]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Username,

        [Parameter( Mandatory = $true, Position = 2 )]
        [AllowEmptyString()]
        [AllowNull()]
        [String[]]
        $Password
    )

    Process {

        # FTP Request
        $FtpRequest = [System.Net.FtpWebRequest]::Create($FtpUrl)
        $FtpRequest.Timeout = 30000
        $FtpRequest.ReadWriteTimeout = 10000
        $FtpRequest.KeepAlive = $False
        $FtpRequest.UseBinary = $True
        $FtpRequest.Proxy = $Null
        $FtpRequest.Credentials = New-Object System.Net.NetworkCredential($Username, $Password)
        $FtpRequest.Method = [System.Net.WebRequestMethods+FTP]::ListDirectoryDetails

        # Send the Ftp Request to the Server
        Try {
            $FtpResponse = $FtpRequest.GetResponse()
        }
        Catch {
            Write-Host "`nError : $_" -ForegroundColor Red
            Break
        }

        # Recieve Stream
        $Global:FtpOutputCache = (Receive-Stream $FtpResponse.GetResponseStream())

        # Format Response
        $List = $Global:FtpOutputCache -replace "(?:.|\n)*<PRE>\s+((?:.*|\n)+)\s+</PRE>(?:.|\n)*",'$1' -split "`n"
        $List = $List -replace "&lt(.+)<BR>", ""
        $List = $List -replace "&lt;DIR&gt;", "DIR"
        $List = $List -replace "\[GMT\]", ""

        # PsObjects Creation Process
        $PsObjects = $( Foreach ($Line in $List | ? { $_ }) {

            # Format Date
            [DateTime] $Date = ($Line -split "\s+")[0]
            [DateTime] $Time = ($Line -split "\s+")[1]
                
            # File name
            [String] $Name = ($Line -split "\s+")[3]

            #### Debug ####
            # For ( $i=0 ; $i -lt $(($Line -split "\s+").Length) ; $i++ ){
            #    Write-Host "Index $i : $(($Line -split "\s+")[$i])"
            # }
            ###############

            # Item is File
            If (! ($Line -match "DIR")){

                # File Size
                If ($(($Line -split "\s+").Length) -eq 4){
                    $Length = "0 KB"
                    $Name = ($Line -split "\s+")[2]
                }
                Else { 
                    $Length = ($Line -split "\s+")[2]
                    $Length = "$([Math]::Round( $($Length/1KB), 2)) KB"
                }

                # File type
                If ( $Name -match "." ){
                    [String] $Type = $Name -split '.+\.'
                    $Type = $Type -replace " ", ""
                    $Type = $Type.Replace($Type[0],$Type[0].ToString().ToUpper())
                }
                Else { 
                    [String]$Type = "Unknown File"
                }
            }
            Else {
                [String]$Length = "Unknown"
                [String]$Type = "Directory"
            }
      
            # Create PsObject
            New-Object PSObject -Property @{
                Name          = $Name
                LastWriteTime = "$(Get-Date $Date -Format "dd/MM/yy") $(Get-Date $Time -Format "HH:mm")"
                Size          = $Length
                Type          = $Type
                FullPath      = "$FtpUrl$Name"
            }
        })

        # Close FtpConnection
        $FtpResponse.Close()

        # Return PsObjects
        Return $PsObjects
    }
}

Function Send-FtpFile {

    <#
    .SYNOPSIS
        Upload file to Ftp Server
    .PARAMETER LocalFile
        Complete path of file to upload (ex: C:\Temp\Rapport.txt)
    .PARAMETER RemotePath
        Distant Uri path (ex: ftp://ftp.contoso.com/)
    .PARAMETER Username
        Username for Ftp user
    .PARAMETER Password
        Password for Ftp user
    .EXAMPLE
        PS C:\> Send-FtpFile -File C:\Temp\Rapport.txt -RemotePath "ftp://ftp.contoso.com/" -Username "Anonymous" -Password $Null
    .NOTES
        Version:  0.1
    #>

    [CmdletBinding()]
    Param (

        [Parameter( Mandatory = $true, Position = 0 )]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $LocalFile,

        [Parameter( Mandatory = $true, Position = 1 )]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $RemotePath,

        [Parameter( Mandatory = $true, Position = 2 )]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Username,

        [Parameter( Mandatory = $true, Position = 3 )]
        [AllowEmptyString()]
        [AllowNull()]
        [String[]]
        $Password
    )

    Process {

        # Check if file exist
        If ($LocalFile){
            
            # Get File info
            $FileInfo = Get-ChildItem $LocalFile

            # FTP Request
            $FtpRequest = [System.Net.FtpWebRequest]::Create("$RemotePath$($FileInfo.Name)")
            $FtpRequest.Timeout = 30000
            $FtpRequest.ReadWriteTimeout = 10000
            $FtpRequest.KeepAlive = $False
            $FtpRequest.UseBinary = $True
            $FtpRequest.UsePassive = $True
            $FtpRequest.Proxy = $Null
            $FtpRequest.Credentials = New-Object System.Net.NetworkCredential($Username, $Password)
            $FtpRequest.Method = [System.Net.WebRequestMethods+FTP]::UploadFile

            # Convert File in Bytes
            $FileinBytes = [System.IO.File]::ReadAllBytes($LocalFile)

            # Resize the FtpRequest size to be the same as File bytes size
            $FtpRequest.ContentLength = $FileinBytes.Length

            # Get Request Stream
            Try {
                $FtpStream = $FtpRequest.GetRequestStream()
            }
            Catch {
                Write-Host "`nError : $_" -ForegroundColor Red
                Break
            }

            # Write the file to Ftp server
            Try {
                $FtpStream.Write($FileinBytes, 0, $FileinBytes.Length)
            }
            Catch {
                Write-Host "`nError : $_" -ForegroundColor Red
                Break
            }

            Write-Host "`nSuccess : '$($FileInfo.Name)' was correctly uploaded to '$RemotePath$($FileInfo.Name)'" -ForegroundColor Green

            # Close FtpConnection
            $FtpStream.Close()
            $FtpStream.Dispose()
        }
        Else {
            Write-Host "`nError : '$LocalFile' doesn't exist or you don't have the correct R/W access." -ForegroundColor Red
        }
    }
}

Function Get-FtpFile {

    <#
    .SYNOPSIS
        Download file from Ftp Server
    .PARAMETER RemoteFile
        Distant file Uri (ex: ftp://ftp.contoso.com/ThisFile.zip)
    .PARAMETER LocalPath
        Complete path to save the file to download (ex: C:\Temp\ThisFile.zip)
    .PARAMETER Username
        Username for Ftp user
    .PARAMETER Password
        Password for Ftp user
    .EXAMPLE
        PS C:\> Get-FtpFile -RemoteFile "ftp://ftp.contoso.com/ThisFile.zip" -LocalPath "C:\Temp\ThisFile.zip" -Username "Anonymous" -Password $Null
    .NOTES
        Version:  0.1
    #>

    [CmdletBinding()]
    Param (

        [Parameter( Mandatory = $true, Position = 0 )]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $RemoteFile,

        [Parameter( Mandatory = $true, Position = 1 )]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $LocalPath,

        [Parameter( Mandatory = $true, Position = 2 )]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Username,

        [Parameter( Mandatory = $true, Position = 3 )]
        [AllowEmptyString()]
        [AllowNull()]
        [String[]]
        $Password
    )

    Process {

        # FTP Request
        $FtpRequest = [System.Net.FtpWebRequest]::Create($RemoteFile)
        $FtpRequest.Timeout = 30000
        $FtpRequest.ReadWriteTimeout = 10000
        $FtpRequest.KeepAlive = $False
        $FtpRequest.UseBinary = $True
        $FtpRequest.UsePassive = $True
        $FtpRequest.Credentials = New-Object System.Net.NetworkCredential($Username, $Password)
        $FtpRequest.Method = [System.Net.WebRequestMethods+FTP]::DownloadFile

        # Send the Ftp Request to the Server
        Try {
            $FtpResponse = $FtpRequest.GetResponse()
        }
        Catch {
            Write-Host "`nError : $_" -ForegroundColor Red
            Break
        }

        # Get Stream from Response
        $FtpStream = $FtpResponse.GetResponseStream()

        Try {

            # Create file
            $File = New-Object IO.FileStream ($LocalPath, [IO.FileMode]::Create)
            
            # Create Buffer
            [Byte[]] $Buffer = New-Object Byte[] 4096
            $Read = 0
        
            Do {
                
                # Read Buffer and Write it
                $Read = $FtpStream.Read($Buffer, 0, 4096)
                $File.Write($Buffer, 0, $Read)
            } 
            While ($Read -ne 0)
        }
        Catch {
            Write-Host "`nError : $_" -ForegroundColor Red
            Break
        }

        
        Write-Host "`nSuccess : '$RemoteFile' was correctly downloaded to '$LocalPath'" -ForegroundColor Green

        # Close Connections
        $File.Close()
        $FtpStream.Close()
        $FtpResponse.Close()
    }
}

Function Remove-FtpFile {

    <#
    .SYNOPSIS
        Remove file from Ftp Server
    .PARAMETER RemoteFile
        Distant file Uri to delete (ex: ftp://ftp.contoso.com/ThisFile.zip)
    .PARAMETER Username
        Username for Ftp user
    .PARAMETER Password
        Password for Ftp user
    .EXAMPLE
        PS C:\> Remove-FtpFile -RemoteFile "ftp://ftp.contoso.com/ThisFile.zip" -Username "Anonymous" -Password $Null
    .NOTES
        Version:  0.1
    #>

    [CmdletBinding()]
    Param (

        [Parameter( Mandatory = $true, Position = 0 )]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $RemoteFile,

        [Parameter( Mandatory = $true, Position = 1 )]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Username,

        [Parameter( Mandatory = $true, Position = 2 )]
        [AllowEmptyString()]
        [AllowNull()]
        [String[]]
        $Password
    )

    Process {

        # FTP Request
        $FtpRequest = [System.Net.FtpWebRequest]::Create($RemoteFile)
        $FtpRequest.Timeout = 30000
        $FtpRequest.ReadWriteTimeout = 10000
        $FtpRequest.KeepAlive = $False
        $FtpRequest.UseBinary = $True
        $FtpRequest.UsePassive = $True
        $FtpRequest.Credentials = New-Object System.Net.NetworkCredential($Username, $Password)
        $FtpRequest.Method = [System.Net.WebRequestMethods+FTP]::DeleteFile

        # Send the Ftp Request to the Server
        Try {
            $FtpResponse = $FtpRequest.GetResponse()
        }
        Catch {
            Write-Host "`nError : $_" -ForegroundColor Red
            Break
        }

        Write-Host "`nSuccess : '$RemoteFile' was correctly removed" -ForegroundColor Green

        # Close Connections
        $FtpResponse.Close()
    }
}

Function New-FtpDirectory {

    <#
    .SYNOPSIS
        Create Directory in Ftp Server
    .PARAMETER NewDir
        Distant file Uri to the new directory (ex: ftp://ftp.contoso.com/NewDirectory)
    .PARAMETER Username
        Username for Ftp user
    .PARAMETER Password
        Password for Ftp user
    .EXAMPLE
        PS C:\> New-FtpDirectory -NewDir "ftp://ftp.contoso.com/NewDirectory" -Username "Anonymous" -Password $Null
    .NOTES
        Version:  0.1
    #>

    [CmdletBinding()]
    Param (

        [Parameter( Mandatory = $true, Position = 0 )]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $NewDir,

        [Parameter( Mandatory = $true, Position = 1 )]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Username,

        [Parameter( Mandatory = $true, Position = 2 )]
        [AllowEmptyString()]
        [AllowNull()]
        [String[]]
        $Password
    )

    Process {

        # FTP Request
        $FtpRequest = [System.Net.FtpWebRequest]::Create($NewDir)
        $FtpRequest.Timeout = 30000
        $FtpRequest.ReadWriteTimeout = 10000
        $FtpRequest.KeepAlive = $False
        $FtpRequest.UseBinary = $True
        $FtpRequest.UsePassive = $True
        $FtpRequest.Credentials = New-Object System.Net.NetworkCredential($Username, $Password)
        $FtpRequest.Method = [System.Net.WebRequestMethods+FTP]::MakeDirectory

        # Send the Ftp Request to the Server
        Try {
            $FtpResponse = $FtpRequest.GetResponse()
        }
        Catch {
            Write-Host "`nError : $_" -ForegroundColor Red
            Break
        }

        Write-Host "`nSuccess : '$NewDir' was correctly created" -ForegroundColor Green

        # Close Connections
        $FtpResponse.Close()
    }
}

Function Remove-FtpDirectory {

    <#
    .SYNOPSIS
        Remove Directory in Ftp Server
    .PARAMETER NewDir
        Distant file Uri to the directory to remove (ex: ftp://ftp.contoso.com/DirectoryToRemove)
    .PARAMETER Username
        Username for Ftp user
    .PARAMETER Password
        Password for Ftp user
    .EXAMPLE
        PS C:\> Remove-FtpDirectory -NewDir "ftp://ftp.contoso.com/DirectoryToRemove" -Username "Anonymous" -Password $Null
    .NOTES
        Version:  0.1
    #>

    [CmdletBinding()]
    Param (

        [Parameter( Mandatory = $true, Position = 0 )]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $RemoveDir,

        [Parameter( Mandatory = $true, Position = 1 )]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Username,

        [Parameter( Mandatory = $true, Position = 2 )]
        [AllowEmptyString()]
        [AllowNull()]
        [String[]]
        $Password
    )

    Process {

        # FTP Request
        $FtpRequest = [System.Net.FtpWebRequest]::Create($RemoveDir)
        $FtpRequest.Timeout = 30000
        $FtpRequest.ReadWriteTimeout = 10000
        $FtpRequest.KeepAlive = $False
        $FtpRequest.UseBinary = $True
        $FtpRequest.UsePassive = $True
        $FtpRequest.Credentials = New-Object System.Net.NetworkCredential($Username, $Password)
        $FtpRequest.Method = [System.Net.WebRequestMethods+FTP]::RemoveDirectory

        # Send the Ftp Request to the Server
        Try {
            $FtpResponse = $FtpRequest.GetResponse()
        }
        Catch {
            Write-Host "`nError : $_" -ForegroundColor Red
            Break
        }

        Write-Host "`nSuccess : '$NewDir' was correctly removed" -ForegroundColor Green

        # Close Connections
        $FtpResponse.Close()
    }
}

Function Rename-FtpItem {

    <#
    .SYNOPSIS
        Rename Item in Ftp Server
    .PARAMETER ItemToRename
        Distant file Uri to the item to rename (ex: ftp://ftp.contoso.com/Test.zip)
    .PARAMETER NewName
        The new name of the item
    .PARAMETER Username
        Username for Ftp user
    .PARAMETER Password
        Password for Ftp user
    .EXAMPLE
        PS C:\> Rename-FtpItem -ItemToRename "ftp://ftp.contoso.com/Test.zip" -NewName "NewTest.zip" -Username "Anonymous" -Password $Null
    .NOTES
        Version:  0.1
    #>

    [CmdletBinding()]
    Param (

        [Parameter( Mandatory = $true, Position = 0 )]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $ItemToRename,

        [Parameter( Mandatory = $true, Position = 1 )]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $NewName,

        [Parameter( Mandatory = $true, Position = 2 )]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Username,

        [Parameter( Mandatory = $true, Position = 3 )]
        [AllowEmptyString()]
        [AllowNull()]
        [String[]]
        $Password
    )

    Process {

        # FTP Request
        $FtpRequest = [System.Net.FtpWebRequest]::Create($ItemToRename)
        $FtpRequest.Timeout = 30000
        $FtpRequest.ReadWriteTimeout = 10000
        $FtpRequest.KeepAlive = $False
        $FtpRequest.UseBinary = $True
        $FtpRequest.UsePassive = $True
        $FtpRequest.Credentials = New-Object System.Net.NetworkCredential($Username, $Password)
        $FtpRequest.Method = [System.Net.WebRequestMethods+FTP]::Rename
        $FtpRequest.RenameTo = $NewName

        # Send the Ftp Request to the Server
        Try {
            $FtpResponse = $FtpRequest.GetResponse()
        }
        Catch {
            Write-Host "`nError : $_" -ForegroundColor Red
            Break
        }

        Write-Host "`nSuccess : '$ItemToRename' was correctly renamed to '$NewName'" -ForegroundColor Green

        # Close Connections
        $FtpResponse.Close()
    }
}

#== Other Functions ==================================================
#=====================================================================

Function Receive-Stream {

    Param( 
        [System.IO.Stream]$Reader,
        $FileName,
        $Encoding = [System.Text.Encoding]::GetEncoding($Null) 
    )
   
    If ($FileName) {
        $Writer = New-Object System.IO.FileStream $FileName, "Create"
    }
    Else {
        [String] $Output = ""
    }
       
    [Byte[]] $Buffer = New-Object Byte[] 4096
    [Int] $Total = [Int]$Count = 0
    
    Do {
        $Count = $Reader.Read($Buffer, 0, $Buffer.Length)
        If ($FileName) {
            $Writer.Write($Buffer, 0, $Count)
        }
        Else {
            $Output += $Encoding.GetString($Buffer, 0, $Count)
        }
    } 
    while ($count -gt 0)

    $Reader.Close()
    If (! $FileName) { $Output }
}

#== Export ===========================================================
#=====================================================================

Export-ModuleMember -Function Get-FtpFileList, Send-FtpFile, Get-FtpFile, Remove-FtpFile, New-FtpDirectory, Remove-FtpDirectory, Rename-FtpItem