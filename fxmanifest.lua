fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

description 'rsg-horses'
version '2.3.1'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/functions.lua',
    'shared/wildhorse_config.lua',
}

client_scripts {
    'client/coat.lua',
    'client/client.lua',
    'client/npcs.lua',
    'client/horses.lua',
    'client/showroom.lua',
    'client/action.lua',
    'client/horseinfo.lua',
    'client/dataview.lua',
    'client/wildhorse.lua'
}

files {
    'shared/horse_settings.lua',
    'shared/horse_comp.lua',
    'locales/*.json',
    'html/index.html',
    'html/style.css',
    'html/script.js',
	'html/icons/*.png',
}

ui_page 'html/index.html'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/webhooks.lua',
    'server/server.lua',
    'server/wildhorse.lua',
    'server/versionchecker.lua'
}

dependencies {
    'rsg-core',
    'ox_lib',
}

lua54 'yes'

export 'CheckHorseLevel'
export 'CheckHorseBondingLevel'
export 'CheckActiveHorse'
