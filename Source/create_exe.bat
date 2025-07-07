REM Build changelog html
REM python -m markdown changelog.md > public\changelog.html

REM Build executable
REM ocra --icon gfx\logo.ico --output server.exe --add-all-core --gem-full --gemfile Gemfile --dll ruby_builtin_dlls\libssp-0.dll --dll ruby_builtin_dlls\libgmp-10.dll --dll ruby_builtin_dlls\libgcc_s_seh-1.dll --dll ruby_builtin_dlls\libwinpthread-1.dll WebService.rb views/*
ocra --icon gfx\logo.ico --output server.exe --add-all-core --gem-full --gemfile Gemfile --dll ruby_builtin_dlls\libcrypto-1_1-x64.dll --dll ruby_builtin_dlls\libffi-7.dll --dll ruby_builtin_dlls\libgcc_s_seh-1.dll --dll ruby_builtin_dlls\libgmp-10.dll --dll ruby_builtin_dlls\libssl-1_1-x64.dll --dll ruby_builtin_dlls\libssp-0.dll --dll ruby_builtin_dlls\libwinpthread-1.dll --dll ruby_builtin_dlls\libyaml-0-2.dll --dll ruby_builtin_dlls\ruby_builtin_dlls.manifest --dll ruby_builtin_dlls\zlib1.dll WebService.rb views/*
