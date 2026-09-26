@echo off

call "%~dp0..\..\fenysha_events\tools\sort\sort_dme.bat"

call "%~dp0..\bootstrap\javascript.bat" "%~dp0build.ts" %*
