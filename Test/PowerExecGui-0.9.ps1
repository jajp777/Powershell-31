# ------------------------------------------------------------------ #
# Script:      PowerExec                                             #
# Auteur:      Julian Da Cunha                                       #
# Date:        12/01/13                                              #
# Description: Utilisez Powershell & PaExec pour controler vos PC    #
# Version:     0.9                                                   #
# ------------------------------------------------------------------ #


# Cache le Shell =======================================
$Script:ShowWindowAsync = Add-Type –MemberDefinition @”
[DllImport("user32.dll")]
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
“@ -Name “Win32ShowWindowAsync” -Namespace Win32Functions –PassThru

Function Show-PowerShell() { 
    $Null = $ShowWindowAsync::ShowWindowAsync((Get-Process –Id $Pid).MainWindowHandle, 10) 
}

Function Hide-PowerShell() { 
    $Null = $ShowWindowAsync::ShowWindowAsync((Get-Process –Id $Pid).MainWindowHandle, 2) 
}

Hide-PowerShell
New-Object -Com Wscript.Network | Where-Object { $_.RemoveNetworkDrive("K:") }
Get-Process iperf | Stop-Process $_
Get-Process paexec | Stop-Process $_
Cls

#########################################################
## VARS & FUNCTIONS #####################################
#########################################################

    # Alias =============================================
        Set-Alias PaExec C:\Script\Sources\paexec.exe
        Set-Alias 7z C:\Script\Sources\7z\7z.exe

    # Vars ==============================================
        $Script:ValidateIPv4 = $False
        $Script:ValidateAccount = $False
        $PrepareToolsError = $False
        $Script:NetworkDrive = $True
        $Script:PsTools = $True
        $Date = Get-date
        $Script:DatetoLog = $Date.ToShortDateString() -replace "/", "-"
        $LocalIP = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName . | Select-Object IPAddress
        $LocalIP = $LocalIP.IPAddress[0]

    # Modules ===========================================
        Import-Module BitsTransfer

    # Set Powershell for Full Debug =====================
        Set-PSDebug -Strict

    # Chargement des Assembly ===========================
        Add-Type –AssemblyName System.Windows.Forms | Out-Null
        Add-Type –AssemblyName System.Drawing | Out-Null

    # Définit les polices de caractères
        $ClassicFont = New-Object System.Drawing.Font( "Tahoma",8,[System.Drawing.FontStyle]::Regular )
        $StateFont = New-Object System.Drawing.Font( "Tahoma",8,[System.Drawing.FontStyle]::Bold )
        $TitleFont = New-Object System.Drawing.Font( "Times New Roman",20,[System.Drawing.FontStyle]::Bold )
        # Regular, Bold, Italic, Underline, Strikeout

    # Définit l'icone générale ==========================
        $Icon = [System.Drawing.Icon]::ExtractAssociatedIcon( $PSHOME + "\powershell.exe" )

    # Alias
        Set-Alias PaExec C:\Script\Sources\paexec.exe
        Set-Alias 7z C:\Script\Sources\7z\7z.exe

    # Fonction Refresh Content ==========================
        Function TextRefresh {
        
            Param ( 
                $TextToRefresh, 
                [String] $NewText, 
                [String] $TextColor
            )

            $TextToRefresh[0].Text = $NewText
            $TextToRefresh[0].ForeColor = $TextColor
            $TextToRefresh[0].Refresh()
        }

    # Fonction Change Window Size =======================
        Function ChangeWindowSize {
        
            Param ( 
                $FormToResize, 
                [Int] $WindowWidth, 
                [Int] $WindowHeight
            )

            $FormToResize[0].Width = $WindowWidth
            $FormToResize[0].Height = $WindowHeight
        }

    # Fonction Form Control For IPV4 ====================
        Function FormControlIPv4 {
    
            Param (
                [Bool] $State
            )

            If ( $State -eq $True ) {
            
                ChangeWindowSize -FormToResize $Form -WindowWidth 365 -WindowHeight 292

                TextRefresh -TextToRefresh $LabelConnectState -NewText "[Non Effectué]" -TextColor "Black"
                TextRefresh -TextToRefresh $ErrorInfo1 -NewText "" -TextColor "Orange"

                $FieldIPv4.Text = ""

                $Script:ValidateIPv4 = $False

                $LabelIPv4.Visible = $True
                $LabelConnect.Visible = $True
                $LabelConnectState.Visible = $True
                $ErrorInfo1.Visible = $True

                $CancelButton1.Visible = $True
                $ValidateButton1.Visible = $True
                $TestConnectButton.Visible = $True

                $FieldIPv4.Visible = $True
            }
            Else {

                $LabelIPv4.Visible = $False
                $LabelConnect.Visible = $False
                $LabelConnectState.Visible = $False
                $ErrorInfo1.Visible = $False

                $ValidateButton1.Visible = $False
                $TestConnectButton.Visible = $False
                $CancelButton1.Visible = $False

                $FieldIPv4.Visible = $False
            }
        }
   
    # Fonction Form Control Confirm =====================
        Function FormControlConfirm {
    
            Param (
                [Bool] $State
            )

            If ( $State -eq $True ) {

                ChangeWindowSize -FormToResize $Form -WindowWidth 370 -WindowHeight 265

                Try {
                    $IP = ($Dns.AddressList | Findstr [0-9].\.).Split()[-1]
                    $Script:Name = $Dns.HostName
                
                    TextRefresh -TextToRefresh $LabelRemoteHostIP -NewText   "Adresse IPv4....: $($IP)" -TextColor "Black"
                    TextRefresh -TextToRefresh $LabelRemoteHostName -NewText "Nom Machine....:  $($Script:Name)" -TextColor "Black"
                }
                Catch {
                    TextRefresh -TextToRefresh $LabelRemoteHostIP -NewText   "Adresse IPv4....: Non Disponnible" -TextColor "Black"
                    TextRefresh -TextToRefresh $LabelRemoteHostName -NewText "Nom Machine....: Non Disponnible" -TextColor "Black"                
                }

                TextRefresh -TextToRefresh $ErrorInfo2 -NewText "" -TextColor "Orange"

                $Script:ValidateAccount = $False

                $LabelRemoteHostIP.Visible = $True
                $LabelRemoteHostName.Visible = $True
                $AdminAccountState.Visible = $True
                $ErrorInfo2.Visible = $True
                $LabelAdminAccountState.Visible = $True
                $LabelAdminAccount.Visible = $True

                $AccountButton.Visible = $True
                $ValidateButton2.Visible = $True
                $HostButton.Visible = $True
                $CancelButton2.Visible = $True
            }
            Else {

                $LabelRemoteHostIP.Visible = $False
                $LabelRemoteHostName.Visible = $False
                $AdminAccountState.Visible = $False
                $ErrorInfo2.Visible = $False
                $LabelAdminAccountState.Visible = $False
                $LabelAdminAccount.Visible = $False

                $AccountButton.Visible = $False
                $ValidateButton2.Visible = $False
                $HostButton.Visible = $False
                $CancelButton2.Visible = $False
            }
        }

    # Fonction Form Control Activate ====================
        Function FormControlActivate {
    
            Param (
                [Bool] $State
            )

            If ( $State -eq $True ) {

                ChangeWindowSize -FormToResize $Form -WindowWidth 400 -WindowHeight 210

                TextRefresh -TextToRefresh $LabelPaExecState -NewText "[Non Vérifié]" -TextColor "Black"
                TextRefresh -TextToRefresh $LabelNetworkDriveState -NewText "[Non Connecté]" -TextColor "Black"

                $LabelNetworkDrive.Visible = $True
                $LabelNetworkDriveState.visible = $True
                $LabelPaExec.Visible = $True
                $LabelPaExecState.visible = $True
                $ErrorInfo3.visible = $True

                $ValidateButton3.Visible = $True
                $CancelButton3.Visible = $True
            }
            Else {

                $LabelNetworkDrive.Visible = $False
                $LabelNetworkDriveState.visible = $False
                $LabelPaExec.Visible = $False
                $LabelPaExecState.Visible = $False
                $ErrorInfo3.visible = $False

                $CancelButton3.Visible = $False
                $ValidateButton3.Visible = $False
            }
        }

    # Fonction Form Control Action ======================
        Function FormControlAction {
    
            Param (
                [Bool] $State
            )

            If ( $State -eq $True ) {

                ChangeWindowSize -FormToResize $Form -WindowWidth 400 -WindowHeight 220

                TextRefresh -TextToRefresh $StatusBar -NewText "Etat: En attente de commandes"

                $InfoComputerButton.Visible = $True
                $StatusBar.Visible = $True

                $RebootButton.Visible = $True
                $HostButton2.Visible = $True
                $QuitButton.visible = $True
                $CopyToHost.Visible = $True
                $CopyToLocal.Visible = $True
                $PaExec2.Visible = $True
                #$Iperf.Visible = $True

                If ( $Script:NetworkDrive -eq $False ){ 
                    $Iperf.Enabled = $False
                    $CopyToHost.Enabled = $False
                    $CopyToLocal.Enabled = $False
                } 
                Else { 
                #    $Iperf.Enabled = $True 
                    $CopyToHost.Enabled = $True
                    $CopyToLocal.Enabled = $True
                }
            }
            Else {

                $InfoComputerButton.Visible = $False
                $StatusBar.Visible = $False

                $QuitButton.visible = $False
                #$Iperf.Visible = $False
                $RebootButton.Visible = $False
                $HostButton2.Visible = $False
                $CopyToHost.Visible = $False
                $CopyToLocal.Visible = $False
                $PaExec2.Visible = $False
            }
        }

    # Fonction Test Connectivity ========================
        Function TestConnectivity {
        
            Param (
                $Remote_Host
            )

            $IPv4 = $Remote_Host
            $FieldIPv4.Enabled = $False
            TextRefresh -TextToRefresh $LabelConnectState -NewText "[En Cours]" -TextColor "Black"
            TextRefresh -TextToRefresh $ErrorInfo1 -NewText "" -TextColor ""
            Try {
                $PingTest = Test-Connection $IPv4 -Quiet -Count 2 -ErrorAction SilentlyContinue
                If ( $PingTest -eq $True ) {
                    TextRefresh -TextToRefresh $LabelConnectState -NewText "[Succès]" -TextColor "Green"
                    TextRefresh -TextToRefresh $ErrorInfo1  -NewText "" -TextColor ""
                    $Script:ValidateIPv4 = $True
                }
                Else {
                    TextRefresh -TextToRefresh $LabelConnectState -NewText "[Erreur]" -TextColor "Red"
                    TextRefresh -TextToRefresh $ErrorInfo1 -NewText "Hôte distant non démarré, ou ICMP bloqué" -TextColor "Orange"
                    $Script:ValidateIPv4 = $False
                }
             }
             Catch {
                TextRefresh -TextToRefresh $LabelConnectState -NewText "[Erreur]" -TextColor "Red"
                TextRefresh -TextToRefresh $ErrorInfo1 -NewText "Veuillez entrer une Adresse IPv4 (ex: 192.168.1.1)" -TextColor "Orange"
                $Script:ValidateIPv4 = $False
             }
             $FieldIPv4.Enabled = $True
        }

    # Fonction Test Account =============================
        Function TestAccount {
    
            Param (
                $Account,
                $Computer
            )

            Try {
                $GetComputerSystem = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $Computer -Credential $Account -ev ErrorRPC -ea SilentlyContinue
                TextRefresh -TextToRefresh $AdminAccountState -NewText " [Valide]" -TextColor "Green"
                TextRefresh -TextToRefresh $ErrorInfo2 -NewText "" -TextColor "Orange"
                $Script:ValidateAccount = $True
            }
            Catch [System.UnauthorizedAccessException] {
                TextRefresh -TextToRefresh $AdminAccountState -NewText " [Erreur]" -TextColor "Red"
                TextRefresh -TextToRefresh $ErrorInfo2 -NewText "Vos informations d'indentification fournis sont incorrect" -TextColor "Orange"
                $Script:ValidateAccount = $False
            }
            If ($ErrorRPC -match "(Exception de HRESULT : 0x800706BA)") {
                TextRefresh -TextToRefresh $AdminAccountState -NewText " [Erreur]" -TextColor "Red"
                TextRefresh -TextToRefresh $ErrorInfo2 -NewText "Le Serveur RPC distant est indisponible" -TextColor "Orange"
                $Script:ValidateAccount = $False   
            }
        }

    # Fonction PSTools ===================================
        Function PsTools {

            Param (
                [Bool]$State
            )

            If ($State -eq $True) {

                If ((Test-Path C:\Script\Sources\PSTools) -eq $True) {                                            
                    TextRefresh -TextToRefresh $LabelPaExecState -NewText "[OK]" -TextColor "Green"
                }
                Else {
                    $Job = Start-BitsTransfer -Source http://download.sysinternals.com/files/PSTools.zip -Destination "C:\Script\Sources" -Asynchronous

                    While (($Job.JobState -eq "Transferring") -or ($Job.JobState -eq "Connecting")){
                        Sleep 1   
                        TextRefresh -TextToRefresh $LabelPaExecState -NewText "$($Job.JobState) ($([math]::truncate($Job.BytesTransferred/1KB))Ko / $([math]::truncate($Job.BytesTotal/1KB))Ko)" -TextColor "Black"
                    }
            
                    Complete-BitsTransfer -BitsJob $Job.JobId

                    If ((Test-Path "C:\Script\Sources\PSTools.zip") -eq $True) {
                        sleep 1
                        TextRefresh -TextToRefresh $LabelPaExecState -NewText "Extraction des fichiers.." -TextColor "Black"
                        Sleep 2
                        7z x "C:\Script\Sources\PSTools.zip" -oC:\Script\Sources\PSTools

                        If ((Test-Path C:\Script\Sources\PSTools) -eq $True) {
                            TextRefresh -TextToRefresh $LabelPaExecState -NewText "[OK]" -TextColor "Green"
                        }
                    }
                    Else {
                        TextRefresh -TextToRefresh $LabelPaExecState -NewText "[Erreur]" -TextColor "Red"
                        TextRefresh -TextToRefresh $ErrorInfo3 -NewText "Téléchargement Echoué, vérifiez votre Firewall, ou vos droits d'écriture" -TextColor "Orange"
                        $Script:PsTools = $False
                    }
                }
            }
        }

    # Connexion Lecteur Réseau
        Function NetworkDrive {

            Param (
                [Bool]$State
            )

            $Drive = New-Object -Com Wscript.Network
            $Drive.MapNetworkDrive("K:", "\\$Script:IPv4\C$", $False, $Script:Login, $Script:Password)
            
            If ((Test-Path K:\) -eq $True){

                TextRefresh -TextToRefresh $LabelNetworkDriveState -NewText "[Connecté]" -TextColor "Green"

                If ((Test-Path K:\Temp) -eq $False){
                    New-Item -Path K:\Temp -type directory -Force
                    
                    If ((Test-Path K:\Temp) -eq $False){
                        TextRefresh -TextToRefresh $LabelNetworkDriveState -NewText "[Erreur]" -TextColor "Red"
                        TextRefresh -TextToRefresh $ErrorInfo3 -NewText "Vérifiez vos droits pour créer le dossier Temp" -TextColor "Orange"
                        $CopyToHost.Enabled = $False
                        $CopyToLocal.Enabled = $False
                        $Script:NetworkDrive = $False
                    }
                }
            }
            Else {
                TextRefresh -TextToRefresh $ErrorInfo3 -NewText "Impossible de connecter le lecteur réseau Q" -TextColor "Orange"
            }
        }

    # Fonction LogComputer
        Function LogComputer {
        
            Param (
                $LogName,
                $Credential,
                $RemoteHost
            )

            TextRefresh -TextToRefresh $StatusBar -NewText "Etat: Récupération des informations en cours.."

            $LogInfo = "C:\Script\Log\(INFO)__$($Script:Hostname.HostName)__($DatetoLog).log"

            Echo "# ------------------------------------------------------------------ #" > $LogInfo
            Echo "# Script:      PowerExec                                             #" >> $LogInfo
            Echo "# Auteur:      Julian Da Cunha                                       #" >> $LogInfo
            Echo "# Date:        $($Script:DatetoLog)                                            #" >> $LogInfo
            Echo "# Heure:       $($Script:DateTime)                                                 #" >> $LogInfo
            Echo "# ------------------------------------------------------------------ #" >> $LogInfo
            Echo "" >> $LogInfo

            $GetComputerSystem = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $RemoteHost -Credential $Credential
            $NetworkAdapterConfiguration = Get-WMIObject Win32_NetworkAdapterConfiguration -ComputerName $RemoteHost -Credential $Credential
            $NetworkAdapter = Get-WMIObject Win32_NetworkAdapter -ComputerName $RemoteHost -Credential $Credential
            $Disques = Get-WMIObject Win32_LogicalDisk -ComputerName $RemoteHost -Credential $Credential
            $OS = Get-WmiObject Win32_OperatingSystem -ComputerName $RemoteHost -Credential $Credential
            $RAM= Get-WmiObject CIM_PhysicalMemory -ComputerName $RemoteHost -Credential $Credential
            $PROC = Get-WmiObject Win32_Processor -ComputerName $RemoteHost -Credential $Credential
            $SP = $OS.ServicePackMajorVersion

            TextRefresh -TextToRefresh $StatusBar -NewText "Etat: Création du fichier log.."

            If ($SP -eq 0) {
                $SP="Aucun"
            }

            Echo "    Informations Matériels :" >> $LogInfo
            Echo "" >> $LogInfo
            Echo "        Nom . . . . . . : $($GetComputerSystem.Name)" >> $LogInfo
            Echo "        Domaine . . . . : $($GetComputerSystem.Domain)" >> $LogInfo
            Echo ""  >> $LogInfo
            Echo "        Model . . . . . : $($GetComputerSystem.Model)" >> $LogInfo
            Echo "        Fabricant . . . : $($GetComputerSystem.Manufacturer)" >> $LogInfo
            Echo "        OS  . . . . . . : $($OS.Caption)" >> $LogInfo
            Echo "        Service Pack  . : $($SP)" >> $LogInfo
            Echo "        Architecture  . : $($OS.OSArchitecture)" >> $LogInfo
            Echo "        Ram Totale  . . : $([math]::Round(($GetComputerSystem.TotalPhysicalMemory)/1GB,2)) Go" >> $LogInfo

            For ($i=0 ; $i -lt $RAM.length ; $i++) {
                $RamType = $RAM[$i]
                Echo "" >> $LogInfo
                Echo "            Taille Barrette . . : $([math]::Round(($RamType.Capacity)/1GB,2)) Go" >> $LogInfo
                Echo "            Channel . . . . . . : $($RamType.DeviceLocator)" >> $LogInfo
                Echo "            Fréquence . . . . . : $($RamType.Speed) Mhz" >> $LogInfo
            }

            Echo ""  >> $LogInfo
            Echo "        Processeur. . . : $($PROC.Name)" >> $LogInfo 
            Echo "        Max Clock . . . : $($PROC.MaxClockSpeed) Mhz" >> $LogInfo
            Echo "        Taille Cache L2 : $($PROC.L2CacheSize) Mo" >> $LogInfo
            Echo "        Taille Cache L3 : $($PROC.L3CacheSize) Mo" >> $LogInfo

            For ($i=0 ; $i -lt $Disques.length ; $i++) {                                            
                $HDD = $Disques[$i]
                If ($HDD.Size -gt 0) {
                    Echo ""  >> $LogInfo
                    Echo "        Disque $($HDD.DeviceID)" >> $LogInfo
                    Echo "            Nom du volume . . . . . . : $($HDD.VolumeName)" >> $LogInfo
                    Echo "            Taille du disque  . . . . : $([math]::Round(($HDD.Size)/1GB,2)) Go" >> $LogInfo
                    Echo "            Taille utilisé  . . . . . : $($([math]::Round(($HDD.Size)/1GB,2))-$([math]::Round(($HDD.FreeSpace)/1GB,2))) Go" >> $LogInfo
                    Echo "            Taille restante . . . . . : $([math]::Round(($HDD.FreeSpace)/1GB,2)) Go" >> $LogInfo
                    Echo "            Utilisation . . . . . . . : $([math]::Round(($($([math]::Round(($HDD.Size)/1GB,2))-$([math]::Round(($HDD.FreeSpace)/1GB,2)))*100/$([math]::Round(($HDD.Size)/1GB,2))),2)) %" >> $LogInfo
                }
            }

            Echo "" >> $LogInfo
            "    Informations Réseau :" >> $LogInfo
            Echo "" >> $LogInfo

            For ($i=0 ; $i -lt $NetworkAdapter.length ; $i++) {
                $Nic = $NetworkAdapter[$i]
                $Configuration = $NetworkAdapterConfiguration[$i]

                If ($Configuration.IPEnabled) {
                    $Index = $Nic.Index
                    $AdapterType = $Nic.AdapterType

                    If ($OS.version -gt 5.0) {
                        $Connecteur = $Nic.NetConnectionID
                    }
                    Else {
                        $Connecteur = $Nic.Index
                    }
                    $DhcpServer=$Configuration.DHCPServer

                    If ($DhcpServer -eq $Null) {
                        $DhcpServer="Aucun"
                    }

                    Echo "        $($Nic.AdapterType) - Adaptateur : $Connecteur" >> $LogInfo
                    Echo "" >> $LogInfo
                    Echo "           Description . . . . . . . : $($Nic.Description)" >> $LogInfo
                    Echo "           Adresse Mac . . . . . . . : $($Nic.MACAddress)" >> $LogInfo
                    Echo "           DHCP Activé . . . . . . . : $($Configuration.DHCPEnabled)" >> $LogInfo
                    Echo "           Addresse IP . . . . . . . : $($Configuration.IPAddress)" >> $LogInfo
                    Echo "           Masque de sous réseau . . : $($Configuration.IPSubnet)" >> $LogInfo
                    Echo "           Passerelle par défaut . . : $($Configuration.DefaultIPGateway)" >> $LogInfo
                    Echo "           Serveur DHCP. . . . . . . : $($Configuration.DHCPEnabled)" >> $LogInfo
                    Echo "           Serveur DNS . . . . . . . : $($Configuration.DNSServerSearchOrder)" >> $LogInfo
                    Echo "" >> $LogInfo
                    Echo "" >> $LogInfo
                }
            }
            Start-Process -FilePath C:\Windows\System32\cmd.exe -ArgumentList "/c start C:\Windows\notepad.exe $LogInfo" -WindowStyle Maximized
            TextRefresh -TextToRefresh $StatusBar -NewText "Etat: Opération Terminée"
        }

    # Fonction PaExec LastExitCode
    Function PaExecErr {

        Param (
            $PaExecError,
            $CustomMessage
        )

        If ($PaExecError -eq 0){
            TextRefresh -TextToRefresh $StatusBar -NewText $CustomMessage
        }
        ElseIf ($PaExecError -eq -1){
            TextRefresh -TextToRefresh $StatusBar -NewText "Etat: [PaExec] Erreur interne"
        }
        ElseIf ($PaExecError -eq -2){
            TextRefresh -TextToRefresh $StatusBar -NewText "Etat: [PaExec] Erreur dans la ligne de commande"
        }
        ElseIf ($PaExecError -eq -4){
            TextRefresh -TextToRefresh $StatusBar -NewText "Etat: [PaExec] Impossible de copier PaExec sur l'hôte distant"
        }
        ElseIf ($PaExecError -eq -5){
            TextRefresh -TextToRefresh $StatusBar -NewText "Etat: [PaExec] Connexion avec l'hôte distant trop longue"
        }
        ElseIf ($PaExecError -eq -6){
            TextRefresh -TextToRefresh $StatusBar -NewText "Etat: [PaExec] Impossible de démarrer PaExec"
        }
        ElseIf ($PaExecError -eq -7){
            TextRefresh -TextToRefresh $StatusBar -NewText "Etat: [PaExec] Impossible de communiquer avec PaExec"
        }
        ElseIf ($PaExecError -eq -8){
            TextRefresh -TextToRefresh $StatusBar -NewText "Etat: [PaExec] La copie du programme sur l'hôte à échoué"
        }
        Else {
            TextRefresh -TextToRefresh $StatusBar -NewText "Etat: [PaExec] La commande s'est terminée avec des erreurs"
        }
    }

#########################################################
## FENETRES ET FORM #####################################
#########################################################

    # Créer la fenêtre ==================================
        $Form = New-Object system.Windows.Forms.Form

    # Action du clavier =================================
        $Form.KeyPreview = $True

    # Change la taille de la fenêtre ====================
        ChangeWindowSize -FormToResize $Form -WindowWidth 365 -WindowHeight 295

    # Centre la position de la fenêtre ==================
        $Form.StartPosition = "CenterScreen"

    # Change le titre de la fenêtre =====================
        $Form.Text = "PowerExec v0.9"

    # Change l'icone ====================================
        $Form.Icon = $Icon

    # Créer les Tooltips ================================
        $Tooltip = New-Object System.Windows.Forms.Tooltip

    # Titre =============================================
        $Titre = New-Object System.Windows.Forms.Label
        $Titre.Text = "PowerExec"
        $Titre.Location = New-Object System.Drawing.Point( 20, 20 )
        $Titre.AutoSize = $True
        $Titre.Font = $TitleFont
        $Titre.Name = "Titre"
        $Form.Controls.Add( $Titre )

    #Auteur =============================================
        $Auteur = New-Object System.Windows.Forms.Label
        $Auteur.Location = New-Object System.Drawing.Point( 160, 33 )
        $Auteur.Text = "by Julian Da Cunha"
        $Auteur.AutoSize = $True
        $Auteur.Font = $ClassicFont
        $Auteur.Name = "Auteur"
        $Form.Controls.Add( $Auteur )

#########################################################
## Form IPv4 ############################################
#########################################################

    # Label IPv4 ========================================
        $LabelIPv4 = New-Object System.Windows.Forms.Label
        $LabelIPv4.Text = "Entrez le nom ou l'adresse IP de l'hôte"
        $LabelIPv4.Location = New-Object System.Drawing.Point( 22, 90 )
        $LabelIPv4.AutoSize = $True
        $LabelIPv4.Font = $ClassicFont
        $LabelIPv4.Name = "IPv4"
        $Form.Controls.Add( $LabelIPv4 )

    # Champ Textbox Adresse IPv4 ========================
        $FieldIPv4 = New-Object System.Windows.Forms.TextBox
        $FieldIPv4.Location = New-Object System.Drawing.Point( 24, 120 )
        $FieldIPv4.Width = 300
        $FieldIPv4.TabIndex = 0
        $Form.Controls.Add( $FieldIPv4 )

    # Bouton Test Connexion =============================
        $TestConnectButton = New-Object System.Windows.Forms.Button
        $TestConnectButton.Text = "Ping Test"
        $TestConnectButton.Location = New-Object System.Drawing.Point( 254, 160 )
        $TestConnectButton.Width = 70
        $Form.Controls.Add( $TestConnectButton )
        $Tooltip.SetToolTip($TestConnectButton, "Permet de vérifier si la machine distante est joignable")

    # Label Connexion ===================================
        $LabelConnect = New-Object System.Windows.Forms.Label
        $LabelConnect.Text = "Test de connexion :"
        $LabelConnect.Location = New-Object System.Drawing.Point( 22, 165 )
        $LabelConnect.AutoSize = $True
        $LabelConnect.Font = $ClassicFont
        $Form.Controls.Add( $LabelConnect )

    # Test Connexion State ==============================
        $LabelConnectState = New-Object System.Windows.Forms.Label
        $LabelConnectState.Text = "[Non Effectué]"
        $LabelConnectState.ForeColor = ""
        $LabelConnectState.Location = New-Object System.Drawing.Point( 125, 165 )
        $LabelConnectState.AutoSize = $True
        $LabelConnectState.Font = $StateFont
        $Form.Controls.Add( $LabelConnectState )

    # Explications Erreur 1 =============================
        $ErrorInfo1 = New-Object System.Windows.Forms.Label
        $ErrorInfo1.Text = ""
        $ErrorInfo1.ForeColor = ""
        $ErrorInfo1.Location = New-Object System.Drawing.Point( 22, 190 )
        $ErrorInfo1.AutoSize = $True
        $ErrorInfo1.Font = $StateFont
        $Form.Controls.Add( $ErrorInfo1 )

    # Bouton Valider ====================================
        $ValidateButton1 = New-Object System.Windows.Forms.Button
        $ValidateButton1.Text = "Valider"
        $ValidateButton1.Location = New-Object System.Drawing.Point( 95, 220 )
        $ValidateButton1.Width = 80
        $Form.Controls.Add( $ValidateButton1 )

    # Bouton Annuler ====================================
        $CancelButton1 = New-Object System.Windows.Forms.Button
        $CancelButton1.Text = "Annuler"
        $CancelButton1.Location = New-Object System.Drawing.Point( 175, 220 )
        $CancelButton1.Width = 80
        $Form.Controls.Add( $CancelButton1 )

#########################################################
## Form Confirm #########################################
#########################################################

    # Bouton Admin Account ==============================
        $AccountButton = New-Object System.Windows.Forms.Button
        $AccountButton.Text = ""
        $AccountButton.Image = [System.Drawing.Image]::FromFile('C:\Script\Sources\images\admin.png')
        $AccountButton.Location = New-Object System.Drawing.Point( 285, 60 )
        $AccountButton.Width = 40
        $AccountButton.Height = 40
        $AccountButton.Visible = $False
        $Form.Controls.Add( $AccountButton )
        $Tooltip.SetToolTip($AccountButton, "Choisir le compte Administrateur (Domaine\Username)")

    # Bouton Changer Host ===============================
        $HostButton = New-Object System.Windows.Forms.Button
        $HostButton.Text = ""
        $HostButton.Image = [System.Drawing.Image]::FromFile('C:\Script\Sources\images\computer.png')
        $HostButton.Location = New-Object System.Drawing.Point( 285, 110 )
        $HostButton.Width = 40
        $HostButton.Height = 40
        $HostButton.Visible = $False
        $Form.Controls.Add( $HostButton )
        $Tooltip.SetToolTip($HostButton, "Changer de machine distante")

    # Label Remote Computer IP ==========================
        $LabelRemoteHostIP = New-Object System.Windows.Forms.Label
        $LabelRemoteHostIP.Text = " Aucun"
        $LabelRemoteHostIP.ForeColor = "Black"
        $LabelRemoteHostIP.Location = New-Object System.Drawing.Point( 22, 70 )
        $LabelRemoteHostIP.AutoSize = $True
        $LabelRemoteHostIP.Font = $ClassicFont
        $LabelRemoteHostIP.Visible = $False
        $Form.Controls.Add( $LabelRemoteHostIP )

    # Label Remote Computer Name ========================
        $LabelRemoteHostName = New-Object System.Windows.Forms.Label
        $LabelRemoteHostName.Text = " Aucun"
        $LabelRemoteHostName.ForeColor = "Black"
        $LabelRemoteHostName.Location = New-Object System.Drawing.Point( 22, 90 )
        $LabelRemoteHostName.AutoSize = $True
        $LabelRemoteHostName.Font = $ClassicFont
        $LabelRemoteHostName.Visible = $False
        $Form.Controls.Add( $LabelRemoteHostName ) 

    # Label Admin Account ===============================
        $LabelAdminAccount = New-Object System.Windows.Forms.Label
        $LabelAdminAccount.Text = "Compte Admin.:  Aucun"
        $LabelAdminAccount.ForeColor = "Black"
        $LabelAdminAccount.Location = New-Object System.Drawing.Point( 22, 110 )
        $LabelAdminAccount.Font = $ClassicFont
        $LabelAdminAccount.AutoSize = $True
        $LabelAdminAccount.Visible = $False
        $Form.Controls.Add( $LabelAdminAccount ) 

    # Label Status Account ==============================
        $LabelAdminAccountState = New-Object System.Windows.Forms.Label
        $LabelAdminAccountState.Text = "Status Compte.: "
        $LabelAdminAccountState.ForeColor = "Black"
        $LabelAdminAccountState.Location = New-Object System.Drawing.Point( 22, 130 )
        $LabelAdminAccountState.Font = $ClassicFont
        $LabelAdminAccountState.AutoSize = $True
        $LabelAdminAccountState.Visible = $False
        $Form.Controls.Add( $LabelAdminAccountState )

    # Test Compte Admin =================================
        $AdminAccountState = New-Object System.Windows.Forms.Label
        $AdminAccountState.Text = " [Non Validé]"
        $AdminAccountState.ForeColor = "Black"
        $AdminAccountState.Location = New-Object System.Drawing.Point( 105, 130 )
        $AdminAccountState.AutoSize = $True
        $AdminAccountState.Font = $StateFont
        $AdminAccountState.Visible = $False
        $Form.Controls.Add( $AdminAccountState )

    # Test Compte Admin Explication =====================
        $ErrorInfo2 = New-Object System.Windows.Forms.Label
        $ErrorInfo2.Text = ""
        $ErrorInfo2.ForeColor = ""
        $ErrorInfo2.Location = New-Object System.Drawing.Point( 22, 162 )
        $ErrorInfo2.AutoSize = $True
        $ErrorInfo2.Font = $StateFont
        $ErrorInfo2.Visible = $False
        $Form.Controls.Add( $ErrorInfo2 )

    # Bouton Valider 2 ==================================
        $ValidateButton2 = New-Object System.Windows.Forms.Button
        $ValidateButton2.Text = "Valider"
        $ValidateButton2.Location = New-Object System.Drawing.Point( 100, 190 )
        $ValidateButton2.Width = 80
        $ValidateButton2.Visible = $False
        $Form.Controls.Add( $ValidateButton2 )

    # Bouton Annuler2 ===================================
        $CancelButton2 = New-Object System.Windows.Forms.Button
        $CancelButton2.Text = "Annuler"
        $CancelButton2.Location = New-Object System.Drawing.Point( 180, 190 )
        $CancelButton2.Width = 80
        $CancelButton2.Visible = $False
        $Form.Controls.Add( $CancelButton2 )

#########################################################
## FORM ACTIVATE ########################################
#########################################################

    # Texte PSTOOLS =====================================
        $LabelPaExec = New-Object System.Windows.Forms.Label
        $LabelPaExec.Text = "Vérification PaExec...........: "
        $LabelPaExec.ForeColor = "Black"
        $LabelPaExec.Location = New-Object System.Drawing.Point( 22, 70 )
        $LabelPaExec.AutoSize = $True
        $LabelPaExec.Font = $ClassicFont
        $LabelPaExec.Visible = $False
        $Form.Controls.Add( $LabelPaExec )

    # State PSTOOLS =====================================
        $LabelPaExecState = New-Object System.Windows.Forms.Label
        $LabelPaExecState.Text = "[Non Vérifié]"
        $LabelPaExecState.ForeColor = "Black"
        $LabelPaExecState.Location = New-Object System.Drawing.Point( 160, 70 )
        $LabelPaExecState.AutoSize = $True
        $LabelPaExecState.Font = $StateFont
        $LabelPaExecState.Visible = $False
        $Form.Controls.Add( $LabelPaExecState )

    # Texte Connexion Lecteur réseau ====================
        $LabelNetworkDrive = New-Object System.Windows.Forms.Label
        $LabelNetworkDrive.Text = "Création Lecteur Réseau..: "
        $LabelNetworkDrive.ForeColor = "Black"
        $LabelNetworkDrive.Location = New-Object System.Drawing.Point( 22, 90 )
        $LabelNetworkDrive.AutoSize = $True
        $LabelNetworkDrive.Font = $ClassicFont
        $LabelNetworkDrive.Visible = $False
        $Form.Controls.Add( $LabelNetworkDrive )

    # State Connexion Lecteur Réseau ====================
        $LabelNetworkDriveState = New-Object System.Windows.Forms.Label
        $LabelNetworkDriveState.Text = "[Non Connecté]"
        $LabelNetworkDriveState.ForeColor = "Black"
        $LabelNetworkDriveState.Location = New-Object System.Drawing.Point( 160, 90 )
        $LabelNetworkDriveState.AutoSize = $True
        $LabelNetworkDriveState.Font = $StateFont
        $LabelNetworkDriveState.Visible = $False
        $Form.Controls.Add( $LabelNetworkDriveState )

    # ErrorInfo3
        $ErrorInfo3 = New-Object System.Windows.Forms.Label
        $ErrorInfo3.Text = ""
        $ErrorInfo3.ForeColor = ""
        $ErrorInfo3.Location = New-Object System.Drawing.Point( 22, 110 )
        $ErrorInfo3.AutoSize = $True
        $ErrorInfo3.Font = $StateFont
        $ErrorInfo3.Visible = $False
        $Form.Controls.Add( $ErrorInfo3 )

    # Bouton Valider 3 ==================================
        $ValidateButton3 = New-Object System.Windows.Forms.Button
        $ValidateButton3.Text = "Valider"
        $ValidateButton3.Location = New-Object System.Drawing.Point( 120, 135 )
        $ValidateButton3.Width = 80
        $ValidateButton3.Visible = $False
        $Form.Controls.Add( $ValidateButton3 )

    # Bouton Annuler 3 ==================================
        $CancelButton3 = New-Object System.Windows.Forms.Button
        $CancelButton3.Text = "Annuler"
        $CancelButton3.Location = New-Object System.Drawing.Point( 200, 135 )
        $CancelButton3.Width = 80
        $CancelButton3.Visible = $False
        $Form.Controls.Add( $CancelButton3 )

#########################################################
## FORM ACTION ##########################################
#########################################################

    # Bouton Reboot =====================================
        $RebootButton = New-Object System.Windows.Forms.Button
        $RebootButton.Text = "Redémarrer"
        $RebootButton.Location = New-Object System.Drawing.Point( 22, 80 )
        $RebootButton.Width = 100
        $RebootButton.Visible = $False
        $Form.Controls.Add( $RebootButton )
        $Tooltip.SetToolTip($RebootButton, "Redémarre la machine distante")

    # Bouton InfoComputer ===============================
        $InfoComputerButton = New-Object System.Windows.Forms.Button
        $InfoComputerButton.Text = "Info. Computer"
        $InfoComputerButton.Location = New-Object System.Drawing.Point( 22, 110 )
        $InfoComputerButton.Width = 100
        $InfoComputerButton.Visible = $False
        $Form.Controls.Add( $InfoComputerButton )
        $Tooltip.SetToolTip($InfoComputerButton, "Permet d'obtenir les informations Hardware et la configuration réseau de la machine")

    # Copie Local Vers Distant ==========================
        $CopyToHost = New-Object System.Windows.Forms.Button
        $CopyToHost.Text = "Copie 2 Distant"
        $CopyToHost.Location = New-Object System.Drawing.Point( 142, 80 )
        $CopyToHost.Width = 100
        $CopyToHost.Visible = $False
        $Form.Controls.Add( $CopyToHost )
        $Tooltip.SetToolTip($CopyToHost, "Permet de copier un fichier local vers la machine distante")

    # Copie Distant Vers Local ==========================
        $CopyToLocal = New-Object System.Windows.Forms.Button
        $CopyToLocal.Text = "Copie 2 Local"
        $CopyToLocal.Location = New-Object System.Drawing.Point( 142, 110 )
        $CopyToLocal.Width = 100
        $CopyToLocal.Visible = $False
        $Form.Controls.Add( $CopyToLocal )
        $Tooltip.SetToolTip($CopyToLocal, "Permet de copier de la machine distante vers le local")

    # Commande PaExec ===================================
        $PaExec2 = New-Object System.Windows.Forms.Button
        $PaExec2.Text = "PaExec"
        $PaExec2.Location = New-Object System.Drawing.Point( 260, 80 )
        $PaExec2.Width = 100
        $PaExec2.Visible = $False
        $Form.Controls.Add( $PaExec2 )
        $Tooltip.SetToolTip($PaExec2, "Permet d'executer une commande sur la machine distante, grâce à PaExec")

    # IPerf =============================================
        #$Iperf = New-Object System.Windows.Forms.Button
        #$Iperf.Text = "IPerf"
        #$Iperf.Location = New-Object System.Drawing.Point( 142, 110 )
        #$Iperf.Width = 100
        #$Iperf.Visible = $False
        #$Form.Controls.Add( $Iperf )
        #$Tooltip.SetToolTip($Iperf, "Lance un test de débit entre la machine distante et le host")

    # Label Commande PaExec =============================
        $LabelPaExec2 = New-Object System.Windows.Forms.Label
        $LabelPaExec2.Text = "Commande PaExec : "
        $LabelPaExec2.ForeColor = "Black"
        $LabelPaExec2.Location = New-Object System.Drawing.Point( 22, 157 )
        $LabelPaExec2.AutoSize = $True
        $LabelPaExec2.Font = $ClassicFont
        $LabelPaExec2.Visible = $False
        $Form.Controls.Add( $LabelPaExec2 )

    # Champ Textbox Commande PaExec =====================
        $FieldPaExec = New-Object System.Windows.Forms.TextBox
        $FieldPaExec.Location = New-Object System.Drawing.Point( 130, 155 )
        $FieldPaExec.Width = 180
        $FieldPaExec.TabIndex = 0
        $FieldPaExec.Visible = $False
        $Form.Controls.Add( $FieldPaExec )

    # Bouton Valider PaExec =============================
        $PaExecValidate = New-Object System.Windows.Forms.Button
        $PaExecValidate.Text = "Ok"
        $PaExecValidate.Location = New-Object System.Drawing.Point( 320, 150 )
        $PaExecValidate.Width = 30
        $PaExecValidate.Height = 30
        $PaExecValidate.Visible = $False
        $Form.Controls.Add( $PaExecValidate )

    # Bouton Changer Host2 ==============================
        $HostButton2 = New-Object System.Windows.Forms.Button
        $HostButton2.Text = ""
        $HostButton2.Image = [System.Drawing.Image]::FromFile('C:\Script\Sources\images\computer.png')
        $HostButton2.Location = New-Object System.Drawing.Point( 320, 15 )
        $HostButton2.Width = 40
        $HostButton2.Height = 35
        $HostButton2.Visible = $False
        $Form.Controls.Add( $HostButton2 )
        $Tooltip.SetToolTip($HostButton2, "Changer de machine distante")

    # StatusBar =============================================
        $StatusBar = New-Object System.Windows.Forms.StatusBar
        $StatusBar.Text = ""
        $StatusBar.Height = 22
        $StatusBar.Width = 400
        $StatusBar.Visible = $False
        $StatusBar.Location = New-Object System.Drawing.Point( 0, 300 )
        $Form.Controls.Add($StatusBar)

    # Quitter ===========================================
        $QuitButton = New-Object System.Windows.Forms.Button
        $QuitButton.Text = "Quitter"
        $QuitButton.Location = New-Object System.Drawing.Point( 260, 110 )
        $QuitButton.Width = 100
        $QuitButton.Visible = $False
        $Form.Controls.Add($QuitButton)

#########################################################
## SCRIPT ###############################################
#########################################################


    # FORM IPV4 *****************************************
    #****************************************************
    
        # Bouton Test Connexion =========================
        $TestConnectButton.Add_Click({
            TestConnectivity -Remote_Host $FieldIPv4.Text
        })

        # Bouton Valider Form ===========================
        $ValidateButton1.Add_Click({

            If ( $Script:ValidateIPv4 -eq $True ) {
                
                $Script:IPv4 = $FieldIPv4.Text
                
                Try {
                    If (( $Script:IPv4 -Match "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}") -eq $True ) {
                        $Dns = [System.Net.Dns]::GetHostByAddress("$($Script:IPv4)")
                    }
                    Else {
                        $Dns = [System.Net.Dns]::GetHostByName("$($Script:IPv4)")
                    }
                }
                Catch {
                }
                $Script:Hostname = $Dns
                FormControlIPv4 -State $False
                FormControlConfirm -State $True
            }
            Else {
                TextRefresh -TextToRefresh $LabelConnectState -NewText "[Erreur]" -TextColor "Red"
                TextRefresh -TextToRefresh $ErrorInfo1 -NewText "Aucune Adresse IP Validé" -TextColor "Orange"            
            }
         })

        # Bouton Annuler ================================
        $CancelButton1.Add_CLick({
            $Form.Close()
        })

    # FORM CONFIRM **************************************
    #****************************************************

        # Bouton Annuler2 ===============================
        $CancelButton2.Add_CLick({
            $Form.Close()
        })

        # Bouton Valider 2 ==============================
        $ValidateButton2.Add_Click({

            If ( $Script:ValidateAccount -eq $True ) {

                FormControlConfirm -State $False
                FormControlActivate -State $True
                
                NetworkDrive -State $True
                PsTools -State $True

            }
            Else {
                TextRefresh -TextToRefresh $AdminAccountState -NewText "[Erreur]" -TextColor "Red"
                TextRefresh -TextToRefresh $ErrorInfo2 -NewText "Aucun compte Admin validé" -TextColor "Orange"
            }
        })

        # Bouton Account ================================
        $AccountButton.Add_Click({
            
            Try {
                $Script:Credential = Get-Credential -Message "Entrez vos identifiant Admins Poste ou Admins du Domaine"
                $Script:NetworkCredential = $Script:Credential.GetNetworkCredential()                  
                $Script:Login = "$($Script:NetworkCredential.Domain)\$($Script:NetworkCredential.UserName)"
                $Script:Password = $Script:NetworkCredential.Password
                
                TextRefresh -TextToRefresh $LabelAdminAccount -NewText "Compte Admin..:  $($Script:Login)" -TextColor "Black"
                TestAccount -Account $Script:Credential -Computer $Script:IPv4
            }
            Catch {
                TextRefresh -TextToRefresh $ErrorInfo2 -NewText "Veuillez spécifier un compte Administrateur" -TextColor "Orange"
                TextRefresh -TextToRefresh $AdminAccountState -NewText " [Erreur]" -TextColor "Red"
            }

        })

        # Bouton Changer Host ===========================
        $HostButton.Add_Click({
            FormControlConfirm -State $False
            FormControlIPv4 -State $True
        })


    # FORM ACTIVATE *************************************
    #****************************************************

        # Bouton Annuler2 ===============================
        $CancelButton3.Add_CLick({
            $Form.Close()
        })

        # Bouton Valider3 ===============================
        $ValidateButton3.Add_CLick({
                
            # Enable WinRM ==============================
            PaExec \\$Script:IPv4 -u $Script:Login -p $Script:Password cmd /c winrm quickconfig -q
            
            If (( $Script:PsTools -eq $False ) -And ($Script:NetworkDrive -eq $False)){
                $ValidateButton3.Enabled = $False
                TextRefresh -TextToRefresh $ErrorInfo3 -NewText "Impossible de continuer car PaExec n'est pas disponnible." -TextColor "Orange"
            }
            Else {
                FormControlActivate -State $False
                FormControlAction -State $True
            }
        })


    # FORM ACTION ***************************************
    #****************************************************

        # Bouton Reboot =================================
        $RebootButton.Add_Click({

            $RebootButton.Enabled = $False
            $InfoComputerButton.Enabled = $False
            $HostButton2.Enabled = $False
            $QuitButton.Enabled = $False
            $CopyToHost.Enabled = $False
            $CopyToLocal.Enabled = $False
            $PaExec2.Enabled = $False
            $Iperf.Enabled = $False

            TextRefresh -TextToRefresh $StatusBar -NewText "Etat: Redémarrage de [ $($Script:Hostname.HostName) ] en cours.."
            Restart-Computer -ComputerName $Script:IPv4 -Credential $Script:Credential -Force
            Start-Sleep 2       
                    
            For ($i=1; $i -le 60; $i++){
                TextRefresh -TextToRefresh $StatusBar -NewText "Etat: $(60-$i)  secondes avant test de connexion"
                Start-Sleep 1
            }
            For ($i=1; $i -le 5; $i++){

                $PingTest = Test-Connection $Script:IPv4 -Quiet -Count 1    
                                                  
                If ($PingTest -eq "True") {
                    TextRefresh -TextToRefresh $StatusBar -NewText "Etat: $($Script:Hostname.HostName) a bien redémarré"
                    $RebootButton.Enabled = $True
                    $InfoComputerButton.Enabled = $True
                    $HostButton2.Enabled = $True
                    $QuitButton.Enabled = $True
                    $CopyToHost.Enabled = $True
                    $CopyToLocal.Enabled = $True
                    $PaExec2.Enabled = $True
                    $Iperf.Enabled = $True
                    $i=6
                }
                Else { 
                    TextRefresh -TextToRefresh $StatusBar -NewText "Etat: La machine n'a pas redémarré, tentatives de connexion restantes $(5-$i)"
                    If ($i -ne 5){
                        Start-Sleep 2
                        $i+1
                    }
                    Else {
                        TextRefresh -TextToRefresh $StatusBar -NewText "Etat: [ERREUR] La machine n'a pas redémarré"
                    }
                }
            }
        })

        # Bouton Info Computer ==========================
        $InfoComputerButton.Add_Click({
            $Heure = $Date.Hour
            If ($Date.Minute -le 9){
                $Minute = "0"+$Date.Minute
            }
            Else {
                $Minute = $Date.Minute
            }
            $Script:DateTime = "$($Date.Hour):$($Minute)"
            LogComputer -LogName $Script:Hostname.HostName -Credential $Script:Credential -RemoteHost $Script:IPv4
        })

        # Bouton Copie Local Vers Distant ===============
        $CopyToHost.Add_Click({
            
            $ObjectFile = New-Object System.Windows.Forms.Openfiledialog
            $ObjectFile.InitialDirectory = "C:\"
            $ObjectFile.Title = "Ouvrir un fichier"
            $ObjectFile.Showdialog()
            $File = $ObjectFile.Filename
            $Filename = $ObjectFile.SafeFileName
            
            TextRefresh -TextToRefresh $StatusBar -NewText "Etat: Copie du fichier vers $($Script:Hostname.HostName)"
            Try {
                Copy-Item -Path $File -Destination K:\Temp
                If ((Test-Path K:\Temp\$Filename) -eq $False){
                    TextRefresh -TextToRefresh $StatusBar -NewText "Etat: [ERREUR] Fichier non copié, veuillez vérifier vos droits"
                }
                Else {
                    TextRefresh -TextToRefresh $StatusBar -NewText "Etat: Fichier copié"                                                                                                     
                }
            }
            Catch {
                TextRefresh -TextToRefresh $StatusBar -NewText "Etat: [ERREUR] Aucun Fichier sélectionné"
            }
        })

        # Bouton Copie Local Vers Distant ===============
        $CopyToLocal.Add_Click({
            
            $ObjectFile = New-Object System.Windows.Forms.Openfiledialog
            $ObjectFile.InitialDirectory = "K:\"
            $ObjectFile.Title = "Ouvrir un fichier"
            $ObjectFile.Showdialog()
            $File = $ObjectFile.Filename
            $Filename = $ObjectFile.SafeFileName
            
            TextRefresh -TextToRefresh $StatusBar -NewText "Etat: Copie du fichier dans C:\Temp"
            Try {
                Copy-Item -Path $File -Destination C:\Temp
                If ((Test-Path C:\Temp\$Filename) -eq $False){
                    TextRefresh -TextToRefresh $StatusBar -NewText "Etat: [ERREUR] Fichier non copié, veuillez vérifier vos droits"
                }
                Else {
                    TextRefresh -TextToRefresh $StatusBar -NewText "Etat: Fichier copié"                                                                                                     
                }
            }
            Catch {
                TextRefresh -TextToRefresh $StatusBar -NewText "Etat: [ERREUR] Aucun Fichier sélectionné"
            }
        })

        # Bouton PaExec =================================
        $Script:PaExecOn = $True

        $PaExec2.Add_Click({

            If ($Script:PaExecOn -eq $True){

                ChangeWindowSize -FormToResize $Form -WindowWidth 400 -WindowHeight 260

                $Script:PaExecOn = $False

                $RebootButton.Enabled = $False
                $InfoComputerButton.Enabled = $False
                $HostButton2.Enabled = $False
                $QuitButton.Enabled = $False
                $CopyToHost.Enabled = $False
                $CopyToLocal.Enabled = $False
                #$Iperf.Enabled = $False

                $LabelPaExec2.Visible = $True
                $FieldPaExec.Visible = $True
                $PaExecValidate.Visible = $True
                $PaExecValidate.Enabled = $True
            
                TextRefresh -TextToRefresh $StatusBar -NewText "Etat: Entrez votre commande DOS"

                $FieldPaExec.Text = ""

                $PaExecValidate.Add_Click({

                    TextRefresh -TextToRefresh $StatusBar -NewText "Etat: Commande en cours d'execution..."

                    $PaExecValidate.Enabled = $False
                    $Command = $($FieldPaExec.Text).Split()
                    $FieldPaExec.Enabled = $False
                    $LogInfo = "C:\Script\Log\(PAEXEC)__$($Script:Hostname.HostName)__($DatetoLog).log"
                    $PaExecCmd = PaExec \\$Script:IPv4 -u $Script:Login -p $Script:Password $Command
                    
                    $PaExecCmd | Out-File -FilePath $LogInfo -Encoding utf8
                    $Messages = "Etat: La commande a bien été exécuté !"
                    PaExecErr -PaExecError $LASTEXITCODE -CustomMessage $Messages

                    Start-Process -FilePath C:\Windows\System32\cmd.exe -ArgumentList "/c start C:\Windows\notepad.exe $LogInfo" -WindowStyle Maximized
                })
            }
            Else {

                TextRefresh -TextToRefresh $StatusBar -NewText "Etat: En attente de commandes"

                ChangeWindowSize -FormToResize $Form -WindowWidth 400 -WindowHeight 220
                
                $Script:PaExecOn = $True

                $RebootButton.Enabled = $True
                $InfoComputerButton.Enabled = $True
                $HostButton2.Enabled = $True
                $QuitButton.Enabled = $True
                #$Iperf.Enabled = $True
                $FieldPaExec.Enabled = $True

                If ($Script:NetworkDrive -eq $True){
                    $CopyToHost.Enabled = $True
                    $CopyToLocal.Enabled = $True
                }

                $LabelPaExec2.Visible = $False
                $FieldPaExec.Visible = $False
                $PaExecValidate.Visible = $False
            }
        })

        # Bouton Change Host2 ===========================
        $HostButton2.Add_Click({

            FormControlAction -State $False
            FormControlIPv4 -State $True

        })

        # IPerf =========================================
        #$Iperf.Add_CLick({

        #    $Command = $("C:\Temp\IPerf\iperf.exe -c $LocalIP -r").Split()
        #    $Command2 = $('powershell.exe "Get-Process iperf | Stop-Process"').Split()
        #    $Command3 = $('C:\Temp\7z\7z.exe x "C:\Temp\IPerf.zip" -oC:\Temp\IPerf').Split()
        #    $LogInfo = "C:\Script\Log\(IPERF)__$($Script:Hostname.HostName)__($DatetoLog).log"

        #    If ((Test-Path K:\Temp\IPerf\iperf.exe) -eq $False){

        #        Copy-Item -Path C:\Script\Sources\IPerf.zip -Destination K:\Temp
        #        New-Item -Path K:\Temp\7z -Type directory -Force
        #        Copy-Item -Path C:\Script\Sources\7z\7z.dll -Destination K:\Temp\7z
        #        Copy-Item -Path C:\Script\Sources\7z\7z.exe -Destination K:\Temp\7z

        #        PaExec \\$Script:IPv4 -u $Script:Login -p $Script:Password $Command3
        #        $Messages = "Etat: Les fichiers nécessaires au test ont bien été copié sur l'hôte distant"
        #        PaExecErr -PaExecError $LASTEXITCODE -CustomMessage $Messages
        #    }

        #    Start-Process -FilePath C:\Script\Sources\IPerf\iperf.exe -ArgumentList "-s" -WindowStyle Hidden
        #    TextRefresh -TextToRefresh $StatusBar -NewText "Etat: IPerf à bien démarré sur le LocalHost"

        #    PaExec \\$Script:IPv4 -u $Script:Login -p $Script:Password $Command | Out-File -FilePath $LogInfo
        #    $Messages = "Etat: IPerf à bien été démarré sur la machine distante"
        #    PaExecErr -PaExecError $LASTEXITCODE -CustomMessage $Messages

        #    Get-Process iperf | Stop-Process

        #    PaExec \\$Script:IPv4 -u $Script:Login -p $Script:Password $Command2
        #    $Messages = "Etat: Le processus IPerf à bien été arreté"
        #    PaExecErr -PaExecError $LASTEXITCODE -CustomMessage $Messages
        #    Start-Sleep 2

        #    TextRefresh -TextToRefresh $StatusBar -NewText "Etat: Fin du test IPerf"
        #    Start-Process -FilePath C:\Windows\System32\cmd.exe -ArgumentList "/c start C:\Windows\notepad.exe $LogInfo" -WindowStyle Maximized
        #})

        # Bouton Quitter ================================
        $QuitButton.Add_CLick({

            # Suppression du service PaExec =============
                $SessionName = "HostConnect"
                $Session = New-PSSession -ComputerName $Script:Name -Credential $Script:Credential -Name $ -ErrorAction SilentlyContinue

                Invoke-Command -Session $Session -ScriptBlock {
        
                    $Service = Get-WmiObject -Class win32_service
                    For ( $i=0 ; $i -lt $Service.Length ; $i++ ){
                        If (($Service[$i].Name) -match "paexec"){
                            $(Gwmi win32_service -filter "name='$($Service[$i].Name)'").delete()
                        }
                    }
                } -ErrorAction SilentlyContinue
    
                Remove-PSSession -Name $SessionName
            
            New-Object -Com Wscript.Network | Where-Object { $_.RemoveNetworkDrive("K:") }            
            $Form.Close()
        
        })

    # Affiche les Formulaires ===========================
        $Form.ShowDialog() | Out-Null


















#### CATCH ERROR ####
#
# $Error.Clear()
# COMMANDE
# $Error.Exception.Gettype().FullName


# SIGNATURE DU SCRIPT ############################################

# SIG # Begin signature block
# MIIELQYJKoZIhvcNAQcCoIIEHjCCBBoCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU5B/ZlJCBFyavY80abzT2U345
# WG6gggI9MIICOTCCAaagAwIBAgIQolCvALuYz71B7n/7VxXPdTAJBgUrDgMCHQUA
# MCYxJDAiBgNVBAMTG1Bvd2VyU2hlbGwgVGVzdCBDZXJ0aWZpY2F0ZTAeFw0xMzAx
# MTQxOTM0MzRaFw0zOTEyMzEyMzU5NTlaMCYxJDAiBgNVBAMTG1Bvd2VyU2hlbGwg
# VGVzdCBDZXJ0aWZpY2F0ZTCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEAqiJT
# YyUoQtvqGHz+B6rJBea+VJVWOiOS6KgOowy12NZDKKTDovHl+fs2Tcxf3D2aKH+Q
# eE7WsCZdC3hUx7c5Kd60/V0B0ZDo7K3GiUd/QJTwNdyLlEGpgLiyHPvnEHnQ2eI+
# mUiPs89hRWj+jEqdBku+7pNX2vTxXr38J3jPdukCAwEAAaNwMG4wEwYDVR0lBAww
# CgYIKwYBBQUHAwMwVwYDVR0BBFAwToAQlIndM+tfeBNtMoUpf5WeB6EoMCYxJDAi
# BgNVBAMTG1Bvd2VyU2hlbGwgVGVzdCBDZXJ0aWZpY2F0ZYIQolCvALuYz71B7n/7
# VxXPdTAJBgUrDgMCHQUAA4GBAFPXIPO40j/ZwNekFarffn1WORVr/BNVqtdrFSTQ
# xTPMLTRJ8MIZ/TOHnO/MVtlvQDipg64sOGu6rxX6bcqNmCqfFiODrbdtyLvGwvIT
# T24Rm3Uj2GCSyEz+wzet5yC491NQi/KFPI2vN+upRrHYpOG98ClNwntyyFiyHgxz
# wmkEMYIBWjCCAVYCAQEwOjAmMSQwIgYDVQQDExtQb3dlclNoZWxsIFRlc3QgQ2Vy
# dGlmaWNhdGUCEKJQrwC7mM+9Qe5/+1cVz3UwCQYFKw4DAhoFAKB4MBgGCisGAQQB
# gjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYK
# KwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFC+A7ymX
# RS4a4eNfhzRbm+QfZO2BMA0GCSqGSIb3DQEBAQUABIGAb78gt18EK4tMaZPBbomS
# 5qvROZW66De/Fpq8t+S8tc84Pbvvg8n6YKpFspBcg2bDzbvbmuGWwuYQx/dJ/9ov
# r6MkNnLMB4LfXA+A7fYYzVQvt0DY0Va+ra8Shdp1HyaYIypM2vmNCOCNPNa9cykr
# 176rZCEUQMaSAIGE+S4JePw=
# SIG # End signature block