local QBCore = exports["qb-core"]:GetCoreObject()
local pedList = {}
local inpoints = true
local music_puesta = false

local function CreatePedNPC(pedData)
    local pedHash = GetHashKey(pedData.npc)

    RequestModel(pedHash)
    while not HasModelLoaded(pedHash) do Wait(100) end

    local ped = CreatePed(4, pedHash,
        pedData.coordinates.x, pedData.coordinates.y, pedData.coordinates.z,
        pedData.heading, false, true
    )

    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    
    if pedData.anim then
        RequestAnimDict(pedData.anim.animDictionary)
        while not HasAnimDictLoaded(pedData.anim.animDictionary) do Wait(100) end
        TaskPlayAnim(
            ped,
            pedData.anim.animDictionary,
            pedData.anim.animationName,
            pedData.anim.blendInSpeed,
            pedData.anim.blendOutSpeed,
            pedData.anim.duration,
            pedData.anim.flag,
            pedData.anim.playbackRate,
            pedData.anim.lockX,
            pedData.anim.lockY,
            pedData.anim.lockZ
        )
    end

    table.insert(pedList, ped)

    exports['nn_interaction']:addInteractionLocalEntity(
        "npc_dialog_" .. tostring(ped),
        ped,
        {
            distance = 8.0,       
            distanceText = 2.0,    
            checkVisibility = false,
            hideSquare = false,
            showInVehicle = false,
            bone = "head",
            offset = {
                text = {x = 0.0, y = 0.0, z = 0.2},
                target = {x = 0.0, y = 0.0, z = 0.0}
            },
            options = {
                {
                    name = "talk",
                    label = "Hablar con " .. (pedData.uiText or "NPC"),
                    icon = "fa-solid fa-comment",
                    key = "E",
                    duration = 1000,
                    onSelect = function(entity)
                        local playerData = QBCore.Functions.GetPlayerData()
                        local authorized = true

                        if pedData.autireze then
                            authorized = false
                            if pedData.autireze.job then
                                for _, job in ipairs(pedData.autireze.job) do
                                    if playerData.job.name == job then
                                        authorized = true
                                    end
                                end
                            end
                            if pedData.autireze.gang then
                                for _, gang in ipairs(pedData.autireze.gang) do
                                    if playerData.gang.name == gang then
                                        authorized = true
                                    end
                                end
                            end
                        end

                        if not authorized then
                            lib.notify({
                                title = "Acceso denegado",
                                description = "No perteneces al personal autorizado",
                                type = "error"
                            })
                            return
                        end

                        local data = {
                            uiText = pedData.uiText,
                            dialog = pedData.dialog,
                            options = pedData.options,
                            gender = pedData.gender,
                            pedInfo = entity
                        }
                        local px, py, pz = table.unpack(GetEntityCoords(entity, true))
                        local forwardX = GetEntityForwardX(entity)
                        local forwardY = GetEntityForwardY(entity)

                        local camCoords = vector3(px + forwardX * 1.2, py + forwardY * 1.2, pz + 0.52)
                        local camRotation = GetEntityRotation(entity, 2) + vector3(0.0, 0.0, 181.0)

                        StartCam(camCoords, camRotation)
                        openDialogNpcs(data)
                    end
                }
            }
        }
    )
end

function setupPeds()
    for _, pedData in ipairs(Shared.get) do
        CreatePedNPC(pedData)
    end
end
setupPeds()

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        for _, ped in ipairs(pedList) do
            exports['nn_interaction']:removeLocalEntity(ped)
            if DoesEntityExist(ped) then DeleteEntity(ped) end
        end
    end
end)

function openDialogNpcs(data)
    if (data.type == 'exp') then
        local ped = data.pedInfo
        local camCoords = nil
        local camRotation = nil

        local px, py, pz = table.unpack(GetEntityCoords(ped, true))
        local x, y, z = px + GetEntityForwardX(ped) * 1.2, py + GetEntityForwardY(ped) * 1.2, pz + 0.52
        camCoords = vector3(x, y, z)
        local rx = GetEntityRotation(ped, 2)
        camRotation = rx + vector3(0.0, 0.0, 181)
        pedInfo = {
            model = ped,
            coordinates = camCoords,
            entity = ped,
            camCoords = camCoords,
            camRotation = camRotation,
        }
        StartCam(pedInfo.coordinates, pedInfo.camCoords, pedInfo.camRotation, pedInfo.entity, 'IDK')
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'uiopen',
            name = data.uiText,
            dialog = data.dialog,
            options = data.options,
            gender = data.gender,

        })
    else
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'uiopen',
            name = data.uiText,
            dialog = data.dialog,
            options = data.options,
            gender = data.gender,
        })
    end
end


function StartCam(coords, rotation)
    cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", coords, rotation, GetGameplayCamFov())
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 750, true, false)
end

exports('OpenDialog', function(data)
    openDialogNpcs(data)
end)

RegisterNUICallback('action', function(data, cb)
    if data.action == 'close' then
        SetNuiFocus(false, false)
        inpoints = true
        hasEntered = true
        EndCam()
        inMenu = false
        waitMore = false
    elseif data.action == 'option' then
        inpoints = true
        SetNuiFocus(false, false)
        hasEntered = true
        EndCam()
        inMenu = false
        waitMore = false
        if data.options[3] == 'c' then
            if data.options[4] then 
                TriggerEvent(data.options[2], data.options[4])
            else
                TriggerEvent(data.options[2])
            end
        elseif data.options[3] ~= nil then
            TriggerServerEvent(data.options[2])
        end
    end
end)

function EndCam()
    RenderScriptCams(false, true, 1 * 750, true, false)
    DestroyCam(cam, false)
    cam = nil
end

CreateThread(function()
    for k, v in pairs(Shared.get) do
        if (Shared.get[k].blip) then
            blip = AddBlipForCoord(Shared.get[k].coordinates)
            SetBlipSprite(blip, Shared.get[k].blipType)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, Shared.get[k].blipScale)
            SetBlipColour(blip, Shared.get[k].blipColor)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(Shared.get[k].blipText)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

---------------------- Quest ----------------------
local VendedorIlegal = {
    Title = 'Comprar taladro',
    Desc =
    'Este taladro te puede venir muy bien si deseas forzar la cerraduras de los trenes de carga que recorren la ciudad.',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Efectivo',
                ammountneed = 2500,
            },
        },
        reward = {
            {
                item_name = 'taladrorobo',
                label = 'Taladro',
                ammountreward = 1,
            },
        },
    }
}

local Llave = {
    Title = 'Comprar llave',
    Desc = 'Por nada más que 500 cheles esta preciada llave puede ser tuya, ¿qué dices? La contraseña la tienes en la parte trasera de la llave.',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Efectivo',
                ammountneed = 1500,
            },
        },
        reward = {
            {
                item_name = 'methkey',
                label = 'Llave A',
                ammountreward = 1,
            },
        },
    }
}

local AlmacenRobo = {
    Title = 'Comprar llave',
    Desc = 'Por nada más que 1500 cheles y un chicle de melón, esta preciada llave puede ser tuya, ¿qué dices? La contraseña la tienes en la parte trasera de la llave.',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Efectivo',
                ammountneed = 1500,
            },
        },
        reward = {
            {
                item_name = 'llaveb',
                label = 'Llave B',
                ammountreward = 1,
            },
        },
    }
}

local HotDogs = {
    Title = 'Comprar hot-dog',
    Desc = '¡Hey! ¡Ven aquí y prueba los mejores hot-dogs de la ciudad! ¿Desea que le prepare uno?',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Efectivo',
                ammountneed = 10,
            },
        },
        reward = {
            {
                item_name = 'hotdog',
                label = 'Hot-Dog',
                ammountreward = 1,
            },
        },
    }
}

local Donuts = {
    Title = 'Comprar donut',
    Desc = 'Como estás amigo? ¿Desea que le sirva un donut? ¡Están deliciosos!',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Efectivo',
                ammountneed = 6,
            },
        },
        reward = {
            {
                item_name = 'donut',
                label = 'Donut',
                ammountreward = 1,
            },
        },
    }
}

local Burger = {
    Title = 'Comprar hamburguesa',
    Desc =
    '¡Estas hamburguesas son 1000 veces más saludables que las de cualquier burguer shot! ¡Desea que le prepare una caballero?',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Efectivo',
                ammountneed = 8,
            },
        },
        reward = {
            {
                item_name = 'burger',
                label = 'Hamburguesa',
                ammountreward = 1,
            },
        },
    }
}

local ClaudeSpeed = {
    Title = 'Robar cuadros',
    Desc =
    'A ver, te comento, necesito que te cueles a la galería de arte y robes todos los cuadros que veas que puedan ser de alto valor, debería ser un trabajo fácil, ya que no hay vigilancia apenas en el lugar.',

    siquierestrigearalgomas = true,
    triggername = 'rHeist:artheist:start',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = false,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'weapon_switchblade',
                label = 'Navaja',
                ammountneed = 1,
            },
        },
        reward = {
            {
                item_name = 'cash',
                label = 'Efectivo',
            },
        },
    }
}

local ClaudeSpeed2 = {
    Title = 'Robar tren',
    Desc =
    'Necesito que robes un tren que pasará por Sandy Shores, deberás hackear el ordenador de la centralita y esperar a que pase el tren, no tardarás nada. El tren lleva también una tarjeta de un banco muy prestigioso, si encuentras a la persona indicada, podrías hacer el trabajito.',

    siquierestrigearalgomas = true,
    triggername = 'Regreso:trainheist',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = false,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'taladrorobo',
                label = 'Taladro',
                ammountneed = 1,
            },
        },
        reward = {
            {
                item_name = 'cash',
                label = 'Efectivo',
                ammountreward = nil,
            },
            {
                item_name = 'tarjetaunion',
                label = 'Tarjeta',
                ammountreward = nil,
            },
        },
    }
}

local Hospital = {
    Title = 'Comprar vendas',
    Desc =
    'Estás vendas te pueden venir muy bien si deseas curarte en cualquier momento o lugar sin necesidad de tener que llamar a cualquier compañero o dirigirte al hospital',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Efectivo',
                ammountneed = 25,
            },
        },
        reward = {
            {
                item_name = 'bandage',
                label = 'Vendas',
                ammountreward = 1,
            },
        },
    }
}


local BuyItem = {
    Title = 'Comprar Paracaidas',
    Desc =
    '¿Quieres comprar un paracaidas? Con el podrias experimentar varias aventuras nuevas!',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Efectivo',
                ammountneed = 120,
            },
        },
        reward = {
            {
                item_name = 'parachute',
                label = 'Paracaida',
                ammountreward = nil,
            },
        },
    }
}

local BobcatHeist = {
    Title = 'Robar Bobcat',
    Desc =
    '¿Conoces el banco Bobcat? Yo trabajaba ahí pero los hijos de puta me despidieron, por lo que hize que lo robarán y les dejarán en la ruina allá en North Yankton hace 20 años, pero los muy cabrones volvieron y se han movido aquí para reabrirlo, por lo que me gustaría que le robases lo poco que tienen en su bóveda, pero antes de nada, corta la luz del banco',

    siquierestrigearalgomas = true,
    triggername = 'rHeists:bobcat:start',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = false,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'blowtorch',
                label = 'Soplete',
                ammountneed = 1,
            },
        },
        reward = {
            {
                item_name = 'cash',
                label = 'Efectivo',
                ammountreward = nil,
            },
        },
    }
}

local TrevorPhilips = {
    Title = '¡VETE A LA MIERDA!',
    Desc =
    'MÁS TE VALE QUE NO ME DESPIERTES, SI VIENES PARA HACER COSAS ESPECIALES PARA CAJAS FUERTES VES A LA MESA DE DENTRO, SI NO TE ESTRANGULARÉ EL CUELLO COMO SI ESTUVIERA EXPRIMIENDO UN LIMÓN, LARGO DE AQUÍ!',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = '',
    functions = '',
    triggerclose = '',
    functionsclose = '',
}


-- SISTEMA DE VENTA DE ARMAS --

local BottleBreak = {
    Title = 'Negocio con Nate',
    Desc =
    'Necesito algo para olvidar tio, unos 15 gramos de maría, si me lo das, te ofrezco algo especial, una puta botella rota lista para acción. ¿Trato hecho, hermano?',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Dinero',
                ammountneed = 5500,
            },
        },
        reward = {
            {
                item_name = 'weapon_bottle',
                label = 'Botella rota',
                ammountreward = 1,
            },
        },
    }
}


local Bate = {
    Title = 'Negocio con Jose Antonio C',
    Desc =
    'Estaba pensando que podríamos hacer un trato interesante. Si me sueltas unos billetes, te puedo proporcionar un bate de béisbol de primera calidad. Este no es cualquier bate, está modificado, ¿sabes? Perfecto para cualquier situación que se te presente en estas calles. ¿Qué dices, hacemos negocios?',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Dinero',
                ammountneed = 1500,
            },
        },
        reward = {
            {
                item_name = 'weapon_bat',
                label = 'Bate de beisbol',
                ammountreward = 1,
            },
        },
    }
}

local Palanca = {
    Title = 'Negocio con Bob',
    Desc =
    '¿Te gustaría tener en tus manos la "Llave Maestra del Caos"? Por unos billetes, esta palanca única te abrirá las puertas del mundo criminal. Desde cajas fuertes hasta la entrada de lugares exclusivos. Imagina las posibilidades, ¿listo para desatar tu creatividad delictiva?',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Dinero',
                ammountneed = 1200,
            },
        },
        reward = {
            {
                item_name = 'weapon_crowbar',
                label = 'Palanca',
                ammountreward = 1,
            },
        },
    }
}

local PaloGolf = {
    Title = 'Negocio con Samantha',
    Desc =
    'Querido, estos no son solo palos de golf ordinarios. Son la esencia misma de la elegancia. Pertencieron a mi difunto padre, ¡que en paz descanse! Por unos billetes, puedes llevar este legado aristocrático contigo. ¿Te animas a adquirir un toque de distinción en tus golpes?',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Dinero',
                ammountneed = 3000,
            },
        },
        reward = {
            {
                item_name = 'weapon_golfclub',
                label = 'Palo de golf',
                ammountreward = 1,
            },
        },
    }
}

local Martillo = {
    Title = 'Negocio con Alex',
    Desc =
    'La vida entre bastidores es dura, sobre todo para un intérprete como yo. Ahora me dedico a arreglar el atrezzo. En el teatro y el cine, los errores se arreglan con tomas falsas y edición, en la vida real, un pequeño error puede acabar con todo. Tenlo presente.',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Dinero',
                ammountneed = 2200,
            },
        },
        reward = {
            {
                item_name = 'weapon_hammer',
                label = 'Martillo',
                ammountreward = 1,
            },
        },
    }
}

local PalodeBillar = {
    Title = 'Negocio con Rupert',
    Desc =
    'Esta casa la heredé de mis abuelos. No me mires así, no soy tan viejo como parece, la salitre del mar me arruga la piel. Todo lo que me queda es esta casa y mi huerto. Y la colección de palos de billar de mi padre.',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Dinero',
                ammountneed = 1850,
            },
        },
        reward = {
            {
                item_name = 'weapon_poolcue',
                label = 'Palo de billar',
                ammountreward = 1,
            },
        },
    }
}

local LlaveInglesa = {
    Title = 'Negocio con Lisa',
    Desc =
    'La energia limpia y renovale debería ser para todo el mundo. ¿Te imaginas un mundo donde la energia eólica fuera la principal fuente para todos? Sin tanta contaminación por culpa de esas industrias que hay en la ciudad.',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Dinero',
                ammountneed = 1900,
            },
        },
        reward = {
            {
                item_name = 'weapon_wrench',
                label = 'Llave inglesa',
                ammountreward = 1,
            },
        },
    }
}

local Navajas = {
    Title = 'Negocio con Elias',
    Desc =
    'Mi técnica es ancestral, mis cortes son magistrales, yo era maestro de Kenjutsu y ahora me dedico a cortar pollo.',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Dinero',
                ammountneed = 3650,
            },
        },
        reward = {
            {
                item_name = 'weapon_switchblade',
                label = 'Navaja',
                ammountreward = 1,
            },
        },
    }
}

local Machete = {
    Title = 'Negocio con Bob',
    Desc =
    'Esos malditos jabalíes destrozan todo, nos roban la comida y encima son agresivos, como me gustaría cazar uno de esos para alimentar a mi familia y usar sus colmillos como palillos de dientes. ',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Dinero',
                ammountneed = 4500,
            },
        },
        reward = {
            {
                item_name = 'weapon_machete',
                label = 'Machete',
                ammountreward = 1,
            },
        },
    }
}

local PunoAmericano = {
    Title = 'Negocio con Robert',
    Desc =
    'A ese viejo que vive solo le faltan un par de tornillos, está obsesionado con los palos, de cualquier forma y tamaño. Yo creo que hay cosas mejores. ',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Dinero',
                ammountneed = 3000,
            },
        },
        reward = {
            {
                item_name = 'weapon_knuckle',
                label = 'Puño americano',
                ammountreward = 1,
            },
        },
    }
}

local PistolaM9 = {
    Title = 'Negocio con M.K',
    Desc =
    '¡Hey, colega! Si estás aquí es porque te han dado el chivatazo. Pocos conocen de mi existencia, y espero que siga siendo asi, si quieres seguir respirando. Ten cuidadito donde te metes, no todo es oro lo que reluce, y menos las placas de esos polis. Ándate con ojo, chaval.',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Dinero',
                ammountneed = 50000,
            },
        },
        reward = {
            {
                item_name = 'weapon_pistol',
                label = 'Pistola M9',
                ammountreward = 1,
            },
        },
    }
}

local GanzuasVehiculos = {
    Title = 'Negocio con M.K',
    Desc =
    '¡Hey, colega! Si estás aquí es porque te han dado el chivatazo. Pocos conocen de mi existencia, y espero que siga siendo asi, si quieres seguir respirando. Ten cuidadito donde te metes, no todo es oro lo que reluce, y menos las placas de esos polis. Ándate con ojo, chaval.',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'lockpick',
                label = 'Ganzua',
                ammountneed = 1,
            },
        },
        reward = {
            {
                item_name = 'vehicle_lockpick',
                label = 'Ganzua para Vehículos',
                ammountreward = 1,
            },
        },
    }
}

local PistolaSNS = {
    Title = 'Negocio con Truman',
    Desc =
    '¿No te parecen las serpientes lo más bonito que existe? Son sigilosas, silenciosas y nunca retroceden, justamente como yo. ¿Qué miras? Dame lo mio, coge lo tuyo y pirate. ',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Dinero',
                ammountneed = '',
            },
        },
        reward = {
            {
                item_name = 'weapon_snspistol',
                label = 'Pistola SNS',
                ammountreward = 25000,
            },
        },
    }
}

local PistolaVintage = {
    Title = 'Negocio con Louis',
    Desc =
    'Mi abuelo coleccionaba cosas antiguas, entre ellas, cosas un poco inusuales, pero gracias a el, herede esa pasion por lo antiguo. Tengo autenticas reliquias y quiero revivir las experiencias de los amantes de las armas clásicas. Cada pieza cuenta una historia, porque el pasado nunca dispara obsoleto.',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Dinero',
                ammountneed = 40000,
            },
        },
        reward = {
            {
                item_name = 'weapon_vintagepistol',
                label = 'Pistola Vintage',
                ammountreward = 1,
            },
        },
    }
}

local MicroSMG = {
    Title = 'Negocio con Ezekiel',
    Desc =
    'Cada una de mis niñas, lleva una sutil firma  que sólo pueden descifrar aquellos que están familiarizados con Las Sombras de la ciudad y que saben ver lo bueno cuando lo tienen delante, amigo. Si buscas potencia de fuego rápida y precisa, soy tu hombre.',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Dinero',
                ammountneed = 90000,
            },
        },
        reward = {
            {
                item_name = 'weapon_microsmg',
                label = 'Micro SMG',
                ammountreward = 1,
            },
        },
    }
}

local CombatPDW = {
    Title = 'Negocio con Benjamin',
    Desc =
    'Me conocen por mi discreción y mi capacidad de conseguir armas sin hacer preguntas. Si buscas lo mejor, manteniendo tu anonimato, estás en el lugar indicado.  Mis armas hablan por sí mismas, y recuerda, las armas no tienen prejuicios.',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Dinero',
                ammountneed = 145000,
            },
        },
        reward = {
            {
                item_name = 'weapon_combatpdw',
                label = 'Combat PDW',
                ammountreward = 1,
            },
        },
    }
}

local MiniSMG = {
    Title = 'Negocio con Manuel',
    Desc =
    'Tengo muchas habilidades, entre ellas, habilidades tácticas. ¿Crees estar a mi altura? ¡JA! No te lo crees ni tú. Para esto hay que ser mortífero, pero discreto. Lo que yo poseo es ideal para misiones encubiertas, si eres un cobarde, vuelve por donde has venido.',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Dinero',
                ammountneed = 80000,
            },
        },
        reward = {
            {
                item_name = 'weapon_minismg',
                label = 'Mini SMG',
                ammountreward = 1,
            },
        },
    }
}

local MachinePistol = {
    Title = 'Negocio con Nate',
    Desc =
    'Hay que tener buen ojo para usar estas preciosidades. Y no solo buen ojo, también buena puntería y destreza, porque el resto del trabajo, lo hacen estas armas automáticas. Son una gama única de armas compactas y muy letales que combinan potencia y velocidad.',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Dinero',
                ammountneed = 90000,
            },
        },
        reward = {
            {
                item_name = 'weapon_machinepistol',
                label = 'Pistola automática',
                ammountreward = 1,
            },
        },
    }
}

local Shotgun = {
    Title = 'Negocio con Scarlett',
    Desc =
    'Bienvenido a mi caravana, toda clase de escopetas recortadas, pero una especial para ti. Aquí no hacemos preguntas, no se quien eres, ni de dónde vienes. Velamos por tu seguridad y la de los tuyos. Si quieres una de estas, no me importa tu edad ni tus licencias, solo me importa tu dinero.',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Dinero',
                ammountneed = 140000,
            },
        },
        reward = {
            {
                item_name = 'weapon_sawnoffshotgun',
                label = 'Escopeta recortada',
                ammountreward = 1,
            },
        },
    }
}

local BullpupRifle = {
    Title = 'Negocio con Benjamin',
    Desc =
    'ngenieria y tecnologia militar, esos son mis puntos fuertes, además de mi belleza blindada. Fabrico herramientas de alta gama, para gente de alta calidad. Estas preciosidades no son para cualquier mindundi y menos para gentuza que no sepa apreciarlas como es debido. Esto es lo último en rendimiento.',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Dinero',
                ammountneed = 170000,
            },
        },
        reward = {
            {
                item_name = 'weapon_bullpuprifle',
                label = 'Rifle bullpup',
                ammountreward = 1,
            },
        },
    }
}

local BullpupShotgun = {
    Title = 'Negocio con Isabella',
    Desc =
    'Veo que tienes buena visión de futuro. Sé que buscas equilibrio entre la potencia y la maniobrabilidad, puedo ver que tu futuro será brillante por tu gran fuerza. No hace falta que me digas nada, lo veo, lo presiento. Igual que también presiento que me darás algo muy bueno a cambio de esto. ¿Verdad? ',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Dinero',
                ammountneed = 125000,
            },
        },
        reward = {
            {
                item_name = 'weapon_bullpupshotgun',
                label = 'Escopeta bullpup',
                ammountreward = 1,
            },
        },
    }
}

local HeavyPistol = {
    Title = 'Negocio con Samuel',
    Desc =
    'Pocos pueden aguantar el peso del éxito sobre sus hombros, pero es mucho mejor tener el éxito en tus manos. No es un juguete, tratalo bien y será preciso y leal. Enseñame todo lo que tienes y podremos hablar de negocios.',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Dinero',
                ammountneed = 60000,
            },
        },
        reward = {
            {
                item_name = 'weapon_heavypistol',
                label = 'Pistola pesada',
                ammountreward = 1,
            },
        },
    }
}

local Pistol50 = {
    Title = 'Negocio con Michael',
    Desc =
    'He forjado mi reputación entre susurros clandestinos. Que no te asuste mi rostro sombrío, tejo acuerdos bajo el manto de la noche. Pagame en silencio y no me quedaré con tu vida.',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Dinero',
                ammountneed = 60000,
            },
        },
        reward = {
            {
                item_name = 'weapon_pistol50',
                label = 'Pistola Calibre 50',
                ammountreward = 1,
            },
        },
    }
}

local AssaultRifle = {
    Title = 'Negocio con Daniel',
    Desc =
    'Un arma que se adapta a ti y que además es versátil, puede ser una gran compañera en los asaltos. Debes ser hábil para negociar conmigo, pero te advierto, los rifles cambian de mano muy rápidamente.',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Dinero',
                ammountneed = 200000,
            },
        },
        reward = {
            {
                item_name = 'weapon_assaultrifle',
                label = 'Rifle de asalto',
                ammountreward = 1,
            },
        },
    }
}

local CompactRifle = {
    Title = 'Negocio con Christopher',
    Desc =
    'Esto es minimalista, pero ágil y mortal. La sencillez siempre me ha atraído; la sencillez de un atardecer, la sencillez de un buen café por la mañana, la sencillez de un último aliento… Tu me entiendes, ¿verdad?',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Dinero',
                ammountneed = 170000,
            },
        },
        reward = {
            {
                item_name = 'weapon_compactrifle',
                label = 'Rifle compacto',
                ammountreward = 1,
            },
        },
    }
}

local Gunsenberg = {
    Title = 'Negocio con Lucia',
    Desc =
    'Vivimos en una era de prohibiciones y restricciones, pero eso no me impide crear y restaurar auténticas obras maestras que se ciñen a lo clásico. Me gusta ponerle a mi vida un toque de nostalgia. ¡Revivamos la época dorada de las armas!',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Dinero',
                ammountneed = 100000,
            },
        },
        reward = {
            {
                item_name = 'weapon_gusenberg',
                label = 'Gusenberg',
                ammountreward = 1,
            },
        },
    }
}

-- VENTA DE CHATARRA --

local priceChatarra, priceVidrio, priceAluminium = math.random(150, 170), math.random(120, 140), math.random(140, 160)

local Chatarras = {
    Title = 'Comprar chatarras',
    Desc = 'Mmm... Me interesa esto. Por esto te puedo ofrecer: ' ..
    priceChatarra .. ', pero eso si. Te voy comprando de 20 en 20.',
    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',
    Items = {
        need = {
            {
                item_name = 'chatarra',
                label = 'Chatarra',
                ammountneed = 20,
            },
        },
        reward = {
            {
                item_name = 'cash',
                label = 'Efectivo',
                ammountreward = priceChatarra,
            },
        },
    }
}

local Vidrio = {
    Title = 'Comprar vidrio',
    Desc = 'Mmm... Me interesa esto. Por esto te puedo ofrecer: ' ..
    priceVidrio .. ', pero eso si. Te voy comprando de 20 en 20.',
    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',
    Items = {
        need = {
            {
                item_name = 'vidrio',
                label = 'Vidrio',
                ammountneed = 20,
            },
        },
        reward = {
            {
                item_name = 'cash',
                label = 'Efectivo',
                ammountreward = priceVidrio,
            },
        },
    }
}

local Aluminio = {
    Title = 'Comprar aluminio',
    Desc = 'Mmm... Me interesa esto. Por esto te puedo ofrecer: ' ..
    priceAluminium .. ', pero eso si. Te voy comprando de 20 en 20.',
    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',
    Items = {
        need = {
            {
                item_name = 'tuberias',
                label = 'Tuberias',
                ammountneed = 20,
            },
        },
        reward = {
            {
                item_name = 'cash',
                label = 'Efectivo',
                ammountreward = priceAluminium,
            },
        },
    }
}



-- VENTA DE PAQUETES DE MARIA --

local pricePurpleHaze, priceSkunk, priceOGKush, priceBananaKush, priceAmnesia = math.random(5000, 5500),
    math.random(4500, 5000), math.random(3500, 4000), math.random(4000, 4500), math.random(3500, 4000)

local PurpleHaze = {
    Title = 'Comprar Paquetes de Purple-Haze',
    Desc = 'Mmm... Me interesa esto. Por esto te puedo ofrecer: ' ..
    pricePurpleHaze .. ', pero eso si. Te voy comprando de 2 en 2.',
    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',
    Items = {
        need = {
            {
                item_name = 'packagedweed_purple',
                label = 'Purple Haze empaquetada',
                ammountneed = 2,
            },
        },
        reward = {
            {
                item_name = 'cash',
                label = 'Efectivo',
                ammountreward = pricePurpleHaze,
            },
        },
    }
}

local Skunk = {
    Title = 'Comprar Paquetes de Skunk',
    Desc = 'Mmm... Me interesa esto. Por esto te puedo ofrecer: ' ..
    priceSkunk .. ', pero eso si. Te voy comprando de 2 en 2.',
    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',
    Items = {
        need = {
            {
                item_name = 'packagedweed_skunk',
                label = 'Skunk empaquetada',
                ammountneed = 2,
            },
        },
        reward = {
            {
                item_name = 'cash',
                label = 'Efectivo',
                ammountreward = priceSkunk,
            },
        },
    }
}

local OGKush = {
    Title = 'Comprar Paquetes de OG-Kush',
    Desc = 'Mmm... Me interesa esto. Por esto te puedo ofrecer: ' ..
    priceOGKush .. ', pero eso si. Te voy comprando de 2 en 2.',
    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',
    Items = {
        need = {
            {
                item_name = 'packagedweed_og_kush',
                label = 'OG-Kush empaquetada',
                ammountneed = 2,
            },
        },
        reward = {
            {
                item_name = 'cash',
                label = 'Efectivo',
                ammountreward = priceOGKush,
            },
        },
    }
}

local BananaKush = {
    Title = 'Comprar Paquetes de Banana-Kush',
    Desc = 'Mmm... Me interesa esto. Por esto te puedo ofrecer: ' ..
    priceBananaKush .. ', pero eso si. Te voy comprando de 2 en 2.',
    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',
    Items = {
        need = {
            {
                item_name = 'packagedweed_bananakush',
                label = 'Banana-Kush empaquetada',
                ammountneed = 2,
            },
        },
        reward = {
            {
                item_name = 'cash',
                label = 'Efectivo',
                ammountreward = priceBananaKush,
            },
        },
    }
}

local Amnesia = {
    Title = 'Comprar Paquetes de Banana-Kush',
    Desc = 'Mmm... Me interesa esto. Por esto te puedo ofrecer: ' ..
    priceAmnesia .. ', pero eso si. Te voy comprando de 2 en 2.',
    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',
    Items = {
        need = {
            {
                item_name = 'packagedweed_amnesia',
                label = 'Amnesia empaquetada',
                ammountneed = 2,
            },
        },
        reward = {
            {
                item_name = 'cash',
                label = 'Efectivo',
                ammountreward = priceAmnesia,
            },
        },
    }
}

RegisterNetEvent('teleport:event', function(source)
    local player = PlayerPedId()

    DoScreenFadeIn(1000)
    while not IsScreenFadedIn() do
        Citizen.Wait(0)
    end

    SetEntityCoords(player, -305.65, -1946.17, 21.60)
end)

--- EXPORTS ---

-- VENTA DE PAQUETES DE MARIA --

RegisterNetEvent('rDialog:sell:marihuana:purplehaze', function()
    exports['RevoQuestions']:OpenDialog(PurpleHaze)
end)

RegisterNetEvent('rDialog:sell:marihuana:skunk', function()
    exports['RevoQuestions']:OpenDialog(Skunk)
end)

RegisterNetEvent('rDialog:sell:marihuana:bananakush', function()
    exports['RevoQuestions']:OpenDialog(BananaKush)
end)

RegisterNetEvent('rDialog:sell:marihuana:ogkush', function()
    exports['RevoQuestions']:OpenDialog(OGKush)
end)

RegisterNetEvent('rDialog:sell:marihuana:amnesia', function()
    exports['RevoQuestions']:OpenDialog(Amnesia)
end)

-- VENTA DE CHATARRA --

RegisterNetEvent('rDialog:sell:materials:Chatarras', function()
    exports['RevoQuestions']:OpenDialog(Chatarras)
end)
RegisterNetEvent('rDialog:sell:materials:Vidrio', function()
    exports['RevoQuestions']:OpenDialog(Vidrio)
end)
RegisterNetEvent('rDialog:sell:materials:Aluminio', function()
    exports['RevoQuestions']:OpenDialog(Aluminio)
end)

-- VENTA DE ARMAS --

RegisterNetEvent("Quest:BottleBreak", function()
    print("BottleBreak")
    exports['RevoQuestions']:OpenDialog(BottleBreak)
end)

RegisterNetEvent("Quest:Bate", function()
    exports['RevoQuestions']:OpenDialog(Bate)
end)

RegisterNetEvent("Quest:Palanca", function()
    exports['RevoQuestions']:OpenDialog(Palanca)
end)

RegisterNetEvent("Quest:PaloGolf", function()
    exports['RevoQuestions']:OpenDialog(PaloGolf)
end)

RegisterNetEvent("Quest:Martillo", function()
    exports['RevoQuestions']:OpenDialog(Martillo)
end)

RegisterNetEvent("Quest:Machete", function()
    exports['RevoQuestions']:OpenDialog(Machete)
end)

RegisterNetEvent("Quest:PunoAmericano", function()
    exports['RevoQuestions']:OpenDialog(PunoAmericano)
end)

RegisterNetEvent("Quest:Navajas", function()
    exports['RevoQuestions']:OpenDialog(Navajas)
end)

RegisterNetEvent("Quest:PalodeBillar", function()
    exports['RevoQuestions']:OpenDialog(PalodeBillar)
end)

RegisterNetEvent("Quest:LlaveInglesa", function()
    exports['RevoQuestions']:OpenDialog(LlaveInglesa)
end)

RegisterNetEvent("Quest:PistolaM9", function()
    exports['RevoQuestions']:OpenDialog(PistolaM9)
end)

RegisterNetEvent("Quest:Ganzuas", function()
    exports['RevoQuestions']:OpenDialog(GanzuasVehiculos)
end)

RegisterNetEvent("Quest:PistolaSNS", function()
    exports['RevoQuestions']:OpenDialog(PistolaSNS)
end)


RegisterNetEvent("Quest:PistolaVintage", function()
    exports['RevoQuestions']:OpenDialog(PistolaVintage)
end)

RegisterNetEvent("Quest:MicroSMG", function()
    exports['RevoQuestions']:OpenDialog(MicroSMG)
end)

RegisterNetEvent("Quest:CombatPDW", function()
    exports['RevoQuestions']:OpenDialog(CombatPDW)
end)

RegisterNetEvent("Quest:MiniSMG", function()
    exports['RevoQuestions']:OpenDialog(MiniSMG)
end)

RegisterNetEvent("Quest:MachinePistol", function()
    exports['RevoQuestions']:OpenDialog(MachinePistol)
end)


RegisterNetEvent("Quest:Shotgun", function()
    exports['RevoQuestions']:OpenDialog(Shotgun)
end)

RegisterNetEvent("Quest:BullpupRifle", function()
    exports['RevoQuestions']:OpenDialog(BullpupRifle)
end)

RegisterNetEvent("Quest:BullpupShotgun", function()
    exports['RevoQuestions']:OpenDialog(BullpupShotgun)
end)


RegisterNetEvent("Quest:HeavyPistol", function()
    exports['RevoQuestions']:OpenDialog(HeavyPistol)
end)

RegisterNetEvent("Quest:Pistol50", function()
    exports['RevoQuestions']:OpenDialog(Pistol50)
end)

RegisterNetEvent("Quest:AssaultRifle", function()
    exports['RevoQuestions']:OpenDialog(AssaultRifle)
end)

RegisterNetEvent("Quest:CompactRifle", function()
    exports['RevoQuestions']:OpenDialog(CompactRifle)
end)

RegisterNetEvent("Quest:Gunsenberg", function()
    exports['RevoQuestions']:OpenDialog(Gunsenberg)
end)

---- ATRACOS ---

RegisterNetEvent("Quest:VendedorIlegal", function()
    exports['RevoQuestions']:OpenDialog(VendedorIlegal)
end)


RegisterNetEvent("Quest:Donuts", function()
    exports['RevoQuestions']:OpenDialog(Donuts)
end)

RegisterNetEvent("Quest:Burger", function()
    exports['RevoQuestions']:OpenDialog(Burger)
end)

RegisterNetEvent("Quest:HotDogs", function()
    exports['RevoQuestions']:OpenDialog(HotDogs)
end)

RegisterNetEvent("Quest:ClaudeSpeed", function()
    exports['RevoQuestions']:OpenDialog(ClaudeSpeed)
end)

RegisterNetEvent('slatar:buy', function()
    exports['RevoQuestions']:OpenDialog(BuyItem)
end)

RegisterNetEvent("Quest:ClaudeSpeed2", function()
    exports['RevoQuestions']:OpenDialog(ClaudeSpeed2)
end)

RegisterNetEvent("Quest:ClaudeSpeed3", function()
    QBCore.Functions.Notify(
    'Parece que hay demasiada vigilancia ahora mismo como para poder hacer ese trabajo.. Te avisaré cuando podamos hacerlo.',
        "person")
end)

RegisterNetEvent("Quest:Hospital", function()
    exports['RevoQuestions']:OpenDialog(Hospital)
end)

RegisterNetEvent("Quest:BobcatHeist", function()
    exports['RevoQuestions']:OpenDialog(BobcatHeist)
end)

RegisterNetEvent("Quest:TrevorPhilips", function()
    exports['RevoQuestions']:OpenDialogTalk(TrevorPhilips)
end)

RegisterNetEvent("Quest:LLaves", function()
    exports['RevoQuestions']:OpenDialog(Llave)
end)

RegisterNetEvent("Quest:AlmacenRobo", function()
    exports['RevoQuestions']:OpenDialog(AlmacenRobo)
end)

---------------------- Quest ----------------------

RegisterNetEvent('rental:bmx', function()
    TriggerEvent('spawnvehicle:rental', 'bmx')
end)

RegisterNetEvent('rental:cruiser', function()
    TriggerEvent('spawnvehicle:rental', 'cruiser')
end)

RegisterNetEvent('rental:fixter', function()
    TriggerEvent('spawnvehicle:rental', 'fixter')
end)

RegisterNetEvent('rental:scorcher', function()
    TriggerEvent('spawnvehicle:rental', 'scorcher')
end)

RegisterNetEvent('rental:tribike', function()
    TriggerEvent('spawnvehicle:rental', 'tribike')
end)

RegisterNetEvent('Regreso:trainheist', function()
    SetNewWaypoint(vector3(2628.30, 2940.08, 40.42))
end)

RegisterNetEvent("Regreso:medico")
AddEventHandler("Regreso:medico", function()
    getPlayerOnDuty(function(result)
        if (result >= 2) then
            QBCore.Functions.Notify('Hay especialistas disponibles.')
        else
            QBCore.Functions.Progressbar("hospital_checkin", "Revisando heridas...", 2000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {}, {}, {}, function()
                local bedId = 4
                if bedId ~= nil then
                    TriggerServerEvent("hospital:server:SendToBed", math.random(1, 5), true)
                else
                    QBCore.Functions.Notify("Las camillas están ocupadas.", 'warning')
                end
            end, function()
                QBCore.Functions.Notify("¡El registro falló!", "Error")
            end)
        end
    end)
end)



function getPlayerOnDuty(callback)
    QBCore.Functions.TriggerCallback('getPlayersJob', function(players)
        local jobCount = {}
        local count = 0
        for _, player in pairs(players) do
            local playerJob = player.PlayerData.job.name
            if playerJob == "ambulance" and player.PlayerData.job.onduty then
                count = count + 1
            end
        end
        callback(count)
    end)
end

RegisterNetEvent('medical:ilegal', function()
    local healt      = GetEntityHealth(PlayerPedId()) / 2;
    local porcentaje = math.ceil(healt)
    QBCore.Functions.Progressbar('asdasd', 'Curando..', 5000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, function()
    end, function()
        TriggerEvent('hospital:client:Revive')
    end)
end)

local rental = {
    [1] = {
        coords = vector3(302.87, -1641.78, 32.53),
        spawn = vector4(300.74, -1639.82, 32.53, 32.07),
        type = 'bici'
    },
    --    [2] = {
    --         coords = vector3(1859.8837, 3865.4370, 33.0602),
    --         spawn = vector4(1851.1497, 3871.6025, 32.9375, 28.8780)
    --         type = 'bici'
    --     },
    [3] = {
        coords = vector3(-685.8125, -1103.8126, 14.5255),
        spawn = vector4(-680.7591, -1099.9073, 14.5255, 27.9992),
        type = 'bici'
    },

    [4] = {
        coords = vector3(-108.7031, 6310.3672, 31.4784),
        spawn = vector4(-98.3952, 6313.1602, 31.4905, 120.7334),
        type = 'bici'
    },
    [5] = {
        coords = vector3(-1151.2457, -1519.6815, 4.3594),
        spawn = vector4(-1156.2402, -1518.8607, 4.3589, 34.7192),
        type = 'bici'
    },
    [6] = {
        coords = vector3(-522.9638, -1224.0934, 18.4550),
        spawn = vector4(-510.2646, -1212.6370, 18.5048, 87.0900),
        type = 'bici'
    },
    [7] = {
        coords = vector3(273.6191, -833.1981, 29.4125),
        spawn = vector4(276.5448, -836.7487, 29.2257, 178.2028),
        type = 'bici'
    },
    [8] = {
        coords = vector3(-458.2397, 263.6853, 83.1192),
        spawn = vector4(-463.5222, 264.5187, 83.1275, 172.8350),
        type = 'bici'
    },
    [9] = {
        coords = vector3(1201.9138, 2655.5647, 37.8519),
        spawn = vector4(1203.4302, 2660.5435, 37.8214, 1.8763),
        type = 'bici'
    },
    [10] = {
        coords = vector3(1278.4, -2736.93, 1.82),
        spawn = vector4(1269.38, -2750.4, 0.02, 150.21),
        type = 'barco'
    },
    [11] = {
        coords = vector3(-1657.31, -982.6, 8.17),
        spawn = vector4(-1748.37, -1058.82, 0.43, 136.95),
        type = 'barco'
    },
    [11] = {
        coords = vector3(-769.18, 5596.63, 33.61),
        spawn = vector4(-680.7591, -1099.9073, 14.5255, 27.9992),
        type = 'bici'
    },
}

RegisterNetEvent('barco:reysel', function(type)
    local elements = {
        { label = 'Speeder', value = 'speeder' },
        { label = 'Tropic2', value = 'tropic2' },
        { label = 'Tropic',  value = 'tropic' },
        { label = 'Dinghy3', value = 'dinghy3' },
        { label = 'Dinghy4', value = 'dinghy4' },
        { label = 'Dinghy',  value = 'dinghy' },
    }
    local staffList = {}
    staffList[#staffList + 1] = { 
        isMenuHeader = true,
        header = 'Alquiler de barcos - 120$',
        icon = 'fa-solid fa-infinity'
    }
    for k,v in pairs(elements) do  
        staffList[#staffList + 1] = {  
            header = v.label,
            icon = 'fa-duotone fa-ship',
            params = {
                handler = function()
                    if not type then 
                        spawnvehicle(v.value, vector4(1275.26, -2750.32, 0.57, 50.09))
                        QBCore.Functions.TriggerCallback('removemoney:rental', function() end, 'barco')
                        QBCore.Functions.Notify('Has alquilado un ' .. v.value .. ' por ~g~120$')
                    elseif type == "2" then 
                        spawnvehicle(v.value, vector4(2346.21, -2167.28, 0.39, 176.05))
                        QBCore.Functions.TriggerCallback('removemoney:rental', function() end, 'barco')
                        QBCore.Functions.Notify('Has alquilado un ' .. v.value .. ' por ~g~120$')
                    elseif type == "3" then 
                        spawnvehicle(v.value, vector4(526.99, -3162.92, -0.48, 176.60))
                        QBCore.Functions.TriggerCallback('removemoney:rental', function() end, 'barco')
                        QBCore.Functions.Notify('Has alquilado un ' .. v.value .. ' por ~g~120$')
                    end
                end
            }
        }
    end
    exports['qb-menu']:openMenu(staffList)
end)


function spawnvehicle(model, coords)
    QBCore.Functions.SpawnVehicle(model, function(veh)
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
    end, coords, true)
end

CreateThread(function()
    for k, v in pairs(rental) do
        local blip = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        if (v.type == 'bici') then
            AddTextComponentString('Alquiler de bicis')
            SetBlipSprite(blip, 376)
        elseif (v.type == 'barco') then
            AddTextComponentString('Alquiler de barcos')
            SetBlipSprite(blip, 427)
        end
        SetBlipScale(blip, 0.5)
        SetBlipColour(blip, 77)
        EndTextCommandSetBlipName(blip)
    end
end)

RegisterNetEvent('spawnvehicle:rental', function(model)
    local player = PlayerPedId()
    local isinvehicle = IsPedInAnyVehicle(player, false)
    
    if isinvehicle then
        QBCore.Functions.Notify('Debes salir del vehículo para alquilar una bicicleta.')
        return
    end
    
    spawnvehicle(model, GetEntityCoords(PlayerPedId()))
    QBCore.Functions.Notify('Has alquilado una ' .. model .. '')
end)

-- local sound_list = {
--     [1] = { sound_name = 'https://youtu.be/jZkmyBJmOWc', label = 'Reproduciendo: Un Malo & Medio \n \n Artista: Braulio Fogon', anim_random = 'disco' },
--     [2] = { sound_name = 'https://youtu.be/7QVXgCE188c', label = 'Reproduciendo: Cuéntale \n \n Artista: Quevedo', anim_random = 'savage' },
--     [3] = { sound_name = 'https://youtu.be/aZmHDSZgyes', label = 'Reproduciendo: Gasolina \n \n Artista: Daddy Yankee', anim_random = 'bloodwalk' },
--     [4] = { sound_name = 'https://youtu.be/NmMeD4uIIRg', label = 'Reproduciendo: Del Kilo \n \n Artista: Anuel AA', anim_random = 'woowalk' },
--     [5] = { sound_name = 'https://youtu.be/kZwjgbSy-Qw', label = 'Reproduciendo: Yonaguni \n \n Artista: Bad Bunny', anim_random = 'rollie' },
--     [6] = { sound_name = 'https://youtu.be/JudRJpATiHo', label = 'Reproduciendo: Yandel 150 \n \n Artista: Ferxxoo', anim_random = 'danceclub' },
--     [7] = { sound_name = 'https://youtu.be/m2ugcRkwKdc', label = 'Reproduciendo: La Macarena \n \n Artista: Los Del Rio', anim_random = 'macarena' },
--     [10] = { sound_name = 'https://youtu.be/yb6IJRqoytU', label = 'Reproduciendo: Baby Hello \n \n Artista: Rauw Alejandro', anim_random = 'pullup' },
--     [11] = { sound_name = 'https://youtu.be/d-ou8UcbfQo', label = 'Reproduciendo: Bzrp Music Sessions 56 \n \n Artista: Rauw Alejandro', anim_random = 'drilldance' },
--     [12] = { sound_name = 'https://youtu.be/K0vXF7lJcWY', label = 'Reproduciendo: Me porto bonito \n \n Artista: Bad Bunny', anim_random = 'armwave' },
--     [13] = { sound_name = 'https://youtu.be/juRFjpB5Ppg', label = 'Reproduciendo: Tití Me Preguntó \n \n Artista: Bad Bunny', anim_random = 'taketheL' },
--     [14] = { sound_name = 'https://youtu.be/JmP89cIGJZM', label = 'Reproduciendo: Como Camaron \n \n Artista: Estopa', anim_random = 'lloss' },
--     [15] = { sound_name = 'https://youtu.be/wECwsE4yNSQ', label = 'Reproduciendo: La Raja de Tu Falda \n \n Artista: Estopa', anim_random = 'renegade' },
--     [17] = { sound_name = 'https://youtu.be/adKMjeTPYXQ', label = 'Reproduciendo: Flow Violento Remix \n \n Artista: YoSoyPlex ', anim_random = 'yeet' },
-- }

-- RegisterNetEvent('xdpunto', function()
--     if (not music_puesta) then
--         QBCore.Functions.Notify(
--             'Qué pasa Ma G, no tengo nada que hablar contigo solo bailo ¡BAILA CONMIGO! <i class="fa-solid fa-poo"></i>',
--             "person")
--         local random_url = math.random(1, #sound_list)
--         local random_label = sound_list[random_url].label
--         local random_sound = sound_list[random_url].sound_name
--         local anim_random = sound_list[random_url].anim_random
--         print(random_url)
--         QBCore.Functions.Notify(random_label, "person")
--         exports['xsound']:PlayUrl('xd', random_sound, 0.5, false)
--         music_puesta = true
--         ExecuteCommand('e ' .. anim_random)
--         Wait(50000)
--         if (music_puesta) then
--             QBCore.Functions.Notify('Si quieres quitar la música, usa /quitarmusica', "person")
--             SetTimeout(120000, function()
--                 if (music_puesta) then
--                     ExecuteCommand('e c')
--                     QBCore.Functions.Notify(
--                         'Bueno, Ya esta. Dejame seguir bailando solo. CHU CHU CHU <i class="fa-solid fa-poo"></i>',
--                         "person")
--                     exports['xsound']:Destroy('xd')
--                     music_puesta = false
--                 end
--             end)
--         end
--     else
--         QBCore.Functions.Notify('Ya hay música puesta', "error")
--     end
-- end)

-- RegisterCommand('quitarmusica', function()
--     if (not music_puesta) then
--         QBCore.Functions.Notify('No hay música puesta', "error")
--     else
--         music_puesta = false
--         exports['xsound']:Destroy('xd')
--         ExecuteCommand('e c')
--     end
-- end)

RegisterNetEvent('act:exit:recly', function()
    SetEntityCoords(PlayerPedId(), vector4(55.576, 6472.12, 31.42, 230.732))
end)

RegisterNetEvent('act:enter:recly', function()
    SetEntityCoords(PlayerPedId(), vector4(1072.72, -3102.51, -40.0, 82.95))
end)

RegisterNetEvent('police:talk', function()
    QBCore.Functions.Notify("Acabo de avisar a un compañero, manténgase a la espera.", "person")
    TriggerServerEvent("SendAlert:police", {
        type = "COMISARÍA",
        title = "Aviso de comisaría",
        message = "Hay una persona en la recepción de comisaría de Mission Row que le gustaría hablar con un agente",
        coords = GetEntityCoords(PlayerPedId())
    })
end)

RegisterNetEvent('shop:parachutes', function()
    exports["qb-menu"]:openMenu({
        {
            header = "Coste: 30$",
            isMenuHeader = true,
        },
        {
            header = "Aceptar",
            txt = "Acepta la oferta",
            icon = 'fa-solid fa-check',
            params = {
                handler = function()
                    local dialog = exports['qb-input']:ShowInput({
                        header = "Comprar paracaídas",
                        submitText = "Comprar",
                        inputs = {
                            {
                                text = "Cantidad",
                                name = "cantidad",
                                type = "number",
                                isRequired = true,
                            }
                        },
                    })
                    if dialog ~= nil then
                        if dialog.cantidad then
                            QBCore.Functions.TriggerCallback('talk:shop', function() end, 'parachute',
                                30 * dialog.cantidad, dialog.cantidad, 'Paracaídas')
                        else
                            QBCore.Functions.Notify('Te falta algo por terminar', 'info')
                        end
                    end
                end
            }
        },
        {
            header = "Rechazar",
            txt = "Rechaza la oferta",
            icon = 'fa-solid fa-x',
            params = {
                handler = function()
                    QBCore.Functions.Notify("Aquí estoy por si cambias de opinión.", "person")
                end
            }
        },
    })
end)

RegisterNetEvent('police:talk', function ()
    return 
end)

RegisterNetEvent('setnew:waypoint', function()
    SetNewWaypoint(1200.51, -1494.85)
end)

-- venta termita

local termita = {
    Title = 'Comprar taladro',
    Desc =
    'Este taladro te puede venir muy bien si deseas forzar la cerraduras de los trenes de carga que recorren la ciudad.',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'cash',
                label = 'Efectivo',
                ammountneed = 1500,
            },
        },
        reward = {
            {
                item_name = 'thermite',
                label = 'Termita',
                ammountreward = 1,
            },
        },
    }
}


RegisterNetEvent("rDialog:sell:thermite", function()
    exports['RevoQuestions']:OpenDialog(termita)
end)
-- venta de termita

local joyas = {
    Title = 'Vender joyas',
    Desc =
    '¿Tienes joyas de algún robo?. Me interesa comprarlas.',

    siquierestrigearalgomas = false,
    triggername = '',
    howtotrigger = 'client',
    siquiereeliminarlosobjetos = true,
    functions = '',
    triggerclose = '',
    functionsclose = '',

    Items = {
        need = {
            {
                item_name = 'anillo_oro',
                label = 'Anillo',
                ammountneed = 1,
            },
        },
        reward = {
            {
                item_name = 'cash',
                label = 'Efectivo',
                ammountreward = 550,
            },
        },
    }
}

RegisterNetEvent("rDialog:sell:jewelry", function()
    exports['RevoQuestions']:OpenDialog(joyas)
end)