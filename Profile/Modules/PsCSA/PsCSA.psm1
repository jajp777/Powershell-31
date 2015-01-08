<#

  	.NOTES
======================================================================
	Created on:   	03/06/14
 	Created by:   	JCU
	Organization: 	CARL Software
	Script name:	PsCSA
	Description:	Module permettant de controler CSA,
                    depuis le clientcsadmcli.
======================================================================

#>


#== Other ============================================================
#=====================================================================

    Filter Out-ColorWord {

        Param (

            [String[]] $Word,
            [String[]] $Color
        )

        $Line = $_
        $Index = $Line.IndexOf($Word, [System.StringComparison]::InvariantCultureIgnoreCase)

        While ($Index -ge 0){

            Write-Host $Line.Substring(0,$Index) -NoNewline
            Write-Host $Line.Substring($Index, $Word.Length) -NoNewline -ForegroundColor $Color
            $Used = $Word.Length + $Index
            $Remain = $Line.Length - $Used
            $Line = $Line.Substring($Used, $Remain)
            $Index = $Line.IndexOf($Word, [System.StringComparison]::InvariantCultureIgnoreCase)
        }

        Write-Host $Line
    }

    Function Format-Color ([Hashtable]$Colors = @{}, [Switch]$SimpleMatch) {

	    $Lines = ($Input | Out-String) -Replace "`r", "" -Split "`n"
	
        Foreach ($Line in $Lines) {

		    $Color = ''

		    Foreach ($Pattern in $Colors.Keys) {

			    If (!$SimpleMatch -and $Line -match $Pattern) {$Color = $Colors[$Pattern]}
			    Elseif ($SimpleMatch -and $Line -like $Pattern) {$Color = $Colors[$Pattern] }
		    }

		    If ($Color) {
			    Write-Host -ForegroundColor $Color $Line
		    }
            Else {
			    Write-Host $Line
		    }
	    }
    }

    Function Unprotect-PsCredential {

        <#
        .SYNOPSIS
            Permet de decrypter le mot de passe d'un objet PsCredential.
        .DESCRIPTION
            La fonction Unprotect-PsCredential permet de retourner en clair un mot de passe contenu dans un objet PsCredential, 
            afin de pouvoir l'utiliser dans d'autres outils ne prenant pas en charge les objets PsCredential.
        .PARAMETER Password
            Ce paramètre doit être un Mot de passe de type PsCredential.
        .EXAMPLE
            PS C:\> $PsCredential = Get-Credential
            PS C:\> $ClearPassword = Unprotect-PsCredential -Password $($PsCredential[0].Password)
        .NOTES
            Version:  0.1
        #>

        Param (
            [Parameter( Mandatory = $true, Position = 0 )]
            [ValidateNotNullOrEmpty()]
            $Password
        )

        Process {

            $Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($Password)
            [String[]] $Result = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)

            Return $Result
        }
    }

#== Actions ==========================================================
#=====================================================================


    Function Start-CSA {

        <#
        .SYNOPSIS
            Permet de demander le démarrage d'un élément de l'infrastructure.
        .DESCRIPTION
            La fonction Start-CSA demande le démarrage d’un élément de l’infrastructure dont le nom est spécifié par l’option –Target.
            Cette action ne peut s'appliquer qu'à une instance ou à un cluster.
            Si l'équipement n'est pas arrêté une erreur est retournée.
        .PARAMETER Target
            Nom de l’élément ciblé par l’action.
        .PARAMETER CSAHost
            Nom du serveur Carl Source Admin.
        .PARAMETER CSAHostPort
            Spécifie le port d'accès à la console CSA.
        .PARAMETER Credential
            Ce paramètre doit être un Mot de passe de type PsCredential.
        .EXAMPLE
            PS C:\> $Credential = Get-Credential CONTOSO\Admin
            PS C:\> Start-CSA -Target Instance-Production -CSAHost serveur-csa.contoso.com -CSAHostPort 8177 -Credential $Credential
        .NOTES
            Version:  0.1
        #>

        [CmdletBinding()]
        Param (

            [Parameter( Mandatory = $true, Position = 0 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $Target,

            [Parameter( Mandatory = $true, Position = 1 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $CSAHost,

            [Parameter( Mandatory = $true, Position = 2 )]
            [ValidateNotNullOrEmpty()]
            [Int]
            $CSAHostPort,

            [Parameter( Mandatory = $true, Position = 3 )]
            [ValidateNotNullOrEmpty()]
            [System.Management.Automation.Credential()]
            [System.Management.Automation.PSCredential]
            $Credential
        )

        Process {

            $UserName = $($Credential[0].UserName)
            $Password = Unprotect-PsCredential -Password $($Credential[0].Password)

            $Cmd = "csadmcli --action=start --equip='$($Target)' --url='http://$($CSAHost):$($CSAHostPort)/CSAdmin' --login='$($UserName)' --pswd='$($Password)'"
        
            # Execute Command
            $Job = Invoke-Expression "& $Cmd"

            # Format return code
            If ($LastExitCode -eq 0){
                $State = Get-CSAStatus -Status $Job -CSAHost $CSAHost -CSAHostPort $CSAHostPort -Credential $Credential
                If ($State -eq "RUNNING"){
                    Write-Host "`nSUCCES: Démarrage de '$Target' en cours (Job id: $Job)" -ForegroundColor Green
                    Enter-CSAJob -JobName "[Start] $Target" -JobId $Job -Status $State -CSAHost $CSAHost -CSAHostPort $CSAHostPort
                    Return "SUCCES: Démarrage de '$Target' en cours (Job id: $Job)"                    
                }
            }
            ElseIf ($LastExitCode -eq 1){
                Write-Host "`nCLIENT | $Job " -ForegroundColor Red
                Return "CLIENT | $Job "
            }
            Else {
                Write-Host "`nSERVER | $Job " -ForegroundColor Red
                Return "SERVER | $Job "
            }
        }
    }

    Function Stop-CSA {

        <#
        .SYNOPSIS
            Permet de demander l'arrêt d'un élément de l'infrastructure.
        .DESCRIPTION
            La fonction Stop-CSA demande l'arrêt d’un élément de l’infrastructure dont le nom est spécifié par l’option –Target.
            Cette action ne peut s'appliquer qu'à une instance ou à un cluster.
            Si l'équipement n'est pas arrêté une erreur est retournée.
        .PARAMETER Target
            Nom de l’élément ciblé par l’action.
        .PARAMETER CSAHost
            Nom du serveur Carl Source Admin.
        .PARAMETER CSAHostPort
            Spécifie le port d'accès à la console CSA.
        .PARAMETER Credential
            Ce paramètre doit être un Mot de passe de type PsCredential.
        .EXAMPLE
            PS C:\> $Credential = Get-Credential CONTOSO\Admin
            PS C:\> Stop-CSA -Target Instance-Production -CSAHost serveur-csa.contoso.com -CSAHostPort 8177 -Credential $Credential
        .NOTES
            Version:  0.1
        #>

        [CmdletBinding()]
        Param (

            [Parameter( Mandatory = $true, Position = 0 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $Target,

            [Parameter( Mandatory = $true, Position = 1 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $CSAHost,

            [Parameter( Mandatory = $true, Position = 2 )]
            [ValidateNotNullOrEmpty()]
            [Int]
            $CSAHostPort,

            [Parameter( Mandatory = $true, Position = 3 )]
            [ValidateNotNullOrEmpty()]
            [System.Management.Automation.Credential()]
            [System.Management.Automation.PSCredential]
            $Credential
        )

        Process {

            $UserName = $($Credential[0].UserName)
            $Password = Unprotect-PsCredential -Password $($Credential[0].Password)

            $Cmd = "csadmcli --action=stop --equip='$($Target)' --url='http://$($CSAHost):$($CSAHostPort)/CSAdmin' --login='$($UserName)' --pswd='$($Password)'"
        
            # Execute Command
            $Job = Invoke-Expression "& $Cmd"

            # Format return code
            If ($LastExitCode -eq 0){
                $State = Get-CSAStatus -Status $Job -CSAHost $CSAHost -CSAHostPort $CSAHostPort -Credential $Credential
                If ($State -eq "RUNNING"){
                    Write-Host "`nSUCCES: Arrêt de '$Target' en cours (Job id: $Job)" -ForegroundColor Green
                    Enter-CSAJob -JobName "[Stop] $Target" -JobId $Job -Status $State -CSAHost $CSAHost -CSAHostPort $CSAHostPort
                    Return "SUCCES: Arrêt de '$Target' en cours (Job id: $Job)"                    
                }
            }
            ElseIf ($LastExitCode -eq 1){
                Write-Host "`nCLIENT | $Job " -ForegroundColor Red
                Return "CLIENT | $Job "
            }
            Else {
                Write-Host "`nSERVER | $Job " -ForegroundColor Red
                Return "SERVER | $Job "
            }
        }
    }

    Function New-CSAFolder {

        <#
        .SYNOPSIS
            Permet de créer un dossier dans Carl Source Admin.
        .DESCRIPTION
            La fonction New-CSAFolder permet de créer un équipement de type dossier dans CSA.
        .PARAMETER Name
            Spécifie le nom du dossier CSA.
        .PARAMETER Root
            Nom de l'équipement auquel il sera rattaché. Si le paramètre n'est pas spécifié, le dossier sera créer à la racine.
        .PARAMETER CSAHost
            Nom du serveur Carl Source Admin.
        .PARAMETER CSAHostPort
            Spécifie le port d'accès à la console CSA.
        .PARAMETER Credential
            Ce paramètre doit être un Mot de passe de type PsCredential.
        .EXAMPLE
            PS C:\> New-CSAFolder -Name "Serveurs" -Root "" -CSAHost $Server -CSAHostPort $Port -Credential $Credential
        .EXAMPLE
            PS C:\> New-CSAFolder -Name "Jboss" -Root "Serveurs" -CSAHost $Server -CSAHostPort $Port -Credential $Credential
        .NOTES
            Version:  0.1
        #>

        [CmdletBinding()]
        Param (

            [Parameter( Mandatory = $true, Position = 0 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $Name,

            [Parameter( Mandatory = $false, Position = 1 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $Root,

            [Parameter( Mandatory = $true, Position = 2 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $CSAHost,

            [Parameter( Mandatory = $true, Position = 3 )]
            [ValidateNotNullOrEmpty()]
            [Int]
            $CSAHostPort,

            [Parameter( Mandatory = $true, Position = 4 )]
            [ValidateNotNullOrEmpty()]
            [System.Management.Automation.Credential()]
            [System.Management.Automation.PSCredential]
            $Credential
        )

        Process {

            If (Test-Path "C:\CSAdmcli\templates\Folder.txt"){

                $Template = "C:\CSAdmcli\templates\Folder.txt"
        
                $UserName = $($Credential[0].UserName)
                $Password = Unprotect-PsCredential -Password $($Credential[0].Password)

                $Cmd = "csadmcli --addEqpt='$($Template)' --eqptName='$($Name)' --url='http://$($CSAHost):$($CSAHostPort)/CSAdmin' --login='$($Username)' --pswd='$($Password)'"

                If ($Root){ $Cmd += " --parentEqptName='$Root'"} Else { $Cmd += " --parentEqptName=ROOT_EQUIPMENT" }

                # Execute Command
                $Job = Invoke-Expression "& $Cmd"

                # Format return code
                If ($LastExitCode -eq 0){
                    Write-Host "`nSUCCES: Création du dossier '$Name'" -ForegroundColor Green
                    Return "SUCCES: Création du dossier '$Name'"
                }
                ElseIf ($LastExitCode -eq 1){
                    Write-Host "`nCLIENT | $Job " -ForegroundColor Red
                    Return "CLIENT | $Job "
                }
                Else {
                    Write-Host "`nSERVER | $Job " -ForegroundColor Red
                    Return "SERVER | $Job "
                }
            }
            Else {
                Write-Host "`nERROR: Le template pour la création du dossier n'existe pas sous 'C:\CSAdmcli\templates\Folder.txt'" -ForegroundColor Red
                Return "ERROR: Le template pour la création du dossier n'existe pas sous 'C:\CSAdmcli\templates\Folder.txt'"
            }
        }
    }

    Function New-CSAHost {

        <#
        .SYNOPSIS
            Permet de créer un hôte dans Carl Source Admin.
        .DESCRIPTION
            La fonction New-CSAHost permet de créer un équipement de type hôte dans CSA.
        .PARAMETER LogicalName
            Définit le nom Logique qui sera affiché dans Carl Source Admin.
        .PARAMETER HostName
            Spécifie le nom fqdn de la machine qui sera ajoutée.
        .PARAMETER AdminLogin
            Indique le nom du compte Admin Local. (Par défaut: csadmin)
        .PARAMETER AdminPassword
            Indique le mot de passe du compte Admin Local.
        .PARAMETER Root
            Nom de l'équipement auquel il sera rattaché. Si le paramètre n'est pas spécifié, l'hôte sera créé à la racine.
        .PARAMETER UnzipDirCmd
        .PARAMETER ZipDirCmd
        .PARAMETER WinrmHttpsPort
        .PARAMETER WinrmHttpPort
        .PARAMETER WinrmProtocol
        .PARAMETER ConnectionProtocol
        .PARAMETER CSAHost
            Nom du serveur Carl Source Admin.
        .PARAMETER CSAHostPort
            Spécifie le port d'accès à la console CSA.
        .PARAMETER Credential
            Ce paramètre doit être un Mot de passe de type PsCredential.
        .EXAMPLE
            PS C:\> New-CSAHost -LogicalName TEST -HostName TEST.carl-intl.fr -Root "" -CSAHost TEST-CSA.Carl-intl.fr -CSAHostPort 8177 -Credential $Credential
        .EXAMPLE
            PS C:\> New-CSAHost -LogicalName TEST -HostName TEST.carl-intl.fr -Root "" -AdminPassword MotdepasseAdmin -CSAHost TEST-CSA.Carl-intl.fr -CSAHostPort 8177 -Credential $Credential
        .EXAMPLE
            PS C:\> New-CSAHost -LogicalName TEST -HostName TEST.carl-intl.fr -Root "" -AdminLogin AdminAccountName -AdminPassword MotdepasseAdmin -CSAHost TEST-CSA.Carl-intl.fr -CSAHostPort 8177 -Credential $Credential
        .NOTES
            Version:  0.1
        #>

        [CmdletBinding()]
        Param (

            [Parameter( Mandatory = $true, Position = 0 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $LogicalName,
        
            [Parameter( Mandatory = $true, Position = 1 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $HostName,

            [Parameter( Mandatory = $false, Position = 2 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $Root,

            [Parameter( Mandatory = $false, Position = 3 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $AdminLogin,

            [Parameter( Mandatory = $false, Position = 4 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $AdminPassword,

            [Parameter( Mandatory = $false, Position = 5 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $ConnectionProtocol,

            [Parameter( Mandatory = $false, Position = 6 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $WinrmProtocol,

            [Parameter( Mandatory = $false, Position = 7 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $WinrmHttpPort,

            [Parameter( Mandatory = $false, Position = 8 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $WinrmHttpsPort,

            [Parameter( Mandatory = $false, Position = 9 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $ZipDirCmd,

            [Parameter( Mandatory = $false, Position = 10 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $UnzipDirCmd,

            [Parameter( Mandatory = $false, Position = 11 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $OSVersion,

            [Parameter( Mandatory = $true, Position = 12 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $CSAHost,

            [Parameter( Mandatory = $true, Position = 13 )]
            [ValidateNotNullOrEmpty()]
            [Int]
            $CSAHostPort,

            [Parameter( Mandatory = $true, Position = 14 )]
            [ValidateNotNullOrEmpty()]
            [System.Management.Automation.Credential()]
            [System.Management.Automation.PSCredential]
            $Credential
        )

        Process {

            

            If (Test-Path "C:\CSAdmcli\templates\Host-Windows.txt"){

                $Template = "C:\CSAdmcli\templates\Host-Windows.txt"
        
                $UserName = $($Credential[0].UserName)
                $Password = Unprotect-PsCredential -Password $($Credential[0].Password)
            
                $Cmd = "csadmcli --addEqpt='$($Template)' --eqptName='$($LogicalName)' --hostName='$($HostName)' --carladminLogin='$($AdminLogin)' --carladminPassword='$($AdminPassword)' --url='http://$($CSAHost):$($CSAHostPort)/CSAdmin' --login='$($Username)' --pswd='$($Password)'"

                #$OSVersion = (Get-WmiObject -class Win32_OperatingSystem -ComputerName $HostName -ErrorAction Ignore).Version
                If ($OSVersion){ $Cmd += " --opsysVersion='$($OSVersion)'" } Else { $Cmd += " --opsysVersion=6.3.9600" }
                If ($Root){ $Cmd += " --parentEqptName='$($Root)'"} Else { $Cmd += " --parentEqptName=ROOT_EQUIPMENT" }
                If ($WorkDirPath){ $Cmd += " --workDirPath='$($WorkDirPath)'"} Else { $Cmd += " --workDirPath='C:\Users\$($AdminLogin)'" }
                If ($ConnectionProtocol){ $Cmd += " --connectionProtocol='$($ConnectionProtocol)'" }
                If ($WinrmProtocol){ $Cmd += " --winrmProtocol='$($WinrmProtocol)'" }
                If ($WinrmHttpPort){ $Cmd += " --winrmHttpPort='$($WinrmHttpPort)'" }
                If ($WinrmHttpsPort){ $Cmd += " --winrmHttpsPort='$($WinrmHttpsPort)'" }
                If ($ZipDirCmd){ $Cmd += " --zipDirCmd='$($ZipDirCmd)'" }
                If ($UnzipDirCmd){ $Cmd += " --unzipDirCmd='$($UnzipDirCmd)'" }

                # Execute Command
                $Job = Invoke-Expression "& $Cmd"

                # Format return code
                If ($LastExitCode -eq 0){
                    Write-Host "`nSUCCES: Création du host '$LogicalName'" -ForegroundColor Green
                    Return "SUCCES: Création du host '$LogicalName'"
                }
                ElseIf ($LastExitCode -eq 1){
                    Write-Host "`nCLIENT | $Job " -ForegroundColor Red
                    Return "CLIENT | $Job "
                }
                Else {
                    Write-Host "`nSERVER | $Job " -ForegroundColor Red
                    Return "SERVER | $Job |"
                }
            }
            Else {
                Write-Host "`nERROR: Le template pour la création du host n'existe pas sous 'C:\CSAdmcli\templates\Host-Windows.txt'" -ForegroundColor Red
                Return "ERROR: Le template pour la création du host n'existe pas sous 'C:\CSAdmcli\templates\Host-Windows.txt'"
            }
        }
    }

    Function New-CSADatabase {

        <#
        .SYNOPSIS
            Permet de créer un élément du type base de données dans Carl Source Admin.
        .DESCRIPTION
            La fonction New-CSADatabase permet de créer un équipement de type database dans CSA.
        .PARAMETER LogicalName
            Définit le nom Logique qui sera affiché dans Carl Source Admin.
        .PARAMETER HostName
            Spécifie le nom logique (CSA) auquel la base de donnée sera rattachée.
        .PARAMETER DbaLogin
            Indique le nom du compte Administrateur de la base de donnée.
        .PARAMETER DbaPassword
            Indique le mot de passe du compte Administrateur de la base de donnée.
        .PARAMETER DBInstance
        .PARAMETER DBVersion
        .PARAMETER DBCollation
        .PARAMETER Root
            Nom du dossier auquel il sera rattaché. Si le paramètre n'est pas spécifié, l'équipement sera créer à la racine.
        .PARAMETER CSAHost
            Nom du serveur Carl Source Admin.
        .PARAMETER CSAHostPort
            Spécifie le port d'accès à la console CSA.
        .PARAMETER Credential
            Ce paramètre doit être un Mot de passe de type PsCredential.
        .EXAMPLE
            PS C:\> New-CSAHost -LogicalName TEST -HostName TEST.carl-intl.fr -Root "Hosts" -CSAHost TEST-CSA.Carl-intl.fr -CSAHostPort 8177 -Credential $Credential
        .EXAMPLE
            PS C:\> New-CSAHost -LogicalName TEST -HostName TEST.carl-intl.fr -DbaLogin sa -DbaPassword Mdp1234 -CSAHost TEST-CSA.Carl-intl.fr -CSAHostPort 8177 -Credential $Credential
        .EXAMPLE
            PS C:\> New-CSAHost -LogicalName TEST -HostName TEST.carl-intl.fr -DbaLogin sa -DbaPassword Mdp1234 -DBCollation French_CI_AS -DBVersion 11.00.3000.00 -CSAHost TEST-CSA.Carl-intl.fr -CSAHostPort 8177 -Credential $Credential
        .NOTES
            Version:  0.1
        #>

        [CmdletBinding()]
        Param (

            [Parameter( Mandatory = $true, Position = 0 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $LogicalName,
        
            [Parameter( Mandatory = $true, Position = 1 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $HostName,

            [Parameter( Mandatory = $false, Position = 2 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $Root,

            [Parameter( Mandatory = $false, Position = 3 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $DBLogin,

            [Parameter( Mandatory = $false, Position = 4 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $DBPassword,

            [Parameter( Mandatory = $false, Position = 5 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $DBInstance,

            [Parameter( Mandatory = $false, Position = 6 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $DBVersion,

            [Parameter( Mandatory = $false, Position = 7 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $DBCollation,

            [Parameter( Mandatory = $true, Position = 8 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $CSAHost,

            [Parameter( Mandatory = $true, Position = 9 )]
            [ValidateNotNullOrEmpty()]
            [Int]
            $CSAHostPort,

            [Parameter( Mandatory = $true, Position = 10 )]
            [ValidateNotNullOrEmpty()]
            [System.Management.Automation.Credential()]
            [System.Management.Automation.PSCredential]
            $Credential
        )

        Process {

            [String] $InfoSrv = Get-CSAEquipInfo -Target $HostName -CSAHost $CSAHost -CSAHostPort $CSAHostPort -Credential $Credential

            If ($LastExitCode -eq 0){
                $Found = $InfoSrv -Match "hostName.+carladminLogin"
                If ($Found) {
                    $InfoSrv = $Matches[0]
                }

                $InfoSrv = $InfoSrv.Replace("hostName", "")
                $InfoSrv = $InfoSrv.Replace("carladminLogin", "")
                $InfoSrv = $InfoSrv.Replace(" ", "")

                $Jdbc = "jdbc:sqlserver://$($InfoSrv):1433;InstanceName=$($DBInstance)"
            

                If (Test-Path "C:\CSAdmcli\templates\Database.txt"){

                    $Template = "C:\CSAdmcli\templates\Database.txt"
        
                    $UserName = $($Credential[0].UserName)
                    $Password = Unprotect-PsCredential -Password $($Credential[0].Password)
            
                    $Cmd = "csadmcli --addEqpt='$($Template)' --eqptName='$($LogicalName)' --host='HOST $($HostName)' --dbaLogin='$($DBLogin)' --dbaPassword='$($DBPassword)' --jdbcUrl='$($Jdbc)' --instanceName='$($DBInstance)' --url='http://$($CSAHost):$($CSAHostPort)/CSAdmin' --login='$($Username)' --pswd='$($Password)'"

                    If ($DBVersion){ $Cmd += " --dbVersion='$($DBVersion)'" }
                    If ($DBCollation){ $Cmd += " --dbCollation='$($DBCollation)'" }
                    If ($Root){ $Cmd += " --parentEqptName='$Root'"} Else { $Cmd += " --parentEqptName=ROOT_EQUIPMENT" }

                    # Execute Command
                    $Job = Invoke-Expression "& $Cmd"

                    # Format return code
                    If ($LastExitCode -eq 0){
                        Write-Host "`nSUCCES: Création de la base de donnée '$LogicalName'" -ForegroundColor Green
                        Return "SUCCES: Création de la base de donnée '$LogicalName'"
                    }
                    ElseIf ($LastExitCode -eq 1){
                        Write-Host "`nCLIENT | $Job " -ForegroundColor Red
                        Return "CLIENT | $Job "
                    }
                    Else {
                        Write-Host "`nSERVER | $Job " -ForegroundColor Red
                        Return "SERVER | $Job "
                    }
                }
                Else {
                    Write-Host "`nERROR: Le template pour la création de la base de donnée n'existe pas sous 'C:\CSAdmcli\templates\Database.txt'" -ForegroundColor Red
                    Return "ERROR: Le template pour la création de la base de donnée n'existe pas sous 'C:\CSAdmcli\templates\Database.txt'"
                }
            }
            Else {
                Write-Host "`nERROR: Le serveur SQL hôte '$HostName' n'a pas été trouvé sur Carl Source Admin" -ForegroundColor Red
                Return "ERROR: Le serveur SQL hôte '$HostName' n'a pas été trouvé sur Carl Source Admin"
            }
        }
    }

    Function New-CSADatasource {

        <#
        .SYNOPSIS
            Permet de créer un dossier dans Carl Source Admin.
        .DESCRIPTION
            La fonction New-CSAFolder permet de créer un équipement de type dossier dans CSA.
        .PARAMETER LogicalName
            Définit le nom Logique qui sera affiché dans Carl Source Admin.
        .PARAMETER HostName
            Spécifie le nom logique (CSA) auquel la base de donnée sera rattachée. (Ex: Database)
        .PARAMETER DBName

        .PARAMETER DBUserLogin
            Indique le nom du compte Utilisateur de la base de donnée.
        .PARAMETER DBUserPassword
            Indique le mot de passe du compte Administrateur de la base de donnée.
        .PARAMETER DBCollation

        .PARAMETER DatabaseSize
            Taille du fichier de la base en Mb.
        .PARAMETER LogSize
            Taille du fichier de logs en Mb.
        .PARAMETER Root
            Nom de l'équipement auquel il sera rattaché. Si le paramètre n'est pas spécifié, le dossier sera créer à la racine.
        .PARAMETER Licence

        .PARAMETER CSAHost
            Nom du serveur Carl Source Admin.
        .PARAMETER CSAHostPort
            Spécifie le port d'accès à la console CSA.
        .PARAMETER Credential
            Ce paramètre doit être un Mot de passe de type PsCredential.
        .EXAMPLE
            PS C:\> New-CSAHost -LogicalName TEST -HostName TEST.carl-intl.fr -Root "Hosts" -CSAHost TEST-CSA.Carl-intl.fr -CSAHostPort 8177 -Credential $Credential
        .EXAMPLE
            PS C:\> New-CSAHost -LogicalName TEST -HostName TEST.carl-intl.fr -DbaLogin sa -DbaPassword Mdp1234 -CSAHost TEST-CSA.Carl-intl.fr -CSAHostPort 8177 -Credential $Credential
        .EXAMPLE
            PS C:\> New-CSAHost -LogicalName TEST -HostName TEST.carl-intl.fr -DbaLogin sa -DbaPassword Mdp1234 -DBCollation French_CI_AS -DBVersion 11.00.3000.00 -CSAHost TEST-CSA.Carl-intl.fr -CSAHostPort 8177 -Credential $Credential
        .NOTES
            Version:  0.1
        #>

        [CmdletBinding()]
        Param (

            [Parameter( Mandatory = $true, Position = 0 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $LogicalName,

            [Parameter( Mandatory = $true, Position = 1 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $SQLHostName,
        
            [Parameter( Mandatory = $true, Position = 2 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $HostName,
        
            [Parameter( Mandatory = $true, Position = 3 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $DBName,

            [Parameter( Mandatory = $true, Position = 4 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $DBUserLogin,

            [Parameter( Mandatory = $true, Position = 5 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $DBUserPassword,

            [Parameter( Mandatory = $false, Position = 6 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $DBCollation,

            [Parameter( Mandatory = $false, Position = 7 )]
            [ValidateNotNullOrEmpty()]
            [Int]
            $DatabaseSize,

            [Parameter( Mandatory = $false, Position = 8 )]
            [ValidateNotNullOrEmpty()]
            [Int]
            $LogSize,

            [Parameter( Mandatory = $false, Position = 9 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $Licence,

            [Parameter( Mandatory = $true, Position = 10 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $CSAHost,

            [Parameter( Mandatory = $true, Position = 11 )]
            [ValidateNotNullOrEmpty()]
            [Int]
            $CSAHostPort,

            [Parameter( Mandatory = $true, Position = 12 )]
            [ValidateNotNullOrEmpty()]
            [System.Management.Automation.Credential()]
            [System.Management.Automation.PSCredential]
            $Credential
        )

        Process {

            $Jdbc = "jdbc:sqlserver://$($SQLHostName):1433;databaseName=$DBName;sendStringParametersAsUnicode=false"

            If (Test-Path "C:\CSAdmcli\templates\Datasource.txt"){

                $Template = "C:\CSAdmcli\templates\Datasource.txt"
        
                $UserName = $($Credential[0].UserName)
                $Password = Unprotect-PsCredential -Password $($Credential[0].Password)
            
                $Cmd = "csadmcli --addEqpt='$($Template)' --eqptName='$($LogicalName)' --parentEqptName='$($HostName)' --dbName='$($DBName)' --dbUserLogin='$($DBUserLogin)' --dbUserPassword='$($DBUserPassword)' --jdbcUrl='$($Jdbc)' --url='http://$($CSAHost):$($CSAHostPort)/CSAdmin' --login='$($Username)' --pswd='$($Password)'"

                If ($DBCollation){ $Cmd += " --collation='$($DBCollation)'" }
                If ($DatabaseSize){ [String]$DatabaseSize = "$DatabaseSize" + "Mb"; $Cmd += " --size1='$($DatabaseSize)'" }
                If ($LogSize){ [String]$LogSize = "$LogSize" + "Mb"; $Cmd += " --size2='$($LogSize)'" }
                If ($Licence){ $Cmd += " --deploy.customer='$($Licence)'" }

                # Execute Command
                $Job = Invoke-Expression "& $Cmd"

                # Format return code
                If ($LastExitCode -eq 0){
                    Write-Host "`nSUCCES: Création de la Datasource '$LogicalName'" -ForegroundColor Green
                    Return "SUCCES: Création de la Datasource '$LogicalName'"
                }
                ElseIf ($LastExitCode -eq 1){
                    Write-Host "`nCLIENT | $Job " -ForegroundColor Red
                    Return "CLIENT | $Job "
                }
                Else {
                    Write-Host "`nSERVER | $Job " -ForegroundColor Red
                    Return "SERVER | $Job "
                }
            }
            Else {
                Write-Host "`nERROR: Le template pour la création de la Datasource n'existe pas sous 'C:\CSAdmcli\templates\Datasource.txt'" -ForegroundColor Red
                Return "ERROR: Le template pour la création de la Datasource n'existe pas sous 'C:\CSAdmcli\templates\Datasource.txt'"
            }
        }
    }

    Function New-CSAJBoss {

        <#
        .SYNOPSIS
            Permet de créer un conteneur JBoss dans Carl Source Admin.
        .DESCRIPTION
            La fonction New-CSAJBoss permet de créer un équipement de type JBoss dans CSA.
        .PARAMETER LogicalName
            Définit le nom Logique qui sera affiché dans Carl Source Admin.
        .PARAMETER HostName
            Spécifie le nom logique (CSA) auquel le conteneur JBoss sera rattachée. (Ex: Serveur-JBoss)
        .PARAMETER Root
            Nom de l'équipement auquel il sera rattaché. Si le paramètre n'est pas spécifié, l'équipement sera créer à la racine.
        .PARAMETER JBossPath
            Chemin du conteneur JBoss sur le serveur Hôte. (Par défaut: C:\CARLappl\jboss423)
        .PARAMETER JdkVersion
            Numéro de version du Jdk Java. (Ex: 1.6.0_43)
        .PARAMETER JBossVersion
            Numéro de version du conteneur JBoss. (Ex: 4.2.3)
        .PARAMETER CSAHost
            Nom du serveur Carl Source Admin.
        .PARAMETER CSAHostPort
            Spécifie le port d'accès à la console CSA.
        .PARAMETER Credential
            Ce paramètre doit être un Mot de passe de type PsCredential.
        .EXAMPLE
            PS C:\> New-CSAJBoss -LogicalName JBoss -HostName Serveur-JBoss.carl-intl.fr -Root "CARL" -CSAHost TEST-CSA.Carl-intl.fr -CSAHostPort 8177 -Credential $Credential
        .EXAMPLE
            PS C:\> New-CSAJBoss -LogicalName JBoss -HostName Serveur-JBoss.carl-intl.fr -Root "CARL" -JBossPath "C:\CARLappl\jboss423" -CSAHost TEST-CSA.Carl-intl.fr -CSAHostPort 8177 -Credential $Credential
        .EXAMPLE
            PS C:\> New-CSAJBoss -LogicalName JBoss -HostName Serveur-JBoss.carl-intl.fr -Root "CARL" -JdkVersion 1.6.0_43 -CSAHost TEST-CSA.Carl-intl.fr -CSAHostPort 8177 -Credential $Credential
        .EXAMPLE
            PS C:\> New-CSAJBoss -LogicalName JBoss -HostName Serveur-JBoss.carl-intl.fr -Root "CARL" -JBossVersion 4.2.3 -CSAHost TEST-CSA.Carl-intl.fr -CSAHostPort 8177 -Credential $Credential
        .NOTES
            Version:  0.1
        #>

        [CmdletBinding()]
        Param (

            [Parameter( Mandatory = $true, Position = 0 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $LogicalName,
        
            [Parameter( Mandatory = $true, Position = 1 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $HostName,

            [Parameter( Mandatory = $false, Position = 2 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $Root,

            [Parameter( Mandatory = $false, Position = 3 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $JBossVersion,

            [Parameter( Mandatory = $false, Position = 4 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $JBossPath,

            [Parameter( Mandatory = $false, Position = 5 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $JdkVersion,

            [Parameter( Mandatory = $true, Position = 6 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $CSAHost,

            [Parameter( Mandatory = $true, Position = 7 )]
            [ValidateNotNullOrEmpty()]
            [Int]
            $CSAHostPort,

            [Parameter( Mandatory = $true, Position = 8 )]
            [ValidateNotNullOrEmpty()]
            [System.Management.Automation.Credential()]
            [System.Management.Automation.PSCredential]
            $Credential
        )

        Process {

            If (Test-Path "C:\CSAdmcli\templates\JBoss.txt"){

                $Temlpate = "C:\CSAdmcli\templates\JBoss.txt"
        
                $UserName = $($Credential[0].UserName)
                $Password = Unprotect-PsCredential -Password $($Credential[0].Password)
            
                $Cmd = "csadmcli --addEqpt='$($Temlpate)' --eqptName='$($LogicalName)' --host='HOST $($HostName)' --url='http://$($CSAHost):$($CSAHostPort)/CSAdmin' --login='$($Username)' --pswd='$($Password)'"

                If ($Root){ $Cmd += " --parentEqptName='$Root'"} Else { $Cmd += " --parentEqptName=ROOT_EQUIPMENT" }
                If ($JBossPath){ $Cmd += " --homeDirPath='$($JBossPath)'" }
                If ($JdkVersion){ $Cmd += " --jdkVersion='$($JdkVersion)'" }
                If ($JBossVersion){ $Cmd += " --containerVersion='$($JBossVersion)'" }

                # Execute Command
                $Job = Invoke-Expression "& $Cmd"

                # Format return code
                If ($LastExitCode -eq 0){
                    Write-Host "`nSUCCES: Création du conteneur JBoss '$LogicalName'" -ForegroundColor Green
                    Return "`nSUCCES: Création du conteneur JBoss '$LogicalName'"
                }
                ElseIf ($LastExitCode -eq 1){
                    Write-Host "`nCLIENT | $Job " -ForegroundColor Red
                    Return "`nCLIENT | $Job "
                }
                Else {
                    Write-Host "`nSERVER | $Job " -ForegroundColor Red
                    Return "`nSERVER | $Job "
                }
            }
            Else {
                Write-Host "`nERROR: Le template pour la création du conteneur JBoss n'existe pas sous 'C:\CSAdmcli\templates\JBoss.txt'" -ForegroundColor Red
                Return "`nERROR: Le template pour la création du conteneur JBoss n'existe pas sous 'C:\CSAdmcli\templates\JBoss.txt'"
            }
        }
    }

    Function New-CSAInstance {

        <#
        .SYNOPSIS
            Permet de créer un conteneur JBoss dans Carl Source Admin.
        .DESCRIPTION
            La fonction New-CSAJBoss permet de créer un équipement de type JBoss dans CSA.
        .PARAMETER LogicalName
            Définit le nom Logique qui sera affiché dans Carl Source Admin.
        .PARAMETER HostName
            Spécifie le nom logique (CSA) auquel le conteneur JBoss sera rattachée. (Ex: Serveur-JBoss)
        .PARAMETER InstanceName
        .PARAMETER ServiceName
        .PARAMETER Licence
        .PARAMETER WebPort
        .PARAMETER JMXPort
        .PARAMETER HomeDirPath
        .PARAMETER DeployDirPath
        .PARAMETER DocRootDirPath
        .PARAMETER CsContext
        .PARAMETER CsPublicUrl
        .PARAMETER BirtContext
        .PARAMETER BirtPublicUrl
        .PARAMETER AuthSSO
        .PARAMETER MailServer
        .PARAMETER MailFrom
        .PARAMETER NodeName
        .PARAMETER OverwriteGatewayInstallation
        .PARAMETER WebSocketGateway
        .PARAMETER WebSocketHostname
        .PARAMETER WebSocketPort
        .PARAMETER TouchAppliExternalURL
        .PARAMETER ExecDirPath
        .PARAMETER TempDirPath
        .PARAMETER SynchroServerPublicURL
        .PARAMETER CSAHost
            Nom du serveur Carl Source Admin.
        .PARAMETER CSAHostPort
            Spécifie le port d'accès à la console CSA.
        .PARAMETER Credential
            Ce paramètre doit être un Mot de passe de type PsCredential.
        .EXAMPLE
            PS C:\> New-CSAJBoss -LogicalName JBoss -HostName Serveur-JBoss.carl-intl.fr -Root "CARL" -CSAHost TEST-CSA.Carl-intl.fr -CSAHostPort 8177 -Credential $Credential
        .NOTES
            Version:  0.1
        #>

        [CmdletBinding()]
        Param (

            [Parameter( Mandatory = $true, Position = 0 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $LogicalName,

            [Parameter( Mandatory = $true, Position = 1 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $Datasource,

            [Parameter( Mandatory = $true, Position = 2 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $HostName,

            [Parameter( Mandatory = $true, Position = 3 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $InstanceName,

            [Parameter( Mandatory = $false, Position = 4 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $ServiceName,

            [Parameter( Mandatory = $false, Position = 5 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $Licence,

            [Parameter( Mandatory = $false, Position = 6 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $WebPort,

            [Parameter( Mandatory = $false, Position = 7 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $JMXPort,

            [Parameter( Mandatory = $false, Position = 8 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $HomeDirPath,

            [Parameter( Mandatory = $false, Position = 9 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $DeployDirPath,

            [Parameter( Mandatory = $false, Position = 10 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $DocRootDirPath,

            [Parameter( Mandatory = $false, Position = 11 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $CsContext,

            [Parameter( Mandatory = $false, Position = 12 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $CsPublicUrl,

            [Parameter( Mandatory = $false, Position = 13 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $BirtContext,

            [Parameter( Mandatory = $false, Position = 14 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $BirtPublicUrl,

            [Parameter( Mandatory = $false )]
            [Switch]
            $AuthSSO,

            [Parameter( Mandatory = $false, Position = 15 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $MailServer,

            [Parameter( Mandatory = $false, Position = 16 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $MailFrom,

            [Parameter( Mandatory = $false, Position = 17 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $NodeName,

            [Parameter( Mandatory = $false )]
            [Switch]
            $OverwriteGatewayInstallation,

            [Parameter( Mandatory = $false, Position = 18 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $WebSocketGateway,

            [Parameter( Mandatory = $false, Position = 19 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $WebSocketHostname,

            [Parameter( Mandatory = $false, Position = 20 )]
            [ValidateNotNullOrEmpty()]
            [Int]
            $WebSocketPort,

            [Parameter( Mandatory = $false, Position = 21 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $TouchAppliExternalURL,

            [Parameter( Mandatory = $false, Position = 22 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $ExecDirPath,

            [Parameter( Mandatory = $false, Position = 23 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $TempDirPath,

            [Parameter( Mandatory = $false, Position = 24 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $SynchroServerPublicURL,

            [Parameter( Mandatory = $true, Position = 25 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $CSAHost,

            [Parameter( Mandatory = $true, Position = 26 )]
            [ValidateNotNullOrEmpty()]
            [Int]
            $CSAHostPort,

            [Parameter( Mandatory = $true, Position = 27 )]
            [ValidateNotNullOrEmpty()]
            [System.Management.Automation.Credential()]
            [System.Management.Automation.PSCredential]
            $Credential
        )

        Process {

            If (Test-Path "C:\CSAdmcli\templates\Instance.txt"){

                $Temlpate = "C:\CSAdmcli\templates\Instance.txt"
        
                $UserName = $($Credential[0].UserName)
                $Password = Unprotect-PsCredential -Password $($Credential[0].Password)
            
                $Cmd = "csadmcli --addEqpt='$($Temlpate)' --parentEqptName='$($HostName)' --eqptName='$($LogicalName)' --appli.datasource='DATASOURCE $($Datasource)' --instanceName='$($InstanceName)' --url='http://$($CSAHost):$($CSAHostPort)/CSAdmin' --login='$($Username)' --pswd='$($Password)'"

                If ($Licence){ $Cmd += " --deploy.customer='$($Licence)'" }
                If ($ServiceName){ $Cmd += " --serviceName='$($ServiceName)'" }
                If ($WebPort){ $Cmd += " --webPort='$($WebPort)'" }
                If ($JMXPort){ $Cmd += " --jmxPort='$($JMXPort)'" }
                If ($HomeDirPath){ $Cmd += " --homeDirPath='$($HomeDirPath)'"} Else { $Cmd += " --homeDirPath='C:\CARLappl\jboss423\server\$($InstanceName)'" }
                If ($DeployDirPath){ $Cmd += " --deployDirPath='$($DeployDirPath)'"} Else { $Cmd += " --deployDirPath='C:\CARLappl\jboss423\server\$($InstanceName)\deploy'" }
                If ($DocRootDirPath){ $Cmd += " --appli.docRootDirPath='$($DocRootDirPath)'" }
                If ($CsContext){ $Cmd += " --appli.csContext='$($CsContext)'" }
                If ($CsPublicUrl){ $Cmd += " --appli.csPublicUrl='$($CsPublicUrl)'" }
                If ($BirtContext){ $Cmd += " --birtContext='$($BirtContext)'" }
                If ($BirtPublicUrl){ $Cmd += " --birtPublicUrl='$($BirtPublicUrl)'" }
                If ($AuthSSO){ $Cmd += " --appli.authSSO='true'" }
                If ($MailServer){ $Cmd += " --mailServer='$($MailServer)'" }
                If ($MailFrom){ $Cmd += " --mailFrom='$($MailFrom)'" }
                If ($NodeName){ $Cmd += " --nodeName='$($NodeName)'" }
                If ($OverwriteGatewayInstallation){ $Cmd += " --appli.overwriteGatewayInstallation='true'" }
                If ($WebSocketGateway){ $Cmd += " --appli.webSocketGateway='$($WebSocketGateway)'" }
                If ($WebSocketHostname){ $Cmd += " --appli.webSocketHostname='$($WebSocketHostname)'" }
                If ($WebSocketPort){ $Cmd += " --appli.webSocketPort='$($WebSocketPort)'" }
                If ($TouchAppliExternalURL){ $Cmd += " --appli.touchAppliExternalURL='$($TouchAppliExternalURL)'" }
                If ($ExecDirPath){ $Cmd += " --appli.execDirPath='$($ExecDirPath)'" }
                If ($TempDirPath){ $Cmd += " --appli.tempDirPath='$($TempDirPath)'" }
                If ($SynchroServerPublicURL){ $Cmd += " --appli.synchroServerPublicURL='$($SynchroServerPublicURL)'" }

                # Execute Command
                $Job = Invoke-Expression "& $Cmd"

                # Format return code
                If ($LastExitCode -eq 0){
                    Write-Host "`nSUCCES: Création de l'instance Carl Source '$LogicalName'" -ForegroundColor Green
                    Return "SUCCES: Création de l'instance Carl Source '$LogicalName'"
                }
                ElseIf ($LastExitCode -eq 1){
                    Write-Host "`nCLIENT | $Job " -ForegroundColor Red
                    Return "CLIENT | $Job "
                }
                Else {
                    Write-Host "`nSERVER | $Job " -ForegroundColor Red
                    Return "SERVER | $Job "
                }
            }
            Else {
                Write-Host "`nERROR: Le template pour la création de l'instance Carl Source n'existe pas sous 'C:\CSAdmcli\templates\Instance.txt'" -ForegroundColor Red
                Return "ERROR: Le template pour la création de l'instance Carl Source n'existe pas sous 'C:\CSAdmcli\templates\Instance.txt'"
            }
        }
    }

    Function Add-CSADistribs {  

        <#
        .SYNOPSIS
            Permet d'ajouter des distributions, addons, et patchs sur CSA.
        .DESCRIPTION
            La fonction Add-CSADistribs ajoute des distributions dans CSA, pour permettre de les utiliser dans des déploiements.
        .PARAMETER Distribs
            Ce paramètre doit être un Tableau, et doit contenir les chemins des fichiers .zip.
        .PARAMETER ToUpload
            Va permetttre d'uploader les fichiers .zip sur le serveur Carl Source Admin.
        .PARAMETER CSAHost
            Nom du serveur Carl Source Admin.
        .PARAMETER CSAHostPort
            Spécifie le port d'accès à la console CSA.
        .PARAMETER Credential
            Ce paramètre doit être un Mot de passe de type PsCredential.
        .EXAMPLE
            PS C:\> $Distribs = @("C:\Temp\carlsource_v4.0.2_c.zip", "C:\Temp\carlsource_cm_fr_v4.0.2-A1-L1_a.zip")
            PS C:\> Add-CSADistribs -Distribs $Array -CSAHost $Server -CSAHostPort $Port -Credential $Credential
        .EXAMPLE
            PS C:\> $Distribs = @("C:\Users\Mes Documents\Carl Source Distributions\carlsource_v4.0.2_c.zip", "C:\Users\Mes Documents\Carl Source Distributions\carlsource_cm_fr_v4.0.2-A1-L1_a.zip")
            PS C:\> Add-CSADistribs -Distribs $Array -CSAHost $Server -CSAHostPort $Port -Credential $Credential -ToUpload
        .NOTES
            Version:  0.1
        #>

        [CmdletBinding()]
        Param (

            [Parameter( Mandatory = $true, Position = 0 )]
            [ValidateNotNullOrEmpty()]
            [Array]
            $Distribs,

            [Parameter( Mandatory = $false )]
            [Switch]
            $ToUpload,

            [Parameter( Mandatory = $true, Position = 1 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $CSAHost,

            [Parameter( Mandatory = $true, Position = 2 )]
            [ValidateNotNullOrEmpty()]
            [Int]
            $CSAHostPort,

            [Parameter( Mandatory = $true, Position = 3 )]
            [ValidateNotNullOrEmpty()]
            [System.Management.Automation.Credential()]
            [System.Management.Automation.PSCredential]
            $Credential
        )

        Process {

            $UserName = $($Credential[0].UserName)
            $Password = Unprotect-PsCredential -Password $($Credential[0].Password)
            $Return = @()

            For ( $i=0; $i -lt $Distribs.Length; $i++ ){

                If ($ToUpload) {
                    $Cmd = "csadmcli --addDistrib=toupload:'$($Distribs[$i])' --url='http://$($CSAHost):$($CSAHostPort)/CSAdmin' --login='$($Username)' --pswd='$($Password)'"
                }
                Else {
                    $Cmd = "csadmcli --addDistrib='$($Distribs[$i])' --url='http://$($CSAHost):$($CSAHostPort)/CSAdmin' --login='$($Username)' --pswd='$($Password)'"
                }

                # Execute Command
                $Job = Invoke-Expression "& $Cmd"

                # Format return code
                If ($LastExitCode -eq 0){
                    Write-Host "`nSUCCES: Upload et Déploiement du package '$($Distribs[$i])'" -ForegroundColor Green
                    $Return += "SUCCES: Upload et Déploiement du package '$($Distribs[$i])'"
                }
                ElseIf ($LastExitCode -eq 1){
                    Write-Host "`nCLIENT | $Job " -ForegroundColor Red
                    $Return += "CLIENT | $Job "
                }
                Else {
                    Write-Host "`nSERVER | $Job " -ForegroundColor Red
                    $Return += "SERVER | $Job "
                }

                Sleep 1
            }

            Return $Return
        }
    }

    Function Start-CSADeploy {

        <#
        .SYNOPSIS
            Permet de déployer un Carl Source, une langue, un addon etc.
        .DESCRIPTION
            La fonction Start-CSADeploy execute le déploiement d'une ou plusieurs distribution sur une instance.
        .PARAMETER Target
            Nom logique de l'instance Carl Source à déployer.
        .PARAMETER Distribs
            ID des distributions a déployer, en tant que chaine de caractère (ex: "carlsource_v4.0.2,carlsource_fr_v4.0.2-L1,carlsource_help_v4.0.2-A1")
        .PARAMETER CSAHost
            Nom du serveur Carl Source Admin.
        .PARAMETER CSAHostPort
            Spécifie le port d'accès à la console CSA.
        .PARAMETER Credential
            Ce paramètre doit être un Mot de passe de type PsCredential.
        .EXAMPLE
            PS C:\> $Distribs = "carlsource_v4.0.2,carlsource_fr_v4.0.2-L1,carlsource_help_v4.0.2-A1,carlsource_help_fr_v4.0.2-A1-L1"
            PS C:\> $Credential = Get-Credential CONTOSO\Admin
            PS C:\> Start-CSADeploy -Target "Instance-Production" -Distribs $Distribs -CSAHost serveur-csa.contoso.com -CSAHostPort 8177 -Credential $Credential
        .NOTES
            Version:  0.1
        #>

        [CmdletBinding()]
        Param (

            [Parameter( Mandatory = $true, Position = 0 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $Target,

            [Parameter( Mandatory = $true, Position = 1 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $Distribs,

            [Parameter( Mandatory = $false, Position = 2 )]
            [Switch]
            $Backup,

            [Parameter( Mandatory = $true, Position = 3 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $CSAHost,

            [Parameter( Mandatory = $true, Position = 4 )]
            [ValidateNotNullOrEmpty()]
            [Int]
            $CSAHostPort,

            [Parameter( Mandatory = $true, Position = 5 )]
            [ValidateNotNullOrEmpty()]
            [System.Management.Automation.Credential()]
            [System.Management.Automation.PSCredential]
            $Credential
        )

        Process {

            $UserName = $($Credential[0].UserName)
            $Password = Unprotect-PsCredential -Password $($Credential[0].Password)

            $Cmd = "csadmcli --action=deploy --addDistribs='$($Distribs)' --equip='$($Target)' --url='http://$($CSAHost):$($CSAHostPort)/CSAdmin' --login='$($Username)' --pswd='$($Password)'"

            # Options
            If ($Backup){ $Cmd += " --backupBefore=true" } Else { $Cmd += " --backupBefore=false" }

            # Execute Command
            $Job = Invoke-Expression "& $Cmd"

            # Format return code
            If ($LastExitCode -eq 0){
                $State = Get-CSAStatus -Status $Job -CSAHost $CSAHost -CSAHostPort $CSAHostPort -Credential $Credential
                If ($State -eq "RUNNING"){
                    Write-Host "`nSUCCES: Déploiement sur '$Target' en cours (Job id: $Job)" -ForegroundColor Green
                    Enter-CSAJob -JobName "[Deploy] $Target" -JobId $Job -Status $State -CSAHost $CSAHost -CSAHostPort $CSAHostPort
                    Return "SUCCES: Déploiement sur '$Target' en cours (Job id: $Job)"                    
                }
            }
            ElseIf ($LastExitCode -eq 1){
                Write-Host "`nCLIENT | $Job " -ForegroundColor Red
                Return "CLIENT | $Job "
            }
            Else {
                Write-Host "`nSERVER | $Job " -ForegroundColor Red
                Return "SERVER | $Job "
            }
        }
    }

#== Backup, Restore, Duplicate, Clean, Scan, Import, Loaddata ========
#=====================================================================

    Function Start-CSABackup {

        <#
        .SYNOPSIS
            Permet de faire la sauvegarde d’une instance ou d'un cluster.
        .DESCRIPTION
            La fonction Start-CSABackup permet de lancer la sauvegarde d’une instance ou d'un cluster dont le nom est spécifié par l’option –Target.
            Cette action peut s’appliquer à une instance ou à un cluster.
            Si l’équipement est démarré il sera automatiquement arrêté.
        .PARAMETER Target
            Nom de l’élément ciblé par l’action.
        .PARAMETER OnlyData
             Au lieu de lancer une sauvergarde complète, cela execute la sauvegarde du répertoire de déploiement sur le serveur applicatif.
             Ne peut être utilisé avec OnlyApp.
        .PARAMETER OnlyApp
            Au lieu de lancer une sauvergarde complète, cela execute la sauvegarde du schéma sur le serveur de données.
            Ne peut être utilisé avec OnlyData.
        .PARAMETER CSAHost
            Nom du serveur Carl Source Admin.
        .PARAMETER CSAHostPort
            Spécifie le port d'accès à la console CSA.
        .PARAMETER Credential
            Ce paramètre doit être un Mot de passe de type PsCredential.
        .EXAMPLE
            PS C:\> $Credential = Get-Credential CONTOSO\Admin
            PS C:\> Start-CSA -Target Instance-Production -CSAHost serveur-csa.contoso.com -CSAHostPort 8177 -Credential $Credential
        .NOTES
            Version:  0.1
        #>

        [CmdletBinding()]
        Param (

            [Parameter( Mandatory = $true, Position = 0 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $Target,

            [Parameter( Mandatory = $false )]
            [Switch]
            $OnlyData,

            [Parameter( Mandatory = $false )]
            [Switch]
            $OnlyApp,

            [Parameter( Mandatory = $true, Position = 1 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $CSAHost,

            [Parameter( Mandatory = $true, Position = 2 )]
            [ValidateNotNullOrEmpty()]
            [Int]
            $CSAHostPort,

            [Parameter( Mandatory = $true, Position = 3 )]
            [ValidateNotNullOrEmpty()]
            [System.Management.Automation.Credential()]
            [System.Management.Automation.PSCredential]
            $Credential
        )

        Process {

            $UserName = $($Credential[0].UserName)
            $Password = Unprotect-PsCredential -Password $($Credential[0].Password)

            If (($OnlyData) -and ($OnlyApp)){

                Return "ERROR: Les options OnlyData et OnlyApp, ne peuvent être utilisés en même temps."
            }
            Else {
            
                $Cmd = "csadmcli --action=backup --equip='$($Target)' --url='http://$($CSAHost):$($CSAHostPort)/CSAdmin' --login='$($UserName)' --pswd='$($Password)'"

                If ($OnlyData){ $Cmd += " --tiers=app" }
                If ($OnlyApp){ $Cmd += " --tiers=dat" }
        
                # Execute Command
                $Job = Invoke-Expression "& $Cmd"

                # Format return code
                If ($LastExitCode -eq 0){
                    $State = Get-CSAStatus -Status $Job -CSAHost $CSAHost -CSAHostPort $CSAHostPort -Credential $Credential
                    If ($State -eq "RUNNING"){
                        Write-Host "`nSUCCES: Backup de '$Target' en cours (Job id: $Job)" -ForegroundColor Green
                        Enter-CSAJob -JobName "[Backup] $Target" -JobId $Job -Status $State -CSAHost $CSAHost -CSAHostPort $CSAHostPort
                        Return "SUCCES: Backup de '$Target' en cours (Job id: $Job)"                        
                    }
                }
                ElseIf ($LastExitCode -eq 1){
                    Write-Host "`nCLIENT | $Job " -ForegroundColor Red
                    Return "CLIENT | $Job "
                }
                Else {
                    Write-Host "`nSERVER | $Job " -ForegroundColor Red
                    Return "SERVER | $Job "
                }
            }
        }
    }

    Function Start-CSARestore {

        <#
        .SYNOPSIS
            Permet de faire la sauvegarde d’une instance ou d'un cluster.
        .DESCRIPTION
            La fonction Start-CSABackup permet de lancer la sauvegarde d’une instance ou d'un cluster dont le nom est spécifié par l’option –Target.
            Cette action peut s’appliquer à une instance ou à un cluster.
            Si l’équipement est démarré il sera automatiquement arrêté.
        .PARAMETER Target
            Nom de l’élément ciblé par l’action.
        .PARAMETER BackupFile
            Chemin du fichier .zip qui contient le backup.
        .PARAMETER ToUpload
            Permet d'uploader le fichier .zip du backup. (BackupFile)
        .PARAMETER RestoreApp
            Pour préciser la restauration de l'application.
        .PARAMETER BackupBefore
            Effectue une sauvegarde complète avant la restauration.
        .PARAMETER BaseDir

        .PARAMETER CSAHost
            Nom du serveur Carl Source Admin.
        .PARAMETER CSAHostPort
            Spécifie le port d'accès à la console CSA.
        .PARAMETER Credential
            Ce paramètre doit être un Mot de passe de type PsCredential.
        .EXAMPLE
            PS C:\> $Credential = Get-Credential CONTOSO\Admin
            PS C:\> Start-CSA -Target Instance-Production -CSAHost serveur-csa.contoso.com -CSAHostPort 8177 -Credential $Credential
        .NOTES
            Version:  0.1
        #>

        [CmdletBinding()]
        Param (

            [Parameter( Mandatory = $true, Position = 0 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $Target,

            [Parameter( Mandatory = $true, Position = 1 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $BackupFile,

            [Parameter( Mandatory = $false )]
            [Switch]
            $RestoreApp,

            [Parameter( Mandatory = $false )]
            [Switch]
            $BackupBefore,

            [Parameter( Mandatory = $false )]
            [Switch]
            $ToUpload,

            [Parameter( Mandatory = $true, Position = 2 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $BaseDir,

            [Parameter( Mandatory = $true, Position = 3 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $CSAHost,

            [Parameter( Mandatory = $true, Position = 4 )]
            [ValidateNotNullOrEmpty()]
            [Int]
            $CSAHostPort,

            [Parameter( Mandatory = $true, Position = 5 )]
            [ValidateNotNullOrEmpty()]
            [System.Management.Automation.Credential()]
            [System.Management.Automation.PSCredential]
            $Credential
        )

        Process {

            $UserName = $($Credential[0].UserName)
            $Password = Unprotect-PsCredential -Password $($Credential[0].Password)

            If ($ToUpload) { 
                $Cmd = "csadmcli --action=restore --equip='$($Target)' --backupFile=toupload:'$($BackupFile)' --url='http://$($CSAHost):$($CSAHostPort)/CSAdmin' --login='$($UserName)' --pswd='$($Password)'"
            }
            Else {
                $Cmd = "csadmcli --action=restore --equip='$($Target)' --backupFile='$($BackupFile)' --url='http://$($CSAHost):$($CSAHostPort)/CSAdmin' --login='$($UserName)' --pswd='$($Password)'"
            }

            #If ($BaseDir){ $Cmd += " --baseDir='$($BaseDir)'" }
            If ($BaseDir){ 

                $Cmd += " --dir_doc_DOC='$($BaseDir)\librairies'"
                $Cmd += " --dir_doc_ICON='$($BaseDir)\librairies'"
                $Cmd += " --dir_doc_IMG='$($BaseDir)\librairies'"
                $Cmd += " --dir_doc_PLAN='$($BaseDir)\librairies'"

                $Cmd += " --dir_rpt_BIRT='$($BaseDir)\birt'"

                $Cmd += " --dir_edp_CSV::INPUTDIR='$($BaseDir)\interfaces\in'"
                $Cmd += " --dir_edp_CSV::INPUTSTOREDIR='$($BaseDir)\interfaces\in'"
                $Cmd += " --dir_edp_CTR_REGLEMENTAIRE::INPUTDIR='$($BaseDir)\interfaces\in'"
                $Cmd += " --dir_edp_CTR_REGLEMENTAIRE::INPUTSTOREDIR='$($BaseDir)\interfaces\in'"
                $Cmd += " --dir_edp_FILE_DIR::INPUTDIR='$($BaseDir)\interfaces\in'"

                $Cmd += " --dir_edp_CSV::OUTPUTDIR='$($BaseDir)\interfaces\out'"
                $Cmd += " --dir_edp_CSV::OUTPUTSTOREDIR='$($BaseDir)\interfaces\out'"
                $Cmd += " --dir_edp_CTR_REGLEMENTAIRE::OUTPUTDIR='$($BaseDir)\interfaces\out'"
                $Cmd += " --dir_edp_CTR_REGLEMENTAIRE::OUTPUTSTOREDIR='$($BaseDir)\interfaces\out'"
                $Cmd += " --dir_edp_FILE_DIR::OUTPUTDIR='$($BaseDir)\interfaces\out'"
            }
            If ($RestoreApp){ $Cmd += " --restoreAppli=true" } Else { $Cmd += " --restoreAppli=false" }
            If ($BackupBefore){ $Cmd += " --backupBefore=true" } Else { $Cmd += " --backupBefore=false" }
            # --dir_<dirType>_<dirCode>=<dirPath>
        
            # Execute Command
            $Job = Invoke-Expression "& $Cmd"

            # Format return code
            If ($LastExitCode -eq 0){
                $State = Get-CSAStatus -Status $Job -CSAHost $CSAHost -CSAHostPort $CSAHostPort -Credential $Credential
                If ($State -eq "RUNNING"){
                    Write-Host "`nSUCCES: Restauration de '$Target' en cours (Job id: $Job)" -ForegroundColor Green
                    Enter-CSAJob -JobName "[Restore] $Target" -JobId $Job -Status $State -CSAHost $CSAHost -CSAHostPort $CSAHostPort
                    Return "SUCCES: Restauration de '$Target' en cours (Job id: $Job)"                    
                }
            }
            ElseIf ($LastExitCode -eq 1){
                Write-Host "`nCLIENT | $Job " -ForegroundColor Red
                Return "CLIENT | $Job "
            }
            Else {
                Write-Host "`nSERVER | $Job " -ForegroundColor Red
                Return "SERVER | $Job "
            }
        }
    }

    Function New-CSAImport {

        <#
        .SYNOPSIS
            Permet d'importer une sauvegarde.
        .DESCRIPTION
            La fonction Start-CSABackup permet d'importer une sauvegarde d'un autre Carl Source.
        .PARAMETER Target
            Nom de l’élément ciblé par l’action.
        .PARAMETER AppBackupFile
            Chemin de la sauvegarde (.zip) de l'application.
        .PARAMETER DataBackupFile
            Chemin de la sauvegarde (.zip) des données.
        .PARAMETER CSAHost
            Nom du serveur Carl Source Admin.
        .PARAMETER CSAHostPort
            Spécifie le port d'accès à la console CSA.
        .PARAMETER Credential
            Ce paramètre doit être un Mot de passe de type PsCredential.
        .EXAMPLE
            PS C:\> $Credential = Get-Credential CONTOSO\Admin
            PS C:\> Start-CSA -Target Instance-Production -CSAHost serveur-csa.contoso.com -CSAHostPort 8177 -Credential $Credential
        .NOTES
            Version:  0.1
        #>

        [CmdletBinding()]
        Param (

            [Parameter( Mandatory = $true, Position = 0 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $Target,

            [Parameter( Mandatory = $false, Position = 1 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $AppBackupFile,

            [Parameter( Mandatory = $false, Position = 2 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $DataBackupFile,

            [Parameter( Mandatory = $true, Position = 3 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $CSAHost,

            [Parameter( Mandatory = $true, Position = 4 )]
            [ValidateNotNullOrEmpty()]
            [Int]
            $CSAHostPort,

            [Parameter( Mandatory = $true, Position = 5 )]
            [ValidateNotNullOrEmpty()]
            [System.Management.Automation.Credential()]
            [System.Management.Automation.PSCredential]
            $Credential
        )

        Process {

            $UserName = $($Credential[0].UserName)
            $Password = Unprotect-PsCredential -Password $($Credential[0].Password)

            $Cmd = "csadmcli --action=import --equip='$($Target)' --url='http://$($CSAHost):$($CSAHostPort)/csadmin' --login='$($UserName)' --pswd='$($Password)'"

            If ($AppBackupFile){ $Cmd += " --appBackup='$($AppBackupFile)'" }
            If ($DataBackupFile){ $Cmd += " --datBackup='$($DataBackupFile)'" }
            If ( !(!($DataBackupFile) -and !($AppBackupFile)) ){

                # Execute Command
                $Job = Invoke-Expression "& $Cmd"

                # Format return code
                If ($LastExitCode -eq 0){
                    $State = Get-CSAStatus -Status $Job -CSAHost $CSAHost -CSAHostPort $CSAHostPort -Credential $Credential
                    If ($State -eq "RUNNING"){

                        Write-Host "`nSUCCES: Importation de la sauvegarde (Job id: $Job)" -ForegroundColor Green
                        Enter-CSAJob -JobName "[Import] $Target" -JobId $Job -Status $State -CSAHost $CSAHost -CSAHostPort $CSAHostPort
                        Return "SUCCES: Importation de la sauvegarde (Job id: $Job)"                        
                    }
                }
                ElseIf ($LastExitCode -eq 1){
                    Write-Host "`nCLIENT | $Job " -ForegroundColor Red
                    Return "CLIENT | $Job "
                }
                Else {
                    Write-Host "`nSERVER | $Job " -ForegroundColor Red
                    Return "SERVER | $Job "
                }
            }
            Else {
                Write-Host "`nERROR: Aucun fichier sauvegarde 'Data' ou 'App' n'a été spécifié." -ForegroundColor Red
                Return "ERROR: Aucun fichier sauvegarde 'Data' ou 'App' n'a été spécifié."
            }
        }
    }


    Function Start-CSADuplicate {

        <#
        .SYNOPSIS
            Permet de dupliquer une instance Carl Source.
        .DESCRIPTION
            La fonction Start-CSADuplicate permet de dupliquer une instance Carl Source. 
            La duplication ne peut se faire que sur une instance déployée.
        .PARAMETER Target
            Nom de l'instance Carl Source à dupliquer.
        .PARAMETER Dest
            Nom de l'instance Carl Source ou va être fait la duplication.
        .PARAMETER BackupBefore
            Effectue une sauvegarde complète avant la restauration.
        .PARAMETER BaseDir
            Chemin de restauration des fichiers.
        .PARAMETER CSAHost
            Nom du serveur Carl Source Admin.
        .PARAMETER CSAHostPort
            Spécifie le port d'accès à la console CSA.
        .PARAMETER Credential
            Ce paramètre doit être un Mot de passe de type PsCredential.
        .EXAMPLE
            PS C:\> $Credential = Get-Credential CONTOSO\Admin
            PS C:\> Start-CSA -Target Instance-Production -CSAHost serveur-csa.contoso.com -CSAHostPort 8177 -Credential $Credential
        .NOTES
            Version:  0.1
        #>

        [CmdletBinding()]
        Param (

            [Parameter( Mandatory = $true, Position = 0 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $Target,

            [Parameter( Mandatory = $true, Position = 1 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $Dest,

            [Parameter( Mandatory = $false )]
            [Switch]
            $BackupBefore,

            [Parameter( Mandatory = $true, Position = 2 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $BaseDir,

            [Parameter( Mandatory = $true, Position = 3 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $CSAHost,

            [Parameter( Mandatory = $true, Position = 4 )]
            [ValidateNotNullOrEmpty()]
            [Int]
            $CSAHostPort,

            [Parameter( Mandatory = $true, Position = 5 )]
            [ValidateNotNullOrEmpty()]
            [System.Management.Automation.Credential()]
            [System.Management.Automation.PSCredential]
            $Credential
        )

        Process {

            $UserName = $($Credential[0].UserName)
            $Password = Unprotect-PsCredential -Password $($Credential[0].Password)

            If ($BackupBefore){
                $Cmd = "csadmcli --action=duplicate --equip='$($Target)' --url='http://$($CSAHost):$($CSAHostPort)/CSAdmin' --login='$($UserName)' --pswd='$($Password)' --dstEquip='$($Dest)' --backupBefore=true"
            }
            Else {
                $Cmd = "csadmcli --action=duplicate --equip='$($Target)' --url='http://$($CSAHost):$($CSAHostPort)/CSAdmin' --login='$($UserName)' --pswd='$($Password)' --dstEquip='$($Dest)' --backupBefore=false"
            }

            If ($BaseDir){ $Cmd += " --baseDir='$($BaseDir)'" }
            #--dir_<dirType>_<dirCode>=<dirPath>
        
            # Execute Command
            $Job = Invoke-Expression "& $Cmd"

            # Format return code
            If ($LastExitCode -eq 0){
                $State = Get-CSAStatus -Status $Job -CSAHost $CSAHost -CSAHostPort $CSAHostPort -Credential $Credential
                If ($State -eq "RUNNING"){
                    Write-Host "`nSUCCES: Duplication de '$Target' sur '$Dest' en cours (Job id: $Job)" -ForegroundColor Green
                    Enter-CSAJob -JobName "[Duplicate] $Target" -JobId $Job -Status $State -CSAHost $CSAHost -CSAHostPort $CSAHostPort
                    Return "SUCCES: Duplication de '$Target' sur '$Dest' en cours (Job id: $Job)"                    
                }
            }
            ElseIf ($LastExitCode -eq 1){
                Write-Host "`nCLIENT | $Job " -ForegroundColor Red
                Return "CLIENT | $Job "
            }
            Else {
                Write-Host "`nSERVER | $Job " -ForegroundColor Red
                Return "SERVER | $Job "
            }
        }
    }


    Function Add-CSAXML {

        <#
        .SYNOPSIS
            Permet de charger un fichier xml sur une instance Carl Source.
        .DESCRIPTION
            La fonction Add-CSAXML permet de charger un fichier xml sur une instance Carl Source. 
            Cela permet de modifier des configurations de Carl Source tel que la configuration LDAP.
        .PARAMETER Target
            Nom de l'instance Carl Source à dupliquer.
        .PARAMETER XMLFile
            Chemin du fichier XML à charger.
        .PARAMETER CSAHost
            Nom du serveur Carl Source Admin.
        .PARAMETER CSAHostPort
            Spécifie le port d'accès à la console CSA.
        .PARAMETER Credential
            Ce paramètre doit être un Mot de passe de type PsCredential.
        .EXAMPLE
            PS C:\> $Credential = Get-Credential CONTOSO\Admin
            PS C:\> Add-CSAXML -Target Instance-Production -XMLFile 'C:\Temp\Afile.xml' -CSAHost serveur-csa.contoso.com -CSAHostPort 8177 -Credential $Credential
        .NOTES
            Version:  0.1
        #>

        [CmdletBinding()]
        Param (

            [Parameter( Mandatory = $true, Position = 0 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $Target,

            [Parameter( Mandatory = $true, Position = 1 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $XMLFile,

            [Parameter( Mandatory = $true, Position = 3 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $CSAHost,

            [Parameter( Mandatory = $true, Position = 4 )]
            [ValidateNotNullOrEmpty()]
            [Int]
            $CSAHostPort,

            [Parameter( Mandatory = $true, Position = 5 )]
            [ValidateNotNullOrEmpty()]
            [System.Management.Automation.Credential()]
            [System.Management.Automation.PSCredential]
            $Credential
        )

        Process {

            $UserName = $($Credential[0].UserName)
            $Password = Unprotect-PsCredential -Password $($Credential[0].Password)

            $Cmd = "csadmcli --action=loaddata --equip='$($Target)' --file='$($XMLFile)' --url='http://$($CSAHost):$($CSAHostPort)/CSAdmin' --login='$($UserName)' --pswd='$($Password)'"
        
            # Execute Command
            $Job = Invoke-Expression "& $Cmd"

            # Format return code
            If ($LastExitCode -eq 0){
                $State = Get-CSAStatus -Status $Job -CSAHost $CSAHost -CSAHostPort $CSAHostPort -Credential $Credential
                If ($State -eq "RUNNING"){
                    Write-Host "`nSUCCES: Chargement de '$XMLFile' sur l'instance '$Target' en cours (Job id: $Job)" -ForegroundColor Green
                    Enter-CSAJob -JobName "[Load XML] $Target" -JobId $Job -Status $State -CSAHost $CSAHost -CSAHostPort $CSAHostPort
                    Return "SUCCES: Chargement de '$XMLFile' sur l'instance '$Target' en cours (Job id: $Job)"                    
                }
            }
            ElseIf ($LastExitCode -eq 1){
                Write-Host "`nCLIENT | $Job " -ForegroundColor Red
                Return "CLIENT | $Job "
            }
            Else {
                Write-Host "`nSERVER | $Job " -ForegroundColor Red
                Return "SERVER | $Job "
            }
        }
    }

    Function Clear-CSAInstance {

        <#
        .SYNOPSIS
            Permet de nettoyer une instance CARL Source.
        .DESCRIPTION
            La fonction Clear-CSAInstance permet de nettoyer logiquement ou physiquement une instane CARL Source via l'action CLEAN.
            Si l’équipement est démarré il sera automatiquement arrêté.
        .PARAMETER Target
            Nom de l’élément ciblé par l’action.
        .PARAMETER CSAHost
            Nom du serveur Carl Source Admin.
        .PARAMETER CSAHostPort
            Spécifie le port d'accès à la console CSA.
        .PARAMETER Credential
            Ce paramètre doit être un Mot de passe de type PsCredential.
        .EXAMPLE
            PS C:\> $Credential = Get-Credential CONTOSO\Admin
            PS C:\> Clear-CSAInstance -Target Instance-Production -CSAHost serveur-csa.contoso.com -CSAHostPort 8177 -Credential $Credential
        .NOTES
            Version:  0.1
        #>

        [CmdletBinding()]
        Param (

            [Parameter( Mandatory = $true, Position = 0 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $Target,

            [Parameter( Mandatory = $true, Position = 1 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $CSAHost,

            [Parameter( Mandatory = $true, Position = 2 )]
            [ValidateNotNullOrEmpty()]
            [Int]
            $CSAHostPort,

            [Parameter( Mandatory = $true, Position = 3 )]
            [ValidateNotNullOrEmpty()]
            [System.Management.Automation.Credential()]
            [System.Management.Automation.PSCredential]
            $Credential
        )

        Process {

            $UserName = $($Credential[0].UserName)
            $Password = Unprotect-PsCredential -Password $($Credential[0].Password)
            
            $Cmd = "csadmcli --action=clean --equip='$($Target)' --url='http://$($CSAHost):$($CSAHostPort)/CSAdmin' --login='$($UserName)' --pswd='$($Password)'"
        
            # Execute Command
            $Job = Invoke-Expression "& $Cmd"

            # Format return code
            If ($LastExitCode -eq 0){
                $State = Get-CSAStatus -Status $Job -CSAHost $CSAHost -CSAHostPort $CSAHostPort -Credential $Credential
                If ($State -eq "RUNNING"){
                    Write-Host "`nSUCCES: Nettoyage de '$Target' en cours (Job id: $Job)" -ForegroundColor Green                    
                    Enter-CSAJob -JobName "[Clean] $Target" -JobId $Job -Status $State -CSAHost $CSAHost -CSAHostPort $CSAHostPort
                    Return "SUCCES: Nettoyage de '$Target' en cours (Job id: $Job)"
                }
            }
            ElseIf ($LastExitCode -eq 1){
                Write-Host "`nCLIENT | $Job " -ForegroundColor Red
                Return "CLIENT | $Job "
            }
            Else {
                Write-Host "`nSERVER | $Job " -ForegroundColor Red
                Return "SERVER | $Job "
            }
        }
    }

    # Scan
    # csadmcli --action=scan --equip=<equipName> --url=<serverUrl> --login=<user> --pswd=<password>


#== Job Status, Equipement Info ======================================
#=====================================================================


    Function Get-CSAStatus {

        [CmdletBinding()]
        Param (

            [Parameter( Mandatory = $true, Position = 0 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $Status,

            [Parameter( Mandatory = $true, Position = 1 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $CSAHost,

            [Parameter( Mandatory = $true, Position = 2 )]
            [ValidateNotNullOrEmpty()]
            [Int]
            $CSAHostPort,

            [Parameter( Mandatory = $true, Position = 3 )]
            [ValidateNotNullOrEmpty()]
            [System.Management.Automation.Credential()]
            [System.Management.Automation.PSCredential]
            $Credential
        )

        Process {

            $UserName = $($Credential[0].UserName)
            $Password = Unprotect-PsCredential -Password $($Credential[0].Password)
         
            csadmcli --status=$($Status) --url=http://$($CSAHost):$($CSAHostPort)/CSAdmin --login=$($UserName) --pswd=$($Password)
        }
    }

    Function Get-CSAEquipInfo {

        <#
        .SYNOPSIS
            Permet d'obtenir des informations sur un équipement.
        .DESCRIPTION
            La fonction Get-CSAEquipInfo retourne les propriétés/valeurs d'un équipement CSA.
        .PARAMETER Target
            Nom de l’élément ciblé par l’action.
        .PARAMETER CSAHost
            Nom du serveur Carl Source Admin.
        .PARAMETER CSAHostPort
            Spécifie le port d'accès à la console CSA.
        .PARAMETER Credential
            Ce paramètre doit être un Mot de passe de type PsCredential.
        .EXAMPLE
            PS C:\> Get-CSAEquipInfo -Target Instance-Production -CSAHost serveur-csa.contoso.com -CSAHostPort 8177 -Credential $Credential
            parentEqptName                     TEST-CS-JBOSS
            eqptType                           INSTANCE
            eqptName                           Instance-Production
            deploy.customer                    S01546654 : Carl Source - Licence Demo
            deploy.deployStatus                OK
            instanceName                       Instance-Production
            serviceName                        JBoss AS 4.2.3 CS02
            webPort                            8080
            jmxPort                            9180
            homeDirPath                        C:\CARLappl\jboss423\server\Instance-Production
            deployDirPath                      C:\CARLappl\jboss423\server\Instance-Production\deploy
            appli.datasource                   DATASOURCE Carlsource-mssql-prod
            appli.docRootDirPath               C:\CARLdata\extfiles
            appli.csContext                    gmaoCS02
            appli.csPublicUrl                  http://FRONTAL-APACHE/gmaoCS02
            appli.birtContext                  birtCS02
            appli.birtPublicUrl                http://FRONTAL-APACHE/birtCS02
            appli.authSSO                      false
            mailServer                         smtp.mail.com
            mailFrom                           noreply@mail.com
            mailDebug                          false
            nodeName
            roleList
            appli.overwriteGatewayInstallation false
            appli.webSocketGateway
            appli.webSocketHostname
            appli.webSocketPort
            appli.touchAppliExternalURL        http://FRONTAL-APACHE/gmaoCS02
            appli.execDirPath
            appli.tempDirPath
            appli.synchroServerPublicURL       http://FRONTAL-APACHE/gmaoCS02
        .NOTES
            Version:  0.1
        #>

        [CmdletBinding()]
        Param (

            [Parameter( Mandatory = $true, Position = 0 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $Target,

            [Parameter( Mandatory = $true, Position = 1 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $CSAHost,

            [Parameter( Mandatory = $true, Position = 2 )]
            [ValidateNotNullOrEmpty()]
            [Int]
            $CSAHostPort,

            [Parameter( Mandatory = $true, Position = 3 )]
            [ValidateNotNullOrEmpty()]
            [System.Management.Automation.Credential()]
            [System.Management.Automation.PSCredential]
            $Credential
        )

        Process {

            $UserName = $($Credential[0].UserName)
            $Password = Unprotect-PsCredential -Password $($Credential[0].Password)
         
            csadmcli --equipinfo=$($Target) --url=http://$($CSAHost):$($CSAHostPort)/CSAdmin --login=$($UserName) --pswd=$($Password)
        }
    }

    Function Enter-CSAJob {

        Param (

            [Parameter( Mandatory = $true, Position = 0 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $JobName,

            [Parameter( Mandatory = $true, Position = 1 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $JobId,

            [Parameter( Mandatory = $true, Position = 2 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $Status,

            [Parameter( Mandatory = $true, Position = 3 )]
            [ValidateNotNullOrEmpty()]
            [String[]]
            $CSAHost,

            [Parameter( Mandatory = $true, Position = 4 )]
            [ValidateNotNullOrEmpty()]
            [Int]
            $CSAHostPort
        )    

        Begin {

            If ($Script:JobList -eq $null){
                # Création Tableau
                $Script:JobList = @()
                [Int]$Script:JobCounter = $null
            }
        }

        Process {

            $Date = Get-Date -Format "[dd/MM/yy] HH:mm:ss"
        
            $Script:JobCounter ++
         
            $Objet = New-Object Psobject
            $Objet | Add-Member -Name "N°" -membertype Noteproperty -Value $Script:JobCounter
            $Objet | Add-Member -Name "Nom Job" -membertype Noteproperty -Value "$JobName"
            $Objet | Add-Member -Name "ID Job" -membertype Noteproperty -Value "$JobId"
            $Objet | Add-Member -Name "Status" -membertype Noteproperty -Value "$Status"
            $Objet | Add-Member -Name "CSA Serveur" -membertype Noteproperty -Value "$($CSAHost):$($CSAHostPort)"
            $Objet | Add-Member -Name "Début" -membertype Noteproperty -Value "$Date"

            [Array] $Script:JobList += $Objet
        }
    }

    Function Get-CSAJob {  

        <#
        .SYNOPSIS
            Permet de retourner les informations concernant les Actions lancées.
        .DESCRIPTION
            La fonction Get-CSAJob renvoie un tableau d'objets, récapitulant tout les jobs lancés dans cette session Powershell.
            Attention, le récapitulatif des jobs est effacé à la fin de la session Powershell
        .PARAMETER Credential
            Ce paramètre doit être un Mot de passe de type PsCredential.
        .EXAMPLE
            PS C:\> $Credential = Get-Credential CONTOSO\Admin
            PS C:\> Stop-CSA -Target Instance-Production -CSAHost serveur-csa.contoso.com -CSAHostPort 8177 -Credential $Credential
        .NOTES
            Version:  0.1
        #>

        [CmdletBinding()]
        Param (

            [Parameter( Mandatory = $true, Position = 0 )]
            [ValidateNotNullOrEmpty()]
            [System.Management.Automation.Credential()]
            [System.Management.Automation.PSCredential]
            $Credential,

            [Parameter( Mandatory = $false )]
            [Switch]
            $OnlyRunning
        )

        Process {
    
            If ($Script:JobList -ne $null){

                For ($i = 0 ; $i -lt $Script:JobList.Count ; $i++){

                    If ( $($Script:JobList[$i].Status) -eq "RUNNING"){

                        $State = Get-CSAStatus -Status $($Script:JobList[$i].'ID Job') -CSAHost $((($Script:JobList[$i].'CSA Serveur').Split(":"))[0]) -CSAHostPort $((($Script:JobList[$i].'CSA Serveur').Split(":"))[1]) -Credential $Credential

                        If ( $State -ne $($Script:JobList[$i].Status) ){
                            $Script:JobList[$i].Status = $State
                        }
                    }
                }
                              
                If ($OnlyRunning) {
                    Return $($Script:JobList | Where { $_.Status -eq "RUNNING" })
                }
                Else {
                    Return [Array] $Script:JobList
                }
            }
            Else {
                Write-Host "`nERROR: Impossible d'afficher la liste de Job, aucune action n'a été lancé." -ForegroundColor Red
                Return "ERROR: Impossible d'afficher la liste de Job, aucune action n'a été lancé."
            }
        }
    }

    Function Wait-CSAJob {  

        <#
        .SYNOPSIS
            Permet de faire patienter l'execution du script, le temps que le Job CSA se termine.
        .DESCRIPTION
            La fonction Wait-CSAJob récupère la liste des jobs en cours et attends la fin de leur exécutions.
        .PARAMETER Credential
            Ce paramètre doit être un Mot de passe de type PsCredential.
        .EXAMPLE
            PS C:\> $Credential = Get-Credential CONTOSO\Admin
            PS C:\> Stop-CSA -Target Instance-Production -CSAHost serveur-csa.contoso.com -CSAHostPort 8177 -Credential $Credential
        .NOTES
            Version:  0.1
        #>

        [CmdletBinding()]
        Param (

            [Parameter( Mandatory = $true, Position = 0 )]
            [ValidateNotNullOrEmpty()]
            [System.Management.Automation.Credential()]
            [System.Management.Automation.PSCredential]
            $Credential
        )

        Process {
            
            $Jobs = Get-CSAJob -Credential $Credential -OnlyRunning
            If (($Jobs -ne $null) -and ($Jobs -notmatch "ERROR:")){ Write-Host "`nUn ou plusieurs Jobs sont en cours d'exécution, veuillez patienter.." -ForegroundColor Yellow }
            While (($Jobs -ne $null) -and ($Jobs -notmatch "ERROR:")){
                $Jobs = Get-CSAJob -Credential $Credential -OnlyRunning
            }
        }
    }

#== Export ===========================================================
#=====================================================================

    #Export-ModuleMember -Function Start-CSA, Stop-CSA, New-CSAFolder, New-CSAHost, New-CSADatabase, New-CSADatasource, New-CSAJBoss, New-CSAInstance, Add-CSADistribs, Start-CSADeploy, New-CSAImport, Start-CSABackup, Get-CSAJob, Get-CSAStatus, Get-CSAEquipInfo, Clear-CSAInstance, Start-CSARestore