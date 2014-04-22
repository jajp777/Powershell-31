Clear
Import-Module virtualmachinemanager

$VMMServer = "***"

$VMProcessedList = @()
$VMProcessedCounter = $null
$VMProcessedList += ,@("ID`t", "Nom VM`t`t`t`t`t", "Cloud Associé`t`t`t", "Erreurs")
$VMProcessedList += ,@("-------------------------------------------------------------------------", "", "", "")

# Get VMs for Cloud IT, TMA, CPI, Utilisateurs
$VMs = Get-VM -VMMServer $VMMServer | where {($_.Cloud -Match "IT") -or ($_.Cloud -Match "TMA") -or ($_.Cloud -Match "Utilisateur") -or ($_.Cloud -Match "CPI")}
$UserRole = Get-SCUserRole -VMMServer $VMMServer

# Get UserRole for IT, TMA, CPI, Utilisateurs
$ITUser = $UserRole | where {$_.Name -match "IT"}
$TMAUser = $UserRole | where {$_.Name -match "TMA"}
$CPIUser = $UserRole | where {$_.Name -match "CPI"}
$UtilUser = $UserRole | where {$_.Name -match "Utilisateur"}

# Parcours des VMs correspondant aux clouds
for ($i=0; $i -le $($VMs.Length -1); $i++){
    
    if (($VMs[$i].Cloud -match "IT") -and ($($VMs[$i].GrantedToList).Name -notmatch $ITUser)){
        Grant-SCResource -Resource $($VMs[$i]) -VMMServer $VMMServer -UserRoleName $ITUser -ErrorVariable $Errors -ErrorAction SilentlyContinue | Out-Null
        
        if ($Errors -eq $null) { $Errors = "Succès" }

        if ($($VMs[$i].Name).Length -le 10) { $NameVM = "$($VMs[$i].Name)`t`t`t`t" }
        elseif ($($VMs[$i].Name).Length -ge 14) { $NameVM = "$($VMs[$i].Name)`t" }
        else { $NameVM = "$($VMs[$i].Name)`t`t`t" }
        
        $VMProcessedCounter ++
        $VMProcessedList += ,@("$VMProcessedCounter`t", $NameVM, "$($VMs[$i].Cloud)`t`t`t`t", $Errors)  
    }
    elseif (($VMs[$i].Cloud -match "TMA") -and ($($VMs[$i].GrantedToList).Name -notmatch $TMAUser)){
        Grant-SCResource -Resource $($VMs[$i]) -VMMServer $VMMServer -UserRoleName $TMAUser -ErrorVariable $Errors -ErrorAction SilentlyContinue | Out-Null
        
        if ($Errors -eq $null) { $Errors = "Succès" }

        if ($($VMs[$i].Name).Length -le 10) { $NameVM = "$($VMs[$i].Name)`t`t`t`t" }
        elseif ($($VMs[$i].Name).Length -ge 14) { $NameVM = "$($VMs[$i].Name)`t" }
        else { $NameVM = "$($VMs[$i].Name)`t`t`t" }
        
        $VMProcessedCounter ++
        $VMProcessedList += ,@("$VMProcessedCounter`t", $NameVM, "$($VMs[$i].Cloud)`t`t`t`t", $Errors)  
    }
    elseif (($VMs[$i].Cloud -match "CPI") -and ($($VMs[$i].GrantedToList).Name -notmatch $CPIUser)){
        Grant-SCResource -Resource $($VMs[$i]) -VMMServer $VMMServer -UserRoleName $CPIUser -ErrorVariable $Errors -ErrorAction SilentlyContinue | Out-Null
        
        if ($Errors -eq $null) { $Errors = "Succès" }

        if ($($VMs[$i].Name).Length -le 10) { $NameVM = "$($VMs[$i].Name)`t`t`t`t" }
        elseif ($($VMs[$i].Name).Length -ge 14) { $NameVM = "$($VMs[$i].Name)`t" }
        else { $NameVM = "$($VMs[$i].Name)`t`t`t" }

        $VMProcessedCounter ++
        $VMProcessedList += ,@("$VMProcessedCounter`t", $NameVM, "$($VMs[$i].Cloud)`t`t`t`t", $Errors)  
    }
    elseif (($VMs[$i].Cloud -match "Utilisateur") -and ($($VMs[$i].GrantedToList).Name -notmatch $UtilUser)){
        Grant-SCResource -Resource $($VMs[$i]) -VMMServer $VMMServer -UserRoleName $UtilUser -ErrorVariable $Errors -ErrorAction SilentlyContinue | Out-Null
        
        if ($Errors -eq $null) { $Errors = "Succès" }

        if ($($VMs[$i].Name).Length -le 10) { $NameVM = "$($VMs[$i].Name)`t`t`t`t" }
        elseif ($($VMs[$i].Name).Length -ge 14) { $NameVM = "$($VMs[$i].Name)`t" }
        else { $NameVM = "$($VMs[$i].Name)`t`t`t" }

        if ($($VMs[$i].Cloud).Length -gt 9) {$CloudName = "$($VMs[$i].Cloud)`t"}
        else {$CloudName = "$($VMs[$i].Cloud)`t`t`t`t"}
        
        $VMProcessedCounter ++
        $VMProcessedList += ,@("$VMProcessedCounter`t", $NameVM, "$($VMs[$i].Cloud)`t`t", $Errors)  
    }
}

$OutVar = ""
foreach($VM in $VMProcessedList){
        $OutVar += "$VM`n"
}

Write-Host $OutVar | Format-List