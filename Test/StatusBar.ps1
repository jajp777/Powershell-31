# Chargement des Assembly ===========================
    Add-Type –AssemblyName System.Windows.Forms | Out-Null
    Add-Type –AssemblyName System.Drawing | Out-Null

# Définit les polices de caractères
    $ClassicFont = New-Object System.Drawing.Font( "Tahoma",8,[System.Drawing.FontStyle]::Regular )
    $StateFont = New-Object System.Drawing.Font( "Tahoma",8,[System.Drawing.FontStyle]::Bold )
    $TitleFont = New-Object System.Drawing.Font( "Times New Roman",20,[System.Drawing.FontStyle]::Bold )
    # Regular, Bold, Italic, Underline, Strikeout

# Fonction Refresh Content ==========================
    Function RefreshFormText {
        
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

# Créer la fenêtre ======================================
    $Form = New-Object system.Windows.Forms.Form

# Bouton Test ===========================================
    $Test = New-Object System.Windows.Forms.Button
    $Test.Text = "Test"
    $Test.Location = New-Object System.Drawing.Point( 22, 80 )
    $Test.Width = 100
    $Test.Visible = $true
    $Form.Controls.Add( $Test )

# StatusBar =============================================
    $StatusBar = New-Object System.Windows.Forms.StatusBar
    $StatusBar.Text = "LOL"
    $StatusBar.Height = 22
    $StatusBar.Width = 200
    $StatusBar.Location = New-Object System.Drawing.Point( 0, 250 )
    $Form.Controls.Add($StatusBar)

# Script ================================================ 

    ChangeWindowSize -FormToResize $Form -WindowWidth 200 -WindowHeight 200

    $Test.Add_CLick({
        RefreshFormText -TextToRefresh $StatusBar -NewText "TEST OK" -TextColor "Green"
    })

# Affiche les Formulaires ===============================
    $Form.ShowDialog() | Out-Null

