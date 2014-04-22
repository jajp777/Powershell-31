# ------------------------------------------------------------------ #
# Script:      PrintTable                                            #
# Auteur:      Julian Da Cunha                                       #
# Date:        30/01/13                                              #
# Description: Permet d'afficher les index d'un tableau              #
#              Les index vide ne sont pas affichés                   #
# Utilisation: Mettre la commande dans la variable $cmd              #
# ------------------------------------------------------------------ #


  $cmd = Get-WmiObject win32_NetworkAdapter















                        #  Script plus bas #




















Function PrintTable {
    Param(
        $command
    )
    For ($i=0;$i -lt $command.Length;$i++){
        If ($command[$i] -eq ""){
        }
        Else {
            If ($i -le 9){
                Write-Host "`tIndex N°0$($i) | $($command[$i])"
            }
            Else {
                Write-Host "`tIndex N°$($i) | $($command[$i])"
            }
        }
    }
}

Cls
Write-Host "`nRésultat:`n`n"
PrintTable -command $cmd
Write-Host ""