# ------------------------------------------------------------------ #
# Script:      CalendarAccessRights                                  #
# Auteur:      Julian Da Cunha                                       #
# Date:        27/03/13                                              #
# Description: Permet de changer les droits pour Default et Anon     #
# ------------------------------------------------------------------ #

Set-AdServerSettings -ViewEntireForest $true -PreferredGlobalCatalog *** -WarningAction SilentlyContinue

Cls
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host " [ Vérification et Correction des droits Calendrier ]" -ForegroundColor Cyan
Write-Host ""
$UserMail = Read-Host "  -> Entrez le nom d'utilisateur "
Write-Host ""

If (-not (Get-PSSnapin | Where-Object {$_.Name -like "Microsoft.Exchange.Management.PowerShell.E2010"})){ 
    Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 
} 

$Mailbox = Get-Mailbox $UserMail -ErrorAction Stop
Trap { 
    Write-Host "    - Erreur l'utilisateur '$UserMail' est introuvable" -ForegroundColor Red
    Write-Host ""
    exit
}

$Calendar = (($Mailbox.SamAccountName)+ ":\" + (Get-MailboxFolderStatistics -Identity $Mailbox.SamAccountName -FolderScope Calendar | Select-Object -First 1).Name) 
$GetMailboxPerm = Get-MailboxFolderPermission $Calendar -ErrorAction Stop
Trap { 
    Write-Host "    - Erreur le Calendrier pour '$UserMail' est introuvable" -ForegroundColor Red
    Write-Host ""
    exit
}

For ( $i=0 ; $i -lt $GetMailboxPerm.Length ; $i++ ){
    
    $User = $GetMailboxPerm[$i].User.UserType
    $Right = $GetMailboxPerm[$i].AccessRights

    If ($User -like "Default"){
        If ($Right -like "None"){
            Write-Host ""
            Write-Host "    - Modification des droits pour l'utilisateur : $User" -ForegroundColor Yellow
            Set-MailboxFolderPermission -User "Default" -AccessRights "AvailabilityOnly" -Identity $calendar
        }
        Else {
            Write-Host ""
            Write-Host "    - Permissions pour $User........: OK ($Right)" -ForegroundColor Green
        }
    }
    ElseIf ($User -like "Anonymous"){
        If ($Right -like "None"){
            Write-Host "    - Permissions pour $User......: OK ($Right)" -ForegroundColor Green
            Write-Host ""
        }
        Else {
            Write-Host "    - Modification des droits pour l'utilisateur : $User" -ForegroundColor Yellow
            Set-MailboxFolderPermission -User "Anonymous" -AccessRights "None" -Identity $calendar
            Write-Host ""
        }
    }
}

Write-Host ""
Write-Host ""