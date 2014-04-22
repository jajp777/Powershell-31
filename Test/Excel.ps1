Cls

# Définition informations culturelles
[System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo] "en-US"

# Instanciation objet
$Excel = New-Object -ComObject "Excel.Application"

# Affiche Excel
$Excel.Visible = $true

# Emplacement fichier Excel
$File = "E:\Mes Documents\Techniques\Bureau\demo.xlsx"

# Ouverture fichier Excel
$Workbook = $Excel.Workbooks.Open($File)
$Worksheet = $Workbook.Sheets.Item("Data")

# Fermeture Excel
$Excel.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel) | Out-Null