param(
    [string]$OutputDirectory = 'build/web'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$enginePath = & (Join-Path $PSScriptRoot 'install-web-tools.ps1')
$outputPath = if ([System.IO.Path]::IsPathRooted($OutputDirectory)) {
    $OutputDirectory
} else {
    Join-Path $projectRoot $OutputDirectory
}
New-Item -ItemType Directory -Force -Path $outputPath | Out-Null

function Invoke-CheckedGodot {
    param(
        [string]$StepName,
        [string[]]$GodotArguments,
        [string]$RequiredOutput = ''
    )

    # Godot can return exit code zero after a script fails to parse. Inspect its
    # combined output as well, without treating ordinary warnings as failures.
    $previousErrorAction = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $PSNativeCommandUseErrorActionPreference = $false
        $lines = @(& $enginePath @GodotArguments 2>&1 | ForEach-Object { $_.ToString() })
        $nativeExitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorAction
    }
    $output = $lines -join [Environment]::NewLine
    Write-Host $output
    if ($nativeExitCode -ne 0) {
        throw "$StepName failed with exit code $nativeExitCode."
    }
    if ($output -match '(?i)SCRIPT ERROR:|Parse Error:|ERROR:\s+(?:Failed to load script|Error parsing|Error loading[^\r\n]*script)') {
        throw "$StepName reported a script or parse error."
    }
    if ($RequiredOutput -and $output -notmatch $RequiredOutput) {
        throw "$StepName did not report its required success marker."
    }
}

Invoke-CheckedGodot -StepName 'Godot resource import' -GodotArguments @(
    '--headless', '--path', $projectRoot, '--editor', '--import', '--quit'
)

Invoke-CheckedGodot -StepName 'Workday smoke test' -GodotArguments @(
    '--headless', '--path', $projectRoot,
    '--max-fps', '120', '--quit-after', '1800', '--', '--smoke-test'
) -RequiredOutput '(?m)^\s*SMOKE TEST PASS\b'

Invoke-CheckedGodot -StepName 'Godot web export' -GodotArguments @(
    '--headless', '--path', $projectRoot, '--export-release', 'Web',
    (Join-Path $outputPath 'index.html')
)

foreach ($name in @('index.html', 'index.js', 'index.wasm', 'index.pck')) {
    $file = Join-Path $outputPath $name
    if (-not (Test-Path -LiteralPath $file) -or (Get-Item -LiteralPath $file).Length -eq 0) {
        throw "Web export did not produce $name."
    }
}
New-Item -ItemType File -Force -Path (Join-Path $outputPath '.nojekyll') | Out-Null
Write-Host "Web build ready: $outputPath"
Get-ChildItem -LiteralPath $outputPath -File | Select-Object Name, Length
