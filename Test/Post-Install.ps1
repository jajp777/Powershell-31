# ------------------------------------------------------------------ #
# Script:         Post-Install                                       #
# Auteur:         Julian Da Cunha                                    #
# Date:           26/03/14                                           #
# Description:    Automatisation Post-déploiement                    #
# Version:        0.1                                                #
# ------------------------------------------------------------------ #

Cls

# Vars
# ====================================================================

    $Script:Hostname = $Env:Computername
    #$User = "$Env:Userdomain\$Env:Username"
    $Script:User = "BUILTIN\Utilisateurs"
    $Script:DataDrive = "E:"
    $Script:SourceOracle = "\\***\Partage\SCCM-Deployments\Sources\Logiciels\Windows\Base de données\Oracle\OraDB-11.2.0.3_x64"
    $Script:SourcePdfCreator = "\\***\Partage\SCCM-Deployments\Sources\Logiciels\Windows\Bureautique\PDFCreator\PDFCreator1.7.0_x86"
    $Env:path = $Env:path + ";$DataDrive\Oracle\OraDB11GR2\bin"


# Functions
# ====================================================================

    Function Configure-HyperV {
    <#
        .SYNOPSIS
        Configure les chemins des VMs et VHDs dans Hyper-V.
    #>

        [CmdletBinding()]
        Param ()

        Begin {
            Import-Module -Name Hyper-V

            $Hyperv = "MS-HyperV"
            $VMPath = "$Script:DataDrive\$Hyperv\VMs"
            $VHDPath = "$Script:DataDrive\$Hyperv\VHDs"
        }

        Process {
            If (!(Test-Path $VMPath)){
                New-Item -ItemType Directory -Path $VMPath -Force
            }
            If (!(Test-Path $VHDPath)){
                New-Item -ItemType Directory -Path $VHDPath -Force
            }

            Invoke-Command -ArgumentList $VMPath, $VHDPath -ScriptBlock { Set-VMHost -VirtualHardDiskPath $VHDPath -VirtualMachinePath $VMPath -ErrorAction SilentlyContinue }
            $CommandExitCode = Invoke-Command -ScriptBlock { $LastExitCode }
            #Set-VMHost -VirtualHardDiskPath $VHDPath -VirtualMachinePath $VMPath -ErrorAction SilentlyContinue
        }

        End {
            If ( ((Get-VMHost).VirtualHardDiskPath -ne $VHDPath) -and ((Get-VMHost).VirtualMachinePath -ne $VMPath) -or ($CommandExitCode -ne 0) ) {
                Write-Host "`nConfiguration Hyper-V : Erreur" -ForegroundColor Red
            }
            Else {
                Write-Host "`nConfiguration Hyper-V : Succès" -ForegroundColor Green
            }
        }
    }

    Function Control-SmartScreen {
    <#
        .SYNOPSIS
        Permet de controler SmartScreen. Il y a 3 arguments RequireAdmin, Prompt et Off.
    #>

        [CmdletBinding()]
        Param ($Set)
        
        Process {
            Start-Process Powershell -Verb RunAs -ArgumentList "Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer -Name SmartScreenEnabled -Value $Set -Force" -Wait
        }

        End {

            $State = (Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer -Name SmartScreenEnabled).SmartScreenEnabled

            If ($State -eq $Set){
                Write-Host "`nConfiguration SmartScreen : Succès" -ForegroundColor Green
                Write-Host "Etat : $State`n" -ForegroundColor Yellow
            }
            Else {
                Write-Host "`nConfiguration SmartScreen : Erreur" -ForegroundColor Red
                Write-Host "Etat : $State`n" -ForegroundColor Yellow
            }
        }
    }

    Function Create-Directories {
    <#
        .SYNOPSIS
        Création des répertoires sur le disque de données.
    #>

        [CmdletBinding()]
        Param ($Data)

        Begin {
            $MyDoc = "$Data\Mes Documents" 
        }

        Process {
            New-Item -Path "$Data\Temp" -ItemType Directory -Force -ErrorVariable $CustomError
            New-Item -Path "$Data\MS-HyperV" -ItemType Directory -Force -ErrorVariable $CustomError
            New-Item -Path $MyDoc -ItemType Directory -Force -ErrorVariable $CustomError

            New-Item -Path "$MyDoc\Musiques" -ItemType Directory -Force -ErrorVariable $CustomError
            New-Item -Path "$MyDoc\Images" -ItemType Directory -Force -ErrorVariable $CustomError
            New-Item -Path "$MyDoc\Favoris" -ItemType Directory -Force -ErrorVariable $CustomError
            New-Item -Path "$MyDoc\Vidéos" -ItemType Directory -Force -ErrorVariable $CustomError
            New-Item -Path "$MyDoc\Techniques" -ItemType Directory -Force -ErrorVariable $CustomError
            New-Item -Path "$MyDoc\Techniques\Téléchargements" -ItemType Directory -Force -ErrorVariable $CustomError
            New-Item -Path "$MyDoc\Techniques\Contacts" -ItemType Directory -Force -ErrorVariable $CustomError
            New-Item -Path "$MyDoc\Techniques\Outlook" -ItemType Directory -Force -ErrorVariable $CustomError
            New-Item -Path "$MyDoc\Techniques\Bureau" -ItemType Directory -Force -ErrorVariable $CustomError
        }

        End {
            If ($CustomError -eq $null){
                Write-Host "`nCréations des répertoires : Succès" -ForegroundColor Green
            }
            Else {
                Write-Host "`nCréations des répertoires : Erreur" -ForegroundColor Red
            }
        }
    }

    Function Modify-Acl {
    <#
        .SYNOPSIS
        Permet de modifier les droits sur un répertoire sans héritage, et récursivement.
    #>

        [CmdletBinding()]
        Param (
            $User,
            $Directory
        )

        Begin {
            $Inherit = [system.security.accesscontrol.InheritanceFlags]"ContainerInherit, ObjectInherit"
            $Propagation = [system.security.accesscontrol.PropagationFlags]"None"
            $Permission = $User,"FullControl",$Inherit,$Propagation,"Allow"
            $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $Permission
        }
    
        Process {
            $Acl = Get-Acl $Directory
            $Acl.AddAccessRule($AccessRule)
            Invoke-Command -ArgumentList $Acl, $Directory -ScriptBlock { $Acl | Set-Acl $Directory } -Verb Runas
            $CommandExitCode = Invoke-Command -ScriptBlock { $LastExitCode }
            Write-Host $CommandExitCode
        }

        End {
            If ($CommandExitCode -eq 0){
                Write-Host "`nModification des droits sur $Directory : Succès" -ForegroundColor Green
            }
            ElseIf ($CommandExitCode -eq 1){
                Write-Host "`nModification des droits sur $Directory : Succès avec des avertissements (droits déjà existants)" -ForegroundColor Yellow
            }
            Else {
                Write-Host "`nModification des droits sur $Directory : Erreur" -ForegroundColor Red
            }
        }
    }

    Function Install-Oracle {
    <#
        .SYNOPSIS
        Installe Oracle.
    #>

        [CmdletBinding()]
        Param (
            $Source,
            $Destination
        )

        Process {
            Robocopy $Source $Destination /COPYALL /E /R:0 /xo
            Invoke-Command -ArgumentList $Destination -ScriptBlock { . $Destination\install\oui.exe -responseFile "$Destination\CARL-DB11G.rsp" -silent -nowelcome -showProgress }
            $CommandExitCode = Invoke-Command -ScriptBlock { $LastExitCode }
            #. $Destination\install\oui.exe -responseFile "$Destination\CARL-DB11G.rsp" -silent -nowelcome -showProgress
        }

        End {
            If ($CommandExitCode -eq 0){
                Write-Host "`nInstallation Oracle : Succès" -ForegroundColor Green
            }
            Else {
                Write-Host "`nInstallation Oracle : Erreur" -ForegroundColor Red
            }
        }
    }

    Function Install-PdfCreator {
    <#
        .SYNOPSIS
        Installe PdfCreator.
    #>

        [CmdletBinding()]
        Param (
            $Source,
            $Destination
        )

        Process {
            Robocopy $Source $Destination /COPYALL /E /R:0 /xo
            #Invoke-Command -ArgumentList $Destination -ScriptBlock { . $Destination\PDFCreator-1_7_0_setup.exe /LOADINF="$Destination\setup_pdf_creator.ini" /VERYSILENT /FORCEINSTALL }
            #$CommandExitCode = Invoke-Command -ScriptBlock { $LastExitCode }
            . $Destination\PDFCreator-1_7_0_setup.exe /LOADINF="$Destination\setup_pdf_creator.ini" /VERYSILENT /FORCEINSTALL
        }

        End {
            If ((Test-Path "C:\Program Files (x86)\PDFCreator") -eq $true){
                Write-Host "`nInstallation PdfCreator : Succès" -ForegroundColor Green
            }
            Else {
                Write-Host "`nInstallation PdfCreator : Erreur" -ForegroundColor Red
            }
        }
    }

    Function Update-SCCMMachinePolicy {
    <#
    .SYNOPSIS
    Initiates the Machine Policy Evaluation Cycle on a given computer

    .DESCRIPTION
    Uses a COM interface and Invoke-Command to initiate the Machine Policy Evaluation and Evalutation cycle on a local or remote computer

    .PARAMETER ComputerName

    .PARAMETER Credential
    Accepts a credential object, [System.Management.Automation.PSCredential]

    .EXAMPLE 
    Get-content C:\computers.txt | Update-SCCMMachinePolicy

    Starts the cycle on all computers listed in the file c:\computers.txt
    #>

        [CmdletBinding()]
        Param
            (
            [parameter()]
            [String[]]$ComputerName = $env:COMPUTERNAME,
            [System.Management.Automation.PSCredential]$credential
            )

        Begin {
            $param = @{ScriptBlock = {`
                if (-not(Test-Path C:\Windows\CCM\CcmExec.exe)) {
                    Write-Host "Le client SCCM n'est pas installé !" -ForegroundColor Red
                }
                Else {
                    $CPAppletMGR = new-object -ComObject CPApplet.CPAppletmgr
                    $SMSActions = $CPAppletMGR.GetClientActions()
                    $action = $SMSActions | where {$_.Name -eq "Request & Evaluate Machine Policy"}
                    $action.PerformAction()
                    Write-Host "Le client SCCM est en train d'effectuer la récupération de stratégie ordinateur et cycle d'évaluation." -ForegroundColor Yellow
                }
            }}
        }

        Process {
            If (Test-Connection $ComputerName -Quiet -Count 2) {
                If ($ComputerName -ne $env:COMPUTERNAME) {
                    $param.Add("ComputerName",$ComputerName)
                }
                if ($credential) {
                    $param.Add("Credential",$credential)
                }            
                Invoke-Command @param
            }
            Else { 
                Write-Host "L'ordinateur, $ComputerName, n'est pas joignable." -ForegroundColor Red
            }
        }

        End {}
    }

    Function Start-SCCMFileCollection {
    <#
    .SYNOPSIS
    Initiates the File Collection Cycle on a given computer

    .DESCRIPTION
    Uses a COM interface and Invoke-Command to initiate the File Collection and Evalutation cycle on a local or remote computer

    .PARAMETER ComputerName

    .PARAMETER Credential
    Accepts a credential object, [System.Management.Automation.PSCredential]

    .EXAMPLE 
    Get-content C:\computers.txt | Start-SCCMFileCollection

    Starts the cycle on all computers listed in the file c:\computers.txt
    #>
        [CmdletBinding()]
        Param (
            [parameter()]
            [String[]]$ComputerName = $env:COMPUTERNAME,
            [System.Management.Automation.PSCredential]$credential
        )

        Begin {
            $param = @{ScriptBlock = {`
                if (-not(Test-Path C:\Windows\CCM\CcmExec.exe)) {
                    Write-Host "Le client SCCM n'est pas installé !" -ForegroundColor Red
                }
                Else {
                    $CPAppletMGR = new-object -ComObject CPApplet.CPAppletmgr
                    $SMSActions = $CPAppletMGR.GetClientActions()
                    $action = $SMSActions | where {$_.Name -eq "Standard File Collection Cycle"}
                    $action.PerformAction()
                    Write-Host "Le client SCCM est en train d'effectuer le cycle d'évaluation du déploiement de l'application." -ForegroundColor Yellow
                }
            }}
        }

        Process {
            If (Test-Connection $ComputerName -Quiet -Count 2) {
                If ($ComputerName -ne $env:COMPUTERNAME) {
                    $param.Add("ComputerName",$ComputerName)
                }
                if ($credential) {
                    $param.Add("Credential",$credential)
                }            
                Invoke-Command @param
            }
            Else { 
                Write-Host "L'ordinateur, $ComputerName, n'est pas joignable." -ForegroundColor Red
            }
        }

        End {}
    }

    Function Sleep-Bar {
    <#
        .SYNOPSIS
        Installe PdfCreator.
    #>

        [CmdletBinding()]
        Param (
            $Time,
            $Text
        )

        Process {
            $X = $Time*60
            $Length = $X / 100
            While ($X -gt 0) {
              $Min = [int](([string]($x/60)).split('.')[0])
              $TextTime = " " + $Min + " minutes " + ($X % 60) + " secondes restantes"
              Write-Progress $Text -status $TextTime -perc ($X/$Length)
              Start-Sleep -s 1
              $X--
            }
        }
    }

# Scripts
# ====================================================================

    # Début
    Write-Host "------------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "Script:         Post-Install                                      " -ForegroundColor Cyan
    Write-Host "Auteur:         Julian Da Cunha                                   " -ForegroundColor Cyan
    Write-Host "Date:           26/03/14                                          " -ForegroundColor Cyan
    Write-Host "Description:    Automatisation Post-déploiement                   " -ForegroundColor Cyan
    Write-Host "Version:        0.1                                               " -ForegroundColor Cyan
    Write-Host "------------------------------------------------------------------" -ForegroundColor Cyan


    # Création des répertoires sur E:
    Create-Directories -Data $Script:DataDrive
    Pause
    Write-Host ""

    # Mise à jour CCM
    Update-SCCMMachinePolicy
    Start-SCCMFileCollection
    Sleep-Bar -Time 5 -Text "Mise à jour des stratégie SCCM..."


    # Installation d'Oracle
    #Install-Oracle -Source $SourceOracle -Destination "$Script:DataDrive\Temp\Oracle"
    If ((Test-Path "$DataDrive\Oracle\OraDATA\CARL\CONTROL01.CTL") -eq $false){
        Write-Host "`nInstallez Oracle depuis le centre logiciel puis continuer l'exécution du script.." -ForegroundColor Yellow
    }
    Else {
        Write-Host "`nAttention Oracle est déjà installé... " -ForegroundColor Yellow
    }
    Pause

    # Modification des droits sur E:\Oracle
    #Modify-Acl -User $User -Directory "$Script:DataDrive\Oracle"
    Write-Host "`nVeuillez modifier les droits pour '$User' sur '$DataDrive\Oracle\' avec réplication puis continuer l'exécution du script... " -ForegroundColor Yellow
    Pause

    # Création Datapump
    New-Item -Path "$Script:DataDrive\Oracle\DATAPUMP" -ItemType Directory -Force
    Pause

    # Modification SQLNET
    $Replace = Get-Content $DataDrive\Oracle\OraDB11GR2\NETWORK\ADMIN\sqlnet.ora | foreach { $_ -replace "NTS","NONE" }
    Sleep 2
    Invoke-Command -ArgumentList $Replace, $DataDrive -ScriptBlock { Set-Content $DataDrive\Oracle\OraDB11GR2\NETWORK\ADMIN\sqlnet.ora $Replace }
    $CommandExitCode = Invoke-Command -ScriptBlock { $LastExitCode }
    If ($CommandExitCode -eq 0){
        Write-Host "`nModification sqlnet.ora : Succès" -ForegroundColor Green
    }
    Else {
        Write-Host "`nModification sqlnet.ora : Erreur" -ForegroundColor Red
    }
    Pause

    # Création du Script SQL
    echo "create directory DATAPUMP as '$Script:DataDrive\Oracle\DATAPUMP';" > $Script:DataDrive\Temp\Oracle.sql
    echo "grant read, write on directory DATAPUMP to SYSTEM;" >> $Script:DataDrive\Temp\Oracle.sql
    echo "ALTER PROFILE DEFAULT LIMIT PASSWORD_LIFE_TIME UNLIMITED;" >> $Script:DataDrive\Temp\Oracle.sql
    echo "ALTER SYSTEM SET SEC_CASE_SENSITIVE_LOGON = FALSE;" >> $Script:DataDrive\Temp\Oracle.sql
    echo "ALTER SYSTEM SET PROCESSES = 350 SCOPE = SPFILE;" >> $Script:DataDrive\Temp\Oracle.sql
    echo "Commit;" >> $Script:DataDrive\Temp\Oracle.sql
    echo "SHUTDOWN IMMEDIATE" >> $Script:DataDrive\Temp\Oracle.sql
    echo "STARTUP" >> $Script:DataDrive\Temp\Oracle.sql
    echo "EXIT" >> $Script:DataDrive\Temp\Oracle.sql

    # Execution Script SQL
    Invoke-Command -ScriptBlock { sqlplus sys/enterprise as sysdba @$DataDrive\Temp\Oracle.sql }
    $CommandExitCode = Invoke-Command -ScriptBlock { $LastExitCode }
    If ($CommandExitCode -eq 0){
        Write-Host "`nApplication script SQL : Succès" -ForegroundColor Green
    }
    Else {
        Write-Host "`nApplication script SQL : Erreur" -ForegroundColor Red
    }
    Pause

    # Automatisation Hyper-V
    Write-Host "`nAttention veuillez vérifier que Hyper-V .." -ForegroundColor Yellow
    Pause
    Configure-HyperV
    Pause

    # Désactive SmartScreen
    Control-SmartScreen -Set Off
    
    # Installation PdfCreator
    #Install-PdfCreator -Source $SourcePdfCreator -Destination "$DataDrive\Temp\PdfCreator"
    Write-Host "`nInstallez Pdf Creator depuis le centre logiciel puis continuer l'exécution du script.." -ForegroundColor Yellow
    Pause

    # Réactivation SmartScreen
    Control-SmartScreen -Set Prompt