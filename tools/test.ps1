$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$enginePath = Join-Path $projectRoot '.tools\godot\Godot_v4.7.2-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $enginePath)) {
    throw 'Run Start Game.cmd once to download the portable Godot engine.'
}
& $enginePath --headless --path $projectRoot --editor --import --quit
if ($LASTEXITCODE -ne 0) { throw 'Project import failed.' }
& $enginePath --headless --path $projectRoot -- --smoke-test
if ($LASTEXITCODE -ne 0) { throw 'Workday progression failed.' }
foreach ($testName in @('story_test.gd', 'world_test.gd', 'input_test.gd', 'desk_interaction_test.gd', 'kitchen_interaction_test.gd', 'office_interaction_test.gd', 'engineering_cases_test.gd', 'schedule_test.gd', 'campaign_test.gd')) {
    & $enginePath --headless --path $projectRoot --script (Join-Path $projectRoot ('tests\' + $testName))
    if ($LASTEXITCODE -ne 0) { throw ('Failed: ' + $testName) }
}
Write-Host 'All prototype checks passed.' -ForegroundColor Green
