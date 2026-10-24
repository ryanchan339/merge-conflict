$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$engineDir = Join-Path $projectRoot '.tools\godot'
$enginePath = Join-Path $engineDir 'Godot_v4.7.2-stable_win64.exe'
if (-not (Test-Path -LiteralPath $enginePath)) {
    Write-Host 'Downloading the portable Godot engine. No installation is required.'
    New-Item -ItemType Directory -Force -Path $engineDir | Out-Null
    $archivePath = Join-Path $projectRoot '.tools\godot.zip'
    Invoke-WebRequest -Uri 'https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_win64.exe.zip' -OutFile $archivePath
    Expand-Archive -LiteralPath $archivePath -DestinationPath $engineDir -Force
}
Start-Process -FilePath $enginePath -ArgumentList @('--path', ('"' + $projectRoot + '"')) -WorkingDirectory $projectRoot
