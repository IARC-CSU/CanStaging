echo "Starting CanStaging -- Please wait." 
START "CanStaging" .\WebService.exe
rundll32 url.dll,FileProtocolHandler .\loader.html
