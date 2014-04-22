Cls
Import-Module ActiveDirectory
$GroupList = @()
$GroupNumber = $null


#$Username = "HOSTING\SCOR_AS"
#$Password = ConvertTo-SecureString "BADchQdyW1" -AsPlainText -Force 
$Username = "***\***"
$Password = ConvertTo-SecureString "***" -AsPlainText -Force
$Credential = New-object -Typename System.Management.Automation.PSCredential -Argumentlist $Username, $Password


$GroupInput = Read-Host -Prompt "Nom du groupe"
#$GroupLDAP = Get-ADGroup -LDAPFilter "(&(objectCategory=group)(cn=*))" -Credential $Credential -Server "jurau.hosting.carl.lan"
$GroupLDAP = Get-ADGroup -LDAPFilter "(&(objectCategory=group)(cn=*))" -Credential $Credential -Server "mckinley.carl-intl.fr"

Foreach ($Group in $GroupLDAP){

    If ($Group.Name -match $GroupInput){

        $GroupNumber ++        
        
        # Collect group info
        $Objet = New-Object Psobject
        $Objet | Add-Member -Name "ID" -membertype Noteproperty -Value $GroupNumber
        $Objet | Add-Member -Name "Nom" -membertype Noteproperty -Value $($Group.Name)
        $Objet | Add-Member -Name "SID" -membertype Noteproperty -Value $($Group.SID)
        $Objet | Add-Member -Name "SAM" -membertype Noteproperty -Value $($Group.SamAccountName)
        $Objet | Add-Member -Name "DN" -membertype Noteproperty -Value $($Group.DistinguishedName)

        $GroupList += $Objet
    }

}


Cls
$GroupList | Format-Table -AutoSize