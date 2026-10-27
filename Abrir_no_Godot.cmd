@echo off
setlocal
set "GODOT_GAME_BIN=%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
if exist "%~dp0Godot.exe" set "GODOT_GAME_BIN=%~dp0Godot.exe"
if not exist "%GODOT_GAME_BIN%" (
  echo Importe o arquivo project.godot no gerenciador de projetos do Godot 4.
  pause
  exit /b 1
)
start "Godot - Mushrooms" "%GODOT_GAME_BIN%" --editor --path "%~dp0."
