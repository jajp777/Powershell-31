Cls

$ToMove = @()
#$Folder = "\\viconga.carl-intl.fr\SAM$\"
$Folder = "\\viconga.carl-intl.fr\SAM$\Oracle\"
#$Destination = "\\viconga.carl-intl.fr\SAM$\Oracle"
$Destination = "\\viconga.carl-intl.fr\SAM$\Oracle\XE"

ForEach ($File in Get-ChildItem $Folder){

    $Read = Get-Content ($Folder + $File)

    #If ($Read -match "oracle.exe"){
    If ($Read -match "OracleJobSchedulerXE"){
        $ToMove += $File
    }
}

#Write-Host "Il y a $($ToMove.Count) sur $((Get-ChildItem $Folder).count) rapports qui contiennent 'Oracle.exe'"
Write-Host "Il y a $($ToMove.Count) sur $((Get-ChildItem $Folder).count) rapports qui contiennent 'OracleJobSchedulerXE'"

For ( $i=0 ; $i -lt $ToMove.Length ; $i++ ){
    Copy-Item -Path $($ToMove[$i].VersionInfo.FileName) -Destination $Destination
}