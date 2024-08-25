fx_version 'cerulean'
game 'gta5'

shared_scripts {
    'config.lua'
}

client_scripts {
    'PolyZone/client.lua',       
    'PolyZone/BoxZone.lua',        
    'PolyZone/CircleZone.lua',   
    'PolyZone/ComboZone.lua',      
    'PolyZone/EntityZone.lua',    
    'PolyZone/PolyZone.lua',       
    'lua/client/cam.lua',            
    'lua/client/main.lua'           
}

server_scripts {
    'creation/server/*.lua',
    'PolyZone/server.lua',
    'lua/server/cacheFile.lua',
}

ui_page 'html/index.html'

files {
    'html/*.png',
    'html/*.js',
    'html/*.css',
    'html/*.html',
    'js/jquery-3.7.1.min.js',
}