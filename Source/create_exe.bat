REM Build changelog html
python -m markdown ..\changelog.md > public\changelog.html

REM Build executable
ocra --icon gfx\logo.ico --output CanStaging.exe --gemfile Gemfile WebService.rb views/* public/*
