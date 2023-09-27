fx_version 'cerulean'

game 'gta5'
author 'ESX-Framework'
description 'Official Multicharacter System For ESX Legacy. Redesigned to ox_lib and cam by CX-SCRIPTS'
version '1.10.1'
lua54 'yes'

dependencies { 'es_extended', 'ox_lib', 'esx_identity' }

shared_scripts { '@es_extended/imports.lua', '@es_extended/locale.lua', '@ox_lib/init.lua', 'locales/*.lua', 'config.lua' }

server_scripts { '@oxmysql/lib/MySQL.lua', 'server/*.lua' }

client_scripts { 'client/*.lua' }

ui_page { 'html/ui.html' }

files { 'html/ui.html', 'html/css/main.css', 'html/js/app.js', 'html/locales/*.js' }
