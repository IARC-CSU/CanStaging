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
%zx% a -tzip CanStaging-Setup.zip *.exe
cd ..

REM make zip file
%zx% a -tzip CanStaging.zip CanStaging.exe
%zx% a -tzip CanStaging.zip launch.bat
%zx% a -tzip CanStaging.zip loader.html
%zx% a "-xr!logg.db" -tzip CanStaging.zip data
%zx% a -tzip CanStaging.zip i18n
%zx% a -tzip CanStaging.zip public
%zx% a -tzip CanStaging.zip Tables
%zx% a -tzip CanStaging.zip changelog.md
move CanStaging.zip dist
