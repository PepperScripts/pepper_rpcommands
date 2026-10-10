-- Pepper RP-Commands – /me, /do, /try und /roll mit Text über dem Kopf (Standalone, kostenlos)
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pepper_rpcommands'
author 'Pepper Scripts'
description '/me, /do, /try and /roll with text above the head – standalone'
version '1.0.0'
repository 'https://github.com/PepperScripts/pepper_rpcommands'

shared_scripts {
    'config.lua',
    'shared/locale.lua',
}
client_script 'client/main.lua'
server_script 'server/main.lua'

files {
    'locales/*.json',
}

-- Offener Quellcode: Wird die Ressource über das Cfx.re Portal ausgeliefert, bleibt alles lesbar und änderbar.
escrow_ignore {
    'config.lua',
    'client/*.lua',
    'server/*.lua',
    'shared/*.lua',
    'locales/*.json',
}
