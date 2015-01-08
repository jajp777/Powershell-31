Import-Module PsGet
Import-Module PSReadLine
Import-Module posh-git
Import-Module SSH-Sessions

function su {

    # Check for Administrator elevation
    $Wid = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $Prp = new-object System.Security.Principal.WindowsPrincipal($Wid)
    $Adm = [System.Security.Principal.WindowsBuiltInRole]::Administrator
    $IsAdmin = $Prp.IsInRole($Adm)

    if ($IsAdmin) {       
        Write-Host "`nVous êtes déjà dans une session administrateur." -ForegroundColor Yellow
        return " "
    }
    else {
        $OldPid = $PID
        Start-Process Powershell -Verb RunAs
        Stop-Process $OldPid
    }
}

function prompt {       

    # Check for Administrator elevation
    $wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
    $prp=new-object System.Security.Principal.WindowsPrincipal($wid)
    $adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator
    $IsAdmin=$prp.IsInRole($adm)
   
    if ($IsAdmin) {     

        # Set Window Title
        $host.UI.RawUI.WindowTitle = "ADMIN@$ENV:COMPUTERNAME - $(Get-Location)"
        
        # Beep like R2D2
        #1..$(Get-Random -Minimum 3 -Maximum 6) | ForEach-Object {
        #    $frequency = Get-Random -Minimum 250 -Maximum 9000
        #    $duration = Get-Random -Minimum 100 -Maximum 600
        #    [Console]::Beep($frequency, $duration)
        #} 

        # Set Prompt
        Write-Host ""
        Write-Host " [" -NoNewline
	Write-Host "$(Get-Date -Format HH:mm)" -NoNewline -ForegroundColor Magenta
        Write-Host "]-[" -NoNewline -ForegroundColor White
        Write-Host "ADMIN" -NoNewline -ForegroundColor Red
        Write-Host "@$ENV:COMPUTERNAME" -NoNewline -ForegroundColor Yellow
        Write-Host "]-[" -NoNewline -ForegroundColor White
        Write-Host $(get-location) -NoNewline -ForegroundColor Green
        Write-Host "]" -ForegroundColor White
        Write-Host ""
        Write-Host " # : " -NoNewline -ForegroundColor Red
        return " "
    }
    else {   

        # Set Window Title
        $host.UI.RawUI.WindowTitle = "$ENV:USERNAME@$ENV:COMPUTERNAME - $(Get-Location)"

        # Beep like R2D2
        #1..$(Get-Random -Minimum 3 -Maximum 6) | ForEach-Object {
        #    $frequency = Get-Random -Minimum 250 -Maximum 9000
        #    $duration = Get-Random -Minimum 100 -Maximum 600
        #    [Console]::Beep($frequency, $duration)
        #} 

        # Set Prompt
        Write-Host ""
        Write-Host " [" -NoNewline
	Write-Host "$(Get-Date -Format HH:mm)" -NoNewline -ForegroundColor Magenta
        Write-Host "]-[" -NoNewline -ForegroundColor White
        Write-Host "$ENV:USERNAME" -NoNewline -ForegroundColor Cyan
        Write-Host "@$ENV:COMPUTERNAME" -NoNewline -ForegroundColor Yellow
        Write-Host "]-[" -NoNewline -ForegroundColor White
        Write-Host $(get-location) -NoNewline -ForegroundColor Green
        Write-Host "]" -ForegroundColor White
        Write-Host ""    
        Write-Host " $ : " -NoNewline -ForegroundColor White
        return " "
    }
 }
Import-Module PsCSA

Import-Module SecureStringFunctions
