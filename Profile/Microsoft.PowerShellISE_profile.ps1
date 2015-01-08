Import-Module PsGet

function prompt {       

    # Check for Administrator elevation
    $wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
    $prp=new-object System.Security.Principal.WindowsPrincipal($wid)
    $adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator
    $IsAdmin=$prp.IsInRole($adm)
   
    if ($IsAdmin) {     

        # Set Window Title
        $host.UI.RawUI.WindowTitle = "ADMIN@$ENV:COMPUTERNAME - $(Get-Location)"  

        # Set Prompt
        Write-Host ""
        Write-Host "[" -NoNewline
	Write-Host "$(Get-Date -Format HH:mm)" -NoNewline -ForegroundColor Magenta
        Write-Host "]-[" -NoNewline -ForegroundColor White
        Write-Host "ADMIN" -NoNewline -ForegroundColor Red
        Write-Host "@$ENV:COMPUTERNAME" -NoNewline -ForegroundColor Yellow
        Write-Host "]-[" -NoNewline -ForegroundColor White
        Write-Host $(get-location) -NoNewline -ForegroundColor Green
        Write-Host "]" -ForegroundColor White
        Write-Host ""
        Write-Host "# : " -NoNewline -ForegroundColor Red
        return " "
    }
    else {   

        # Set Window Title
        $host.UI.RawUI.WindowTitle = "$ENV:USERNAME@$ENV:COMPUTERNAME - $(Get-Location)"

        # Set Prompt
        Write-Host ""
        Write-Host "[" -NoNewline
	Write-Host "$(Get-Date -Format HH:mm)" -NoNewline -ForegroundColor Magenta
        Write-Host "]-[" -NoNewline -ForegroundColor White
        Write-Host "$ENV:USERNAME" -NoNewline -ForegroundColor Cyan
        Write-Host "@$ENV:COMPUTERNAME" -NoNewline -ForegroundColor Yellow
        Write-Host "]-[" -NoNewline -ForegroundColor White
        Write-Host $(get-location) -NoNewline -ForegroundColor Green
        Write-Host "]" -ForegroundColor White
        Write-Host ""    
        Write-Host "$ : " -NoNewline -ForegroundColor White
        return " "
    }
 }