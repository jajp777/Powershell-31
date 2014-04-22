trap [System.Exception] {
  write-host ("trapped " + $_.Exception.GetType().Name);
  continue;
}

$Error.Clear()                                                                 #reinitialise error array
$curErrAct = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"
$testPwsFolder = Join-Path $Env:USERPROFILE Demos #must contain all the demos and scripts => copy paste of the original folder contents
$powGuiFolder = Join-Path $Env:ProgramFiles PowerGui\ScriptEditor.exe #PowerGui path
$global:scriptErrors = $null

if (!(Test-Path -Path $testPwsFolder))	{
	New-Item $testPwsFolder -type directory
}

Set-Location $testPwsFolder

#very bad side effect : all the demo scripts are included in the environment paths thus no need to dotsource them to execute them
#$env:path += ";$env:USERPROFILE;$testPwsFolder"

#scripts load
.\get-examples.ps1
. .\start-demo.ps1
. .\GetGuiHelp.ps1

#functions
function List-Alias ($def) {  # lists all the aliases that match a certain chain passed as parameter
	Get-Alias |  ? { $_.definition -match $def } | Sort-Object definition | Select-Object definition, name | Format-Table -AutoSize
}

function Search-EnvVarFuncAlias ($ch, [switch]$e, [switch]$v, [switch]$f, [switch]$l, [switch]$a) {
	if ($e) {
		$res = dir env:
	}
	elseif ($v) {
		$res = dir variable:
	}
	elseif ($f) {
		$res = dir function:
	}
	elseif ($l) {
		$res = dir alias:
	}
	elseif ($a) {
		$res = dir env:
		$res += dir variable:
		$res += dir function:
		$res += dir alias:
	}	

	$res = $res | Where-Object { $_.name -match $ch	}

	$res | Format-Table name, psdrive -AutoSize
}

function Open-GuiScript($script) {
	invoke-item $script  #starts the script with the application linked to the ps1 files
	#&"$env:programfiles\PowerGui\Scripteditor.exe" $pwd\$script  #starts specifically with PowerGui
}

#aliases
Set-Alias gh help
Set-Alias exp Explorer
Set-Alias ed Notepad
Set-Alias ex get-examples
Set-Alias dem run-demo
Set-Alias guih get-guihelp
Set-Alias la List-Alias              #la   : shortcut for List-Alias
Set-Alias sf Search-EnvVarFuncAlias  #sf   : shortcut for Search-EnvVarFuncAlias
Set-Alias pgui Open-GuiScript        #pgui : shortcut for Open-GuiScript
#cls
$d = (Get-Date).ToShortDateString() + " " + (Get-Date).ToShortTimeString()
Write-Output "profile initialization done : $d"

Write-Output "-----------------------------------------------------"
Write-Output "|initial information available through variable `$inf|"
Write-Output "-----------------------------------------------------"

if ($Error -ne $null){
	$global:scriptErrors = $Error | ForEach-Object { $_.Exception }
}

$ErrorActionPreference = $curErrAct
$Error.Clear()                                                            #reinitialise error array

$inf

#here-strings
$global:inf = @"
gh  alias for help
ed  alias for Notepad
exp alias for Explorer
      exp test.txt

ex  alias of get-examples : personal script to execute examples of standard cmdlets
      ex cmdlet-name

dem alias of run-demos (start-demo.ps1) : script to run demos of 10325
      dem 4 3               #instructions from file 10325A-mod4-demo3.txt

guih alias of get-guihelp : script to see information from chm file for Powershell
      guih Get-ChildItem
      guih About_Parsing    #in about topics, sometimes word in plural but page invoqued in singular (ex : parameters : about_parameter)
      guih InStr
      guih 'For Each'

la  alias for List-Alias
      la ho   #any sub-chain of the alias name

sf  alias for Search-EnvVarFuncAlias  #allows to find environnement variables, functions, aliases and standard variables just with subchain
      sf comp -e  #search for environment variables that contain 'comp'
      sf comp -f  #search for functions that contain 'comp'
      sf pa   -v  #search for environment variables that contain 'pa'
      sf pa   -l  #search for aliases for cmdlets that contain 'pa'
      sf comp -a  #search for environment variables, functions and powershell variables that contain 'comp'

pgui alias for Open-GuiScript #allows to open a script in PowerGui
      pgui -script script_name.ps1
			
`$scriptErrors  variable to invoke to check if there were errors in the script

$ : Alt 36	
& : Alt 38
@ : Alt 64
``: Alt 96
| : Alt 124
~ : Alt 126
( : Alt 40  
) : Alt 41
/ : Alt 47
\ : Alt 92
[ : Alt 91
] : Alt 93
{ : Alt 123
} : Alt 125

`$jpinf is a user info variable
"@