@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

:: Tham so tu Launcher:
:: %1=APP_NAME %2=APP_EXE %3=APP_MANIFEST %4=CACHE_ROOT %5=CACHE_DIR %6=MODS_LIST_PATH
set "APP_NAME=%~1"
set "APP_EXE=%~2"
set "APP_MANIFEST=%~3"
set "CACHE_ROOT=%~4"
set "CACHE_DIR=%~5"
set "MODS_LIST=%~6"

if "%APP_NAME%"=="" set "APP_NAME=GTA5S"
if "%APP_EXE%"=="" set "APP_EXE=GTA5S.exe"
if "%APP_MANIFEST%"=="" set "APP_MANIFEST=GTA5S.VisualElementsManifest.xml"

title %APP_NAME% Cài đặt Mod nhanh - Install Mods (Coded by KayC)
color A

echo(
echo %APP_NAME% Cài đặt Mod - Install Mods (Coded by KayC)
echo(
echo "   ____ _____  _    ____ ____   _   _ _____ _____ "
echo "  / ___|_   _|/ \  | ___/ ___| | \ | | ____|_   _| "
echo " | |  _  | | / _ \ |___ \___ \ |  \| |  _|   | | "
echo " | |_| | | |/ ___ \ ___) |__) || |\  | |___  | | "
echo "  \____| |_/_/   \_\____/____(_)_| \_|_____| |_| "
echo(

:: ===================== CACHE SAFE =====================
:: Nếu cache root không dùng được, fallback localappdata (tránh bị chặn quyền)
if not defined CACHE_DIR set "CACHE_DIR=%TEMP%\GTA5SModsCache"
if not exist "%CACHE_DIR%\" mkdir "%CACHE_DIR%" >nul 2>&1

set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"

:: ============================================================
:: ===================== MOD LIST (ONLINE) =====================
:: ============================================================
:: Format mods.list (UTF-8):
:: Ten mod|URL
:: VD:
:: Mod bầu trời|https://.../a.rpf
:: Mod tiếng súng|https://.../b.rpf

set "MOD_COUNT=0"
if exist "%MODS_LIST%" (
  for /f "usebackq delims=" %%L in ("%MODS_LIST%") do (
    set "LINE=%%L"
    if not "!LINE!"=="" (
      if /I not "!LINE:~0,1!"=="#" (
        for /f "tokens=1* delims=|" %%A in ("!LINE!") do (
          set /a MOD_COUNT+=1
          set "MOD_NAME_!MOD_COUNT!=%%A"
          set "MOD_URL_!MOD_COUNT!=%%B"
        )
      )
    )
  )
)

if %MOD_COUNT% LEQ 0 (
  echo [ERR] Khong doc duoc danh sach mods hoac danh sach rong.
  echo File: "%MODS_LIST%"
  echo Hay kiem tra mods.list tren GitHub.
  pause
  exit /b 1
)

:: ============================================================
:: ============ AUTO-DETECT GAME FOLDER (FAST, no UI) ==========
:: ============================================================
set "GAME_DIR="
set "OUT=%CACHE_DIR%\game_dir.txt"
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
echo(
echo "   ____ _____  _    ____ ____   _   _ _____ _____ "
echo "  / ___|_   _|/ \  | ___/ ___| | \ | | ____|_   _| "
echo " | |  _  | | / _ \ |___ \___ \ |  \| |  _|   | | "
echo " | |_| | | |/ ___ \ ___) |__) || |\  | |___  | | "
echo "  \____| |_/_/   \_\____/____(_)_| \_|_____| |_| "
echo(
echo(
echo ==========================================
echo        %APP_NAME% - MOD INSTALLER BY KAYC
echo ==========================================
echo(
echo 0. Cài đặt tất cả mods bên dưới trên %APP_NAME% ⭐
echo(

for /L %%I in (1,1,%MOD_COUNT%) do (
  echo %%I. !MOD_NAME_%%I!
)

echo(
echo X. Thoát
echo(
set "CH="
set /p "CH=Lựa chọn mod muốn cài đặt (Nhập số và ENTER): "

if /I "%CH%"=="X" exit /b 0

if "%CH%"=="0" (
  cls
  call :PRINT_HEADER
  echo(
  echo Bạn đã chọn: CÀI TẤT CẢ MODS
  call :INSTALL_ALL
  if errorlevel 1 (
    echo(
    echo [!] Có lỗi khi cài một số mod. Bấm phím bất kỳ để quay lại menu...
    pause >nul
    goto :MENU
  )
  goto :AFTER_INSTALL
)

:: Validate numeric selection
for /f "delims=0123456789" %%A in ("%CH%") do (
  echo(
  echo Lựa chọn không hợp lệ. Thử lại...
  timeout /t 2 >nul
  goto :MENU
)

if %CH% GEQ 1 if %CH% LEQ %MOD_COUNT% (
  cls
  call :PRINT_HEADER
  echo(
  echo Bạn đã chọn: !MOD_NAME_%CH%!
  call :INSTALL_MOD %CH%
  if errorlevel 1 (
    echo(
    echo [!] Cài mod thất bại. Bấm phím bất kỳ để quay lại menu...
    pause >nul
    goto :MENU
  )
  goto :AFTER_INSTALL
)

echo(
echo Lựa chọn không hợp lệ. Thử lại...
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


:: ===================== INSTALL ALL =====================
:INSTALL_ALL
set "OK=0"
set "FAIL=0"
echo(
echo Đang cài đặt tất cả mods trên %APP_NAME% ...

for /L %%I in (1,1,%MOD_COUNT%) do (
  set "U=!MOD_URL_%%I!"
  if defined U (
    call :INSTALL_MOD %%I
    if errorlevel 1 (set /a FAIL+=1) else (set /a OK+=1)
  )
)

echo(
echo ==========================================
echo Hoàn tất cài đặt tất cả mods:
echo Thành công: !OK!
echo Thất bại : !FAIL!
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

set "DL_DIR=%CACHE_DIR%\downloads"
if not exist "!DL_DIR!" mkdir "!DL_DIR!" >nul 2>&1

set "DL_PATH=!DL_DIR!\!MFILE!"
del /f /q "!DL_PATH!" >nul 2>&1

echo(
echo Đang tải và cài đặt: !MNAME!
echo(

"%PS%" -NoProfile -ExecutionPolicy Bypass -Command ^
  "$u='%MURL%'; $o='%DL_PATH%';" ^
  "try{ [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13; Invoke-WebRequest -Uri $u -OutFile $o -UseBasicParsing -ErrorAction Stop; exit 0 }catch{ exit 1 }" >nul 2>&1

if errorlevel 1 exit /b 1
if not exist "!DL_PATH!" exit /b 1

copy /y "!DL_PATH!" "%MODS_DIR%\" >nul
if errorlevel 1 exit /b 1

echo [OK] Đã cài đặt thành công: "!MNAME!" trên %APP_NAME%
exit /b 0


:: ===================== AFTER INSTALL =====================
:AFTER_INSTALL
echo(
choice /c YN /m "Bạn có muốn vào game %APP_NAME% ngay không? (Y=Vao game / N=Ve MENU)"
if errorlevel 2 goto :MENU

start "" "%GAME_DIR%\%APP_EXE%"
echo(
echo Đang mở %APP_NAME%. Tự động đóng sau 5 giây ...
timeout /t 5 >nul
exit /b 0
