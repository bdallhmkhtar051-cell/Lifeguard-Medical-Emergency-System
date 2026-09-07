@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0verify-all.ps1" %*
