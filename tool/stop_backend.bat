@echo off
rem Stops the ShareLoop API started by start_backend.bat (whatever is
rem listening on port 8000).
set "FOUND="
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /r /c:":8000 .*LISTENING"') do (
  taskkill /PID %%p /T /F >nul 2>&1
  set "FOUND=1"
)
if defined FOUND (echo ShareLoop API stopped.) else (echo Nothing was running on port 8000.)
timeout /t 2 >nul
