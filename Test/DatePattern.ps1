Cls

$Pattern2 = "^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])$"

$Date = "2014-12-31"

If ($Date -match $Pattern2){
    Write-Host "OK"
}
Else {
    Write-Host "NOT OK"
}