Cls

# Vars
$Destination = Read-Host "Ordinateur distant (ex: JCU-WIN8) "
$Username = ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name).Replace("***²\", "")

# Suppresion de l'ancien lecteur réseau Powershell (éviter problèmes)
$Drive = New-Object -Com Wscript.Network
$Drive | Where-Object { $_.RemoveNetworkDrive("Z:") } -ErrorAction SilentlyContinue | Out-Null

# Connexion Lecteur Réseau
$Drive.MapNetworkDrive("Z:", "\\$Destination\E$\Temp", $True)        
If ((Test-Path Z:\) -eq $True){
    Write-Host "Lecteur réseau 'Z:\' a correctement été monté.`n" -ForegroundColor Green
    Sleep 2
    Cls
}
Else {
    Write-Host "Erreur, le lecteur réseau 'Z:\' n'a pas été monté.`n" -ForegroundColor Red
    Sleep 10
    Exit
}

$Mesure = Measure-Command {
    Write-Host "`nDébut de la copie:`n===================`n`n"

    # Sauvegarde Mozilla
    If ((Test-Path "C:\Users\$Username\AppData\Roaming\Mozilla") -eq $True){
        Copy-Item -Path "C:\Users\$Username\AppData\Roaming\Mozilla" -Destination Z:\ -Force -Recurse -ErrorAction SilentlyContinue
        If ((Test-Path "Z:\Mozilla") -eq $True){
            Write-Host "Copie des paramètres Mozilla: Success" -ForegroundColor Green
        } 
        Else {Write-Host "Copie des paramètres Mozilla: Erreur" -ForegroundColor Red}
    }

    # Sauvegarde Signature Outlook
    If ((Test-Path "C:\Users\$Username\AppData\Roaming\Microsoft\Signatures") -eq $True){
        Copy-Item -Path "C:\Users\$Username\AppData\Roaming\Microsoft\Signatures" -Destination Z:\ -Force -Recurse -ErrorAction SilentlyContinue
        If ((Test-Path "Z:\Signatures") -eq $True){
            Write-Host "Copie des Signatures Outlook: Success" -ForegroundColor Green
        } 
        Else {Write-Host "Copie des Signatures Outlook: Erreur" -ForegroundColor Red}
    }

    # Favoris Internet Explorer
    If ((Test-Path "C:\Users\$Username\Favorites") -eq $True){
        Copy-Item -Path "C:\Users\$Username\Favorites" -Destination "Z:\Favoris" -Force -Recurse -ErrorAction SilentlyContinue
        If ((Test-Path "Z:\Favoris") -eq $True){
            Write-Host "Copie des Favoris Internet Explorer: Success" -ForegroundColor Green
        } 
        Else {Write-Host "Copie des Favoris Internet Explorer: Erreur" -ForegroundColor Red}
    }

    # Documents
    If ((Test-Path "E:\Mes Documents") -eq $True){
        Copy-Item -Path "E:\Mes Documents" -Destination "Z:\Mes Documents" -Force -Recurse -ErrorAction SilentlyContinue
        If ((Test-Path "Z:\Mes Documents") -eq $True){
            Write-Host "Copie des Documents: Success" -ForegroundColor Green
        } 
        Else {Write-Host "Copie des Documents: Erreur" -ForegroundColor Red}
    }
    ElseIf ((Test-Path "E:\Documents") -eq $True){
        Copy-Item -Path "E:\Documents" -Destination "Z:\Mes Documents" -Force -Recurse -ErrorAction SilentlyContinue
        If ((Test-Path "Z:\Mes Documents") -eq $True){
            Write-Host "Copie des Documents: Success" -ForegroundColor Green
        } 
        Else {Write-Host "Copie des Documents: Erreur" -ForegroundColor Red}
    }
}

Write-Host "`n La migration des données s'est terminée en $($Mesure.Hours) H $($Mesure.Minutes) min $($Mesure.Seconds) s"