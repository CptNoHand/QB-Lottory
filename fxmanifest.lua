fx_version 'cerulean'
game 'gta5'
version '0.0.1'

Author 'GNRL Tailya'
Description  'A lottery Ticket system for QB based servers'

shared_script 'config.lua'
client_script 'client.lua'
server_script {
    'server.lua',
    '@oxmysql/lib/MySQL.lua'
}

lua54 'yes'