# ------------------------------------------------------------------ #
# Script:      PowerExec                                             #
# Auteur:      Julian Da Cunha                                       #
# Date:        12/01/13                                              #
# Description: Utilisez Powershell & PaExec pour controler vos PC    #
# Version:     0.9                                                   #
# ------------------------------------------------------------------ #

Cls

#########################################################
## VARS  ################################################
#########################################################

# Importation des fonctions
Import-Module NewProject -Force -PassThru -Scope Global | Out-Null



#########################################################
## SCRIPTS ##############################################
#########################################################


# Initialisation Clé registre SetVPN
If ((Test-Path "HKCU:\Software\SetVPN") -eq $False){

    CreateKey -KeyPath "HKCU:\Software\" -KeyName SetVPN

    Write-Host "Création HKCU:\Software\SetVPN - OK"

    If ((Test-Path "HKCU:\Software\SetVPN")-eq $False){

        Write-Host "ERREUR initialisation clé registre SetVPN"
    }
    Else {

        Write-Host "Initialisation clé registre SetVPN - OK"    
    }
}

# Initilisation Clé registre utilisateur
$Ans0 = $False
While ($Ans0 -eq $False){
    Cls
    Write-Host "=== Configuration de l'accès VPN ===`n"
    $User = Read-Host "`tNom (Trigramme)"
    If (($User -match "[A-Za-z]") -and ($User.Length -le 4)){
        $Ans0 = $true
    }
}

# Vérification Existance clée utilisateur
If ((Test-Path "HKCU:\Software\SetVPN\$User") -eq $False){

    CreateUserDir -User $User

    $KeyPath = "HKCU:\Software\SetVPN\$User"

    If ((Test-Path $KeyPath)-eq $False){

        Write-Host "Création $User - ERREUR"
        Break
    }
    Else {

        Write-Host "Création $User - OK"
        $ModifyUser = 1
    }
}
# Si elle existe choix à faire
Else {

    $KeyPath = "HKCU:\Software\SetVPN\$User"
    $Ans = $False
    While ($Ans -eq $False){
        Cls
        Write-Host "=== Options pour l'utilisateur $User ==="
        Write-Host "`n`t1. Modifier Accès`n`t2. Supprimer Accès`n`t3. Quitter`n"
        $ModifyUser = Read-Host "Que voulez-vous faire"
        If ($ModifyUser -match "[1-3]{1}"){
            $Ans = $true
        }
    }
}

# Choix Modifier Acces
If ($ModifyUser -eq 1){
    $UserKey = ReadKey -Key $KeyPath
    $Ans2 = $False
    While ($Ans2 -eq $False){
        Cls
        Write-Host "=== Modification de l'accès VPN pour $User ==="
        Write-Host "`n`tType d'accès: `n`n`t`t1.Journalier`n`t`t2.Période`n"
        $AccessType = Read-Host "`tVotre choix"
        If ($AccessType -match "[1-2]{1}"){
            $Ans2 = $true
        }    
    }
    # Choix Journalier
    If ($AccessType -eq 1){
        Cls
        $Ans5 = $False
        While ($Ans5 -eq $False){
            Cls
            Write-Host "=== Sélection des jours d'accès ==="
            $Days = Read-Host "`n`tEntrez les jours (ex: lun,mar,ven)"

            $SplitDays = $($Days).Split(",")

            For ($i=0; $i -le $($SplitDays.Length); $i++){

                If (($SplitDays[$i] -match "lun") -or ($SplitDays[$i] -match "mar") -or ($SplitDays[$i] -match "mer") -or ($SplitDays[$i] -match "jeu") -or ($SplitDays[$i] -match "ven")){
                    $Ans5 = $true
                }
            }
        }

        # Choix Type VPN
        Cls
        $Ans6 = $False
        While ($Ans6 -eq $False){
            Cls
            Write-Host "=== Sélection du type d'accès VPN ==="
            $VPNType = Read-Host "`n`tQuel type de VPN (1-Complet, 2-Limité)"
            If ($VPNType -match "[1-2]{1}"){
                $Ans6 = $true
            }
        }

        ModifyKey -KeyPath $KeyPath -KeyName "InitDate" -KeyValue -1
        ModifyKey -KeyPath $KeyPath -KeyName "TimeSet" -KeyValue 0
        ModifyKey -KeyPath $KeyPath -KeyName "Days" -KeyValue $Days
        ModifyKey -KeyPath $KeyPath -KeyName "Access" -KeyValue 1
        ModifyKey -KeyPath $KeyPath -KeyName "VpnType" -KeyValue $VPNType

        $UserKey = ReadKey -Key $KeyPath
        Cls
        Write-Host "=== Récapitulatif de la modification de $User ==="
        Write-Host "`n`tAccess`t : $($UserKey.Access)`n`tDays`t : $($UserKey.Days)`n`tTimeSet`t : $($UserKey.TimeSet)`n`tInitDate : $($UserKey.InitDate)`n`tVpnType`t : $($UserKey.VpnType)`n"

    }
    # Choix Periode
    Else {
        $Ans4 = $False
        While ($Ans4 -eq $False){
            Cls
            Write-Host "=== Choix du nombre de jour ==="
            $Time = Read-Host "`n`tCombien de jours voulez-vous créditer"
            If ($Time -match "\d{1,3}"){
                $Ans4 = $true
            }    
        }
    
        # Choix Type VPN
        Cls
        $Ans6 = $False
        While ($Ans6 -eq $False){
            Cls
            Write-Host "=== Sélection du type d'accès VPN ==="
            $VPNType = Read-Host "`n`tQuel type de VPN (1-Complet, 2-Limité)"
            If ($VPNType -match "[1-2]{1}"){
                $Ans6 = $true
            }
        }


        # Crédite jours
        ModifyKey -KeyPath $KeyPath -KeyName "TimeSet" -KeyValue $Time
        ModifyKey -KeyPath $KeyPath -KeyName "Days" -KeyValue "none"
        ModifyKey -KeyPath $KeyPath -KeyName "Access" -KeyValue 1
        ModifyKey -KeyPath $KeyPath -KeyName "InitDate" -KeyValue $(Get-Date -Format dd/MM/yyyy)
        ModifyKey -KeyPath $KeyPath -KeyName "VpnType" -KeyValue $VPNType

        $UserKey = ReadKey -Key $KeyPath
        Cls
        Write-Host "=== Récapitulatif de la modification de $User ==="
        Write-Host "`n`tAccess`t : $($UserKey.Access)`n`tDays`t : $($UserKey.Days)`n`tTimeSet`t : $($UserKey.TimeSet)`n`tInitDate : $($UserKey.InitDate)`n`tVpnType`t : $($UserKey.VpnType)`n"

    }

}
# Choix Supprimer Acces
ElseIf ($ModifyUser -eq 2){
    ModifyKey -KeyPath $KeyPath -KeyName Access -KeyValue 0
    ModifyKey -KeyPath $KeyPath -KeyName Days -KeyValue "none"
    ModifyKey -KeyPath $KeyPath -KeyName TimeSet -KeyValue 0
    ModifyKey -KeyPath $KeyPath -KeyName VpnType -KeyValue 0
    Cls
    $UserKey = ReadKey -Key $KeyPath
    Write-Host "=== Désactivation de l'accès VPN pour $User ==="
    Write-Host "`n`tAccess`t: $($UserKey.Access)`n`tDays`t: $($UserKey.Days)`n`tTimeSet`t: $($UserKey.TimeSet)`n"
}
# Choix Quitter
Else {
    Cls
    Break
}