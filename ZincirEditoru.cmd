@echo off
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\launch.ps1" -ChainEditor
if errorlevel 1 pause
