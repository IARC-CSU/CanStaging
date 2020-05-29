REM Build changelog html
python -m markdown changelog.md > public\changelog.html

REM Build executable
ocra --icon gfx\logo.ico --output CanStaging.exe --gemfile Gemfile WebService.rb views/* public/*


REM /lib/ruby/gems/2.6.0/gems/sqlite3-1.4.2/lib/sqlite3/sqlite3_native.so