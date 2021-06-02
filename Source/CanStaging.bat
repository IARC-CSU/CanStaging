echo "Starting CanStaging+ -- Please wait." 
START /min "CanStaging+" .\bin\CanStaging.exe
rundll32 url.dll,FileProtocolHandler .\loader.html
