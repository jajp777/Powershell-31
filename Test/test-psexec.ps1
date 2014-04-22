Cls
Set-Alias PsExec C:\Script\Sources\PSTools\PsExec.exe

$IPv4 = "192.168.200.209"
$Login = "RPS_JAURE_INF10\***"
$Password = "***"

$Command = @( )
$Command += "cmd"
$Command += "/c"
$Command += "ipconfig"

#& "C:\Script\Sources\EchoArgs.exe"  
PsExec \\$IPv4 -u $Login -p $Password $Command