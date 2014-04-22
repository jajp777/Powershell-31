$GetUserLDAPGroup = Get-ADUser -LDAPFilter "(&(objectCategory=person)(sAMAccountName=*))"
$Pattern = "^Demo-[0-9]{2}$"
$Names = $GetUserLDAPGroup.SamAccountName
$AllNames = @()
$a = 0

# Parcours des utilisateurs LDAP
Foreach ($Name in $Names){

    If ($Name -match $Pattern){

        # Découpage des derniers caractères
        [Int] $DemoNb = $Name.Substring($Name.Length-2, 2)

        # Redim tableau
        $AllNames += @($a)

        # Ajoute valeur dans tableau
        $AllNames[$a] = $DemoNb
        $a++
    }
}


# Parcours tableau
For ( $i=1 ; $i -lt $AllNames.Length ; $i++ ){

    # Comparaison des valeurs du tableau + sélectionne valeur la plus haute
    If ($i -eq 1){
        If ($AllNames[$i] -gt $AllNames[0]){
            $Highest = $AllNames[$i]
        }
        Else {
            $Highest = $AllNames[0]            
        }
    }
    Else {
        If ($AllNames[$i] -gt $Highest){
            $Highest = $AllNames[$i]
        }
    }

}

# Traitement pour nouveau nom
$DemoNb = $Highest + 1

If ($DemoNb -lt 10){
    [String] $DemoNb = "0" + $DemoNb
}
Else {
    [String] $DemoNb = $DemoNb
}

$NewDemo = "Demo-"+$DemoNb