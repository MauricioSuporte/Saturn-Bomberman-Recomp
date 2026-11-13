@echo off
rem Saturn Bomberman: starts the game built by setup.ps1 (see README.md).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0play.ps1" %*
if errorlevel 1 pause
