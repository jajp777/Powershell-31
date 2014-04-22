Cls
Import-Module ActiveDirectory
$UserList = @()
$UserNumber = $null


$Username = "***\***"
$Password = ConvertTo-SecureString "***" -AsPlainText -Force
$Credential = New-object -Typename System.Management.Automation.PSCredential -Argumentlist $Username, $Password


$UserInput = Read-Host -Prompt "Nom de l'utilisateur"
$UserLDAP = Get-ADUser -LDAPFilter "(&(objectCategory=person)(sAMAccountName=*))"-Credential $Credential -Server "***"

Foreach ($User in $UserLDAP){

    If ($User.SamAccountName -match $UserInput){

        $UserNumber ++        
        
        # Collect group info
        $Objet = New-Object Psobject
        $Objet | Add-Member -Name "ID" -membertype Noteproperty -Value $UserNumber
        $Objet | Add-Member -Name "Nom" -membertype Noteproperty -Value $($User.Name)
        $Objet | Add-Member -Name "SID" -membertype Noteproperty -Value $($User.SID)
        $Objet | Add-Member -Name "SAM" -membertype Noteproperty -Value $($User.SamAccountName)
        $Objet | Add-Member -Name "DN" -membertype Noteproperty -Value $($User.DistinguishedName)

        $UserList += $Objet
    }

}


Cls
$UserList | Format-Table -AutoSize