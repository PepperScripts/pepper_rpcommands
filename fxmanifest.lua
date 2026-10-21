-- Pepper RP-Commands – Roleplay-Befehle mit Sprechblasen über dem Kopf (Standalone, kostenlos)
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pepper_rpcommands'
author 'Pepper Scripts'
description '/me, /do, /try, /roll, /dice, /coin, /status, /looc, /whisper and /shout with speech bubbles – standalone'
version '2.0.0'
repository 'https://github.com/PepperScripts/pepper_rpcommands'

shared_scripts {
    'config.lua',
    'shared/locale.lua',
}

client_script 'client/main.lua'

server_scripts {
    'config_server.lua',
    'server/bridge.lua',
    'server/log.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'locales/*.json',
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

-- Offener Quellcode: Wird die Ressource über das Cfx.re Portal ausgeliefert, bleibt alles lesbar und änderbar.
escrow_ignore {
    'config.lua',
    'config_server.lua',
    'client/*.lua',
    'server/*.lua',
    'shared/*.lua',
    'locales/*.json',
}
