/*
    Organizaciones.lua, en este archivo se definen los NPCs relacionados con organizaciones.
    Estos NPCs pueden ofrecer diferentes servicios y diálogos a los jugadores que pertenecen a organizaciones.
    El archivo contiene una tabla que define las propiedades y comportamientos de cada NPC de organización.
*/

return {
    { -- MEDICO ILEGAL:  briangotti
		npc ='s_m_m_scientist_01',                                                       
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
		uiText = 'John McKiver',                                                        
		dialog = 'Solo quiero volver a ver a mi familia, te curare lo que necesites.',                                                
		coordinates =  vector3(-1336.10, -1219.51, 9.72), 
		heading = 111.21,                                                 
		options = {         
			{'<i class="fa-solid fa-syringe"></i>Curarse', 'medical:ilegal', 'c'},
		},
	},
	{ -- MEDICO ILEGAL:  xiplun mikell
		npc ='s_m_m_scientist_01',                                                       
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
		uiText = 'John McKiver',                                                        
		dialog = 'Solo quiero volver a ver a mi familia, te curare lo que necesites.',                                                
		coordinates =  vector3(-183.88, 932.27, 218.08),  
		heading = 327.38,                                                 
		options = {         
			{'<i class="fa-solid fa-syringe"></i>Curarse', 'medical:ilegal', 'c'},
		},
	}, 

    { -- JAVI DE TODA LA VIDA: tienda chalecos 
		blip = false,
		blipType = 59,
		blipText = 'polietileno',
		blipColor = 15,
		blipScale = 0.6,
		npc ='a_m_y_hiker_01',                                                  
		uiText = 'Uvuvwevwevwe Onyetenyevwe Ugwemubwem Ossas',                                                
		dialog = 'Polietileno del bueno, ¿que necesitas?',                                                        
		coordinates = vector3(2006.68, 3385.94, 50.62), 
		heading = 225.39,                                                
		options = {                                                            
			{'<i class="fa-solid fa-building-memo"></i>Chalecos', 'opensellMenu:chalecospadrino', 'c'},
		},
	},

    { -- JAVI DE TODA LA VIDA:  tienda accesorios armas
		npc ='s_m_m_highsec_02',                                                       
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
		uiText = 'Jesus Maria',                                                        
		dialog = 'Polietileno del bueno, ¿que necesitas?',                                                
		coordinates =  vector3(2010.97, 3386.25, 50.61),  
		heading = 141.53,                                                 
		options = {         
			{'<i class="fa-solid fa-syringe"></i>Accesorios', 'opensellMenu:accesoriosilegalfull', 'c'},
		},
	},

    {  -- JAVI DE TODA LA VIDA: medico ilegal
		npc ='s_m_m_scientist_01',                                                       
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
		uiText = 'John McKiver',                                                        
		dialog = 'Solo quiero volver a ver a mi familia, te curare lo que necesites.',                                                
		coordinates =  vector3(2008.83, 3352.63, 45.60),  
		heading =  304.53,                                                 
		options = {         
			{'<i class="fa-solid fa-syringe"></i>Curarse', 'medical:ilegal', 'c'},
		},
	},
}