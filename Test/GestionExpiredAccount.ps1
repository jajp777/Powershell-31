Cls

#$Result = C:\windows\System32\WindowsPowerShell\v1.0\PowerShell.exe -NonInteractive -Command {

    Import-Module ActiveDirectory
    
    $Members = @()
    $AccountExpired = @()
    $ToDel = @()
    $Date = Get-Date
    $Removed = @()
    $Reminder = @()
    $NeverExpires = "9223372036854775807"

    $Username = "***\***"
    $Password = ConvertTo-SecureString "***" -AsPlainText -Force 
    $Credential = New-object -Typename System.Management.Automation.PSCredential -Argumentlist $Username, $Password

    # Filtre les comptes expirés par rapport à aujourd'hui
    $UserLDAP = Get-ADUser -Filter * -Properties accountExpires -Credential $Credential -Server "***"
    Foreach ($User in $UserLDAP){
        If ($User.accountExpires -ne $NeverExpires){
            $Expire = [datetime]::FromFileTime($User.accountExpires)
            If ($Expire -lt $Date){
                $AccountExpired += $User
            }
        }
    }

    # Filtre les groupes CS-DEMO-*-ACCESS et trouve leurs membres
    $GroupsLDAP = Get-ADGroup -LDAPFilter "(&(objectCategory=group)(cn=CS-DEMO-*-ACCESS))" -Credential $Credential -Server "***"
    Foreach ($Group in $GroupsLDAP) {
        $Members += Get-ADGroupMember -Identity $Group -Credential $Credential -Server "***"
    }
  
    # Compare les comptes expirés aux membres des groupes DEMO
    Foreach ($Expired in $AccountExpired){
        Foreach ($Member in $Members){
            If ($Expired.Name -eq $Member.name){
                $ToDel += $Expired
            }
        }
    }

    # Suppression des comptes
    Foreach ($User in $ToDel){

        $Expire = [datetime]::FromFileTime($User.accountExpires)
        $Diff = ($Date - $Expire).Days

        If ($Diff -le 7){
            $Reminder += $User.Name
        }
        If ($Diff -gt 15){
            Remove-ADUser -Identity $($User.DistinguishedName) -Credential $Credential -Server "***" -Confirm
            $Removed += $User.Name
        }
    }

    # Envoi Email
    If ($Reminder -ne $null){
        Send-MailMessage -From "someone@test.com" -To "i@m.com" -Subject "RAPPEL : Suppression de compte - HOSTING" -Body "Liste des utilisateurs de *** *** ayant un compte expire depuis moins de 7 jours: `n`n$($Reminder | Format-List | Out-String)" -Priority High -SmtpServer ***
    }
    If ($Removed -ne $null){
        Send-MailMessage -From "someone@test.com" -To "i@m.com" -Subject "Suppression de compte - HOSTING" -Body "Liste des utilisateurs de *** *** ayant supprime: `n`n $($Removed | Format-List | Out-String)" -Priority High -SmtpServer ***
    }
#}