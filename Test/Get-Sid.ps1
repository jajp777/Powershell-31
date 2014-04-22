# Importation des modules
Import-Module ActiveDirectory
Get-ADUser -LDAPFilter "(objectCategory=person)" | Select sAMAccountName, SID | where { $_.sAMAccountName -eq "JFR"}