
-- ----------------------------------------------

--   This file is part of elegresorp FiveM Server.

--   Unauthorized copying and modifying of this file via any medium
--   is strictly prohibited and protected by copyright laws. 
--   Licensed under BSD License
  
-- ----------------------------------------------  
fx_version 'adamant'
game 'gta5'
ui_page 'UIPage/ui.html'
shared_scripts {
	'Shared.lua',
	'IlegalesGeneral.lua',
	'Organizaciones.lua',
	'World.lua',
	'Police.lua',
	'Negocios.lua',
}
	
client_script 'Lua/CMain.lua'
server_script 'Lua/SMain.lua'

lua54 'yes'
files {
	'UIPage/*.*',
	'UIPage/fonts/*.*'
}