<#
  .SYNOPSIS
  Powershell creates Draw.io libraries (.xml) with the latest Azure icons in https://github.com/DSchoutsen/Drawio_Library

  .DESCRIPTION
  The script loops through a folder with .svg-files with Azure Icons.
  For each folder and files the function new-library is called
  The function determines for each file the current aspect ratio. 
  The aspect ratio and the provided size determines the width and height of the shape in the library.
  The image of the shape is stored as reference to the github repository. This way the .xml is only a few KB's.
  For each icon the definition is stored as a xml string in a format.
  All definitions lines together determines the library and is returned to execution phase
  The output of the function is saved as a .xml-file

  .PARAMETER size
  Specify the maximum size of the shape, width or height based on aspect ratio.  
  .PARAMETER fontFamily
  Specify the font family
  .PARAMETER fontSize
  Specify the font size in pts
  .PARAMETER fontColor
  Specify the font color in HTML color code

  .INPUTS
  The script uses a folder with icons as input to generate the library definitions. 
  To keep the integrity of the library you can download the files from github with the following commands.    

  Invoke-WebRequest 'https://github.com/DSchoutsen/Drawio_Library/archive/refs/heads/master.zip' -OutFile .\Azure-Design.zip
  Expand-Archive -Path ".\Drawio_Library.zip"
  Run these commands in the same file location as where you run this powershell script.

  Also check the baseURL for the image. This is different for each folder in the repo. 
  You can check the baseURL by clicking on an icon in the repo and copy the image link by right click on the image. 
  Its something like: https://raw.githubusercontent.com/<Account>/<repository>/<GUID>/SVG_Azure_Grouped"

  .OUTPUTS
  The script outputs two types of libraries:
  - seperate libraries group by Azure theme (AI, Compute, Manageement, etc.)
  - One big library with 1200+ icons - almost all Azure services 

  The libraries are saved in the current file location from where the script is run.

  .NOTES
  Version: 1.0.0.0
  Author:  Dennis Schoutsen

  .EXAMPLE
  new-drawiolibrary -size 60 -fontFamily helvetica -fontSize 12 -fontColor #999999
#>

[CmdletBinding()]
Param (
  [Parameter(
    Position = 0,
    Mandatory = $false,
    ValueFromPipeline = $false,
    ValueFromPipelineByPropertyName = $false)
  ]
  [int]$size = 50, # Default size is 50pts 

  [Parameter(
    Position = 1,
    Mandatory = $False,
    ValueFromPipeline = $False,
    ValueFromPipelineByPropertyName = $False)
  ]
  [string]$fontFamily = "Verdana",  # default font for labels is Verdana
  
  [Parameter(
    Position = 1,
    Mandatory = $False,
    ValueFromPipeline = $False,
    ValueFromPipelineByPropertyName = $False)
  ]
  [int]$fontSize = 10,   # default fontsize for labels
  
  [Parameter(
    Position = 1,
    Mandatory = $False,
    ValueFromPipeline = $False,
    ValueFromPipelineByPropertyName = $False)
  ]
  [string]$fontColor = "#331A00"   # default fontcolor, in HTML Colorcode, is dark blue (light theme) of light yellow (dark theme) 
)

#requires -Version 7.0

#region ----------------------------------------------------------[ Declarations ]----------------------------------------------------------

#endregion -------------------------------------------------------[ Declarations ]----------------------------------------------------------

#region ---------------------------------------------------------[ Initialisations ]--------------------------------------------------------

# Set Error Action to Stop
$ErrorActionPreference = 'Stop'
$WarningPreference = 'Continue'

#endregion ------------------------------------------------------[ Initialisations ]--------------------------------------------------------

#region -----------------------------------------------------------[ Functions ]------------------------------------------------------------

function new-library ($FilesObject, $Foldername, $IconSize, $baseURL) {

    # Reset the shapedefinitions variable
    $shapedefinitions = ""

    # Count the number of icons in the folder for a counter
    $filesCount = $files.count
    $index = 1

    # loop through the .svg-files and generate the configurationline of the icon
    foreach ($file in $FilesObject) {
        $shapeName = $file.name -replace '.svg', '' 
        $imageUrl = "$baseURL/$Foldername/" + [uri]::EscapeDataString($shapeName) + ".svg"

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
    
    "<mxlibrary>[ `n $shapedefinitions `n ]</mxlibrary>" 
}

#endregion --------------------------------------------------------[ Functions ]------------------------------------------------------------
  
#region -----------------------------------------------------------[ Execution ]------------------------------------------------------------

$baseURL = "https://raw.githubusercontent.com/DSchoutsen/Drawio_Library/b2224d982ef8b40adc1a0facaacb1e2ff19bd696/SVG_Azure_Grouped"

# Create libraries on the SVG_Azure_Grouped folders
$folders = Get-ChildItem -Path '.\Drawio_Library\Drawio_Library-main/SVG_Azure_Grouped' -Directory

foreach ($folder in $folders) {
    $foldername = $folder.Name
    $files = Get-ChildItem -Path $folder -File
    $librarydefinition = new-library -Foldername $foldername -FilesObject $files -IconSize $Size -baseURL $baseURL
    $librarydefinition | Out-File -FilePath "./$foldername.xml"
}

# Create big library on the SVG_Azure_All folder 1200+ icons
$baseURL = "https://raw.githubusercontent.com/DSchoutsen/Drawio_Library/b98ad08179bba3c95467eab3a88cb1510d1fa053"

$folder = '.\Drawio_Library\Drawio_Library-main\SVG_Azure_All'
$files = Get-ChildItem -Path $folder -File
$librarydefinition = new-library -Foldername 'SVG_Azure_All' -FilesObject $files -IconSize $Size -baseURL $baseURL
$librarydefinition | Out-File -FilePath "./SVG_Azure_All.xml"

#endregion --------------------------------------------------------[ Execution ]------------------------------------------------------------


