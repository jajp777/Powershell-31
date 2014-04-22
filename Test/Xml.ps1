Cls

# Lecture Fichier Xml
    [xml]$XmlFile = Get-Content "C:\Script\Log\test.xml"

# Modifier une valeur dans le fichier xml
    #$XmlFile.Config.Drive.Letter = "A"

# Lecture Xml avec plusieurs vars
    $Users = $XmlFile.Config.AllUsers.User.Name
    $Users

# Sauvegarde fichier xml modifié
    #$XmlFile.Save("E:\Mes Documents\Techniques\Bureau\test.xml")