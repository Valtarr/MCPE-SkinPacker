param([string]$DIR)
# ===================
#  Parse params
# ===================
if(!$DIR) {
    Write-Host "Usage:" -ForegroundColor Green
    Write-Host $MyInvocation.MyCommand.Name "<path_to_skins_directory>" -ForegroundColor Yellow
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

function WriteSkinNames([SkinItem[]]$skins, [bool]$isSlim=$false) {
    $count = $skins.Count
    if ($count -gt 0) {
        if($isSlim) {
            Write-Host "$count slim skins found:" -ForegroundColor Green
        }
        else {
            Write-Host "$count common skins found:" -ForegroundColor Green
        }
        Foreach($skin in $skins) {
            Write-Host $skin.texture
        }

        Write-Host
    }
}

# ===================
#      Main
# ===================
$ID = GetId $NAME

$manifest = New-Object Manifest $NAME, $version

[SkinItem[]]$allSkins = Get-ChildItem "$DIR" -File | ForEach-Object {
    New-Object SkinItem -Property @{
        'localization_name' = GetId $_.BaseName
        'texture' = $_.Name
    }
}

WriteSkinNames $allSkins $false

if(Test-Path "$SLIM") {
    $slimSkins = Get-ChildItem "$SLIM" -File | ForEach-Object {
        New-Object SkinItem -Property @{
            'localization_name' = GetId $_.BaseName
            'geometry' = $geometrySlim
            'texture' = $_.Name
        }
    }

    WriteSkinNames $slimSkins $true

    $allSkins = $allSkins + $slimSkins
}

$skinSet = New-Object SkinsSet -Property @{
    'skins' = $allSkins
    'serialize_name' = $NAME
    'localization_name' = $ID
}

$enUsLang = $skinSet.skins | ForEach-Object { "skin.$ID." + $_.localization_name + '=' + [System.IO.Path]::GetFileNameWithoutExtension($_.texture) }
$enUsLang += "skinpack.$ID=$NAME"

Write-Host 'Create manifest.json'
$manifestJson = ConvertTo-Json $manifest -Depth 100
Out-File -InputObject $manifestJson -Encoding default -FilePath "$outDir\manifest.json"

Write-Host 'Create skins.json'
$skinSetJson = ConvertTo-Json $skinSet -Depth 100
Out-File -InputObject $skinSetJson -Encoding default -FilePath "$outDir\skins.json"

Write-Host 'Create en_US.lang'
Out-File -InputObject $enUsLang -Encoding default -FilePath "$outDirTexts\en_US.lang"

Write-Host "Compress temporary dir '$outDir'"
Compress-Archive -Path "$outDir\**" -DestinationPath "$outDir.zip" -Force
if(Test-Path "$outDir.mcpack") { Remove-Item "$outDir.mcpack" }
Rename-Item -Path "$outDir.zip" -NewName "$outDir.mcpack" -Force
Write-Host "Package '$outDir.mcpack' created" -ForegroundColor Green

Write-Host "Remove temporary folder '$outdir'"
Remove-Item $outDir -Recurse

Write-Host "Finished" -ForegroundColor Green