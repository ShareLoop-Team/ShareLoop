@echo off
setlocal
title ShareLoop app (Chrome)
rem Runs the Flutter app in Chrome against the local API
rem (start tool\start_backend.bat first). Uses the repo's .env.
cd /d "%~dp0.."
if not exist .env copy .env.example .env >nul
call flutter pub get || goto :fail
call flutter run -d chrome --web-hostname localhost --web-port 5000 --dart-define-from-file=.env
goto :eof
:fail
pause
