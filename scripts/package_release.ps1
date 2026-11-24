param(
    [string]$Version = "v1.0.0",
    [string]$BuildDir = (Join-Path $PSScriptRoot "..\build"),
    [string]$OutDir = (Join-Path $PSScriptRoot "..\dist"),
    [string]$WinDeployQt = "D:\Qt\6.8.3\msvc2022_64\bin\windeployqt.exe"
)

$ErrorActionPreference = "Stop"

$RootDir = Resolve-Path (Join-Path $PSScriptRoot "..")
$StageName = "PhotoZipper-$Version-win-x64"
$StageDir = Join-Path $OutDir $StageName
$ZipPath = Join-Path $OutDir "$StageName-portable.zip"

if (Test-Path $StageDir) { Remove-Item -Recurse -Force $StageDir }
if (Test-Path $ZipPath) { Remove-Item -Force $ZipPath }
New-Item -ItemType Directory -Force -Path $StageDir | Out-Null

Copy-Item (Join-Path $BuildDir "PhotoZipper.exe") -Destination $StageDir -Force

& $WinDeployQt --release --no-translations --no-compiler-runtime --no-opengl-sw `
    --qmldir (Join-Path $RootDir "qml") (Join-Path $StageDir "PhotoZipper.exe")
if ($LASTEXITCODE -ne 0) { throw "windeployqt failed with exit code $LASTEXITCODE" }

foreach ($dll in @("vcruntime140.dll", "vcruntime140_1.dll", "msvcp140.dll", "msvcp140_1.dll", "msvcp140_2.dll")) {
    $sysDll = Join-Path "C:\Windows\System32" $dll
    if (Test-Path $sysDll) { Copy-Item $sysDll -Destination $StageDir -Force }
}

$EngineSrc = Join-Path $BuildDir "engine\imagemagick"
$EngineDst = Join-Path $StageDir "engine\imagemagick"
if (Test-Path $EngineSrc) {
    New-Item -ItemType Directory -Force -Path $EngineDst | Out-Null
    Copy-Item (Join-Path $EngineSrc "*") -Destination $EngineDst -Recurse -Force
}

$ReadmePath = Join-Path $RootDir "README.md"
if (Test-Path $ReadmePath) { Copy-Item $ReadmePath -Destination $StageDir -Force }

function Get-DirSizeMB([string]$Path) {
    $sum = (Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    return [math]::Round($sum / 1MB, 2)
}

$BeforeMB = Get-DirSizeMB $StageDir

# Prune unused QtQuick.Controls styles, QML debugger/profiler plugins, and unused Qt6 modules
$UnusedPaths = @(
    "Qt6QuickControls2Imagine.dll",
    "Qt6QuickControls2ImagineStyleImpl.dll",
    "Qt6QuickControls2Material.dll",
    "Qt6QuickControls2MaterialStyleImpl.dll",
    "Qt6QuickControls2Fusion.dll",
    "Qt6QuickControls2FusionStyleImpl.dll",
    "Qt6QuickControls2Universal.dll",
    "Qt6QuickControls2UniversalStyleImpl.dll",
    "Qt6QuickControls2FluentWinUI3StyleImpl.dll",
    "Qt6QuickControls2WindowsStyleImpl.dll",
    "Qt6Svg.dll",
    "Qt6QuickEffects.dll",
    "qmltooling",
    "iconengines",
    "generic",
    "imageformats\qsvg.dll",
    "imageformats\qicns.dll",
    "imageformats\qwbmp.dll",
    "tls\qcertonlybackend.dll",
    "qml\QtQuick\Controls\Imagine",
    "qml\QtQuick\Controls\Material",
    "qml\QtQuick\Controls\Fusion",
    "qml\QtQuick\Controls\Universal",
    "qml\QtQuick\Controls\FluentWinUI3",
    "qml\QtQuick\Controls\Windows",
    "qml\QtQuick\NativeStyle",
    "qml\QtQuick\Effects"
)

foreach ($rel in $UnusedPaths) {
    $full = Join-Path $StageDir $rel
    if (Test-Path $full) {
        Remove-Item -Recurse -Force $full
    }
}

$AfterMB = Get-DirSizeMB $StageDir

Push-Location $OutDir
try {
    tar.exe -a -c -f $ZipPath $StageName
    if ($LASTEXITCODE -ne 0) { throw "tar.exe failed with exit code $LASTEXITCODE" }
} finally {
    Pop-Location
}

$ZipMB = [math]::Round((Get-Item $ZipPath).Length / 1MB, 2)
Write-Host "PRUNED_MB: before=${BeforeMB}MB after=${AfterMB}MB saved=$([math]::Round($BeforeMB - $AfterMB, 2))MB zip=${ZipMB}MB"
