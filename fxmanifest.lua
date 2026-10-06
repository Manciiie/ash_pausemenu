fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'ash_pausemenu'
author 'ASH City'
description 'Menu pause ASH City (remplace ÉCHAP) avec bouton pour quitter la session'
version '1.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_script 'client.lua'
server_script 'server.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
}

dependencies {
    'qb-core',
    'ox_lib',
}
