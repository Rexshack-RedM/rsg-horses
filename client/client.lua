local RSGCore = exports['rsg-core']:GetCoreObject()
-------------------
local entities = {}
local npcs = {}
-------------------
local timeout = false
local timeoutTimer = 30
local horsePed = 0
local horseSpawned = false
local HorseCalled = false
local newnames = ''
local horseDBID
-------------------
local ped 
local coords
local hasSpawned = false
local lanternequiped = false
-------------------
local Zones = {}
local zonename = nil
local inStableZone = false
-------------------

RegisterNetEvent('rsg-horses:client:custShop', function()
    local function createCamera(horsePed)
        local coords = GetEntityCoords(horsePed)
        CustomHorse()
        groundCam = CreateCam("DEFAULT_SCRIPTED_CAMERA")
        SetCamCoord(groundCam, coords.x + 0.5, coords.y - 3.6, coords.z )
        SetCamRot(groundCam, 10.0, 0.0, 0 + 20)
        SetCamActive(groundCam, true)
        RenderScriptCams(true, false, 1, true, true)
        fixedCam = CreateCam("DEFAULT_SCRIPTED_CAMERA")
        SetCamCoord(fixedCam, coords.x + 0.5,coords.y - 3.6,coords.z+1.8)
        SetCamRot(fixedCam, -20.0, 0, 0 + -10.0)
        SetCamActive(fixedCam, true)
        SetCamActiveWithInterp(fixedCam, groundCam, 3900, true, true)
        Wait(3900)
        DestroyCam(groundCam)
    end
    if horsePed ~= 0 then
        local pcoords = GetEntityCoords(PlayerPedId())
        local coords = GetEntityCoords(horsePed)
        if #(pcoords - coords) <= 30.0 then
            createCamera(horsePed)
        else
            RSGCore.Functions.Notify('Your Horse Is Too Far!', 'error', 7500)
        end 
    else 
        RSGCore.Functions.Notify('No Horse Detected', 'error', 7500)
    end
end)

-- rename horse name command
RegisterCommand('sethorsename',function(input)
    local input = exports['rsg-input']:ShowInput({
    header = "Name your horse",
    submitText = "Confirm",
    inputs = {
            {
                type = 'text',
                isRequired = true,
                name = 'realinput',
                text = 'text'
            }
        }
    })
    TriggerServerEvent('rsg-horses:renameHorse', input)
end)

-- create stable zones
CreateThread(function() 
    for k=1, #Config.StableZones do
        Zones[k] = PolyZone:Create(Config.StableZones[k].zones, {
            name = Config.StableZones[k].name,
            minZ = Config.StableZones[k].minz,
            maxZ = Config.StableZones[k].maxz,
            debugPoly = false,
        })
        Zones[k]:onPlayerInOut(function(isPointInside)
            if isPointInside then
                inStableZone = true
                zonename = Zones[k].name
                TriggerEvent('rsg-horses:client:triggerStable', zonename)
            else
                inStableZone = false
                TriggerEvent('rsg-horses:client:distroyStable')
            end
        end)
    end
end)

-- trigger stables and create peds and horses
RegisterNetEvent('rsg-horses:client:triggerStable', function(zone)
    if inStableZone == true then
        for k,v in pairs(Config.BoxZones) do
            if k == zone then
                for j, n in pairs(v) do
                    Wait(1)
                    local model = GetHashKey(n.model)
                    while (not HasModelLoaded(model)) do
                        RequestModel(model)
                        Wait(1)
                    end
                    local entity = CreatePed(model, n.coords.x, n.coords.y, n.coords.z-1, n.heading, false, true, 0, 0)
                    while not DoesEntityExist(entity) do
                        Wait(1)
                    end
                    local hasSpawned = true
                    table.insert(entities, entity)
                    Citizen.InvokeNative(0x283978A15512B2FE, entity, true)
                    FreezeEntityPosition(entity, true)
                    SetEntityCanBeDamaged(entity, false)
                    SetEntityInvincible(entity, true)
                    SetBlockingOfNonTemporaryEvents(npc, true)
                    exports['rsg-target']:AddTargetEntity(entity, {
                        options = {
                            {
                                icon = "fas fa-horse-head",
                                label =  n.names.." || " .. n.price ..  "$",
                                targeticon = "fas fa-eye",
                                action = function(newnames)
                                    local dialog = exports['rsg-input']:ShowInput({
                                        header = "Horse Setup",
                                        submitText = "Buy Horse",
                                        inputs = {
                                            {
                                                text = "name",
                                                name = "horsename",
                                                type = "text",
                                                isRequired = true,
                                            },
                                            {
                                                text = "gender",
                                                name = "horsegender",
                                                type = "radio",
                                                options = {
                                                    { value = "male",   text = "Male" },
                                                    { value = "female", text = "Female" },
                                                },
                                            },
                                        }
                                    })
                                    if dialog ~= nil then
                                        for k,v in pairs(dialog) do
                                            newhorsename = dialog.horsename
                                            newhorsegender = dialog.horsegender
                                        end
                                    end
                                    if newhorsename ~= nil then
                                        TriggerServerEvent('rsg-horses:server:BuyHorse', n.price, n.model, newhorsename, newhorsegender)
                                    else
                                        return
                                    end
                                end
                            }
                        },
                        distance = 2.5,
                    })
                    Citizen.InvokeNative(0x9587913B9E772D29, entity, 0)
                    SetModelAsNoLongerNeeded(model)
                end
            else 
            end
        end
        for key,value in pairs(Config.ModelSpawns) do
            while not HasModelLoaded(value.model) do
                RequestModel(value.model)
                Wait(1)
            end
            local ped = CreatePed(value.model, value.coords.x, value.coords.y, value.coords.z - 1.0, value.heading, false, false, 0, 0)
            while not DoesEntityExist(ped) do
                Wait(1)
            end
            Citizen.InvokeNative(0x283978A15512B2FE, ped, true)
            SetEntityCanBeDamaged(ped, false)
            SetEntityInvincible(ped, true)
            FreezeEntityPosition(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            Wait(1)
            exports['rsg-target']:AddTargetEntity(ped, {
                options = {
                    {
                        icon = "fas fa-horse-head",
                        label = "Get your horse",
                        targeticon = "fas fa-eye",
                        action = function()
                            TriggerEvent("rsg-horses:client:menu")
                        end
                    },
                    {
                        icon = "fas fa-horse-head",
                        label = "Store Horse",
                        targeticon = "fas fa-eye",
                        action = function()
                            TriggerEvent("rsg-horses:client:storehorse")
                        end
                    },
                    {
                        icon = "fas fa-horse-head",
                        label = "Sell your horse",
                        targeticon = "fas fa-eye",
                        action = function()
                            TriggerEvent("rsg-horses:client:MenuDel")
                        end
                    },
                    {
                        icon = "fas fa-horse-head",
                        label =  "Tack Shop",
                        targeticon = "fas fa-eye",
                        action = function()
                        TriggerEvent('rsg-horses:client:custShop')
                        end
                    },
                    {
                        icon = "fas fa-horse-head",
                        label =  "Trade Horse",
                        targeticon = "fas fa-eye",
                        action = function()
                        TriggerEvent('rsg-horses:client:tradehorse')
                        end
                    },
                },
                distance = 2.5,
            })
            SetModelAsNoLongerNeeded(value.model)
            table.insert(npcs, ped)
        end
    end
end)

-- destroy stable/npcs once left zone
RegisterNetEvent('rsg-horses:client:distroyStable', function()
    for k,v in pairs(entities) do
        DeletePed(v)
        SetEntityAsNoLongerNeeded(v)
    end
    for k,v in pairs(npcs) do
        DeletePed(v)
        SetEntityAsNoLongerNeeded(v)
    end
end)

-- trade horse
local function TradeHorse()
    RSGCore.Functions.TriggerCallback('rsg-horses:server:GetActiveHorse', function(data,newnames)
        if horsePed ~= 0 then
            local player, distance = RSGCore.Functions.GetClosestPlayer()
            if player ~= -1 and distance < 1.5 then
                local playerId = GetPlayerServerId(player)
                local horseId = data.citizenid
                TriggerServerEvent('rsg-horses:server:TradeHorse', playerId, horseId)
                RSGCore.Functions.Notify('Horse has been traded with nearest person', 'success', 7500)
            else
                RSGCore.Functions.Notify('No nearby person!', 'success', 7500)
            end
        end
    end)
end

-- spawn horse
local function SpawnHorse()
    RSGCore.Functions.TriggerCallback('rsg-horses:server:GetActiveHorse', function(data,newnames)
        if (data) then
            local ped = PlayerPedId()
            local model = GetHashKey(data.horse)
            local location = GetEntityCoords(ped)
            local howfar = math.random(50,100)
            local hname = data.name
            local coords = GetEntityCoords(PlayerPedId())
            local horseCoords = GetEntityCoords(horsePed)
            local distance = GetDistanceBetweenCoords(coords, horsePed)
            if (location) then
                while not HasModelLoaded(model) do
                    RequestModel(model)
                    Wait(10)
                end
                local spawnPosition
                if atCoords == nil then
                    local x, y, z = table.unpack(location)
                    local bool, nodePosition = GetClosestVehicleNode(x, y, z, 0, 3.0, 0.0)
            
                    local index = 0
                    while index <= 25 do
                        local _bool, _nodePosition = GetNthClosestVehicleNode(x, y, z, index, 0, 3.0, 2.5)
                        if _bool == true or _bool == 1 then
                            bool = _bool
                            nodePosition = _nodePosition
                            index = index + 3
                        else
                            break
                        end
                    end
            
                    spawnPosition = nodePosition
                else
                    spawnPosition = atCoords
                end
                if spawnPosition == nil then
                    initializing = false
                    return
                end
                local heading = 300
                if (horsePed == 0) then
                    horsePed = CreatePed(model, spawnPosition, GetEntityHeading(horsePed), true, true, 0, 0)
                    local coords = GetEntityCoords(PlayerPedId())
                    local horseCoords = GetEntityCoords(horsePed)
                    local distance = GetDistanceBetweenCoords(horseCoords, coords)
                    if distance > 150 then
                        RSGCore.Functions.Notify('You need to be near a road!', 'error', 7500)
                        Wait(100)
                        DeleteEntity(horsePed)
                        Wait(100)
                        horsePed = 0
                        HorseCalled = false
                    else 
                        SetModelAsNoLongerNeeded(model)
                        Citizen.InvokeNative(0x58A850EAEE20FAA3, horsePed, true) -- PlaceObjectOnGroundProperly
                        while not DoesEntityExist(horsePed) do
                            Wait(10)
                        end
                        Wait(100)
                        getControlOfEntity(horsePed)
                        Citizen.InvokeNative(0x283978A15512B2FE, horsePed, true) -- SetRandomOutfitVariation
                        Citizen.InvokeNative(0x23F74C2FDA6E7C61, -1230993421, horsePed) -- BlipAddForEntity                        
                        SetModelAsNoLongerNeeded(model)
                        SetPedNameDebug(horsePed, hname)
                        SetPedPromptName(horsePed, hname)
                        -- set horse components
                        Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed, tonumber(data.saddle), true, true, true) -- ApplyShopItemToPed
                        Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed, tonumber(data.blanket), true, true, true) -- ApplyShopItemToPed
                        Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed, tonumber(data.saddlebag), true, true, true) -- ApplyShopItemToPed
                        Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed, tonumber(data.bedroll), true, true, true) -- ApplyShopItemToPed
                        Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed, tonumber(data.horn), true, true, true) -- ApplyShopItemToPed
                        Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed, tonumber(data.stirrup), true, true, true) -- ApplyShopItemToPed
                        Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed, tonumber(data.mane), true, true, true) -- ApplyShopItemToPed
                        Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed, tonumber(data.tail), true, true, true) -- ApplyShopItemToPed
                        Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed, tonumber(data.mask), true, true, true) -- ApplyShopItemToPed
                        Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed, tonumber(data.mustache), true, true, true) -- ApplyShopItemToPed
                        SetPedConfigFlag(horsePed, 297, true) -- PCF_ForceInteractionLockonOnTargetPed
                        Citizen.InvokeNative(0xCC97B29285B1DC3B, horsePed, 1) -- SetAnimalMood
                        -- set horse xp and gender
                        local horsexp = data.horsexp
                        local horsegender = data.gender
                        -- set horse health/stamina (increased by horse training)
                        if horsexp <= 100 then
                            local sethorseheath = tonumber(data.horsexp + Config.InitHorseHealth)
                            local sethorsestamina = tonumber(data.horsexp + Config.InitHorseStamina)
                            Citizen.InvokeNative(0xC6258F41D86676E0, horsePed, 0, sethorseheath) -- SetAttributeCoreValue (horse health)
                            Citizen.InvokeNative(0xC6258F41D86676E0, horsePed, 1, sethorsestamina) -- SetAttributeCoreValue (horse stamina)
                        end
                        if horsexp > 100 then
                            EnableAttributeOverpower(horsePed, 0, 5000.0) -- health overpower
                            EnableAttributeOverpower(horsePed, 1, 5000.0) -- stamina overpower
                            local setoverpower = data.horsexp + .0 -- convert overpower to float value
                            Citizen.InvokeNative(0xF6A7C08DF2E28B28, horsePed, 0, setoverpower) -- set health with overpower
                            Citizen.InvokeNative(0xF6A7C08DF2E28B28, horsePed, 1, setoverpower) -- set stamina with overpower
                        end
                        -- set gender of horse
                        if horsegender == 'male' then
                            Citizen.InvokeNative(0x5653AB26C82938CF, horsePed, 41611, 0.0) -- horse gender (0.0 = male)
                            Citizen.InvokeNative(0xCC8CA3E88256E58F, horsePed, false, true, true, true, false)
                        else
                            Citizen.InvokeNative(0x5653AB26C82938CF, horsePed, 41611, 1.0) -- horse gender (1.0 = female)
                            Citizen.InvokeNative(0xCC8CA3E88256E58F, horsePed, false, true, true, true, false)
                        end
                        horseSpawned = true                    
                        moveHorseToPlayer() 
                    end
                end
            end
        end
    end)
end

----------------------------------------------------------------------------------------------------

local blanketsHash
local saddlesHash
local hornsHash
local saddlebagsHash
local stirrupsHash
local bedrollsHash
local tailsHash
local manesHash
local masksHash
local mustachesHash

MenuData = {}
TriggerEvent('menu_base:getData',function(call)
    MenuData = call
end)

function CustomHorse()
    MenuData.CloseAll()
    local elements = {
            {label = "Blankets",    category = 'blankets',   value = 1, desc = "press [enter] to apply",   type = "slider", min = 1, max = 65},
            {label = "Saddles",     category = 'saddles',    value = 1, desc = "press [enter] to apply",   type = "slider", min = 1, max = 136},
            {label = "Horns",       category = 'horns',      value = 1, desc = "press [enter] to apply",   type = "slider", min = 1, max = 14},
            {label = "Saddle Bags", category = 'saddlebags', value = 1, desc = "press [enter] to apply",   type = "slider", min = 1, max = 20},
            {label = "Stirrups",    category = 'stirrups',   value = 1, desc = "press [enter] to apply",   type = "slider", min = 1, max = 11},
            {label = "Bedrolls",    category = 'bedrolls',   value = 1, desc = "press [enter] to apply",   type = "slider", min = 1, max = 30},
            {label = "Tails",       category = 'tails',      value = 1, desc = "press [enter] to apply",   type = "slider", min = 1, max = 85},
            {label = "Manes",       category = 'manes',      value = 1, desc = "press [enter] to apply",   type = "slider", min = 1, max = 102},
            {label = "Masks",       category = 'masks',      value = 0, desc = "select 0 for no mask",     type = "slider", min = 0, max = 51},
            {label = "Mustaches",   category = 'mustaches',  value = 0, desc = "select 0 for no mustache", type = "slider", min = 0, max = 16},
        }
        MenuData.Open(
        'default', GetCurrentResourceName(), 'horse_menu',
        {
            title    = 'Horse Customization',
            subtext    = '',
            align    = 'top-left',
            elements = elements,
        },
        function(data, menu)
            if data.current.category == 'blankets' then
                TriggerEvent('rsg-horses:client:setBlankets', data.current.category, data.current.value)
            end
            if data.current.category == 'saddles' then
                TriggerEvent('rsg-horses:client:setSaddles', data.current.category, data.current.value)
            end
            if data.current.category == 'horns' then
                TriggerEvent('rsg-horses:client:setHorns', data.current.category, data.current.value)
            end
            if data.current.category == 'saddlebags' then
                TriggerEvent('rsg-horses:client:setSaddlebags', data.current.category, data.current.value)
            end
            if data.current.category == 'stirrups' then
                TriggerEvent('rsg-horses:client:setStirrups', data.current.category, data.current.value)
            end
            if data.current.category == 'bedrolls' then
                TriggerEvent('rsg-horses:client:setBedrolls', data.current.category, data.current.value)
            end
            if data.current.category == 'tails' then
                TriggerEvent('rsg-horses:client:setTails', data.current.category, data.current.value)
            end
            if data.current.category == 'manes' then
                TriggerEvent('rsg-horses:client:setManes', data.current.category, data.current.value)
            end
            if data.current.category == 'masks' then
                TriggerEvent('rsg-horses:client:setMasks', data.current.category, data.current.value)
            end
            if data.current.category == 'mustaches' then
                TriggerEvent('rsg-horses:client:setMustaches', data.current.category, data.current.value)
            end
        end,
        function(data, menu)
        menu.close()
        TriggerEvent('rsg-horses:closeMenu')
    end)
end

-- handle blankets compontent
RegisterNetEvent('rsg-horses:client:setBlankets',function(category, value)
    if category == 'blankets' then
        for k, v in pairs(Components.HorseBlankets) do
            if value == v.hashid then
                blanketsHash = v.hash
            end
        end
        RSGCore.Functions.TriggerCallback('rsg-horses:server:GetActiveHorse', function(data, newnames)
        local ped = PlayerPedId()
        local mount = Citizen.InvokeNative(0x4C8B59171957BCF7, ped)
            if mount ~= nil then
                Citizen.InvokeNative(0xD3A7B003ED343FD9, mount, tonumber(blanketsHash), true, true, true) 
                TriggerServerEvent('rsg-horses:server:SaveBlankets', blanketsHash)
            else
                RSGCore.Functions.Notify('No Horse Found', 'error')
            end
        end)
    else
        print('something went wrong!')
    end
end)

-- handle saddles compontent
RegisterNetEvent('rsg-horses:client:setSaddles',function(category, value)
    if category == 'saddles' then
        for k, v in pairs(Components.HorseSaddles) do
            if value == v.hashid then
                saddlesHash = v.hash
            end
        end
        RSGCore.Functions.TriggerCallback('rsg-horses:server:GetActiveHorse', function(data, newnames)
        local ped = PlayerPedId()
        local mount = Citizen.InvokeNative(0x4C8B59171957BCF7, ped)
            if mount ~= nil then
                Citizen.InvokeNative(0xD3A7B003ED343FD9, mount, tonumber(saddlesHash), true, true, true) 
                TriggerServerEvent('rsg-horses:server:SaveSaddles', saddlesHash)
            else
                RSGCore.Functions.Notify('No Horse Found', 'error')
            end
        end)
    else
        print('something went wrong!')
    end
end)

-- handle horns compontent
RegisterNetEvent('rsg-horses:client:setHorns',function(category, value)
    if category == 'horns' then
        for k, v in pairs(Components.HorseHorns) do
            if value == v.hashid then
                hornsHash = v.hash
            end
        end
        RSGCore.Functions.TriggerCallback('rsg-horses:server:GetActiveHorse', function(data, newnames)
        local ped = PlayerPedId()
        local mount = Citizen.InvokeNative(0x4C8B59171957BCF7, ped)
            if mount ~= nil then
                Citizen.InvokeNative(0xD3A7B003ED343FD9, mount, tonumber(hornsHash), true, true, true) 
                TriggerServerEvent('rsg-horses:server:SaveHorns', hornsHash)
            else
                RSGCore.Functions.Notify('No Horse Found', 'error')
            end
        end)
    else
        print('something went wrong!')
    end
end)

-- handle saddlebags compontent
RegisterNetEvent('rsg-horses:client:setSaddlebags',function(category, value)
    if category == 'saddlebags' then
        for k, v in pairs(Components.HorseSaddlebags) do
            if value == v.hashid then
                saddlebagsHash = v.hash
            end
        end
        RSGCore.Functions.TriggerCallback('rsg-horses:server:GetActiveHorse', function(data, newnames)
        local ped = PlayerPedId()
        local mount = Citizen.InvokeNative(0x4C8B59171957BCF7, ped)
            if mount ~= nil then
                Citizen.InvokeNative(0xD3A7B003ED343FD9, mount, tonumber(saddlebagsHash), true, true, true) 
                TriggerServerEvent('rsg-horses:server:SaveSaddlebags', saddlebagsHash)
            else
                RSGCore.Functions.Notify('No Horse Found', 'error')
            end
        end)
    else
        print('something went wrong!')
    end
end)

-- handle stirrups compontent
RegisterNetEvent('rsg-horses:client:setStirrups',function(category, value)
    if category == 'stirrups' then
        for k, v in pairs(Components.HorseStirrups) do
            if value == v.hashid then
                stirrupsHash = v.hash
            end
        end
        RSGCore.Functions.TriggerCallback('rsg-horses:server:GetActiveHorse', function(data, newnames)
        local ped = PlayerPedId()
        local mount = Citizen.InvokeNative(0x4C8B59171957BCF7, ped)
            if mount ~= nil then
                Citizen.InvokeNative(0xD3A7B003ED343FD9, mount, tonumber(stirrupsHash), true, true, true) 
                TriggerServerEvent('rsg-horses:server:SaveStirrups', stirrupsHash)
            else
                RSGCore.Functions.Notify('No Horse Found', 'error')
            end
        end)
    else
        print('something went wrong!')
    end
end)

-- handle bedrolls compontent
RegisterNetEvent('rsg-horses:client:setBedrolls',function(category, value)
    if category == 'bedrolls' then
        for k, v in pairs(Components.HorseBedrolls) do
            if value == v.hashid then
                bedrollsHash = v.hash
            end
        end
        RSGCore.Functions.TriggerCallback('rsg-horses:server:GetActiveHorse', function(data, newnames)
        local ped = PlayerPedId()
        local mount = Citizen.InvokeNative(0x4C8B59171957BCF7, ped)
            if mount ~= nil then
                Citizen.InvokeNative(0xD3A7B003ED343FD9, mount, tonumber(bedrollsHash), true, true, true) 
                TriggerServerEvent('rsg-horses:server:SaveBedrolls', bedrollsHash)
            else
                RSGCore.Functions.Notify('No Horse Found', 'error')
            end
        end)
    else
        print('something went wrong!')
    end
end)

-- handle tails compontent
RegisterNetEvent('rsg-horses:client:setTails',function(category, value)
    if category == 'tails' then
        for k, v in pairs(Components.HorseTails) do
            if value == v.hashid then
                tailsHash = v.hash
            end
        end
        RSGCore.Functions.TriggerCallback('rsg-horses:server:GetActiveHorse', function(data, newnames)
        local ped = PlayerPedId()
        local mount = Citizen.InvokeNative(0x4C8B59171957BCF7, ped)
            if mount ~= nil then
                Citizen.InvokeNative(0xD3A7B003ED343FD9, mount, tonumber(tailsHash), true, true, true) 
                TriggerServerEvent('rsg-horses:server:SaveTails', tailsHash)
            else
                RSGCore.Functions.Notify('No Horse Found', 'error')
            end
        end)
    else
        print('something went wrong!')
    end
end)

-- handle manes compontent
RegisterNetEvent('rsg-horses:client:setManes',function(category, value)
    if category == 'manes' then
        for k, v in pairs(Components.HorseManes) do
            if value == v.hashid then
                manesHash = v.hash
            end
        end
        RSGCore.Functions.TriggerCallback('rsg-horses:server:GetActiveHorse', function(data, newnames)
        local ped = PlayerPedId()
        local mount = Citizen.InvokeNative(0x4C8B59171957BCF7, ped)
            if mount ~= nil then
                Citizen.InvokeNative(0xD3A7B003ED343FD9, mount, tonumber(manesHash), true, true, true) 
                TriggerServerEvent('rsg-horses:server:SaveManes', manesHash)
            else
                RSGCore.Functions.Notify('No Horse Found', 'error')
            end
        end)
    else
        print('something went wrong!')
    end
end)

-- handle masks compontent
RegisterNetEvent('rsg-horses:client:setMasks',function(category, value)
    if category == 'masks' then
        if value == 0 then
            RSGCore.Functions.TriggerCallback('rsg-horses:server:GetActiveHorse', function(data, newnames)
            local ped = PlayerPedId()
            local mount = Citizen.InvokeNative(0x4C8B59171957BCF7, ped)
                if mount ~= nil then
                    Citizen.InvokeNative(0xD710A5007C2AC539, mount, 0xD3500E5D, 0)
                    Citizen.InvokeNative(0xCC8CA3E88256E58F, mount, 0, 1, 1, 1, 0)
                    TriggerServerEvent('rsg-horses:server:SaveMasks', 0)
                else
                    RSGCore.Functions.Notify('No Horse Found', 'error')
                end
            end)
        else
            for k, v in pairs(Components.HorseMasks) do
                if value == v.hashid then
                    masksHash = v.hash
                end
            end
            RSGCore.Functions.TriggerCallback('rsg-horses:server:GetActiveHorse', function(data, newnames)
            local ped = PlayerPedId()
            local mount = Citizen.InvokeNative(0x4C8B59171957BCF7, ped)
                if mount ~= nil then
                    Citizen.InvokeNative(0xD3A7B003ED343FD9, mount, tonumber(masksHash), true, true, true) 
                    TriggerServerEvent('rsg-horses:server:SaveMasks', masksHash)
                else
                    RSGCore.Functions.Notify('No Horse Found', 'error')
                end
            end)
        end
    else
        print('something went wrong!')
    end
end)

-- handle mustaches compontent
RegisterNetEvent('rsg-horses:client:setMustaches',function(category, value)
    if category == 'mustaches' then
        if value == 0 then
            RSGCore.Functions.TriggerCallback('rsg-horses:server:GetActiveHorse', function(data, newnames)
            local ped = PlayerPedId()
            local mount = Citizen.InvokeNative(0x4C8B59171957BCF7, ped)
                if mount ~= nil then
                    Citizen.InvokeNative(0xD710A5007C2AC539, mount, 0x30DEFDDF, 0)
                    Citizen.InvokeNative(0xCC8CA3E88256E58F, mount, 0, 1, 1, 1, 0)
                    TriggerServerEvent('rsg-horses:server:SaveMustaches', 0)
                else
                    RSGCore.Functions.Notify('No Horse Found', 'error')
                end
            end)
        else
            for k, v in pairs(Components.HorseMustaches) do
                if value == v.hashid then
                    mustachesHash = v.hash
                end
            end
            RSGCore.Functions.TriggerCallback('rsg-horses:server:GetActiveHorse', function(data, newnames)
            local ped = PlayerPedId()
            local mount = Citizen.InvokeNative(0x4C8B59171957BCF7, ped)
                if mount ~= nil then
                    Citizen.InvokeNative(0xD3A7B003ED343FD9, mount, tonumber(mustachesHash), true, true, true) 
                    TriggerServerEvent('rsg-horses:server:SaveMustaches', mustachesHash)
                else
                    RSGCore.Functions.Notify('No Horse Found', 'error')
                end
            end)
        end
    else
        print('something went wrong!')
    end
end)

----------------------------------------------------------------------------------------------------

RegisterNetEvent('rsg-horses:closeMenu', function()
    Wait(1000)
    DestroyAllCams(true)
end)

RegisterNetEvent('rsg-horses:closeMenu', function()
    exports['rsg-menu']:closeMenu()
end)

-- move horse to player
function moveHorseToPlayer()
    Citizen.CreateThread(function()
        --Citizen.InvokeNative(0x6A071245EB0D1882, horsePed, PlayerPedId(), -1, 5.0, 15.0, 0, 0)
        Citizen.InvokeNative(0x6A071245EB0D1882, horsePed, PlayerPedId(), -1, 7.2, 2.0, 0, 0)
        while horseSpawned == true do
            local coords = GetEntityCoords(PlayerPedId())
            local horseCoords = GetEntityCoords(horsePed)
            local distance = #(coords - horseCoords)
            if (distance < 7.0) then
                ClearPedTasks(horsePed, true, true)
                horseSpawned = false
            end
            Wait(1000)
        end
    end)
end

function setPedDefaultOutfit(model)
    return Citizen.InvokeNative(0x283978A15512B2FE, model, true)
end

function getControlOfEntity(entity)
    NetworkRequestControlOfEntity(entity)
    SetEntityAsMissionEntity(entity, true, true)
    local timeout = 2000

    while timeout > 0 and NetworkHasControlOfEntity(entity) == nil do
        Wait(100)
        timeout = timeout - 100
    end
    return NetworkHasControlOfEntity(entity)
end

Citizen.CreateThread(function()
    while true do
        if (timeout) then
            if (timeoutTimer == 0) then
                timeout = false
            end
            timeoutTimer = timeoutTimer - 1
            Wait(1000)
        end
        Wait(0)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if (resource == GetCurrentResourceName()) then
        for k,v in pairs(entities) do
            DeletePed(v)
            SetEntityAsNoLongerNeeded(v)
        end
        for k,v in pairs(npcs) do
            DeletePed(v)
            SetEntityAsNoLongerNeeded(v)
        end
        if (horsePed ~= 0) then
            DeletePed(horsePed)
            SetEntityAsNoLongerNeeded(horsePed)
        end
    end
end)

CreateThread(function()
    for key,value in pairs(Config.ModelSpawns) do    
        local StablesBlip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, value.coords)
        SetBlipSprite(StablesBlip, GetHashKey(Config.Blip.blipSprite), true)
        SetBlipScale(StablesBlip, Config.Blip.blipScale)
        Citizen.InvokeNative(0x9CB1A1623062F402, StablesBlip, Config.Blip.blipName)
    end
end)

local HorseId = nil

RegisterNetEvent('rsg-horses:client:SpawnHorse', function(data)
    HorseId = data.player.id
    TriggerServerEvent("rsg-horses:server:SetHoresActive", data.player.id)
    RSGCore.Functions.Notify('Horse has been set active call from back by whistling', 'success', 7500)
end)

RegisterNetEvent("rsg-horses:client:storehorse", function(data)
 if (horsePed ~= 0) then
    TriggerServerEvent("rsg-horses:server:SetHoresUnActive", HorseId)
    RSGCore.Functions.Notify('Taking your horse to the back', 'success', 7500)
    Flee()
    Wait(10000)
    DeletePed(horsePed)
    SetEntityAsNoLongerNeeded(horsePed)
    HorseCalled = false
    end
end)

RegisterNetEvent("rsg-horses:client:tradehorse", function(data)
    RSGCore.Functions.TriggerCallback('rsg-horses:server:GetActiveHorse', function(data,newnames)
        if (horsePed ~= 0) then
            TradeHorse()
            Flee()
            Wait(10000)
            DeletePed(horsePed)
            SetEntityAsNoLongerNeeded(horsePed)
            HorseCalled = false
        else
            RSGCore.Functions.Notify('You dont have a horse out', 'success', 7500)
        end
    end)
end)

RegisterNetEvent('rsg-horses:client:menu', function()
    local GetHorse = {
        {
            header = "| My Horses |",
            isMenuHeader = true,
            icon = "fa-solid fa-circle-user",
        },
    }
    RSGCore.Functions.TriggerCallback('rsg-horses:server:GetHorse', function(cb)
        for _, v in pairs(cb) do
            GetHorse[#GetHorse + 1] = {
                header = v.name,
                txt = 'Gender : '..v.gender..' / XP : '..v.horsexp..' / Active : '..v.active,
                icon = "fa-solid fa-circle-user",
                params = {
                    event = "rsg-horses:client:SpawnHorse",
                    args = {
                        player = v,
                        active = 1
                    }
                }
            }
        end
        exports['rsg-menu']:openMenu(GetHorse)
    end)
end)

RegisterNetEvent('rsg-horses:client:MenuDel', function()
    local GetHorse = {
        {
            header = "| Sell Horses |",
            isMenuHeader = true,
            icon = "fa-solid fa-circle-user",
        },
    }
    RSGCore.Functions.TriggerCallback('rsg-horses:server:GetHorse', function(cb)
        for _, v in pairs(cb) do
            GetHorse[#GetHorse + 1] = {
                header = v.name,
                txt = "Sell you horse",
                icon = "fa-solid fa-circle-user",
                params = {
                    event = "rsg-horses:client:MenuDelC",
                    args = {}
                }
            }
        end
        exports['rsg-menu']:openMenu(GetHorse)
    end)
end)


RegisterNetEvent('rsg-horses:client:MenuDelC', function(data)
    local GetHorse = {
        {
            header = "| Confirm Sell Horses |",
            isMenuHeader = true,
            icon = "fa-solid fa-circle-user",
        },
    }
    RSGCore.Functions.TriggerCallback('rsg-horses:server:GetHorse', function(cb)
        for _, v in pairs(cb) do
            GetHorse[#GetHorse + 1] = {
                header = v.name,
                txt = "Doing this will make you lose your horse forever!",
                icon = "fa-solid fa-circle-user",
                params = {
                    event = "rsg-horses:client:DeleteHorse",
                    args = {
                        player = v,
                        active = 1
                    }
                }
            }
        end
        exports['rsg-menu']:openMenu(GetHorse)
    end)
end)

RegisterNetEvent('rsg-horses:client:DeleteHorse', function(data)
    RSGCore.Functions.Notify('Horse has been successfully removed', 'success', 7500)
    TriggerServerEvent("rsg-horses:server:DelHores", data.player.id)
end)

-------------------------------------------------------------------------------

-- flee horse
local function Flee()
    TaskAnimalFlee(horsePed, PlayerPedId(), -1)
    Wait(10000)
    DeleteEntity(horsePed)
    Wait(1000)
    horsePed = 0
    HorseCalled = false
end

-- call / flee horse
CreateThread(function()
    while true do
        Wait(1)
        if Citizen.InvokeNative(0x91AEF906BCA88877, 0, RSGCore.Shared.Keybinds['H']) then -- call horse
            if not HorseCalled then
                SpawnHorse()
                HorseCalled = true
                Wait(10000) -- Spam protect
            else
                moveHorseToPlayer()
            end
        elseif Citizen.InvokeNative(0x91AEF906BCA88877, 0, RSGCore.Shared.Keybinds['HorseCommandFlee']) then -- flee horse
            if horseSpawned ~= 0 then
                Flee()
            end
        end
    end
end)

-------------------------------------------------------------------------------

-- open inventory by key
CreateThread(function()
    while true do
        Wait(1)
        if Citizen.InvokeNative(0x580417101DDB492F, 0, RSGCore.Shared.Keybinds['B']) then
            TriggerEvent('rsg-horses:client:inventoryHorse')
        end
    end
end)

-- horse inventory
RegisterNetEvent('rsg-horses:client:inventoryHorse', function()
    RSGCore.Functions.TriggerCallback('rsg-horses:server:GetActiveHorse', function(data, newnames)
        if horsePed ~= 0 then
            local pcoords = GetEntityCoords(PlayerPedId())
            local hcoords = GetEntityCoords(horsePed)
            if #(pcoords - hcoords) <= 1.7 then
                local horsestash = data.name..data.horseid
                TriggerServerEvent("inventory:server:OpenInventory", "stash", horsestash, { maxweight = Config.HorseInvWeight, slots = Config.HorseInvSlots, })
                TriggerEvent("inventory:client:SetCurrentStash", horsestash)
            else
                RSGCore.Functions.Notify('you are NOT in distance to open inventory!', 'error', 7500)
            end 
        else
            RSGCore.Functions.Notify('you do not have a horse active!', 'error', 7500)
        end
    end)
end)  

-------------------------------------------------------------------------------

-- player equip horse lantern
RegisterNetEvent('rsg-horses:client:equipHorseLantern')
AddEventHandler('rsg-horses:client:equipHorseLantern', function()
    local hasItem = RSGCore.Functions.HasItem('horselantern', 1)
    if hasItem then
        local pcoords = GetEntityCoords(PlayerPedId())
        local hcoords = GetEntityCoords(horsePed)
        if #(pcoords - hcoords) <= 3.0 then
            if lanternequiped == false then
                Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed, 0x635E387C, true, true, true)
                lanternequiped = true
                RSGCore.Functions.Notify('horse lantern equiped', 'success')
            elseif lanternequiped == true then
                Citizen.InvokeNative(0xD710A5007C2AC539, horsePed, 0x1530BE1C, 0)
                Citizen.InvokeNative(0xCC8CA3E88256E58F, horsePed, 0, 1, 1, 1, 0)
                lanternequiped = false
                RSGCore.Functions.Notify('horse lantern removed', 'primary')
            end
        else
            RSGCore.Functions.Notify('you need to be closer to do that!', 'error')
        end
    else
        RSGCore.Functions.Notify('you don\'t have a horse lantern!', 'error')
    end
end)

-------------------------------------------------------------------------------

-- player feed horse
RegisterNetEvent('rsg-horses:client:playerfeedhorse')
AddEventHandler('rsg-horses:client:playerfeedhorse', function(itemName)
    if itemName == 'carrot' then
        Citizen.InvokeNative(0xCD181A959CFDD7F4, PlayerPedId(), horsePed, -224471938, 0, 0) -- TaskAnimalInteraction
        Wait(5000)
        local horseHealth = Citizen.InvokeNative(0x36731AC041289BB1, horsePed, 0) -- GetAttributeCoreValue (Health)
        local newHealth = horseHealth + Config.FeedCarrotHealth
        local horseStamina = Citizen.InvokeNative(0x36731AC041289BB1, horsePed, 1) -- GetAttributeCoreValue (Stamina)
        print(horseStamina)
        print(Config.FeedCarrotStamina)
        local newStamina = horseStamina + Config.FeedCarrotStamina
        Citizen.InvokeNative(0xC6258F41D86676E0, horsePed, 0, newHealth) -- SetAttributeCoreValue (Health)
        Citizen.InvokeNative(0xC6258F41D86676E0, horsePed, 1, newStamina) -- SetAttributeCoreValue (Stamina)
        PlaySoundFrontend("Core_Fill_Up", "Consumption_Sounds", true, 0)
    elseif itemName == 'sugarcube' then
        Citizen.InvokeNative(0xCD181A959CFDD7F4, PlayerPedId(), horsePed, -224471938, 0, 0) -- TaskAnimalInteraction
        Wait(5000)
        local horseHealth = Citizen.InvokeNative(0x36731AC041289BB1, horsePed, 0) -- GetAttributeCoreValue (Health)
        local newHealth = horseHealth + Config.FeedSugarCubeHealth
        local horseStamina = Citizen.InvokeNative(0x36731AC041289BB1, horsePed, 1) -- GetAttributeCoreValue (Stamina)
        local newStamina = horseStamina + Config.FeedSugarCubeStamina
        Citizen.InvokeNative(0xC6258F41D86676E0, horsePed, 0, newHealth) -- SetAttributeCoreValue (Health)
        Citizen.InvokeNative(0xC6258F41D86676E0, horsePed, 1, newStamina) -- SetAttributeCoreValue (Stamina)
        PlaySoundFrontend("Core_Fill_Up", "Consumption_Sounds", true, 0)
    else
        print("something went wrong")
    end
end)

-- player brush horse
RegisterNetEvent('rsg-horses:client:playerbrushhorse')
AddEventHandler('rsg-horses:client:playerbrushhorse', function(itemName)
    Citizen.InvokeNative(0xCD181A959CFDD7F4, PlayerPedId(), horsePed, `INTERACTION_BRUSH`, 0, 0)
    Wait(8000)
    Citizen.InvokeNative(0xE3144B932DFDFF65, horsePed, 0.0, -1, 1, 1)
    ClearPedEnvDirt(horsePed)
    ClearPedDamageDecalByZone(horsePed, 10, "ALL")
    ClearPedBloodDamage(horsePed)
    Citizen.InvokeNative(0xD8544F6260F5F01E, horsePed, 10)
    PlaySoundFrontend("Core_Fill_Up", "Consumption_Sounds", true, 0)
end)

-------------------------------------------------------------------------------
