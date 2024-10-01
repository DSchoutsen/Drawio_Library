<# PreRequesites

    Invoke-WebRequest 'https://github.com/DSchoutsen/Drawio_Library/archive/refs/heads/master.zip' -OutFile .\Azure-Design.zip
    Expand-Archive -Path ".\Drawio_Library.zip"

#>
function Create-Library ($FilesObject, $Foldername, $IconSize) {

    # Reset the variable
    $shapedefinitions = ""

    $filesCount = $files.count
    $index = 1

    foreach ($file in $FilesObject) {
        $shapeName = $file.name -replace '.svg', '' 
        $imageUrl = "https://raw.githubusercontent.com/DSchoutsen/Drawio_Library/b2224d982ef8b40adc1a0facaacb1e2ff19bd696/SVG_Azure_Grouped/$Foldername/" + [uri]::EscapeDataString($shapeName) + ".svg"

        #adjust icon Size to requested in pts
        $svgHeigth = (Select-String -path $file "height=")[0].Line  -replace "[^0-9.]" , ''
        $iconHeight = [double]$svgHeigth
        $svgWidth = (Select-String -path $file "width=")[0].Line  -replace "[^0-9.]" , ''
        $iconWidth = [double]$svgWidth
        $iconRatio = $iconWidth / $iconHeight

        if ($iconWidth -gt $iconHeight) {
            $shapeWidth = $IconSize
            $shapeHeigth = [math]::Round($IconSize/$iconRatio, 1)
        }
        else {
            $shapeHeigth = $IconSize
            $shapeWidth = [math]::Round($IconSize*$iconRatio, 1)
        }

        $defenintionStart = '{ "xml": "'
        $shapedefinition = '&lt;mxGraphModel&gt;&lt;root&gt;&lt;mxCell id=\"0\"/&gt;&lt;mxCell id=\"1\" parent=\"0\"/&gt;&lt;mxCell id=\"2\" value=\"'+ $shapeName + '\" style=\"shape=image;imageAspect=0;aspect=fixed;verticalLabelPosition=bottom;verticalAlign=top;image=' + $imageUrl + ';fontColor=' + $fontColor + ';fontSize=' + $fontSize + ';fontFamily=' + $fontFamily + ';\" vertex=\"1\" parent=\"1\"&gt;&lt;mxGeometry width=\"' + $shapeWidth + '\" height=\"' + $shapeHeigth + '\" as=\"geometry\"/&gt;&lt;/mxCell&gt;&lt;/root&gt;&lt;/mxGraphModel&gt;'
        $defenintionEnd = '", "w": ' + $shapeWidth + ', "h": ' + $shapeHeigth + ', "aspect": "fixed", "title": "' + $shapeName + '" }'
        
        if ($index -lt $filesCount) {
            $shapedefinitions = $shapedefinitions + " `n " + $defenintionStart + $shapedefinition + $defenintionEnd + ", "
        }
        else {
            $shapedefinitions = $shapedefinitions + " `n " + $defenintionStart + $shapedefinition + $defenintionEnd
        }
        write-host "$index of $filesCount - $shapeName"
        $index++
    }
    "<mxlibrary>[ `n $shapedefinitions `n ]</mxlibrary>" | Out-File -FilePath "./$Foldername.xml" 
}

$size = 50
$fontFamily = "Verdana"
$fontSize = 10
$fontColor = "#331A00"



# Create libraries on the SVG_Azure_Grouped folders
$folders = Get-ChildItem -Path '.\Drawio_Library\Drawio_Library-main/SVG_Azure_Grouped' -Directory

foreach ($folder in $folders) {
    $foldername = $folder.Name
    $files = Get-ChildItem -Path $folder -File
    Create-Library -Foldername $foldername -FilesObject $files -IconSize $Size
}

# Create big library on the SVG_Azure_All folder 1200+ icons
$foldername = '.\Drawio_Library\Drawio_Library-main\SVG_Azure_All'
$files = Get-ChildItem -Path $foldername -File
Create-Library -Foldername 'Azure_All' -FilesObject $files -IconSize $Size