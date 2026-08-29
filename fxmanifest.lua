fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'DJFIVEM-Battlepass'
author 'DJFIVEM'
description 'Chapter 1 Season 1 battle pass — 28 XP tiers, 30-day season, F12 to open'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/framework.lua',
    'server/main.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/icons/*.svg',
    'html/icons/*.png',
    'html/icons/*.webp'
}

-- Optional: oxmysql. The resource falls back to data/players.json if it is missing.
-- dependency 'oxmysql'
