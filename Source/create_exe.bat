REM Build changelog html
REM python -m markdown changelog.md > public\changelog.html

REM Build executable
ocra --icon gfx\logo.ico --output bin\server.exe --gemfile Gemfile WebService.rb views/*