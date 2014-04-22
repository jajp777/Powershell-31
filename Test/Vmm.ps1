Import-Module "virtualmachinemanager"
$VMMServer = "****"

# Création Tableau
$VMProcessedList = @()
[Int]$VMProcessedCounter = $null

# Get VMs where Cloud not null
$VMs = Get-VM -VMMServer $VMMServer | where {($_.Cloud -ne $null)}
$UserRole = (Get-SCUserRole -VMMServer $VMMServer).Name

# Parcours des VMs associées à un cloud
Foreach ($VM in $VMs){

    # Vars
    $VMName = $VM.Name
    $VMGrantedList = ($VM.GrantedToList).Name
    $VMCloud = $VM.Cloud
    $SplitedCloud = $($VMCloud.ToString()).Substring(6)
    $Role = ""
    $Errors = $null

    # Pas de partage
    If ($VMGrantedList -eq $null) {

        If ($VMCloud -eq "Cloud Utilisateur"){
            # Execution de la commande 
            Grant-SCResource -Resource $VM -VMMServer $VMMServer -UserRoleName "$((Get-SCUserRole -VMMServer $VMMServer).Name | Where { $_ -match "Utilisa"})" -ErrorVariable $Errors -ErrorAction SilentlyContinue | Out-Null                        
        }
        Else {
            # Parcours des UserRole correspondant au Cloud de la VM
            For ($i=0; $i -le $($UserRole.Length-1); $i++){

                If ($UserRole[$i] -match $SplitedCloud) {
                    $Role = $UserRole[$i]
                    # Execution de la commande 
                    Grant-SCResource -Resource $VM -VMMServer $VMMServer -UserRoleName $Role -ErrorVariable $Errors -ErrorAction SilentlyContinue | Out-Null
                }
            }
        }

        # Traitement des données
        If ($Errors -eq $null) { $Errors = "Aucune" }
        $VMProcessedCounter ++
        
        $Objet = New-Object Psobject
        $Objet | Add-Member -Name "ID" -membertype Noteproperty -Value $VMProcessedCounter
        $Objet | Add-Member -Name "Nom VM" -membertype Noteproperty -Value $VMName
        $Objet | Add-Member -Name "Cloud Associé" -membertype Noteproperty -Value $VMCloud
        $Objet | Add-Member -Name "Utilisateur Ajouté" -membertype Noteproperty -Value $Role
        $Objet | Add-Member -Name "Erreurs" -membertype Noteproperty -Value $Errors

        $VMProcessedList += $Objet

    }
}

$Table = $VMProcessedList | Format-Table
$OutVar = $Table | Out-String | ConvertTo-Html