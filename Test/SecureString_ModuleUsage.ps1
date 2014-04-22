Cls
Import-Module "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\SecureString\SecureStringFunctions.psm1"



# Entropy example
    $Entropy = ([Math]::PI)
    #$Entropy = "Ce mot de passe est brouillé par un entropy."



# User password input
    $SecureString = Read-Host -AsSecureString "Enter a secret password."
# Encrypt password and save it to .txt file
    $SecureString | ConvertFrom-SecureString -Entropy $Entropy | Out-File "E:\Mes Documents\Techniques\Bureau\PstoredPassword.txt"



# Make it readable from powershell 
    $NewSecureString = Get-Content -Path "E:\Mes Documents\Techniques\Bureau\PstoredPassword.txt" | ConvertTo-SecureString -Entropy $Entropy
# Display password
    $NewSecureString | ConvertFrom-SecureString -AsPlainText -Force