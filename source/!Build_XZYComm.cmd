@echo off
set /a _Debug=0
::==========================================
:: Get Administrator Rights
set _Args=%*
if "%~1" NEQ "" (
  set _Args=%_Args:"=%
)
fltmc 1>nul 2>nul || (
  cd /d "%~dp0"
  cmd /u /c echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/k cd ""%~dp0"" && ""%~dpnx0"" ""%_Args%""", "", "runas", 1 > "%temp%\GetAdmin.vbs"
  "%temp%\GetAdmin.vbs"
  del /f /q "%temp%\GetAdmin.vbs" 1>nul 2>nul
  exit
)
::==========================================
@shift /0
CLS

@COLOR b
@echo off
chcp 65001 >nul
echo ***************************************************
echo Building XzyComm Components 3
echo ***************************************************

rem ****************************************************************************
rem **** IMPORTANT NOTES *******************************************************
rem ****************************************************************************

rem     DO NOT MOVE THIS FILE!
rem     THIS COMMAND FILE MUST BE LOCATED IN THE SOURCE DIRECTORY FOR YOUR
rem     INSTALLATION OF XZYComm COMPONENTS 3.
rem
rem     e.g. C:\Program Files (x86)\Embarcadero\Studio\22.0\ThirdParty\XzyComm\Source
                         

rem     ALL APPLICATIONS THAT USE THE  XZYComm COMPONENTS 3 RUNTIME PACKAGES
rem     (INCLUDING DELPHI AND RAD STUDIO) MUST BE SHUT DOWN BEFORE REBUILDING 
rem     THE COMPONENTS.


rem ****************************************************************************
rem **** SET CONFIGURATION VARIABLES *******************************************
rem **** 设置配置变量 *********************************************************
rem ****************************************************************************

rem     Uncomment the following goto statement after you have initialized the
rem     Configuration Variables.
rem 	在你初始化了配置变量后，取消对以下goto语句的注释。
rem
goto InitComplete

echo.
echo Build Configuration Variables have not been initialized.  
echo. 该文件没有进行初始化修改，请打开文件，按说明进行修改
echo.
echo Before you can execute this command file to rebuild XzyComm Components 3,
echo you must initialize a few configuration variables.  Simply edit the
echo !Build_XzyComm3.cmd file with a text editor and follow the instructions in the
echo SET CONFIGURATION VARIABLES section. 
echo.
echo Once the configuration variables have been initialized and the
echo !Build_XzyComm3.cmd saved, you can simply run !Build_XzyComm3.cmd file to rebuild
echo xzyComm Components 3.3
echo.
echo 在你执行这个命令文件来重建XzyComm Components 3,
echo 你必须初始化一些配置变量。 只要用文本编辑器编辑
echo !"Build_XzyComm3.cmd "文件，并按照设置配置变量一节的说明操作。
echo.
echo 一旦配置变量被初始化并且!Build_XzyComm3.cmd保存后，你可以简单地
echo 运行!Build_XzyComm3.cmd文件来重新构建 xzyComm Components 3.3
echo 重建后，在Delphi环境中设置好源路径，然后加载控件 Compoent->install Packages->Add...
echo 选择出编译好的，在Delphi系统Bin目录中的 XZYComm???.bpl 即可完成控件的加载。
echo.
pause
exit

:InitComplete


rem     Set the SysPath32 variable to the path of your Windows System folder
rem     for 32-bit DLLs.
rem
rem     32-bit Windows    Usually C:\Windows\System32
rem
rem     64-bit Windows    Usually C:\Windows\SysWOW64

set SysPath32=C:\Windows\SysWOW64

rem 	Set DelphiPath variable to the path of your Delphi System folder
set DelphiPath=C:\Program Files (x86)

set SysPath64=C:\Windows\System32

rem     Set VCLVersion to match version of Delphi/RAD Studio you are using:
rem     设置VCLVersion为正确的版本，请对应你的Delphi版本
rem 
rem     RAD Studio RX11   (Delphi RX11)     VCLVersion=28	Path="Studio\22.0"
rem     RAD Studio RX10.4 (Delphi RX10.4)   VCLVersion=27	Path="Studio\21.0"
rem     RAD Studio RX10.3 (Delphi RX10.3)   VCLVersion=26	Path="Studio\20.0"
rem     RAD Studio RX10.2 (Delphi RX10.2)   VCLVersion=25	Path="Studio\19.0"
rem     RAD Studio RX10.1 (Delphi RX10.1)   VCLVersion=24	Path="Studio\18.0"
rem     RAD Studio RX10   (Delphi RX10)     VCLVersion=23	Path="Studio\17.0"
rem     RAD Studio XE8    (Delphi XE8)      VCLVersion=22	Path="Studio\16.0"
rem     RAD Studio XE7    (Delphi XE7)      VCLVersion=21	Path="Studio\15.0"
rem     RAD Studio XE6    (Delphi XE6)      VCLVersion=20	Path="Studio\14.0"
rem     RAD Studio XE5    (Delphi XE5)      VCLVersion=19	Path="RAD Studio\12.0"
rem     RAD Studio XE4    (Delphi XE4)      VCLVersion=18	Path="RAD Studio\11.0"
rem     RAD Studio XE3    (Delphi XE3)      VCLVersion=17	Path="RAD Studio\10.0"
rem     RAD Studio XE2    (Delphi XE2)      VCLVersion=16	Path="RAD Studio\9.0"
rem     RAD Studio XE     (Delphi XE)       VCLVersion=15	Path="RAD Studio\8.0"
rem     RAD Studio 2010   (Delphi 2010)     VCLVersion=14	Path="RAD Studio\7.0"
rem     RAD Studio 2009   (Delphi 2009)     VCLVersion=12	Path=""
rem     RAD Studio 2007 	(Delphi 2007)    	VCLVersion=11   RS 2007 & BDS 2006 use same VCL
rem     RAD Studio 2006 	(Delphi 2006)    	VCLVersion=10   RS 2007 & BDS 2006 use same VCL
rem     BDS 2006                         		VCLVersion=10
rem     Delphi 2005                      		VCLVersion=9
rem     Delphi 7                         		VCLVersion=7	Path="Borland\Delphi7"

set VCLVersion=28

if %VCLVersion% == 7 set ProgPath=Borland\Delphi7
if %VCLVersion% == 9 set ProgPath=Borland\Delphi2005
if %VCLVersion% == 10 set ProgPath=Borland\Delphi2006
if %VCLVersion% == 12 set ProgPath=Embarcadero\
if %VCLVersion% == 14 set ProgPath=Embarcadero\RAD Studio\7.0
if %VCLVersion% == 15 set ProgPath=Embarcadero\RAD Studio\8.0
if %VCLVersion% == 16 set ProgPath=Embarcadero\RAD Studio\9.0
if %VCLVersion% == 17 set ProgPath=Embarcadero\RAD Studio\10.0
if %VCLVersion% == 18 set ProgPath=Embarcadero\RAD Studio\11.0
if %VCLVersion% == 19 set ProgPath=Embarcadero\RAD Studio\12.0
if %VCLVersion% == 20 set ProgPath=Embarcadero\Studio\14.0
if %VCLVersion% == 21 set ProgPath=Embarcadero\Studio\15.0
if %VCLVersion% == 22 set ProgPath=Embarcadero\Studio\16.0
if %VCLVersion% == 23 set ProgPath=Embarcadero\Studio\17.0
if %VCLVersion% == 24 set ProgPath=Embarcadero\Studio\18.0
if %VCLVersion% == 25 set ProgPath=Embarcadero\Studio\19.0
if %VCLVersion% == 26 set ProgPath=Embarcadero\Studio\20.0
if %VCLVersion% == 27 set ProgPath=Embarcadero\Studio\21.0
if %VCLVersion% == 28 set ProgPath=Embarcadero\Studio\22.0

rem     Set the DCC32EXE variable to the full path of the 32-bit command line
rem     compiler (DCC32.exe) located in your Delphi/RAD Studio Bin directory.

rem set DCC32EXE="C:\Program Files (x86)\Embarcadero\Studio\15.0\Bin\DCC32.exe"
set DCC32EXE="%DelphiPath%\%ProgPath%\Bin\DCC32.exe"

rem     If you are using RAD Studio XE2 or greater, set the DCC64EXE 
rem     variable to the full path of the 64-bit command line compiler 
rem     (DCC64.exe) located in your RAD Studio Bin directory.

rem set DCC64EXE="C:\Program Files (x86)\Embarcadero\Studio\15.0\Bin\DCC64.exe"
set DCC64EXE="%DelphiPath%\%ProgPath%\Bin\DCC64.exe"

rem ****************************************************************************
rem **** DO NOT CHANGE ANYTHING BELOW THIS POINT *******************************
rem ****************************************************************************
rem 下面的代码都不要轻易修改

net session >nul 2>&1
if errorlevel 1 goto Adminerror

rem Enter the current directory in administrator mode
cd /d %~dp0

if %VCLVersion% == 7 goto Version7
if %VCLVersion% == 9 goto Version9
if %VCLVersion% == 10 goto Version10

if %VCLVersion% == 12 goto Version12
if %VCLVersion% == 14 goto Version14
if %VCLVersion% == 15 goto Version15
if %VCLVersion% == 16 goto Version16
if %VCLVersion% == 17 goto Version17
if %VCLVersion% == 18 goto Version18
if %VCLVersion% == 19 goto Version19
if %VCLVersion% == 20 goto Version20
if %VCLVersion% == 21 goto Version21
if %VCLVersion% == 22 goto Version22
if %VCLVersion% == 23 goto Version23
if %VCLVersion% == 24 goto Version24
if %VCLVersion% == 25 goto Version25
if %VCLVersion% == 26 goto Version26
if %VCLVersion% == 27 goto Version27
if %VCLVersion% == 28 goto Version28
echo Invalid VCL Version %VCLVersion%
goto Error

rem ============================================================================
:Version7

set IDE_Name=Delphi 7
set PkgSuffix=70

set LibDir32=D7
set LibDir64=
set Compile64bit=False
set UnitScopeNames=

goto Init

rem ============================================================================
:Version9

set IDE_Name=Delphi 2005
set PkgSuffix=90

set LibDir32=D2005
set LibDir64=
set Compile64bit=False
set UnitScopeNames=

goto Init

rem ============================================================================
:Version10              

set IDE_Name=Borland Developer Studio 2006
set PkgSuffix=100

set LibDir32=BDS2006
set LibDir64=
set Compile64bit=False
set UnitScopeNames=

goto Init
rem ============================================================================
:Version12

set IDE_Name=RAD Studio 2009
set PkgSuffix=120

set LibDir32=RS2009
set LibDir64=
set Compile64bit=False
set UnitScopeNames=

goto Init

rem ============================================================================
:Version14

set IDE_Name=RAD Studio 2010
set PkgSuffix=140

set LibDir32=RS2010
set LibDir64=
set Compile64bit=False
set UnitScopeNames=

goto Init


rem ============================================================================
:Version15

set IDE_Name=RAD Studio XE
set PkgSuffix=150

set LibDir32=RS-XE
set LibDir64=
set Compile64bit=False
set UnitScopeNames=

goto Init


rem ============================================================================
:Version16

set IDE_Name=RAD Studio XE2
set PkgSuffix=160

set LibDir32=RS-XE2\Win32
set LibDir64=RS-XE2\Win64
set Compile64bit=True
set UnitScopeNames=-NSSystem;System.Win;Winapi;Vcl;Vcl.Imaging;Data;

goto Init


rem ============================================================================
:Version17

set IDE_Name=RAD Studio XE3
set PkgSuffix=170

set LibDir32=RS-XE3\Win32
set LibDir64=RS-XE3\Win64
set Compile64bit=True
set UnitScopeNames=-NSSystem;System.Win;Winapi;Vcl;Vcl.Imaging;Data;

goto Init


rem ============================================================================
:Version18

set IDE_Name=RAD Studio XE4
set PkgSuffix=180

set LibDir32=RS-XE4\Win32
set LibDir64=RS-XE4\Win64
set Compile64bit=True
set UnitScopeNames=-NSSystem;System.Win;Winapi;Vcl;Vcl.Imaging;Data;

goto Init


rem ============================================================================
:Version19

set IDE_Name=RAD Studio XE5
set PkgSuffix=190

set LibDir32=RS-XE5\Win32
set LibDir64=RS-XE5\Win64
set Compile64bit=True
set UnitScopeNames=-NSSystem;System.Win;Winapi;Vcl;Vcl.Imaging;Data;

goto Init


rem ============================================================================
:Version20

set IDE_Name=RAD Studio XE6
set PkgSuffix=200

set LibDir32=RS-XE6\Win32
set LibDir64=RS-XE6\Win64
set Compile64bit=True
set UnitScopeNames=-NSSystem;System.Win;Winapi;Vcl;Vcl.Imaging;Data;

goto Init


rem ============================================================================
:Version21

set IDE_Name=RAD Studio XE7
set PkgSuffix=210

set LibDir32=RS-XE7\Win32
set LibDir64=RS-XE7\Win64
set Compile64bit=True
set UnitScopeNames=-NSSystem;System.Win;Winapi;Vcl;Vcl.Imaging;Data;

goto Init


rem ============================================================================
:Version22

set IDE_Name=RAD Studio XE8
set PkgSuffix=220

set LibDir32=RS-XE8\Win32
set LibDir64=RS-XE8\Win64
set Compile64bit=True
set UnitScopeNames=-NSSystem;System.Win;Winapi;Vcl;Vcl.Imaging;Data;

goto Init


rem ============================================================================
:Version23

set IDE_Name=RAD Studio RX10
set PkgSuffix=230

set LibDir32=RX10\Win32
set LibDir64=RX10\Win64
set Compile64bit=True
set UnitScopeNames=-NSSystem;System.Win;Winapi;Vcl;Vcl.Imaging;Data;

goto Init


rem ============================================================================
:Version24

set IDE_Name=RAD Studio RX10.1
set PkgSuffix=240

set LibDir32=RX10.1\Win32
set LibDir64=RX10.1\Win64
set Compile64bit=True
set UnitScopeNames=-NSSystem;System.Win;Winapi;Vcl;Vcl.Imaging;Data;

goto Init


rem ============================================================================
:Version25

set IDE_Name=RAD Studio RX10.2
set PkgSuffix=250

set LibDir32=RX10.2\Win32
set LibDir64=RX10.2\Win64
set Compile64bit=True
set UnitScopeNames=-NSSystem;System.Win;Winapi;Vcl;Vcl.Imaging;Data;

goto Init

rem ============================================================================
:Version26

set IDE_Name=RAD Studio RX10.3
set PkgSuffix=260

set LibDir32=RX10.3\Win32
set LibDir64=RX10.3\Win64
set Compile64bit=True
set UnitScopeNames=-NSSystem;System.Win;Winapi;Vcl;Vcl.Imaging;Data;

goto Init

rem ============================================================================
:Version27

set IDE_Name=RAD Studio RX10.4
set PkgSuffix=270

set LibDir32=RX10.4\Win32
set LibDir64=RX10.4\Win64
set Compile64bit=True
set UnitScopeNames=-NSSystem;System.Win;Winapi;Vcl;Vcl.Imaging;Data;

goto Init

rem ============================================================================
:Version28

set IDE_Name=RAD Studio RX11
set PkgSuffix=280

set LibDir32=RX11\Win32
set LibDir64=RX11\Win64
set Compile64bit=True
set UnitScopeNames=-NSSystem;System.Win;Winapi;Vcl;Vcl.Imaging;Data;

goto Init

rem ============================================================================
:Init

set Options=-LUDclStd

set DCC32=%DCC32EXE% -Q -W -H %UnitScopeNames% -$D- -$L- -$Y-
set DCC64=%DCC64EXE% -Q -W -H %UnitScopeNames% -$D- -$L- -$Y-

set ND_RTP=XZYComm
set ND_RTP_BPL=XZYComm%PkgSuffix%.bpl


set ND_RegFile=XZYComm.pas


rem ============================================================================
:PathSetup

set LibPath32=..\Lib\%LibDir32%
set LibPath64=..\Lib\%LibDir64%
set BinPath=..\Bin
set ProgBinPath="%DelphiPath%\%ProgPath%\Bin"
set DeployPath32=..\Deploy\Win32
set DeployPath64=..\Deploy\Win64

if not exist %LibPath32% md %LibPath32%
if not exist %DeployPath32% md %DeployPath32%
if not exist %BinPath% md %BinPath%
if not exist %LibPath64% md %LibPath64%
if not exist %DeployPath64% md %DeployPath64%

goto Build


rem ============================================================================
rem ==== Build Processing Section ==============================================
rem ============================================================================

:Build

echo.
echo #### %IDE_Name% : 32-bit ############
echo.
echo Compiling %ND_RegFile% File...
echo.
%DCC32% -B %Options% %ND_RegFile%
if errorlevel 1 goto error

echo.
echo Compiling %ND_RTP%.dpk Package...
echo.
%DCC32% -B -jl -LN. %ND_RTP%.dpk
%DCC32% -jl -LN. %ND_RTP%.dpk
if errorlevel 1 goto error
echo.



echo.
echo Deleting Unnecessary Package DCU, HPP, and LIB files...
if %VCLVersion% GEQ 16 goto SkipDeleting32bitPkgDcus
del %ND_RTP%.dcu > nul

:SkipDeleting32bitPkgDcus


echo.
echo Copying Build Files to %LibPath32% and %DeployPath32% ,%SysPath32%,%BinPath% ,%ProgBinPath% ...

copy "*.dcu" %LibPath32% > nul
copy "*.dcr" %LibPath32% > nul
copy "*.res" %LibPath32% > nul
copy "*.hpp" %LibPath32% > nul
copy "*.lib" %LibPath32% > nul

copy %ND_RTP%.dcp %LibPath32% > nul
copy %ND_RTP%.bpi %LibPath32% > nul
copy %ND_RTP%.hpp %LibPath32% > nul
copy %ND_RTP_BPL% %DeployPath32% > nul
copy %ND_RTP_BPL% %SysPath32% > nul
copy %ND_RTP_BPL% %BinPath% > nul
copy %ND_RTP_BPL% %ProgBinPath% > nul


if "%Compile64bit%" == "False" goto SkipCompile64bit
echo.
echo #### %IDE_Name% : 64-bit ############
echo.
echo Compiling %ND_RegFile% File...
echo.
rem %DCC64% -B %Options% %ND_RegFile%
%DCC64% -B -jl %ND_RegFile%
if errorlevel 1 goto error

echo.
echo Compiling %ND_RTP%.dpk Package...
echo.
%DCC64% -B -jl -LN. %ND_RTP%.dpk
%DCC64% -jl -LN. %ND_RTP%.dpk
if errorlevel 1 goto error
echo.


echo.
if %VCLVersion% GEQ 16 goto SkipDeleting64bitPkgDcus
echo Deleting Unnecessary Package DCU files...
del %ND_RTP%.dcu > nul 2>nul

:SkipDeleting64bitPkgDcus


echo.
echo Copying Build Files to %LibPath64% and %DeployPath64% ,%SysPath64% ...

copy "*.dcu" %LibPath64% > nul
copy "*.dcr" %LibPath64% > nul
copy "*.res" %LibPath64% > nul

if %VCLVersion% LEQ 16 goto SkipCopy64bitHppAFiles
rem XE2 does not support 64-bit C++, so only copy *.hpp and *.a files for XE3 or later
copy "*.hpp" %LibPath64% > nul
copy "*.a" %LibPath64% > nul
:SkipCopy64bitHppAFiles

copy %ND_RTP%.dcp %LibPath64% > nul
copy %ND_RTP%.bpi %LibPath64% > nul
copy %ND_RTP%.hpp %LibPath64% > nul
copy %ND_RTP_BPL% %DeployPath64% > nul
copy %ND_RTP_BPL% %SysPath64% > nul

:SkipCompile64bit


goto Success


rem ============================================================================
:Success
echo.
echo Build was Successful.
goto end

:Adminerror
echo.
echo ERROR: Please run !Build_XZYComm.cmd in Administrator mode!

rem ============================================================================
:error
echo.
echo **ERROR**

rem ============================================================================
:end
del *.dcu > nul 2>nul
del *.lib > nul 2>nul
del *.hpp > nul 2>nul
del *.bpi > nul 2>nul
del *.a > nul 2>nul
del *.bpl > nul 2>nul
del *.dcp > nul 2>nul

pause
exit
