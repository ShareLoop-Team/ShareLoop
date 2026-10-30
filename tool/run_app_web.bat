@echo off
setlocal
title ShareLoop app (http://localhost:5000)
rem Serves the Flutter app at http://localhost:5000 for any browser
rem (start tool\start_backend.bat first). Uses the repo's .env.
cd /d "%~dp0.."
if not exist .env copy .env.example .env >nul
call flutter pub get || goto :fail
call flutter run -d web-server --web-hostname localhost --web-port 5000 --dart-define-from-file=.env
goto :eof
:fail
pause
