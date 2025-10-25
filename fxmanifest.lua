fx_version 'cerulean'
game 'gta5'

author 'Eviate'
description 'Flatbed Script'
version '1.0.1'

lua54 'yes'

files {
	'stream/flatbed.ytyp',
}

data_file 'DLC_ITYP_REQUEST' 'stream/flatbed.ytyp'

shared_scripts {
	'config.lua',
}

client_scripts {
	'client/cl_*.lua',
	'bridge/cl_bridge.lua',
}

server_scripts {
	'server/sv_*.lua',
}
