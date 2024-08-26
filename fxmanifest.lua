fx_version 'cerulean'
game 'gta5'

shared_scripts {
    'config.lua'
}

client_scripts {
    'PolyZone/client.lua',         -- PolyZone Hauptdatei
    'PolyZone/BoxZone.lua',        -- BoxZone
    'PolyZone/CircleZone.lua',     -- CircleZone
    'PolyZone/ComboZone.lua',      -- ComboZone
    'PolyZone/EntityZone.lua',     -- EntityZone
    'PolyZone/PolyZone.lua',       -- PolyZone Basisklasse
    'lua/client/cam.lua',            -- Dein Kamera-Skript
    'lua/client/main.lua'            -- Dein Kamera-Skript
}

server_scripts {
    'creation/server/*.lua',
    'PolyZone/server.lua'
  }