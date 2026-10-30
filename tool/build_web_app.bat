@echo off
setlocal
title ShareLoop - build web app into the backend
rem Builds the Flutter web app and puts it in backend\public\app, so the
rem running API also serves the app at http://localhost:8000/app/
rem (one address for both - handy for demos). Uses the repo's .env.
cd /d "%~dp0.."
if not exist .env copy .env.example .env >nul
(
call flutter build web --release --base-href /app/ --dart-define-from-file=.env
echo === build exit %ERRORLEVEL%
robocopy build\web backend\public\app /MIR /NFL /NDL /NJH /NJS
echo === DONE
) > "%~dp0build_web_app.log" 2>&1
type "%~dp0build_web_app.log"
echo.
echo Open http://localhost:8000/app/ (start tool\start_backend.bat first).
