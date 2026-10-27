@echo off
echo ========================================================
echo   Product Launch Management System - Backend Server
echo ========================================================
echo.
echo Compiling Server.java...
javac -cp ".;mysql-connector-j-26.7.0.jar;backend" backend/Server.java
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Compilation failed.
    pause
    exit /b %ERRORLEVEL%
)

echo Starting Java Server on http://localhost:8080/api/products ...
java -cp ".;mysql-connector-j-26.7.0.jar;backend" Server
pause
