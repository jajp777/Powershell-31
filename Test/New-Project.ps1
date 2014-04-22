# ------------------------------------------------------------------ #
# Script:      PowerExec                                             #
# Auteur:      Julian Da Cunha                                       #
# Date:        12/01/13                                              #
# Description: Utilisez Powershell & PaExec pour controler vos PC    #
# Version:     0.9                                                   #
# ------------------------------------------------------------------ #

Cls

#########################################################
## VARS & FUNCTIONS #####################################
#########################################################

# Importation des modules
Import-Module ActiveDirectory

# Fonction ReadKey ==========================
Function ReadKey {

    Param ( 
        $Key
    )

    Get-ItemProperty $Key
}


# Fonction CreateKey ========================
Function CreateKey {

    Param ( 
        $KeyPath,
        $KeyName,
        $KeyValue,
        $KeyType
    )

    New-Item -Path $KeyPath -Name $KeyName -Value $KeyValue -ItemType $KeyType -Force
}


# Fonction ModifyKey ========================
Function ModifyKey {

    Param ( 
        $KeyPath,
        $KeyName,
        $KeyValue
    )

    Set-ItemProperty -Path $KeyPath -Name $KeyName -Value $KeyValue -Force
}


# Fonction CreateUserDir ====================
Function CreateUserDir {
    
    Param (
        $User
    )

    New-Item -Path "HKCU:\Software\SetVPN\" -Name $User -Force
    New-ItemProperty -Path "HKCU:\Software\SetVPN\$User" -Name "Access" -PropertyType DWord -Value 0 -Force
    New-ItemProperty -Path "HKCU:\Software\SetVPN\$User" -Name "InitDate" -PropertyType String -Value 0 -Force
    New-ItemProperty -Path "HKCU:\Software\SetVPN\$User" -Name "TimeSet" -PropertyType DWord -Value 0 -Force
    New-ItemProperty -Path "HKCU:\Software\SetVPN\$User" -Name "VpnType" -PropertyType DWord -Value 0 -Force
}


# Fonction CompareDate ======================
Function CompareDate {

    Param (
        $User
    )

    $KeyPath = "HKCU:\Software\SetVPN\$User"
    $UserKey = ReadKey -Key $KeyPath

    $InitDate = Get-Date -Date $($UserKey.InitDate)

    $ActualDate = Get-Date

    $DiffDates = $ActualDate - $InitDate

    Return $DiffDates.Days
}


# Fonction IsAccess ==========================
Function IsAccess {

    Param(
        $KeyPath
    )

    $UserKey = ReadKey -Key $KeyPath

    If ($($UserKey.Access) -eq 0){
    
        $Access = $False
        #$Msg = "Accès VPN - ERREUR`n"
    }
    Else {

        $Access = $true
        #$Msg = "Accès VPN - OK`n"
    }

    Return $Access #, $Msg
}


# Fonction ReadDays ==========================
Function ReadDays {

    Param(
        $UserKey
    )

    $Days = New-Object -TypeName System.Management.Automation.PSObject
    $Days | Add-Member NoteProperty Monday $false
    $Days | Add-Member NoteProperty Tuesday $false
    $Days | Add-Member NoteProperty Wednesday $false
    $Days | Add-Member NoteProperty Thursday $false
    $Days | Add-Member NoteProperty Friday $false

    $SplitDays = $($UserKey.Days).Split(",")

    For ($i=0; $i -lt $($SplitDays.Length); $i++){

        If ($SplitDays[$i] -match "lun"){
            $Days.Monday = $True
        }
        ElseIf ($SplitDays[$i] -match "mar"){
            $Days.Tuesday = $True
        }
        ElseIf ($SplitDays[$i] -match "mer"){
            $Days.Wednesday = $True
        }
        ElseIf ($SplitDays[$i] -match "jeu"){
            $Days.Thursday = $True
        }
        ElseIf ($SplitDays[$i] -match "ven"){
            $Days.Friday = $True
        }

    }

    Return $Days
}


#########################################################
## SCRIPTS ##############################################
#########################################################

# Définition des Credentials
$Credential = "***\***"

# Définit le chemin des clef de registre
$Path = "HKCU:\Software\SetVPN\"
$Keys = Get-ChildItem -Path $Path

# Get APP - Clients VPN group info
$GroupLDAP = Get-ADGroup -LDAPFilter "(&(objectCategory=group)(cn=APP - Clients VPN - *))"
$Vpn1 = $GroupLDAP | Where-Object {$_.Name -Match "Accès Complet"}
$Vpn2 = $GroupLDAP | Where-Object {$_.Name -Match "Accès Limité"}

# Définit les paramètres du log
$logdate = Get-Date -Format dd-MM-yyyy
$log = "C:\Script\Log\(VpnLog)_$logdate.log"

# En-tête du log
Echo "#########################################" > $log
Echo "### Rapport d'execution du $logdate ###" >> $log
Echo "#########################################" >> $log
Echo "" >> $log
Echo "" >> $log
Echo "Access = Indique si l'utilisateur a accès ou non au VPN (0 = Pas d'accès, 1 = accès)" >> $log
Echo "Days = Spécifie les jours ou l'utilisateur doit avoir accès au VPN (si la valeur est none, c'est que le mode de connexion est TimeSet)" >> $log
Echo "TimeSet = Spécifie le nombre de jour pendant lequel l'utilisateur aura accès au VPN (en rapport avec InitDate)" >> $log
Echo "InitDate = Indique le jour ou le TimeSet a été crédité (si la valeur est -1, c'est que le mode de connexion est Days)" >> $log
Echo "VpnType = Indique le type d'accès VPN (1 = Accès Complet, 2 = Accès Limité)" >> $log
Echo "" >> $log
Echo "" >> $log

# Parcours des Sous-Clef de HKCU:\Software\SetVPN\
For ($i=0; $i -lt $($Keys.Length); $i++){


    # Initilisation Clé registre utilisateur
    $KeyPath = $Keys[$i].Name
    $KeyPath = $KeyPath.Replace("HKEY_CURRENT_USER\Software\SetVPN\","HKCU:\Software\SetVPN\")
    $User = $User = $(Get-ItemProperty $KeyPath).PSChildName

    # Lire Clée Utilisateur
    $UserKey = ReadKey -Key $KeyPath

    # Get LDAP User Info
    $UserLDAP = Get-ADUser -LDAPFilter "(&(objectCategory=person)(sAMAccountName=$User))"


    ####### Par Récurence ########

    If (($($UserKey.InitDate) -eq 0 ) -or ($($UserKey.InitDate) -eq -1 )){


        # Lire Jour d'accès
        $Days = ReadDays -UserKey $UserKey
        $LocalDay = (Get-Date).DayOfWeek
        If ($LocalDay -match "Monday"){
            If ($Days.Monday -eq $true){
                ModifyKey -KeyPath $KeyPath -KeyName "Access" -KeyValue 1
                $UserKey = ReadKey -Key $KeyPath
                Echo "=== Configuration $User ===" >> $log
                Echo "" >> $log
                Echo "`tAccess`t : $($UserKey.Access)" >> $log
                Echo "`tDays`t : $($UserKey.Days)" >> $log
                Echo "`tTimeSet`t : $($UserKey.TimeSet)" >> $log
                Echo "`tInitDate : $($UserKey.InitDate)" >> $log
                Echo "`tVpnType  : $($UserKey.VpnType)" >> $log
            }
            Else {
                ModifyKey -KeyPath $KeyPath -KeyName "Access" -KeyValue 0
                $UserKey = ReadKey -Key $KeyPath
                Echo "=== Configuration $User ===" >> $log
                Echo "" >> $log
                Echo "`tAccess`t : $($UserKey.Access)" >> $log
                Echo "`tDays`t : $($UserKey.Days)" >> $log
                Echo "`tTimeSet`t : $($UserKey.TimeSet)" >> $log
                Echo "`tInitDate : $($UserKey.InitDate)" >> $log
                Echo "`tVpnType  : $($UserKey.VpnType)" >> $log
            }
        }
        If ($LocalDay -match "Tuesday"){
            If ($Days.Tuesday -eq $true){
                ModifyKey -KeyPath $KeyPath -KeyName "Access" -KeyValue 1
                $UserKey = ReadKey -Key $KeyPath
                Echo "=== Configuration $User ===" >> $log
                Echo "" >> $log
                Echo "`tAccess`t : $($UserKey.Access)" >> $log
                Echo "`tDays`t : $($UserKey.Days)" >> $log
                Echo "`tTimeSet`t : $($UserKey.TimeSet)" >> $log
                Echo "`tInitDate : $($UserKey.InitDate)" >> $log
                Echo "`tVpnType  : $($UserKey.VpnType)" >> $log
            }
            Else {
                ModifyKey -KeyPath $KeyPath -KeyName "Access" -KeyValue 0
                $UserKey = ReadKey -Key $KeyPath
                Echo "=== Configuration $User ===" >> $log
                Echo "" >> $log
                Echo "`tAccess`t : $($UserKey.Access)" >> $log
                Echo "`tDays`t : $($UserKey.Days)" >> $log
                Echo "`tTimeSet`t : $($UserKey.TimeSet)" >> $log
                Echo "`tInitDate : $($UserKey.InitDate)" >> $log
                Echo "`tVpnType  : $($UserKey.VpnType)" >> $log
            }
        }
        If ($LocalDay -match "Wednesday"){
            If ($Days.Wednesday -eq $true){
                ModifyKey -KeyPath $KeyPath -KeyName "Access" -KeyValue 1
                $UserKey = ReadKey -Key $KeyPath
                Echo "=== Configuration $User ===" >> $log
                Echo "" >> $log
                Echo "`tAccess`t : $($UserKey.Access)" >> $log
                Echo "`tDays`t : $($UserKey.Days)" >> $log
                Echo "`tTimeSet`t : $($UserKey.TimeSet)" >> $log
                Echo "`tInitDate : $($UserKey.InitDate)" >> $log
                Echo "`tVpnType  : $($UserKey.VpnType)" >> $log
            }
            Else {
                ModifyKey -KeyPath $KeyPath -KeyName "Access" -KeyValue 0
                $UserKey = ReadKey -Key $KeyPath
                Echo "=== Configuration $User ===" >> $log
                Echo "" >> $log
                Echo "`tAccess`t : $($UserKey.Access)" >> $log
                Echo "`tDays`t : $($UserKey.Days)" >> $log
                Echo "`tTimeSet`t : $($UserKey.TimeSet)" >> $log
                Echo "`tInitDate : $($UserKey.InitDate)" >> $log
                Echo "`tVpnType  : $($UserKey.VpnType)" >> $log
            }
        }
        If ($LocalDay -match "Thursday"){
            If ($Days.Thursday -eq $true){
                ModifyKey -KeyPath $KeyPath -KeyName "Access" -KeyValue 1
                $UserKey = ReadKey -Key $KeyPath
                Echo "=== Configuration $User ===" >> $log
                Echo "" >> $log
                Echo "`tAccess`t : $($UserKey.Access)" >> $log
                Echo "`tDays`t : $($UserKey.Days)" >> $log
                Echo "`tTimeSet`t : $($UserKey.TimeSet)" >> $log
                Echo "`tInitDate : $($UserKey.InitDate)" >> $log
                Echo "`tVpnType  : $($UserKey.VpnType)" >> $log
            }
            Else {
                ModifyKey -KeyPath $KeyPath -KeyName "Access" -KeyValue 0
                $UserKey = ReadKey -Key $KeyPath
                Echo "=== Configuration $User ===" >> $log
                Echo "" >> $log
                Echo "`tAccess`t : $($UserKey.Access)" >> $log
                Echo "`tDays`t : $($UserKey.Days)" >> $log
                Echo "`tTimeSet`t : $($UserKey.TimeSet)" >> $log
                Echo "`tInitDate : $($UserKey.InitDate)" >> $log
                Echo "`tVpnType  : $($UserKey.VpnType)" >> $log
            }
        }
        If ($LocalDay -match "Friday"){
            If ($Days.Friday -eq $true){
                ModifyKey -KeyPath $KeyPath -KeyName "Access" -KeyValue 1
                $UserKey = ReadKey -Key $KeyPath
                Echo "=== Configuration $User ===" >> $log
                Echo "" >> $log
                Echo "`tAccess`t : $($UserKey.Access)" >> $log
                Echo "`tDays`t : $($UserKey.Days)" >> $log
                Echo "`tTimeSet`t : $($UserKey.TimeSet)" >> $log
                Echo "`tInitDate : $($UserKey.InitDate)" >> $log
                Echo "`tVpnType  : $($UserKey.VpnType)" >> $log
            }
            Else {
                ModifyKey -KeyPath $KeyPath -KeyName "Access" -KeyValue 0
                $UserKey = ReadKey -Key $KeyPath
                Echo "=== Configuration $User ===" >> $log
                Echo "" >> $log
                Echo "`tAccess`t : $($UserKey.Access)" >> $log
                Echo "`tDays`t : $($UserKey.Days)" >> $log
                Echo "`tTimeSet`t : $($UserKey.TimeSet)" >> $log
                Echo "`tInitDate : $($UserKey.InitDate)" >> $log
                Echo "`tVpnType  : $($UserKey.VpnType)" >> $log
            }
        }
    }



    ####### Par Décompte ########

    Else {

        # Comparaison des jours restants
        $SoldDay = CompareDate -User $User

        If ($SoldDay -gt 0 ){

            # Plus de jours
            ModifyKey -KeyPath $KeyPath -KeyName "Access" -KeyValue 0
            Echo "=== Configuration $User ===" >> $log
            Echo "" >> $log
            Echo "`tAccess`t : $($UserKey.Access) ($($($UserKey.TimeSet)-$SoldDay)j restants)" >> $log
            Echo "`tDays`t : $($UserKey.Days)" >> $log
            Echo "`tTimeSet`t : $($UserKey.TimeSet)" >> $log
            Echo "`tInitDate : $($UserKey.InitDate)" >> $log
            Echo "`tVpnType  : $($UserKey.VpnType)" >> $log
        }
        Else {
            # Reste des jours
            ModifyKey -KeyPath $KeyPath -KeyName "Access" -KeyValue 1
            Echo "=== Configuration $User ===" >> $log
            Echo "" >> $log
            Echo "`tAccess`t : $($UserKey.Access) ($($($UserKey.TimeSet)-$SoldDay)j restants)" >> $log
            Echo "`tDays`t : $($UserKey.Days)" >> $log
            Echo "`tTimeSet`t : $($UserKey.TimeSet)" >> $log
            Echo "`tInitDate : $($UserKey.InitDate)" >> $log
            Echo "`tVpnType  : $($UserKey.VpnType)" >> $log
        }
    }

    # Ajoute le membre dans le groupe 'APP - Clients VPN - Accès Limité', si l'accès est OK et si le type du VPN est Complet
    If (($($UserKey.Access) -eq 1) -and ($($UserKey.VpnType) -eq 1 )){

        # Cherche les groupes de l'utilisateurs
        $GetUserLDAPGroup = Get-ADUser -LDAPFilter "(&(objectCategory=person)(sAMAccountName=$User))" –Properties MemberOf

        # Vérifie si l'utilisateur fait partie du groupe 'APP - Clients VPN - Accès Complet'
        If ($($GetUserLDAPGroup.MemberOf) -notmatch "APP - Clients VPN - Accès Complet"){

            Echo "`tAction   : Ajout dans 'APP - Clients VPN - Accès Complet'" >> $log

            # Ajoute l'utilisateur dans le groupe
            #Add-ADGroupMember -Members $UserLDAP -Identity $Vpn1 -Credential ***\***

            # Cherche les groupes de l'utilisateurs
            $GetUserLDAPGroup = Get-ADUser -LDAPFilter "(&(objectCategory=person)(sAMAccountName=$User))" –Properties MemberOf

            # Verifie si l'utilisateur a bien été ajouté
            If ($($GetUserLDAPGroup.MemberOf) -match "APP - Clients VPN - "){

                Echo "" >> $log
                Echo "  L'utilisateur $User a correctement été ajouté au groupe '$($Vpn1.Name)'" >> $log

            }
            Else {
            
                Echo "" >> $log
                Echo "  L'utilisateur $User n'a pas été ajouté au groupe '$($Vpn1.Name)'" >> $log
            }
        }
        Else {
            Echo "`tAction   : Aucune car $User fait déjà partie de 'APP - Clients VPN - Accès Complet'" >> $log
        }
        Echo "" >> $log
        Echo "" >> $log
    }

    # Ajoute le membre dans le groupe 'APP - Clients VPN - Accès Limité', si l'accès est OK et si le type du VPN est Limité
    ElseIf (($($UserKey.Access) -eq 1) -and ($($UserKey.VpnType) -eq 2 )){

        If ($($GetUserLDAPGroup.MemberOf) -notmatch "APP - Clients VPN - Accès Limité"){

            # Cherche les groupes de l'utilisateurs
            $GetUserLDAPGroup = Get-ADUser -LDAPFilter "(&(objectCategory=person)(sAMAccountName=$User))" –Properties MemberOf

            Echo "`tAction   : Ajout dans 'APP - Clients VPN - Accès Limité'" >> $log

            # Ajoute l'utilisateur dans le groupe
            #Add-ADGroupMember -Members $UserLDAP -Identity $Vpn2 -Credential $Credential

            # Cherche les groupes de l'utilisateurs
            $GetUserLDAPGroup = Get-ADUser -LDAPFilter "(&(objectCategory=person)(sAMAccountName=$User))" –Properties MemberOf

            # Verifie si l'utilisateur a bien été ajouté
            If ($($GetUserLDAPGroup.MemberOf) -match "APP - Clients VPN - "){

                Echo "" >> $log
                Echo "  L'utilisateur $User a correctement été ajouté au groupe '$($Vpn2.Name)'" >> $log

            }
            Else {
            
                Echo "" >> $log
                Echo "  L'utilisateur $User n'a pas été ajouté au groupe '$($Vpn2.Name)'" >> $log
            }
        }
        Else {
            Echo "`tAction   : Aucune car $User fait déjà partie de 'APP - Clients VPN - Accès Complet'" >> $log
        }
        Echo "" >> $log
        Echo "" >> $log
    }

    # Retire le membre du groupe auqel il appartient
    Else {
        Echo "`tAction   : Retiré du groupe " >> $log

        # Cherche les groupes de l'utilisateurs
        $GetUserLDAPGroup = Get-ADUser -LDAPFilter "(&(objectCategory=person)(sAMAccountName=$User))" –Properties MemberOf

        # Supprime l'utilisateur du groupe 'APP - Clients VPN - Accès Complet'
        If($GetUserLDAPGroup.MemberOf -contains $Vpn1){
            #Remove-ADGroupMember -Members $UserLDAP -Identity $Vpn1 -Credential $Credential
            # Verifie si l'utilisateur a bien été supprimé
            If ($($GetUserLDAPGroup.MemberOf) -notmatch "APP - Clients VPN - Accès Complet"){

                Echo "" >> $log
                Echo "  L'utilisateur $User a correctement été supprimé du groupe '$($Vpn1.Name)'" >> $log

            }
            Else {
            
                Echo "" >> $log
                Echo "  L'utilisateur $User n'a pas été ajouté au groupe '$($Vpn1.Name)'" >> $log
            }
        }

        # Supprime l'utilisateur du groupe 'APP - Clients VPN - Accès Limité'
        ElseIf ($GetUserLDAPGroup.MemberOf -contains $Vpn2) {
            #Remove-ADGroupMember -Members $UserLDAP -Identity $Vpn2 -Credential $Credential
            # Verifie si l'utilisateur a bien été supprimé
            If ($($GetUserLDAPGroup.MemberOf) -notmatch "APP - Clients VPN - Accès Limité"){

                Echo "" >> $log
                Echo "  L'utilisateur $User a correctement été supprimé du groupe '$($Vpn2.Name)'" >> $log

            }
            Else {
            
                Echo "" >> $log
                Echo "  L'utilisateur $User n'a pas été ajouté au groupe '$($Vpn2.Name)'" >> $log
            }
        }
        Else {

            Echo "" >> $log
            Echo "  Erreur l'utilisateur ne fait pas partie de 'APP - Clients VPN - Accès Complet' ou de 'APP - Clients VPN - Accès Limité'" >> $log
        }

        Echo "" >> $log
        Echo "" >> $log
    }
}