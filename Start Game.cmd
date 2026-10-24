@echo off
cd /d "%~dp0"
if exist ".tools\godot\Godot_v4.7.2-stable_win64.exe" (
  start "" ".tools\godot\Godot_v4.7.2-stable_win64.exe" --path "%~dp0."
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\start.ps1"
)
