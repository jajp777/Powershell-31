Cls

$Username = "***\***"
$Password = ConvertTo-SecureString "***" -AsPlainText -Force 
$Credential = New-object -Typename System.Management.Automation.PSCredential -Argumentlist $Username, $Password

$AppsToApprove = @()

$Apps = Get-WmiObject -Class SMS_UserApplicationRequest -Namespace root/SMS/site_PRI -ComputerName kunlun.carl-intl.fr -Credential $Credential | Where-Object -FilterScript {$_.CurrentState -eq "1"} 

Foreach ($App in $Apps){

    $AppsToApprove += $App.RequestGuid

}

$RequestsInfo = Get-WmiObject -Class SMS_UserApplicationRequest -Namespace root/SMS/site_PRI -ComputerName kunlun.carl-intl.fr -Credential $Credential | Where-Object -FilterScript {$_.RequestGuid -eq $AppsToApprove}

Foreach ($App in $RequestsInfo) {
    $Comment = $App.Comments
    $User = $App.User
    $AppName = $App.Application
    $Date = $App.ConvertToDateTime($App.LastModifiedDate)
}

Write-Host "$Comment, $User, $AppName, $Date"