@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0update-database.ps1" %*
