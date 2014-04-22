Cls

$Antivirus = Get-WmiObject -namespace root\SecurityCenter2 -Class AntiVirusProduct -Credential mc2a\adm-dacu -ComputerName 192.168.200.209
Write-Host "Antivirus :`t`t`t$($Antivirus.displayName)"

$State = $Antivirus.productState
$State = "{0:x}" -f $State
$State = [Convert]::ToString($State)

Write-Host "Longueur Variable :`t$($State.Length)"
Write-Host "Valeur Variable :`t$($State)"
Write-Host ""

If ($State.Length -eq 6){
    
}
If ($State.Length -eq 5){
    Write-Host "OK"
}

# ProductState Explication
#    Convertir le ProductState en (hex) exemple: 266240 -> 0×041000 (4 10 00)
#    Découper le code hex en 3 block de 3 bytes -> 0x04 0x10 0x00

# Secrutity Provider (Premier groupe de 3)
#
#    FIREWALL               = 0x01
#    AUTOUPDATE_SETTINGS    = 0x02
#    ANTIVIRUS              = 0x04
#    ANTISPYWARE            = 0x08
#    INTERNET_SETTINGS      = 0x16
#    USER_ACCOUNT_CONTROL   = 0x32
#    SERVICE                = 0x64
#    NONE                   = 0x00

# Scanner Setting (Deuxieme groupe de 3)
#
#    UNKNOWN                = 0x01
#    RUNNING                = 0x16

# State (Troisieme groupe de 3)
#
#    UP-TO-DATE             = 0x00
#    TOO-OLD                = 0x10