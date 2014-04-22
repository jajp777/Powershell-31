Clear
Import-Module virtualmachinemanager

$VMMServer = "***"

# Get VMs for Cloud IT, TMA, CPI, Utilisateurs
$VMs = Get-VM -VMMServer $VMMServer | where {($_.Cloud -Match "IT") -or ($_.Cloud -Match "TMA") -or ($_.Cloud -Match "Utilisateur") -or ($_.Cloud -Match "CPI")}
$UserRole = Get-SCUserRole -VMMServer $VMMServer

# Get UserRole for IT, TMA, CPI, Utilisateurs
$ITUser = $UserRole | where {$_.Name -match "IT"}
$TMAUser = $UserRole | where {$_.Name -match "TMA"}
$CPIUser = $UserRole | where {$_.Name -match "CPI"}
$UtilUser = $UserRole | where {$_.Name -match "Utilisateur"}

Write-Host "Nombre de VM :$($VMs.Length)`n`n"

# Parcours des VMs correspondant aux clouds
for ($i=0; $i -le $($VMs.Length -1); $i++){

    if (($VMs[$i].Cloud -match "IT") -and ($($VMs[$i].GrantedToList).Name -notmatch $ITUser)){
        Write-Host "VM not in UserRole List"
        Write-Host "------------------"
        Write-Host "Nom`t  : $($VMs[$i].Name)"
        Write-Host "Cloud : $($VMs[$i].Cloud)`n`n"

        Grant-SCResource -Resource $($VMs[$i]) -VMMServer $VMMServer -UserRoleName $ITUser -ErrorAction Suspend -ErrorVariable $Errors
    }
    elseif (($VMs[$i].Cloud -match "TMA") -and ($($VMs[$i].GrantedToList).Name -notmatch $TMAUser)){
        Write-Host "VM not in UserRole List"
        Write-Host "------------------"
        Write-Host "Nom`t  : $($VMs[$i].Name)"
        Write-Host "Cloud : $($VMs[$i].Cloud)`n`n"

        Grant-SCResource -Resource $($VMs[$i]) -VMMServer $VMMServer -UserRoleName $TMAUser -ErrorAction Suspend -ErrorVariable $Errors
    }
    elseif (($VMs[$i].Cloud -match "CPI") -and ($($VMs[$i].GrantedToList).Name -notmatch $CPIUser)){
        Write-Host "VM not in UserRole List"
        Write-Host "------------------"
        Write-Host "Nom`t  : $($VMs[$i].Name)"
        Write-Host "Cloud : $($VMs[$i].Cloud)`n`n"

        Grant-SCResource -Resource $($VMs[$i]) -VMMServer $VMMServer -UserRoleName $CPIUser -ErrorAction Suspend -ErrorVariable $Errors
    }
    elseif (($VMs[$i].Cloud -match "Utilisateur") -and ($($VMs[$i].GrantedToList).Name -notmatch $UtilUser)){
        Write-Host "VM not in UserRole List"
        Write-Host "------------------"
        Write-Host "Nom`t  : $($VMs[$i].Name)"
        Write-Host "Cloud : $($VMs[$i].Cloud)`n`n"

        Grant-SCResource -Resource $($VMs[$i]) -VMMServer $VMMServer -UserRoleName $UtilUser -ErrorAction Suspend -ErrorVariable $Errors
    }
}