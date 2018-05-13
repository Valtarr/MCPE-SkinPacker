param([string]$DIR)
# ===================
#  Parse params
# ===================
if(!$DIR) {
    Write-Host "Usage:" -ForegroundColor Green
    Write-Host $MyInvocation.MyCommand.Name "<path_to_skins_directory>"
    Write-Host "Slim/Girl skins should be in '\Slim' subdirectory"
    exit
}

if(!(Test-Path $DIR)) {
    Write-Host "Folder '$DIR' does not exist" -ForegroundColor Red
    exit
}

$DIR = $DIR.Trim('\', '/')

# ===================
#  Global variables
# ===================
[int[]]$version = 1,0,0 # SkinPacks are not updateble, so no sence to change version
$NAME = [System.IO.Path]::GetFileNameWithoutExtension($DIR)
$SLIM="$DIR\Slim"
$geometrySlim="geometry.humanoid.customSlim"
$outDir = "$PSScriptRoot\$NAME"
$outDirTexts = "$outDir\texts"
New-Item -ItemType Directory $outDirTexts -Force | Out-Null
Copy-Item -Path "$DIR\*.png" -Destination $outDir
if(Test-Path "$SLIM") {
    Copy-Item -Path "$SLIM\*.png" -Destination $outDir
}

# ===================
#      Classes
# ===================
class Manifest {
    Manifest([string]$name) {
        $this.header.name = $name
    }

    Manifest([string]$name, [int[]]$version) {
        $this.header.name = $name
        $this.header.version = $version
        $this.modules[0].version = $version
    }

    [int]$format_version = 1
    [Manifest_Header]$header = [Manifest_Header]::new()
    [Manifest_Module[]]$modules = [Manifest_Module]::new()
}

class Manifest_Header {
    [string]$name = 'dummy name'
    [guid]$uuid = [guid]::NewGuid()
    [int[]]$version = 1,0,0
}

class Manifest_Module {
    [string]$type = 'skin_pack'
    [guid]$uuid = [guid]::NewGuid()
    [int[]]$version = 1, 0, 0
}

class SkinsSet {
    [string]$geometry = 'skinpacks/skins.json'
    [SkinItem[]]$skins
    [string]$serialize_name
    [string]$localization_name
}

class SkinItem {
    $localization_name
    $geometry='geometry.humanoid.custom'
    $texture
    $type='Free'

}

function GetId([string]$strval) {
     return $strval -replace "[^\w\d]", ""
}

# ===================
#      Main
# ===================
$ID = GetId $NAME

$manifest = New-Object Manifest $NAME, $version

$allSkins = Get-ChildItem "$DIR" -File | ForEach-Object {
    New-Object SkinItem -Property @{
        'localization_name' = GetId $_.BaseName
        'texture' = $_.Name
    }
}

if(Test-Path "$SLIM") {
    $slimSkins = Get-ChildItem "$SLIM" -File | ForEach-Object {
        New-Object SkinItem -Property @{
            'localization_name' = GetId $_.BaseName
            'geometry' = $geometrySlim
            'texture' = $_.Name
        }
    }
    $allSkins = $allSkins + $slimSkins
}

$skinSet = New-Object SkinsSet -Property @{
    'skins' = $allSkins
    'serialize_name' = $NAME
    'localization_name' = $ID
}

$enUsLang = $skinSet.skins | ForEach-Object { "skin.$ID." + $_.localization_name + '=' + [System.IO.Path]::GetFileNameWithoutExtension($_.texture) }
$enUsLang += "skinpack.$ID=$NAME"

Write-Host 'manifest.json:'
$manifestJson = ConvertTo-Json $manifest -Depth 100
Write-Host $manifestJson -ForegroundColor Yellow
Out-File -InputObject $manifestJson -Encoding default -FilePath "$outDir\manifest.json"
Write-Host 'skins.json:'
$skinSetJson = ConvertTo-Json $skinSet -Depth 100
Write-Host $skinSetJson -ForegroundColor Green
Out-File -InputObject $skinSetJson -Encoding default -FilePath "$outDir\skins.json"
Write-Host 'en_US.lang:'
$enUsLang -join "`n" | Write-Host -ForegroundColor Cyan
Out-File -InputObject $enUsLang -Encoding default -FilePath "$outDirTexts\en_US.lang"
Compress-Archive -Path "$outDir\**" -DestinationPath "$outDir.zip" -Force
if(Test-Path "$outDir.mcpack") { Remove-Item "$outDir.mcpack" }
Rename-Item -Path "$outDir.zip" -NewName "$outDir.mcpack" -Force
Remove-Item $outDir -Recurse