@echo off
REM =============================================================================
REM Zoro-Zero: Execution Policy Bypass Wrapper
REM Licensed under the MIT License (https://opensource.org/license/mit)
REM Team-404, Michelle Stonecastle-20260527: v1.0.0
REM
REM DESCRIPTION:
REM   This batch script provides a 100% turnkey experience for Windows users.
REM   By default, Windows blocks running downloaded .ps1 scripts (Execution Policy).
REM   Double-clicking this .bat file automatically launches the PowerShell 
REM   deployment script while safely bypassing the local execution policy for 
REM   this single session.
REM
REM SYNTAX BREAKDOWN (Security Transparency):
REM   - "%~dp0" : Dynamically resolves to the absolute path where this .bat file
REM               lives. This prevents relative path errors if run from elsewhere.
REM   - "%*"    : Blindly captures and forwards any command-line arguments you 
REM               provide (like -ForceCPU) directly to the PowerShell script.
REM =============================================================================

echo [Zoro-Zero] Launching Deployment Environment...
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0Start-Zoro-Zero.ps1" %*
pause
