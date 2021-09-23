REM Build changelog html
REM python -m markdown changelog.md > public\changelog.html

REM Build executable
ocra --icon gfx\logo.ico --output server.exe --gem-full --gemfile Gemfile WebService.rb views/*