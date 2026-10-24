param(
    [ValidatePattern('^\d+\.\d+(\.\d+)?$')]
    [string]$GodotVersion = '4.7.2'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$projectRoot = Split-Path -Parent $PSScriptRoot
$toolsRoot = Join-Path $projectRoot '.tools'
$downloadRoot = Join-Path $toolsRoot 'downloads'
$engineRoot = Join-Path $toolsRoot 'godot'
$releaseBase = "https://github.com/godotengine/godot-builds/releases/download/$GodotVersion-stable"
$isWindowsHost = $env:OS -eq 'Windows_NT'

New-Item -ItemType Directory -Force -Path $downloadRoot, $engineRoot | Out-Null

if ($isWindowsHost) {
    $engineAsset = "Godot_v$GodotVersion-stable_win64.exe.zip"
    $engineName = "Godot_v$GodotVersion-stable_win64_console.exe"
    $templateRoot = Join-Path $env:APPDATA "Godot/export_templates/$GodotVersion.stable"
} else {
    $engineAsset = "Godot_v$GodotVersion-stable_linux.x86_64.zip"
    $engineName = "Godot_v$GodotVersion-stable_linux.x86_64"
    $dataRoot = if ($env:XDG_DATA_HOME) { $env:XDG_DATA_HOME } else { Join-Path ([Environment]::GetFolderPath('UserProfile')) '.local/share' }
    $templateRoot = Join-Path $dataRoot "godot/export_templates/$GodotVersion.stable"
}

$enginePath = Join-Path $engineRoot $engineName
$releaseTemplate = Join-Path $templateRoot 'web_nothreads_release.zip'
$debugTemplate = Join-Path $templateRoot 'web_nothreads_debug.zip'
$needsEngine = -not (Test-Path -LiteralPath $enginePath)
$needsTemplates = -not ((Test-Path -LiteralPath $releaseTemplate) -and (Test-Path -LiteralPath $debugTemplate))

if ($needsEngine -or $needsTemplates) {
    $sumsPath = Join-Path $downloadRoot "Godot_v$GodotVersion-SHA512-SUMS.txt"
    Invoke-WebRequest -Uri "$releaseBase/SHA512-SUMS.txt" -OutFile $sumsPath
    $checksums = @{}
    foreach ($line in Get-Content -LiteralPath $sumsPath) {
        if ($line -match '^([a-fA-F0-9]{128})\s+\*?(.+)$') {
            $checksums[$Matches[2].Trim()] = $Matches[1]
        }
    }
}

function Get-VerifiedAsset([string]$AssetName) {
    if (-not $checksums.ContainsKey($AssetName)) {
        throw "Official SHA512 checksum missing for $AssetName."
    }
    $assetPath = Join-Path $downloadRoot $AssetName
    if (-not (Test-Path -LiteralPath $assetPath)) {
        Write-Host "Downloading official Godot asset: $AssetName"
        Invoke-WebRequest -Uri "$releaseBase/$AssetName" -OutFile $assetPath
    }
    Write-Host "Verifying SHA512: $AssetName"
    $actualHash = (Get-FileHash -LiteralPath $assetPath -Algorithm SHA512).Hash
    if ($actualHash -ne $checksums[$AssetName]) {
        throw "Checksum mismatch for $assetPath. Remove that download and rerun this script."
    }
    return $assetPath
}

if ($needsEngine) {
    $archivePath = Get-VerifiedAsset $engineAsset
    Expand-Archive -LiteralPath $archivePath -DestinationPath $engineRoot -Force
    if (-not $isWindowsHost) {
        & chmod +x $enginePath
        if ($LASTEXITCODE -ne 0) { throw 'Could not make Godot executable.' }
    }
}

if ($needsTemplates) {
    $archivePath = Get-VerifiedAsset "Godot_v$GodotVersion-stable_export_templates.tpz"
    New-Item -ItemType Directory -Force -Path $templateRoot | Out-Null
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($archivePath)
    try {
        foreach ($entry in $archive.Entries) {
            if ($entry.Name -in @('web_nothreads_release.zip', 'web_nothreads_debug.zip', 'version.txt')) {
                $destination = Join-Path $templateRoot $entry.Name
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destination, $true)
            }
        }
    } finally {
        $archive.Dispose()
    }
    if (-not ((Test-Path -LiteralPath $releaseTemplate) -and (Test-Path -LiteralPath $debugTemplate))) {
        throw "Single-threaded web templates were not present in the official archive."
    }
}

$installedVersion = (& $enginePath --version | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or -not $installedVersion.StartsWith("$GodotVersion.stable.")) {
    throw "Expected Godot $GodotVersion stable; found: $installedVersion"
}
Write-Host "Godot $installedVersion and single-threaded web templates are ready."
return $enginePath
