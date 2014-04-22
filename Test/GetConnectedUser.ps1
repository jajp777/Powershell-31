    Cls
    $ComputerList = "192.168.3.13"
    $Credential = Get-Credential
    #Cls

    ForEach ($Computer in $ComputerList) {
        $Processus = Gwmi Win32_Process -Computer $Computer -Filter "Name = 'explorer.exe'" -Credential $Credential
        ForEach ($Proc in $Processus) {
            $Info = "" | Select Computer, Domain, User
            $Info.Computer = $Computer
            $Info.User = ($Proc.GetOwner()).User
            $Info.Domain = ($Proc.GetOwner()).Domain
            Write-Host "`n`t$($Info.User)`n"
        }
    }