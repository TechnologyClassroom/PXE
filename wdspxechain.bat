:: PXE Chains a WDS server to secondary GNU/Linux server

:: Michael McMahon

:: Open a command prompt with Administrator privaleges. 
:: cd ..\..\Users\Administrator\Downloads
:: powershell -Command "Invoke-WebRequest ftp://10.12.17.15/pub/scripts/wdspxechain.bat -Outfile wdspxechain.bat"
:: wdspxechain.bat

:: Do not display commands
@echo off

echo Downloading syslinux 6.03...
powershell -Command "Invoke-WebRequest https://www.kernel.org/pub/linux/utils/boot/syslinux/6.xx/syslinux-6.03.zip -OutFile syslinux-6.03.zip"

echo Extracting syslinux 6.03...
powershell Expand-Archive -Path "syslinux-6.03.zip" -DestinationPath "syslinux-6.03"

echo Backing up original files...
copy D:\RemoteInstall\Boot\x64\pxeboot.com D:\RemoteInstall\Boot\x64\pxeboot.0
copy D:\RemoteInstall\Boot\x64\abortpxe.com D:\RemoteInstall\Boot\x64\abortpxe.0

echo Copying syslinux files...
copy syslinux-6.03/bios/com32/chain/chain.c32 D:\RemoteInstall\Boot\x64\
copy syslinux-6.03/bios/com32/elflink/ldlinux/ldlinux.c32 D:\RemoteInstall\Boot\x64\
copy syslinux-6.03/bios/com32/lib/libcom32.c32 D:\RemoteInstall\Boot\x64\
copy syslinux-6.03/bios/com32/menu/menu.c32 D:\RemoteInstall\Boot\x64\
copy syslinux-6.03/bios/com32/menu/vesamenu.c32 D:\RemoteInstall\Boot\x64\
copy syslinux-6.03/bios/com32/modules/pxechn.c32 D:\RemoteInstall\Boot\x64\
copy syslinux-6.03/bios/com32/libutil/libutil.c32 D:\RemoteInstall\Boot\x64\
copy syslinux-6.03/bios/core/pxelinux.0 D:\RemoteInstall\Boot\x64\

echo Creating pxelinux.cfg folder...
mkdir D:\RemoteInstall\Boot\x64\pxelinux.cfg

echo Writing pxelinux.cfg default file...
(
    echo DEFAULT menu.c32
    echo MENU TITLE WDS PXE Server
    echo PROMPT 0
    echo TIMEOUT 100 # 10 seconds
    echo MENU IMMEDIATE
    echo.
    echo LABEL wds
    echo   MENU DEFAULT
    echo   MENU LABEL ^^Windows Deployment Services ^(WDS^)
    echo   KERNEL pxeboot.0
    echo.
    echo LABEL gnulinuxpxe
    echo   MENU LABEL ^^GNU/Linux PXE Server
    echo   KERNEL pxechn.c32
    echo   APPEND 192.168.1.15::pxelinux.0
    echo.
    echo LABEL abort
    echo   MENU LABEL ^^Abort PXE
    echo   Kernel abortpxe.0
    echo.
    echo LABEL local
    echo   MENU LABEL Boot from ^^Local Computer
    echo   LOCALBOOT 0
) > D:\RemoteInstall\Boot\x64\pxelinux.cfg\default

echo Changing PXE default path...
wdsutil /set-server /bootprogram:boot\x64\pxelinux.0 /architecture:x64
wdsutil /set-server /N12bootprogram:boot\x64\pxelinux.0 /architecture:x64
