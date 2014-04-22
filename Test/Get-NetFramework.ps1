# ------------------------------------------------------------------ #
# Script:      Get-Framework                                         #
# Auteur:      Julian Da Cunha                                       #
# Date:        12/03/13                                              #
# Description: Permet de télécharger .Net en fonction de l'OS        #
# ------------------------------------------------------------------ #

    Cls

    #Tester clé de registre
    Function Test-Key([string]$path, [string]$key) {
        If (!(Test-Path $path)) { 
            Return $false 
        }
        If ((Get-ItemProperty $path).$key -eq $null) {
            Return $false 
        }
        Return $true
    }

    #Connaitre version de DotNet installé
    Function Get-Framework-Versions() {
        $InstalledFrameworks = @()
        If (Test-Key "HKLM:\Software\Microsoft\.NETFramework\Policy\v1.0" "3705") { $InstalledFrameworks += "1.0" }
        If (Test-Key "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v1.1.4322" "Install") { $InstalledFrameworks += "1.1" }
        If (Test-Key "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v2.0.50727" "Install") { $InstalledFrameworks += "2.0" }
        If (Test-Key "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v3.0\Setup" "InstallSuccess") { $InstalledFrameworks += "3.0" }
        If (Test-Key "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v3.5" "Install") { $InstalledFrameworks += "3.5" }
        If (Test-Key "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Client" "Install") { $InstalledFrameworks += "4.0c" }
        If (Test-Key "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Full" "Install") { $InstalledFrameworks += "4.0" }   
     
        Return $InstalledFrameworks
    }

    # Fonction Get-HostOsInfo =============================
        Function Get-HostOsInfo {

            # Récupère les info Version Noyaux NT et x86 ou x64
            $HostOs = Get-WmiObject -Class Win32_OperatingSystem
            $HostOsArch = $HostOs.OSArchitecture
            $HostKern = $HostOs.Version

            $HostInfo = ($HostOsArch, $HostKern)
            
            Return $HostInfo

        }

    # Fonction Get-NetFramework =============================
        Function Get-NetFramework {
    
            Param (
                $Os,
                $Arch,
                $Lang
            )

            #Si C:\Temp existe pas, création
            If ((Test-Path -Path "C:\Temp") -eq $false){
                New-Item -ItemType Directory -Path C:\Temp -Force
            }
            Else {
            
                If ( ($Os -eq "6.0") -and ($Lang -eq "FR") ){ # Windows 2008 x64 FR & Windows 2008 x86 FR

                    Write-Host "`n Téléchargement pour Windows 2008 x64 FR & Windows 2008 x86 FR"

                    $Url =  "http://download.microsoft.com/download/2/0/E/20E90413-712F-438C-988E-FDAA79A8AC3D/dotnetfx35.exe",
                            "http://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe",
                            "http://care.dlservice.microsoft.com//dl/download/F/E/3/FE3F8D2C-135F-478D-9445-6584E83EE99D/1036/SQLFULL_x64_FRA.exe?lcid=1036"
                    
                    # Parcours la variable URL et les téléchargent dans C:\Temp
                    For ($i=0 ; $i -lt $Url.Length ; $i--) { 
                        Start-BitsTransfer -Source $Url[$i] -Destination C:\Temp
                    }
                }
                ElseIf ( ($Os -eq "6.0") -and ($Lang -eq "EN") ) { 

                    If ($Arch -eq "64") { # Windows 2008 x64 US
                        
                        Write-Host "`n Téléchargement pour Windows 2008 x64 US"

                        $Url =  "http://download.microsoft.com/download/2/0/E/20E90413-712F-438C-988E-FDAA79A8AC3D/dotnetfx35.exe",
                                "http://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe",
                                "http://care.dlservice.microsoft.com//dl/download/D/8/0/D808E432-5AC6-4DA5-A087-21947AC4AC5F/1033/SQLFULL_x64_ENU.exe"
                    
                        For ($i=0 ; $i -lt $Url.Length ; $i--) { 
                            Start-BitsTransfer -Source $Url[$i] -Destination C:\Temp
                        }                
                    }

                    Else { # Windows 2008 x86 US

                        Write-Host "`n Téléchargement pour Windows 2008 x86 US"

                        $Url =  "http://download.microsoft.com/download/2/0/E/20E90413-712F-438C-988E-FDAA79A8AC3D/dotnetfx35.exe",
                                "http://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe",
                                "http://care.dlservice.microsoft.com//dl/download/D/8/0/D808E432-5AC6-4DA5-A087-21947AC4AC5F/1033/SQLFULL_x86_ENU.exe"
                    
                        For ($i=0 ; $i -lt $Url.Length ; $i--) { 
                            Start-BitsTransfer -Source $Url[$i] -Destination C:\Temp
                        }                
                    }
                }
                ElseIf (($Os -eq "6.1") -and ($Lang -eq "FR")) { # Windows 2008 R2 x64 FR

                    Write-Host "`n Téléchargement pour Windows 2008 R2 x64 FR"

                    $Url =  "http://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe",
                            "http://care.dlservice.microsoft.com//dl/download/F/E/3/FE3F8D2C-135F-478D-9445-6584E83EE99D/1036/SQLFULL_x64_FRA.exe?lcid=1036"
                    
                    For ($i=0 ; $i -lt $Url.Length ; $i--) { 
                        Start-BitsTransfer -Source $Url[$i] -Destination C:\Temp
                    }                
                }
                ElseIf (($Os -eq "6.1") -and ($Lang -eq "EN")) { # Windows 2008 R2 X64 US
                    
                    Write-Host "`n Téléchargement pour Windows 2008 R2 X64 US"

                    $Url =  "http://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe",
                            "http://care.dlservice.microsoft.com//dl/download/D/8/0/D808E432-5AC6-4DA5-A087-21947AC4AC5F/1033/SQLFULL_x64_ENU.exe"
                    
                    For ($i=0 ; $i -lt $Url.Length ; $i--) { 
                        Start-BitsTransfer -Source $Url[$i] -Destination C:\Temp
                    }
                }
                Else {
                    Write-Host "`n Version de Windows différente de Windows 2008 ou Windows 2008 R2" -ForegroundColor Yellow
                }
            }
        }


############## EXECUTION DU SCRIPT ##############

        $HostInfo = Get-HostOsInfo
        $Langue = "" # A CHANGER FR ou EN

        # Si .net 4.0 ET .net 3.5 installé alors FIN
        If ( (Get-Framework-Versions -eq "4.0") -and (Get-Framework-Versions -eq "3.5") ){
            Write-Host "`n Pas besoin d'installer .netFramework" -ForegroundColor Green
            Write-Host " Version de .net Framework Installé: $(Get-Framework-Versions) `n"
        }
        Else {
            Write-Host "`n Il manque .netFramework 3.5 ou 4.0" -ForegroundColor Red
            Write-Host " Version de .net Framework Installé: $(Get-Framework-Versions) `n"
            Get-NetFramework ( $HostInfo[-1], $HostInfo[0], $Langue )
            Start-BitsTransfer -Source "http://dl.dropbox.com/u/2498909/Varonis-PrerequisitesDownloader/ConfigurationFileVaronis.ini" -Destination C:\Temp
        }