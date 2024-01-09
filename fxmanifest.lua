fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

description 'rsg-horses'
version '1.0.8'

shared_scripts {
    '@ox_lib/init.lua',
    '@rsg-core/shared/locale.lua',
    'shared/horse_comp.lua',
    'locales/en.lua', -- Change this to your preferred language
    'locales/*.lua',
    'shared/config.lua',
}

client_scripts {
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    '@PolyZone/EntityZone.lua',
    '@PolyZone/CircleZone.lua',
    '@PolyZone/ComboZone.lua',
    'client/client.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua'
}

dependencies {
    'rsg-core',
    'menu_base',
    'ox_lib',
}

lua54 'yes'

export 'CheckHorseLevel'
export 'CheckHorseBondingLevel'
export 'CheckActiveHorse'
