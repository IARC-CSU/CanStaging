echo off 

REM Build executable
REM create_exe.bat

REM Delete old stuff
rm dist\*.*

REM Build installer
set isxpath="C:\Program Files (x86)\Inno Setup 5"
set isx=%isxpath%\iscc.exe
set iwz=CanStagingInstaller.iss
set zippath="C:\Program Files\7-Zip"
set zx=%zippath%\7z.exe

REM if not exist %isx% set errormsg=%isx% not found && goto errorhandler
%isx% "%iwz%"
cd dist
%zx% a -tzip CanStaging-Setup.zip CanStaging-Setup.exe
cd ..