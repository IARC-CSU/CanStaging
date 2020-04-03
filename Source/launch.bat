echo "Starting CanStaging -- Please wait." 
START /min "CanStaging" .\CanStaging.exe
rundll32 url.dll,FileProtocolHandler .\loader.html
