@echo off
rem Double-click to play BioShock with UE5 drawing it (the live renderer), starting on Medical.
rem Starts BioShock Remastered through Steam if it is not running, waits for you to load in,
rem then opens UE5 over the game window. Close this window (or Ctrl+C) to stop.
title BioShock live renderer
cd /d "%~dp0..\.."

"%SystemRoot%\System32\tasklist.exe" /FI "IMAGENAME eq BioshockHD.exe" | "%SystemRoot%\System32\find.exe" /I "BioshockHD.exe" >nul
if not errorlevel 1 goto game_running
echo Starting BioShock Remastered...
start "" "steam://rungameid/409710"
:wait_game
"%SystemRoot%\System32\timeout.exe" /t 3 /nobreak >nul
"%SystemRoot%\System32\tasklist.exe" /FI "IMAGENAME eq BioshockHD.exe" | "%SystemRoot%\System32\find.exe" /I "BioshockHD.exe" >nul
if errorlevel 1 goto wait_game
:game_running

echo.
echo  1. In BioShock, load a save in Medical Pavilion (any prepared level also works).
echo  2. Come back here and press a key.
echo  3. Click back into the game - UE5 draws over it, your mouse and keyboard stay with the game.
echo.
pause >nul

"C:\Program Files\Git\bin\bash.exe" tools/livegame/play.sh 120
echo.
echo Session ended.
pause
