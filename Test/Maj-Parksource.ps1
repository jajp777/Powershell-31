# ------------------------------------------------------------------ #
# Script:         MAJ Parksource                                     #
# Auteur:         Julian Da Cunha                                    #
# Date:           18/03/14                                           #
# Description:    Automatisation de la MAJ Parksource                #
# Version:        0.1                                                #
# ------------------------------------------------------------------ #

Cls

# Functions
# ====================================================================

    Function ServiceControl {
        
        Param (
            $Action, 
            $Credential
        )

        If ($Action -eq "stop"){

            Write-Host "`nArrêt des services:`n====================`n`n"
            Write-Host "BANGA`n"
            Invoke-Command -ComputerName "***" -Credential $Credential {   
                #Stop-Service -Force -Name "NAME"
            }
            Write-Host "CANGA`n"
            Invoke-Command -ComputerName "***" -Credential $Credential {   
                #Stop-Service -Force -Name "NAME"
            }
        }
        ElseIf ($Action -eq "start"){
            Write-Host "`nDémarrage des services:`n====================`n`n"
            Write-Host "BANGA`n"
            Invoke-Command -ComputerName "***" -Credential $Credential {   
                #Start-Service -Force -Name "NAME"
            }
            Write-Host "CANGA`n"
            Invoke-Command -ComputerName "***" -Credential $Credential {   
                #Start-Service -Force -Name "NAME"
            }
        }
        Else {
            Write-Host "ERROR: Bad parameter for Action (start|stop)"
        }
    }

    Function ServiceState {

        Write-Host "`nEtat des services:`n====================`n`n"
        Write-Host "BANGA`n"

        Invoke-Command -ComputerName "***" -Credential $Credential {   
            Get-Service -Name "***"
        } | Format-List Name,Status,DisplayName

        Write-Host "CANGA`n"

        Invoke-Command -ComputerName "***" -Credential $Credential {   
            Get-Service -Name "***"
        } | Format-List Name,Status,DisplayName
    }

    Function Export {

        Param (
            $SavName
        )

        Write-Host "`nExport Oracle:`n====================`n`n"

        Invoke-Command -ComputerName "***" -Credential $Credential {   
            SET ORACLE_SID=PROD11
            expdp system/vierges@prod11 directory=DATAPUMP dumpfile=$SavName.DMP logfile=$SavName.LOG schemas=PARKSOURCE
        }

        Write-Host "`nCopie de l'Export:`n====================`n`n"
    
        Invoke-Command -ComputerName "***" -Credential $Credential { 
            xcopy E:\Oracle\Backup\Datapump\$SavName.DMP \\***\Partage\SCCM-Deployments\Backup\ParkSource /E /C /Q /Y
            xcopy E:\Oracle\Backup\Datapump\$SavName.LOG \\***\Partage\SCCM-Deployments\Backup\ParkSource /E /C /Q /Y
        }

        If (((Test-Path -Path \\***\Partage\SCCM-Deployments\Backup\ParkSource\$SavName.DMP) -eq $true) -and ((Test-Path -Path \\***\Partage\SCCM-Deployments\Backup\ParkSource\$SavName.LOG) -eq $true){
            Invoke-Command -ComputerName "***" -Credential $Credential { 
                #### RM FILES ####
            }

            Write-Host "La copie s'est correctement terminée"
        }
        Else {
            Write-Host "ERROR: La copie ne s'est pas correctement terminée"
        }
    }

# Vars
# ====================================================================

    $Credentials = Get-Credential
    $Date = Get-Date -Format ddMMyyyy
    $NamePreSav = "PreMAJ-PARKSOURCE_$Date"
    $NamePostSav = "PostMAJ-PARKSOURCE_$Date"

# Scripts
# ====================================================================

Cls

    # Sauvegarde avant mise à jour
    # ----------------------------
        
        # Arrêt des services *** sur BANGA & CANGA
        ServiceControl -Action stop -Credential $Credentials

        # Etat des services *** sur BANGA & CANGA
        ServiceState

        #"C:\Program Files\7-Zip\7z.exe" a \\***\Partage\SCCM-Deployments\Backup\ParkSource\PreMAJ-PARKSOURCE_18032014.zip "E:\JBoss\server\parksource"

        # Export Oracle et copie sur Partage réseau
        Export -SavName $NamePreSav

    # Sauvegarde après mise à jour
    # ----------------------------

        # Arrêt des services *** sur BANGA & CANGA
        ServiceControl -Action stop -Credential $Credentials

        # Banga
        #"C:\Program Files\7-Zip\7z.exe" a \\***\Partage\SCCM-Deployments\Backup\ParkSource\PostMAJ-PARKSOURCE_18032014.zip "E:\JBoss\server\parksource" 

        # Export Oracle et copie sur Partage réseau
        Export -SavName $NamePostSav

        # Démarrage des services *** sur BANGA & CANGA
        ControlService -Action start -Credential $Credentials

        # Etat des services *** sur BANGA & CANGA
        ServiceState