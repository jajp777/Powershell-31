# -------------------------------------------------------------------------- #
# Script:      ServiceControl                                                #
# Auteur:      Julian Da Cunha                                               #
# Date:        08/02/13                                                      #
# Description: Permet de lister les services et de les activer/desactiver    #
# -------------------------------------------------------------------------- #

Cls

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

#########################################################
## Vars & Functions #####################################
#########################################################

    # Vars ==============================================
        $StateTabs = @()
        $a = 0
        #$Credential = Get-Credential ***\***
        #Enable-PSRemoting -Confirm -Force
        $IPV4 = "JCU-WIN8"

    # Chargement des Assembly ===========================
        Add-Type –AssemblyName System.Windows.Forms | Out-Null
        Add-Type –AssemblyName System.Drawing | Out-Null

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

    # DrawService
        Function DrawService {
            $Tableau1.Rows.Clear()
            For ( $i=0 ; $i -lt $Script:Service.Length ; $i++ ){
                If (($Script:Service[$i].State) -eq "Stopped"){
                    $Status = "Arrêté"
                }
                Else {
                    $Status = "Démarré"
                }

                $Script:Row = ($Service[$i].Name, $Status)
                $Tableau1.Rows.Add($Script:Row)

                ForEach ( $Item in $Script:Row[0] ){
                    $DropDown.Items.Add($Item)
                }

                Foreach ( $Item in $Script:Row[1] ){
                    $Script:StateTabs += @($a)       #Redim
                    $Script:StateTabs[$a] = $Item    #AddToArray
                    $a++
                }
            }
        }

    # Fonction Get Service
        Function GetService {
            
            $Script:Service = Get-WmiObject -Class win32_service -ev ErrorRPC -ea SilentlyContinue
            If ($ErrorRPC -match "(Exception de HRESULT : 0x800706BA)"){
                Cls
                Write-Host "Problème de service RPC"
            }
            DrawService
            #Cls
        }

#########################################################
## Form #################################################
#########################################################

    # Création Form =====================================
        $Form = New-Object System.Windows.Forms.Form 
        $Form.Text = "Services"
        $Form.size = New-Object System.Drawing.Size(396,500)
        $Form.StartPosition = "CenterScreen"

    # Création Tableau ==================================
        $Tableau1 = New-Object System.Windows.Forms.DataGridView
        $Tableau1.Location = New-Object System.Drawing.Size(10,10) 
        $Tableau1.size = New-Object System.Drawing.Size(360,350)
        $Tableau1.ReadOnly = $True
        $Form.Controls.Add($Tableau1)

    # Création Colone Service ===========================
        $Colone1 = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
        $Colone1.HeaderText = "Service"
        $Colone1.Name = "Service"
        $Colone1.Width = 240
        $Colone1.FillWeight = $True
        $Tableau1.Columns.Add($Colone1)

    # Création Colone Etat ==============================
        $Colone2 = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
        $Colone2.HeaderText = "Etat"
        $Colone2.Name = "Etat"
        $Colone2.Width = 60
        $Colone2.FillWeight = $True
        $Tableau1.Columns.Add($Colone2)

    # Label Control =====================================
        $ControlLabel = New-Object System.Windows.Forms.Label
        $ControlLabel.Text = "Choisissez le service à controler :"
        $ControlLabel.Location = New-Object System.Drawing.Point( 10, 375 )
        $ControlLabel.AutoSize = $True
        $ControlLabel.Font = $ClassicFont
        $Form.Controls.Add( $ControlLabel )

    # DropList ==========================================
        $DropDown = New-Object System.Windows.Forms.ComboBox
        $DropDown.Location = New-Object System.Drawing.Size(10,400)
        $DropDown.Width = 250
        $Form.Controls.Add($DropDown)

    # Bouton State  =====================================
        $StateButton = New-Object System.Windows.Forms.Button
        $StateButton.Text = "Choisir"
        $StateButton.Location = New-Object System.Drawing.Point( 290, 400 )
        $StateButton.Width = 80
        $StateButton.Visible = $True
        $Form.Controls.Add( $StateButton )

    # Bouton Quitter  ===================================
        $Quit = New-Object System.Windows.Forms.Button
        $Quit.Text = "Quitter"
        $Quit.Location = New-Object System.Drawing.Point( 290, 430 )
        $Quit.Width = 80
        $Quit.Visible = $True
        $Form.Controls.Add( $Quit )

    # Error Label =======================================
        $ErrorLabel = New-Object System.Windows.Forms.Label
        $ErrorLabel.Text = ""
        $ErrorLabel.Location = New-Object System.Drawing.Point( 10, 430 )
        $ErrorLabel.AutoSize = $True
        $ErrorLabel.Font = $ClassicFont
        $Form.Controls.Add( $ErrorLabel )

#########################################################
## Script ###############################################
#########################################################

    # PsSession =========================================
        #$PSsession = New-PSSession -ComputerName $IPV4 -Credential $Credential
 
    # Analyse des Services ==============================
        GetService

    # Liste déroulante + Bouton Activer\Désactiver ======
        $DropDown.add_SelectedValueChanged({

            $StateButton.Enabled = $True
            $Selected = $DropDown.SelectedIndex
            $State = $Script:StateTabs[$Selected]

            If ($State -eq "Arrêté"){

                TextRefresh -TextToRefresh $StateButton -NewText "Démarrer"

                $StateButton.Add_CLick({

                    $Script:SelectedService = $($DropDown.SelectedItem)

                    #Invoke-Command -Session $PSsession -ArgumentList $Script:SelectedService {

                    $Dependances = $(Get-Service "$Service" -RequiredServices)
                    $a = 0
                    
                    Foreach ($S in $Dependances) {
                        $RequiredService += @($a)                                          #Redim
                        $RequiredService[$a] = "Name=$($S.Name),State=$($S.Status)"        #AddToArray
                        $a++
                    }

                    If ($RequiredService -match "Stopped") {
                        TextRefresh -TextToRefresh $ErrorLabel -NewText "Dépendances non satisfaites [$RequiredService]" -TextColor "Red"
                    }
                    Else {
                        Start-Service "$Service" -ErrorVariable $Global:ServiceStopError -ErrorAction SilentlyContinue -PassThru
                    }
                    
                    Write-Host $Global:ServiceStopError

                    GetService

                    $StateButton.Enabled = $False

                    TextRefresh -TextToRefresh $ErrorLabel -NewText "Service démarré" -TextColor "Green"

                })
            }
            Else {

                TextRefresh -TextToRefresh $StateButton -NewText "Arrêter"

                $StateButton.Add_CLick({
                    
                    $Script:SelectedService = $($DropDown.SelectedItem)

                    #Invoke-Command -Session $PSsession -ArgumentList $Script:SelectedService {

                        #param ($Service)

                    Stop-Service "$Service" -PassThru -Force -ErrorVariable $Global:ServiceStopError -ErrorAction SilentlyContinue

                    #}

                    Write-Host $Global:ServiceStopError

                    GetService

                    TextRefresh -TextToRefresh $ErrorLabel -NewText "Service arrêté" -TextColor "Green"

                    $StateButton.Enabled = $False

                })
            }
        })


    # Bouton Quitter ====================================
        $Quit.Add_CLick({
            $Form.Close()
        })

    # Affiche les Formulaires ===========================
        $Form.ShowDialog() | Out-Null