/*
    Police.lua, en este archivo se definen los NPCs relacionados con la policía.
    Estos NPCs pueden ofrecer diferentes servicios y diálogos a los jugadores que son miembros de la policía.
    El archivo contiene una tabla que define las propiedades y comportamientos de cada NPC policial.
*/

return {
    { --  MÉDICO COMISARIA
		npc ='s_m_m_doctor_01',
		anim = {
			animDictionary = 'abigail_mcs_1_concat-0',
			animationName = 'exportcamera-0',
			blendInSpeed = 8.0,
			blendOutSpeed = 0.0,
			duration = -1,
			flag = 1,
			playbackRate = 0,
			lockX = 0,
			lockY = 0,
			lockZ = 0,
		},
		uiText = 'Dr. Morgan',                                                        
		dialog = 'Buenas, ¿Necesitas asistencia médica?',                                                
		coordinates = vector3(472.30, -987.83, 25.21),
		heading = 265.15,                                                 
		options = {                                                            
			{'<i class="fa-solid fa-bed-pulse"></i>Necesito tratamiento', 'medical:ilegal', 'c'},
		},
	},

    { -- IDENTIFICACIONES POLICIA
		blip = true,
		blipType = 498,
		blipText = 'Identificaciones',
		blipColor = 15,
		blipScale = 0.6,
		npc ='s_m_y_cop_01',                                                     
		anim = {                                                            
			animDictionary = 'amb@world_human_golf_player@male@base',
			animationName = 'base', 
			blendInSpeed = 8.0,
			blendOutSpeed = 0.0,
			duration = -1,
			flag = 1,
			playbackRate = 0,
			lockX = 0,
			lockY = 0,
			lockZ = 0,
		},
		uiText = 'Elliot Alderson',                                                
		dialog = '¿En qué puedo ayudarte?',                                                        
		coordinates = vector3(441.19, -981.96, 29.69),
		heading = 114.47,                                                
		options = {
			{'Hablar con un agente', 'police:talk', 'c'},
			{'Comprar identificacion', 'RevoCardID:buy', 'c'},
			{'Cambiar foto de identificacion', 'RevoCardID:changePhoto', 'c'},
		},
	},
}