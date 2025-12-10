/*
    Negocios.lua, en este archivo se definen los NPCs relacionados con negocios.
    Estos NPCs pueden ofrecer diferentes servicios y diálogos a los jugadores que son dueños o  empleados de negocios.
    El archivo contiene una tabla que define las propiedades y comportamientos de cada NPC de negocio.
*/

return {
    { -- MH MECHANIC CONCESIONARIO
		blip = true,
		blipType = 371,
		blipText = 'Concesionario: Mh Mechanic',
		blipColor = 15,
		blipScale = 0.75,
		npc ='cs_siemonyetarian',                                                     
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
		uiText = 'César Abellan',                                                        
		dialog = 'Bienvenido a la tienda de barcos, ¿Qué desea?',                                                
		coordinates =  vector3(-507.67, 59.00, 51.57),
		heading = 85.05,                                                 
		options = {                                                            
			{'<i class="fa-solid fa-sailboat"></i>Ver catálogo', 'jg-dealerships:client:open-showroom', 'c', 'mhmechanic'},
		},
	},

    {  -- BRAYAN GOTY: medico ilegal (LOCAL DE PELEAS)
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
		uiText = 'Jhon Lennon',                                                        
		dialog = 'Solo quiero volver a ver a mi familia sacame de aqui, te curare lo que necesites.',                                                
		coordinates =  vector3(205.61, 145.30, 102.62),  
		heading =  165.65,                                                 
		options = {         
			{'<i class="fa-solid fa-syringe"></i>Curarse', 'medical:ilegal', 'c'},
		},
	},

    {  -- BRAYAN GOTY: medico ilegal (PITSTOP)
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
		uiText = 'Jhon Lennon',                                                        
		dialog = 'Solo quiero volver a ver a mi familia sacame de aqui, te curare lo que necesites.',                                                
		coordinates =  vector3(930.28, -1570.28, 30.74),  
		heading =  90.18,                                                 
		options = {         
			{'<i class="fa-solid fa-syringe"></i>Curarse', 'medical:ilegal', 'c'},
		},
	},
}