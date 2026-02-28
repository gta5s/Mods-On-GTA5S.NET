@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

:: ===================== CONFIG (CHI DOI 3 DONG) =====================
set "APP_NAME=GTA5S"
set "APP_EXE=GTA5S.exe"
set "APP_MANIFEST=GTA5S.VisualElementsManifest.xml"
:: ==================================================================

title %APP_NAME% Cài đặt Mod nhanh trên GTA5S - Install Mods on GTA5S (Coded by KayC)
color A

echo(
echo %APP_NAME% Cài đặt Mod trên GTA5S - Install Mods on GTA5S (Coded by KayC)
echo(
echo "   ____ _____  _    ____ ____   _   _ _____ _____ "
echo "  / ___|_   _|/ \  | ___/ ___| | \ | | ____|_   _| "
echo " | |  _  | | / _ \ |___ \___ \ |  \| |  _|   | | "
echo " | |_| | | |/ ___ \ ___) |__) || |\  | |___  | | "
echo "  \____| |_/_/   \_\____/____(_)_| \_|_____| |_| "
echo(

set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"

:: ============================================================
:: ===================== MOD LIST (DEFAULT) ====================
:: (Sẽ bị override nếu tải được mods.ini online)
set "MOD_NAME_1=Mod bầu trời"
set "MOD_URL_1=https://github.com/gta5s/Mods-On-GTA5S.NET/raw/refs/heads/main/GTA5VN_Graphic_FPS.rpf"

set "MOD_NAME_2=Mod tiếng súng"
set "MOD_URL_2=https://github.com/gta5s/Mods-On-GTA5S.NET/raw/refs/heads/main/GTA5VN_Graphic_FPS.rpf"

set "MOD_NAME_3=Mod ... (them tiep)"
set "MOD_URL_3=https://example.com/mods/other.rpf"
:: ============================================================

:: ============================================================
:: =============== LOAD MODS ONLINE (mods.ini) =================
:: Bạn đổi URL này đúng repo của bạn
set "MODS_INI_URL=https://raw.githubusercontent.com/gta5s/Mods-On-GTA5S.NET/main/online/mods.ini"
set "MODS_INI_TMP=%TEMP%\GTA5S_mods.ini"

del /f /q "%MODS_INI_TMP%" >nul 2>&1
"%PS%" -NoProfile -ExecutionPolicy Bypass -Command ^
  "$u='%MODS_INI_URL%'; $o='%MODS_INI_TMP%';" ^
  "try{ [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13;" ^
  "Invoke-WebRequest -Uri $u -OutFile $o -UseBasicParsing -EA Stop; exit 0 }catch{ exit 1 }" >nul 2>&1

if exist "%MODS_INI_TMP%" (
  call :LOAD_MODS_INI "%MODS_INI_TMP%"
  del /f /q "%MODS_INI_TMP%" >nul 2>&1
)
:: ============================================================


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
echo ==========================================
echo        %APP_NAME% - MOD INSTALLER BY KAYC
echo ==========================================
echo(
echo 0. Cài đặt tất cả mods bên dưới trên GTA5S ⭐
echo(

set "HAS_ANY="
for /L %%I in (1,1,99) do (
  set "U=!MOD_URL_%%I!"
  if defined U (
    set "N=!MOD_NAME_%%I!"
    if not defined N set "N=Mod so %%I"
    echo %%I. !N!
    set "HAS_ANY=1"
  )
)

if not defined HAS_ANY (
  echo [!] Chua co mod nao (MOD_URL_x trống). Kiem tra mods.ini / MOD LIST.
  echo(
)

echo(
echo X. Thoát
echo(
set "CH="
set /p "CH=Lựa chọn mod muốn cài đặt trên GTA5S (Nhập số tương ứng và bấm ENTER): "

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

:: Validate số và mod tồn tại
set "SEL_URL=!MOD_URL_%CH%!"
if not defined SEL_URL (
  echo(
  echo Lựa chọn không hợp lệ hoặc mod không tồn tại. Thử lại...
  timeout /t 2 >nul
  goto :MENU
)

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


:: ===================== HEADER FOR INSTALL SCREEN =====================
:PRINT_HEADER
echo(
echo "   ____ _____  _    ____ ____   _   _ _____ _____ "
echo "  / ___|_   _|/ \  | ___/ ___| | \ | | ____|_   _| "
echo " | |  _  | | / _ \ |___ \___ \ |  \| |  _|   | | "
echo " | |_| | | |/ ___ \ ___) |__) || |\  | |___  | | "
echo "  \____| |_/_/   \_\____/____(_)_| \_|_____| |_| "
echo(
exit /b 0


:: ===================== LOAD MODS.INI =====================
:: format:
:: MOD_NAME_1=abc
:: MOD_URL_1=https://...
:LOAD_MODS_INI
set "F=%~1"
if not exist "%F%" exit /b 0

:: Clear old mods (1..99) trước khi load để hỗ trợ xoá mod online
for /L %%I in (1,1,99) do (
  set "MOD_NAME_%%I="
  set "MOD_URL_%%I="
)

for /f "usebackq delims=" %%L in ("%F%") do (
  set "LINE=%%L"
  if not "!LINE!"=="" (
    if "!LINE:~0,1!"==";" (
      rem comment
    ) else if "!LINE:~0,1!"=="#" (
      rem comment
    ) else (
      for /f "tokens=1,* delims==" %%A in ("!LINE!") do (
        set "K=%%A"
        set "V=%%B"
        if defined K (
          set "!K!=!V!"
        )
      )
    )
  )
)
exit /b 0


:: ===================== INSTALL ALL =====================
:INSTALL_ALL
set "OK=0"
set "FAIL=0"
echo(
echo Đang cài đặt tất cả mods trên GTA5S ...

for /L %%I in (1,1,99) do (
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

set "DL_DIR=%TEMP%\GTA5S_MODS_DL"
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

echo [OK] Đã cài đặt thành công: "!MNAME!" trên GTA5S
exit /b 0


:: ===================== AFTER INSTALL =====================
:AFTER_INSTALL
echo(
choice /c YN /m "Bạn có muốn vào game GTA5S ngay không? (Bấm Y để vào game / Bấm N để quay lại MENU Mods tiếp)"
if errorlevel 2 goto :MENU

start "" "%GAME_DIR%\%APP_EXE%"
echo(
echo Đang mở %APP_NAME%. Tự động đóng sau 5 giây ...
timeout /t 5 >nul
exit /b 0
