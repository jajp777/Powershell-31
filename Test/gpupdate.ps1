$Gpupdate = cmd /c gpupdate /force
cls
Write-Host ""
If ($Gpupdate[0] -eq "Mise … jour de la strat‚gie..."){ 
    Write-Host "Mise à jour de la stratégie...`n"
}
If ($Gpupdate[4] -eq "La mise … jour de la strat‚gie d'ordinateur s'est termin‚e sans erreur."){
    Write-Host "`tStratégie Ordinateur  [OK]"
}
Else {
    Write-Host "`tStratégie Ordinateur  [Erreur]"
}
If ($Gpupdate[6] -eq "La mise … jour de la strat‚gie utilisateur s'est termin‚e sans erreur."){
    Write-Host "`tStratégie Utilisateur [OK]"
}
Else{
    Write-Host "`tStratégie Utilisateur  [Erreur]"
}
Write-Host ""