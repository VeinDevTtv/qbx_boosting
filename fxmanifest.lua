fx_version 'cerulean'
game 'gta5'

author 'vein'
description 'Boosting system for QBX Framework'
version '1.0.0'

lua54 'yes'

dependencies {
    'qbx_core',
    'ox_lib',
    'oxmysql',
    'qbx_laptop'
}

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/utils.lua',
    'shared/config.lua',
    'shared/locations.lua',
    'shared/contractNames.lua',
    'shared/vehicleClasses.lua'
}

client_scripts {
    'client/main.lua',
    'client/handlers/laptop.lua',
    'client/handlers/boost.lua',
    'client/handlers/garage.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/handlers/auction.lua',
    'server/handlers/boost.lua',
    'server/handlers/contracts.lua',
    'server/handlers/db.lua',
    'server/handlers/garage.lua',
    'server/handlers/laptop.lua',
    'server/handlers/queue.lua'
}

files {
    'shared/types.lua'
} 