@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

:: =========================================================
:: CORE.BAT (ONLINE) - cháº¡y bá»Ÿi Launcher.exe Ä‘Ã£ build 1 láº§n
:: - Mods list Ä‘Æ°á»£c load tá»« mods.ini (update online)
:: - Logic autodetect + download + copy mods giá»¯ nguyÃªn
:: =========================================================

:: ===================== CONFIG (GIU LOGIC CU) =====================
set "APP_NAME=GTA5S"
set "APP_EXE=GTA5S.exe"
set "APP_MANIFEST=GTA5S.VisualElementsManifest.xml"
:: =================================================================

title %APP_NAME% CÃ i Ä‘áº·t Mod nhanh trÃªn GTA5S - Install Mods on GTA5S (Coded by KayC)
color A

:: ===== Nháº­n Ä‘Æ°á»ng dáº«n mods.ini tá»« Launcher =====
set "MODS_INI=%~1"
if not defined MODS_INI set "MODS_INI=%~dp0mods.ini"

:: ===== PowerShell path =====
set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"

:: ===================== LOAD MODS FROM INI =====================
call :LOAD_MODS "%MODS_INI%"
if errorlevel 1 (
  echo(
  echo [ERR] KhÃ´ng load Ä‘Æ°á»£c danh sÃ¡ch mods tá»«:
  echo "%MODS_INI%"
  echo(
  pause
  exit /b 1
)

:: ===================== BANNER (GIU NGUYEN) =====================
echo(
echo %APP_NAME% CÃ i Ä‘áº·t Mod trÃªn GTA5S - Install Mods on GTA5S (Coded by KayC)
echo(
echo "   ____ _____  _    ____ ____   _   _ _____ _____ "
echo "  / ___|_   _|/ \  | ___/ ___| | \ | | ____|_   _| "
echo " | |  _  | | / _ \ |___ \___ \ |  \| |  _|   | | "
echo " | |_| | | |/ ___ \ ___) |__) || |\  | |___  | | "
echo "  \____| |_/_/   \_\____/____(_)_| \_|_____| |_| "
echo(

:: ============================================================
:: ============ AUTO-DETECT GAME FOLDER (FAST, no UI) ==========
:: ============================================================
set "GAME_DIR="
set "OUT=%TEMP%\game_dir.txt"
del /f /q "%OUT%" >nul 2>&1

"%PS%" -NoProfile -ExecutionPolicy Bypass -Command ^
  "$exe='%APP_EXE%'; $man='%APP_MANIFEST%'; $pname=[IO.Path]::GetFileNameWithoutExtension($exe); $hit=$null;" ^
  "function Test([string]$p){ if([string]::IsNullOrWhiteSpace($p)){return $false};" ^
  " (Test-Path (Join-Path $p $exe) -PathType Leaf) -and (Test-Path (Join-Path $p $man) -PathType Leaf) }" ^
  "; try{ $pr=Get-Process $pname -EA SilentlyContinue | Select -First 1; if($pr -and $pr.Path){ $d=Split-Path $pr.Path -Parent; if(Test $d){$hit=$d} } }catch{}" ^
  "; if(-not $hit){" ^
  "  try{ $k='HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\'+$exe; $ap=(Get-ItemProperty $k -EA SilentlyContinue).'((default))' }catch{}" ^
  "  if(-not $ap){ try{ $k='HKLM:\Software\Microsoft\Windows\CurrentVersion\App Paths\'+$exe; $ap=(Get-ItemProperty $k -EA SilentlyContinue).'((default))' }catch{} }" ^
  "  if(-not $ap){ try{ $k='HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\'+$exe; $ap=(Get-ItemProperty $k -EA SilentlyContinue).'((default))' }catch{} }" ^
  "  if($ap){ $d=Split-Path $ap -Parent; if(Test $d){$hit=$d} }" ^
  "}" ^
  "; if(-not $hit){" ^
  "  $cand=@(" ^
  "    (Join-Path $env:LOCALAPPDATA $pname)," ^
  "    (Join-Path $env:LOCALAPPDATA ('Programs\'+$pname))," ^
  "    (Join-Path $env:ProgramFiles $pname)," ^
  "    (Join-Path ${env:ProgramFiles(x86)} $pname)," ^
  "    (Join-Path $env:ProgramData $pname)" ^
  "  ) | Where-Object { Test-Path $_ };" ^
  "  foreach($c in $cand){ if(Test $c){ $hit=$c; break } }" ^
  "}" ^
  "; if(-not $hit){" ^
  "  $root=$env:LOCALAPPDATA; if(Test-Path $root){" ^
  "    try{ $x=Get-ChildItem -LiteralPath $root -Filter $exe -File -Recurse -Depth 4 -EA SilentlyContinue | Select -First 1;" ^
  "      if($x){ $d=$x.DirectoryName; if(Test $d){ $hit=$d } } }catch{}" ^
  "  }" ^
  "}" ^
  "; if(-not $hit){" ^
  "  $dr=(Get-CimInstance Win32_LogicalDisk | ?{ $_.DriveType -eq 3 }).DeviceID;" ^
  "  foreach($d in $dr){" ^
  "    foreach($p in @($pname,('Games\'+$pname),('Game\'+$pname),('Program Files\'+$pname),('Program Files (x86)\'+$pname)) ){" ^
  "      $pp=Join-Path $d $p; if(Test $pp){ $hit=$pp; break }" ^
  "    }" ^
  "    if($hit){ break }" ^
  "  }" ^
  "  if(-not $hit){" ^
  "    foreach($d in $dr){" ^
  "      try{ $x=Get-ChildItem -LiteralPath ($d+'\') -Filter $exe -File -Recurse -Depth 5 -EA SilentlyContinue | Select -First 1;" ^
  "        if($x){ $d2=$x.DirectoryName; if(Test $d2){ $hit=$d2; break } } }catch{}" ^
  "    }" ^
  "  }" ^
  "}" ^
  "; if($hit){ $hit | Out-File -Encoding ASCII '%OUT%' }" >nul 2>&1

if exist "%OUT%" (
  set /p GAME_DIR=<"%OUT%"
  del /f /q "%OUT%" >nul 2>&1
)

:: ===== Fallback (chi khi that su KHONG tim thay) =====
if not defined GAME_DIR (
  for /f "usebackq delims=" %%D in (`
    "%PS%" -STA -NoProfile -ExecutionPolicy Bypass -Command ^
    "Add-Type -AssemblyName System.Windows.Forms; $f=New-Object Windows.Forms.FolderBrowserDialog;" ^
    "$f.Description='Chon thu muc chua %APP_EXE%'; if($f.ShowDialog() -eq 'OK'){[Console]::WriteLine($f.SelectedPath)}"
  `) do set "GAME_DIR=%%D"
)

if not defined GAME_DIR (
  echo Khong tim thay thu muc %APP_NAME% tren he thong. Thoat.
  pause & exit /b 1
)

if not exist "%GAME_DIR%\%APP_EXE%" (
  echo Thu muc da chon khong co %APP_EXE%. Thoat.
  echo Thu muc: "%GAME_DIR%"
  pause & exit /b 1
)

if not exist "%GAME_DIR%\%APP_MANIFEST%" (
  echo Thu muc da chon khong co %APP_MANIFEST%. Thoat.
  echo Thu muc: "%GAME_DIR%"
  pause & exit /b 1
)

:: ===================== MODS FOLDER =====================
set "MODS_DIR=%GAME_DIR%\GTA5S.app\mods"
if not exist "%MODS_DIR%" mkdir "%MODS_DIR%" >nul 2>&1

if not exist "%MODS_DIR%" (
  echo [ERR] Khong tao/truy cap duoc thu muc mods:
  echo "%MODS_DIR%"
  pause & exit /b 1
)

:: ===================== MENU =====================
:MENU
cls
call :PRINT_HEADER

echo(
echo 0. CÃ i Ä‘áº·t táº¥t cáº£ mods bÃªn dÆ°á»›i trÃªn GTA5S â­
echo(
call :PRINT_MOD_LIST
echo(
echo X. ThoÃ¡t
echo(
set "CH="
set /p "CH=Lá»±a chá»n mod muá»‘n cÃ i Ä‘áº·t trÃªn GTA5S (Nháº­p sá»‘ tÆ°Æ¡ng á»©ng vÃ  báº¥m ENTER): "

if /I "%CH%"=="X" exit /b 0

if "%CH%"=="0" (
  cls
  call :PRINT_HEADER
  echo(
  echo Báº¡n Ä‘Ã£ chá»n: CÃ€I Táº¤T Cáº¢ MODS
  call :INSTALL_ALL
  if errorlevel 1 (
    echo(
    echo [!] CÃ³ lá»—i khi cÃ i má»™t sá»‘ mod. Báº¥m phÃ­m báº¥t ká»³ Ä‘á»ƒ quay láº¡i menu...
    pause >nul
    goto :MENU
  )
  goto :AFTER_INSTALL
)

:: chá»n mod theo sá»‘ (giá»¯ Ä‘Ãºng logic, chá»‰ tá»•ng quÃ¡t hÃ³a)
set "U=!MOD_URL_%CH%!"
if defined U (
  cls
  call :PRINT_HEADER
  echo(
  echo Báº¡n Ä‘Ã£ chá»n: !MOD_NAME_%CH%!
  call :INSTALL_MOD %CH%
  if errorlevel 1 (
    echo(
    echo [!] CÃ i mod tháº¥t báº¡i. Báº¥m phÃ­m báº¥t ká»³ Ä‘á»ƒ quay láº¡i menu...
    pause >nul
    goto :MENU
  )
  goto :AFTER_INSTALL
)

echo(
echo Lá»±a chá»n khÃ´ng há»£p lá»‡. Thá»­ láº¡i...
timeout /t 2 >nul
goto :MENU


:: ===================== HEADER FOR INSTALL SCREEN =====================
:PRINT_HEADER
echo(
echo "   ____ _____  _    ____ ____   _   _ _____ _____ "
echo "  / ___|_   _|/ \  | ___/ ___| | \ | | ____|_   _| "
echo " | |  _  | | / _ \ |___ \___ \ |  \| |  _|   | | "
echo " | |_| | | |/ ___ \ ___) |__) || |\  | |___  | | "
echo "  \____| |_/_/   \_\____/____(_)_| \_|_____| |_| "
echo(
echo ==========================================
echo        %APP_NAME% - MOD INSTALLER BY KAYC
echo ==========================================
exit /b 0


:: ===================== PRINT MOD LIST =====================
:PRINT_MOD_LIST
for /L %%I in (1,1,99) do (
  set "N=!MOD_NAME_%%I!"
  set "U=!MOD_URL_%%I!"
  if defined U (
    if not defined N set "N=Mod so %%I"
    echo %%I. !N!
  )
)
exit /b 0


:: ===================== INSTALL ALL =====================
:INSTALL_ALL
set "OK=0"
set "FAIL=0"
echo(
echo Äang cÃ i Ä‘áº·t táº¥t cáº£ mods trÃªn GTA5S ...

for /L %%I in (1,1,99) do (
  set "U="
  set "U=!MOD_URL_%%I!"
  if defined U (
    call :INSTALL_MOD %%I
    if errorlevel 1 (set /a FAIL+=1) else (set /a OK+=1)
  )
)

echo(
echo ==========================================
echo HoÃ n táº¥t cÃ i Ä‘áº·t táº¥t cáº£ mods:
echo ThÃ nh cÃ´ng: !OK!
echo Tháº¥t báº¡i : !FAIL!
echo ==========================================
if !OK! gtr 0 (exit /b 0) else (exit /b 1)


:: ===================== INSTALL MOD =====================
:INSTALL_MOD
set "IDX=%~1"
set "MNAME=!MOD_NAME_%IDX%!"
set "MURL=!MOD_URL_%IDX%!"

if "!MURL!"=="" exit /b 1
if "!MNAME!"=="" set "MNAME=Mod so %IDX%"

for %%A in ("!MURL!") do set "MFILE=%%~nxA"
for /f "delims=?" %%Q in ("!MFILE!") do set "MFILE=%%Q"
if "!MFILE!"=="" exit /b 1

set "DL_DIR=%TEMP%\GTA5S_MODS_DL"
if not exist "!DL_DIR!" mkdir "!DL_DIR!" >nul 2>&1

set "DL_PATH=!DL_DIR!\!MFILE!"
del /f /q "!DL_PATH!" >nul 2>&1

echo(
echo Äang táº£i vÃ  cÃ i Ä‘áº·t: !MNAME!
echo(

"%PS%" -NoProfile -ExecutionPolicy Bypass -Command ^
  "$u='%MURL%'; $o='%DL_PATH%';" ^
  "try{ [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13;" ^
  "Invoke-WebRequest -Uri $u -OutFile $o -UseBasicParsing -ErrorAction Stop; exit 0 }catch{ exit 1 }" >nul 2>&1

if errorlevel 1 exit /b 1
if not exist "!DL_PATH!" exit /b 1

copy /y "!DL_PATH!" "%MODS_DIR%\" >nul
if errorlevel 1 exit /b 1

echo [OK] ÄÃ£ cÃ i Ä‘áº·t thÃ nh cÃ´ng: "!MNAME!" trÃªn GTA5S
exit /b 0


:: ===================== AFTER INSTALL =====================
:AFTER_INSTALL
echo(
choice /c YN /m "Báº¡n cÃ³ muá»‘n vÃ o game GTA5S ngay khÃ´ng? (Báº¥m Y Ä‘á»ƒ vÃ o game / Báº¥m N Ä‘á»ƒ quay láº¡i MENU Mods tiáº¿p)"
if errorlevel 2 goto :MENU

start "" "%GAME_DIR%\%APP_EXE%"
echo(
echo Äang má»Ÿ %APP_NAME%. Tá»± Ä‘á»™ng Ä‘Ã³ng sau 5 giÃ¢y ...
timeout /t 5 >nul
exit /b 0


:: ===================== LOAD MODS INI =====================
:LOAD_MODS
set "INI=%~1"
if not exist "%INI%" exit /b 1

:: clear old vars
for /L %%I in (1,1,99) do (
  set "MOD_NAME_%%I="
  set "MOD_URL_%%I="
)

set "INMODS=0"
for /f "usebackq delims=" %%L in ("%INI%") do (
  set "LINE=%%L"
  if "!LINE!"=="" goto :CONT
  if "!LINE:~0,1!"==";" goto :CONT
  if "!LINE:~0,1!"=="#" goto :CONT

  if /i "!LINE!"=="[mods]" (
    set "INMODS=1"
    goto :CONT
  )

  if "!LINE:~0,1!"=="[" (
    set "INMODS=0"
    goto :CONT
  )

  if "!INMODS!"=="1" (
    for /f "tokens=1,* delims==" %%A in ("!LINE!") do (
      set "K=%%A"
      set "V=%%B"
      if defined K (
        :: key dáº¡ng: 1.name / 1.url
        for /f "tokens=1,2 delims=." %%I in ("!K!") do (
          set "IDX=%%I"
          set "FIELD=%%J"
          if /i "!FIELD!"=="name" set "MOD_NAME_!IDX!=!V!"
          if /i "!FIELD!"=="url"  set "MOD_URL_!IDX!=!V!"
        )
      )
    )
  )

  :CONT
)

:: Ã­t nháº¥t pháº£i cÃ³ 1 url
set "HAS=0"
for /L %%I in (1,1,99) do (
  if defined MOD_URL_%%I set "HAS=1"
)
if "!HAS!"=="1" exit /b 0
exit /b 1
