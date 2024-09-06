fx_version 'cerulean'
game 'gta5'

author 'Paviin - Pavyn & m6rccc - Marc'
description 'Fivem Video Recording Script'
version '1.0.0'

shared_scripts {
    'config.lua',
    'locales.lua',
}

client_scripts {
    'PolyZone/client.lua',       
    'PolyZone/BoxZone.lua',        
    'PolyZone/CircleZone.lua',   
    'PolyZone/ComboZone.lua',      
    'PolyZone/EntityZone.lua',    
    'PolyZone/PolyZone.lua',       
    'lua/client/cam.lua',  
    'lua/client/controlPoint.lua',          
    'lua/client/main.lua'           
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'PolyZone/server.lua',
    'lua/server/cacheFile.lua',
    'lua/server/cameraPerms.lua',
    'lua/server/getOutfit.lua'
}

ui_page 'html/index.html'

files {
    'html/**.*',
}

dependencies { 'oxmysql' }