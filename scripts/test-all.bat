@echo off
echo ========================================================
echo Running Monorepo Verification Test Suites
echo ========================================================

echo.
echo [1/2] Running NestJS Backend Jest Tests...
cd /d "%~dp0..\apps\api"
call npm run test
if %ERRORLEVEL% NEQ 0 (
  echo [FAILED] Backend tests failed!
  exit /b %ERRORLEVEL%
)

echo.
echo [2/2] Running Flutter Mobile Widget and Unit Tests...
cd /d "%~dp0..\apps\mobile"
call flutter test
if %ERRORLEVEL% NEQ 0 (
  echo [FAILED] Mobile tests failed!
  exit /b %ERRORLEVEL%
)

echo.
echo ========================================================
echo [SUCCESS] All backend and mobile tests passed!
echo ========================================================
