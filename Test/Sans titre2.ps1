Cls

Import-Module ActiveDirectory

$User = "JCU"

$GroupLDAP = Get-ADGroup -LDAPFilter "(&(objectCategory=group)(cn=APP - Clients VPN - *))"
$UserLDAP = Get-ADUser -LDAPFilter "(&(objectCategory=person)(sAMAccountName=$User))"

$Vpn1 = $GroupLDAP | Where-Object {$_.Name -Match "Accès Complet"}
$Vpn2 = $GroupLDAP | Where-Object {$_.Name -Match "Accès Limité"}

Write-Host $Vpn1

#Add-ADGroupMember -Members $UserLDAP -Identity $Vpn1 -Verbose -Credential CARLINTL\AdminJCU

$test = Get-ADUser -LDAPFilter "(&(objectCategory=person)(sAMAccountName=$User))" –Properties MemberOf

if($test.MemberOf -contains $Vpn1){
    Write-Host "VPN1"
}
Else {
    Write-Host "Inconnu"
}

#If ($($GetUserLDAPGroup.MemberOf) -match "APP - Clients VPN - "){

#    Write-Host "L'utilisateur $User a correctement été ajouté au groupe '$($Vpn1.Name)'"

#}
#Else {

#    Write-Host "L'utilisateur $User n'a pas été ajouté au groupe '$($Vpn1.Name)'"
#}