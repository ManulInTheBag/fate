@echo off
title Fate Scoreboard Bot
cd /d "%~dp0"

echo ============================================
echo   Fate Scoreboard Bot
echo   The bot is ON while this window is open.
echo   Close this window (or press Ctrl+C) to stop.
echo ============================================
echo.

if not exist ".venv\Scripts\python.exe" (
    echo [ERROR] Python environment not found ^(.venv^).
    echo Run setup first. See README.md.
    echo.
    pause
    exit /b 1
)

:loop
".venv\Scripts\python.exe" bot.py
echo.
echo --------------------------------------------
echo  Bot stopped. Restarting in 5 seconds...
echo  (Close this window now if you want it OFF.)
echo --------------------------------------------
timeout /t 5 >nul
goto loop
