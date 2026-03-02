@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

:: =========================================================
:: CORE.BAT (ONLINE)
:: - Nhận đường dẫn mods.ini từ Launcher.exe/launcher.bat
:: - Load mods list từ mods.ini (update online)
:: - Giữ nguyên logic autodetect + download + copy mods
:: =========================================================

:: ===== Nhận đường dẫn mods.ini từ Launcher =====
set "MODS_INI=%~1"
if not defined MODS_INI set "MODS_INI=%~dp0mods.ini"

:: ===================== DEFAULT CONFIG (fallback) =====================
set "APP_NAME=GTA5S"
set "APP_EXE=GTA5S.exe"
set "APP_MANIFEST=GTA5S.VisualElementsManifest.xml"
:: ====================================================================

:: ===================== LOAD CONFIG FROM mods.ini =====================
if exist "%MODS_INI%" (
  call :LOAD_INI_APP "%MODS_INI%"
  call :LOAD_INI_MODS "%MODS_INI%"
) else (
  echo [ERR] Khong tim thay mods.ini:
  echo "%MODS_INI%"
  pause
  exit /b 1
)

title %APP_NAME% Cài đặt Mod nhanh trên GTA5S - Install Mods on GTA5S (Coded by KayC)
color A

:: Banner
echo(
echo %APP_NAME% Cài đặt Mod trên GTA5S - Install Mods on GTA5S (Coded by KayC)
echo(
echo "   ____ _____  _    ____ ____   _   _ _____ _____ "
echo "  / ___|_   _|/ \  | ___/ ___| | \ | | ____|_   _| "
echo " | |  _  | | / _ \ |___ \___ \ |  \| |  _|   | | "
echo " | |_| | | |/ ___ \ ___) |__) || |\  | |___  | | "
echo "  \____| |_/_/   \_\____/____(_)_| \_|_____| |_| "
echo(

:: ===================== AUTO-DETECT GAME FOLDER (FAST, no UI) =====================
set "GAME_DIR="
set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
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

:: ===================== MENU LOOP =====================
:MENU
cls
call :PRINT_HEADER

echo(
echo 0. Cai dat tat ca mods ben duoi tren GTA5S ⭐
echo(

call :PRINT_MODS_MENU

echo(
echo X. Thoat
echo(
set "CH="
set /p "CH=Lua chon mod muon cai dat tren GTA5S (Nhap so tuong ung va bam ENTER): "

if /I "%CH%"=="X" exit /b 0

if "%CH%"=="0" (
  cls
  call :PRINT_HEADER
  echo(
  echo Ban da chon: CAI TAT CA MODS
  call :INSTALL_ALL
  if errorlevel 1 (
    echo(
    echo [!] Co loi khi cai mot so mod. Bam phim bat ky de quay lai menu...
    pause >nul
    goto :MENU
  )
  goto :AFTER_INSTALL
)

:: Nếu user nhập số: kiểm tra có url không rồi cài
set "U=!MOD_URL_%CH%!"
if not defined U (
  echo(
  echo Lua chon khong hop le. Thu lai...
  timeout /t 2 >nul
  goto :MENU
)

cls
call :PRINT_HEADER
echo(
echo Ban da chon: !MOD_NAME_%CH%!
call :INSTALL_MOD %CH%
if errorlevel 1 (
  echo(
  echo [!] Cai mod that bai. Bam phim bat ky de quay lai menu...
  pause >nul
  goto :MENU
)
goto :AFTER_INSTALL


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


:: ===================== PRINT MODS MENU =====================
:PRINT_MODS_MENU
for /L %%I in (1,1,99) do (
  set "N=!MOD_NAME_%%I!"
  set "U=!MOD_URL_%%I!"
  if defined N if defined U (
    echo %%I. !N!
  )
)
exit /b 0


:: ===================== INSTALL ALL =====================
:INSTALL_ALL
set "OK=0"
set "FAIL=0"
echo(
echo Dang cai dat tat ca mods tren GTA5S ...

for /L %%I in (1,1,99) do (
  set "U=!MOD_URL_%%I!"
  if defined U (
    call :INSTALL_MOD %%I
    if errorlevel 1 (set /a FAIL+=1) else (set /a OK+=1)
  )
)

echo(
echo ==========================================
echo Hoan tat cai dat tat ca mods:
echo Thanh cong: !OK!
echo That bai : !FAIL!
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
echo Dang tai va cai dat: !MNAME!
echo(

"%PS%" -NoProfile -ExecutionPolicy Bypass -Command ^
  "$u='%MURL%'; $o='%DL_PATH%';" ^
  "try{ [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13; Invoke-WebRequest -Uri $u -OutFile $o -UseBasicParsing -ErrorAction Stop; exit 0 }catch{ exit 1 }" >nul 2>&1

if errorlevel 1 exit /b 1
if not exist "!DL_PATH!" exit /b 1

copy /y "!DL_PATH!" "%MODS_DIR%\" >nul
if errorlevel 1 exit /b 1

echo [OK] Da cai dat thanh cong: "!MNAME!" tren GTA5S
exit /b 0


:: ===================== AFTER INSTALL =====================
:AFTER_INSTALL
echo(
choice /c YN /m "Ban co muon vao game GTA5S ngay khong? (Bam Y de vao game / Bam N de quay lai MENU Mods tiep)"
if errorlevel 2 goto :MENU

start "" "%GAME_DIR%\%APP_EXE%"
echo(
echo Dang mo %APP_NAME%. Tu dong dong sau 5 giay ...
timeout /t 5 >nul
exit /b 0


:: ===================== INI PARSERS =====================
:LOAD_INI_APP
set "INI=%~1"
for /f "usebackq tokens=1,* delims==" %%A in (`findstr /R /C:"^[ ]*[a-zA-Z0-9_.-][a-zA-Z0-9_.-]*=" "%INI%"`) do (
  set "K=%%A"
  set "V=%%B"
  call :TRIM K
  call :TRIM V

  :: chỉ nhận trong [app] bằng cách check biến SECTION hiện tại
)
:: parser dưới đây làm theo dòng để biết section
set "SECTION="
for /f "usebackq delims=" %%L in ("%INI%") do (
  set "LINE=%%L"
  call :PARSE_LINE_APP
)
exit /b 0

:PARSE_LINE_APP
set "L=!LINE!"
for /f "tokens=* delims= " %%Z in ("!L!") do set "L=%%Z"
if "!L!"=="" exit /b 0
if "!L:~0,1!"==";" exit /b 0
if "!L:~0,1!"=="#" exit /b 0

if "!L:~0,1!"=="[" (
  set "SECTION=!L!"
  exit /b 0
)

if /I "!SECTION!" NEQ "[app]" exit /b 0

for /f "tokens=1,* delims==" %%A in ("!L!") do (
  set "K=%%A"
  set "V=%%B"
  call :TRIM K
  call :TRIM V

  if /I "!K!"=="name" set "APP_NAME=!V!"
  if /I "!K!"=="exe" set "APP_EXE=!V!"
  if /I "!K!"=="manifest" set "APP_MANIFEST=!V!"
)
exit /b 0

:LOAD_INI_MODS
set "INI=%~1"
for /L %%I in (1,1,99) do (
  set "MOD_NAME_%%I="
  set "MOD_URL_%%I="
)

set "SECTION="
for /f "usebackq delims=" %%L in ("%INI%") do (
  set "LINE=%%L"
  call :PARSE_LINE_MODS
)
exit /b 0

:PARSE_LINE_MODS
set "L=!LINE!"
for /f "tokens=* delims= " %%Z in ("!L!") do set "L=%%Z"
if "!L!"=="" exit /b 0
if "!L:~0,1!"==";" exit /b 0
if "!L:~0,1!"=="#" exit /b 0

if "!L:~0,1!"=="[" (
  set "SECTION=!L!"
  exit /b 0
)

if /I "!SECTION!" NEQ "[mods]" exit /b 0

for /f "tokens=1,* delims==" %%A in ("!L!") do (
  set "K=%%A"
  set "V=%%B"
  call :TRIM K
  call :TRIM V

  :: K dạng: 1.name / 1.url
  for /f "tokens=1,2 delims=." %%i in ("!K!") do (
    set "IDX=%%i"
    set "KEY=%%j"
  )

  if not defined IDX exit /b 0
  if not defined KEY exit /b 0

  for /f "delims=0123456789" %%X in ("!IDX!") do (
    rem nếu IDX có ký tự không phải số -> bỏ
    exit /b 0
  )

  if /I "!KEY!"=="name" set "MOD_NAME_!IDX!=!V!"
  if /I "!KEY!"=="url"  set "MOD_URL_!IDX!=!V!"
)
exit /b 0

:TRIM
set "%~1=!%~1: =!"
exit /b 0
