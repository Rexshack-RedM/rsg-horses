local RSGCore = exports['rsg-core']:GetCoreObject()
-------------------
local entities = {}
local horseComps = {}
-------------------
local timeout = false
local timeoutTimer = 30
local horsePed = 0
local horseBlip = nil
local horseSpawned = false
local HorseCalled = false
local horsexp = 0
local horsegender = nil
local horseBonding = 0
local bondingLevel = 0
local horseLevel = 0
-------------------
local lanternequiped = false
local lanternUsed = false
local holsterequiped = false
local holsterUsed = false
-------------------
local HorsePrompts
local HorseLayPrompts
local SaddleBagPrompt
local HorsePLayPrompts
local BrushPrompt
-------------------
local closestStable = nil
local Customize = false
local RotatePrompt
local BuyPrompt
local CustomizePrompt = GetRandomIntInRange(0, 0xffffff)
local Components = lib.load('shared.horse_comp')
local CurrentPrice = 0
local initialHorseComps = {}

MenuData = {}
TriggerEvent('rsg-menubase:getData', function(call)
    MenuData = call
end)
-------------------

function SetupHorsePrompts()

    if horsexp >= Config.TrickXp.Lay then
        local string = Lang:t('action.lay')
        HorseLayPrompts = PromptRegisterBegin()
        PromptSetControlAction(HorseLayPrompts, Config.Prompt.HorseLay)
        string = CreateVarString(10, 'LITERAL_STRING', string)
        PromptSetText(HorseLayPrompts, string)
        PromptSetEnabled(HorseLayPrompts, 1)
        PromptSetVisible(HorseLayPrompts, 1)
        PromptSetStandardMode(HorseLayPrompts,1)
        PromptSetGroup(HorseLayPrompts, HorsePrompts)
        Citizen.InvokeNative(0xC5F428EE08FA7F2C, HorseLayPrompts, true)
        PromptRegisterEnd(HorseLayPrompts)
    end

    if horsexp >= Config.TrickXp.Play then
        local string2 = Lang:t('action.play')
        HorsePLayPrompts = PromptRegisterBegin()
        PromptSetControlAction(HorsePLayPrompts, Config.Prompt.HorsePlay)
        string2 = CreateVarString(10, 'LITERAL_STRING', string2)
        PromptSetText(HorsePLayPrompts, string2)
        PromptSetEnabled(HorsePLayPrompts, 1)
        PromptSetVisible(HorsePLayPrompts, 1)
        PromptSetStandardMode(HorsePLayPrompts,1)
        PromptSetGroup(HorsePLayPrompts, HorsePrompts)
        Citizen.InvokeNative(0xC5F428EE08FA7F2C, HorsePLayPrompts, true)
        PromptRegisterEnd(HorsePLayPrompts)
    end

    local str2 = Lang:t('action.saddlebag')
    SaddleBagPrompt = PromptRegisterBegin()
    PromptSetControlAction(SaddleBagPrompt, Config.Prompt.HorseSaddleBag)
    str2 = CreateVarString(10, 'LITERAL_STRING', str2)
    PromptSetText(SaddleBagPrompt, str2)
    PromptSetEnabled(SaddleBagPrompt, 1)
    PromptSetVisible(SaddleBagPrompt, 1)
    PromptSetStandardMode(SaddleBagPrompt,1)
    PromptSetGroup(SaddleBagPrompt, HorsePrompts)
    Citizen.InvokeNative(0xC5F428EE08FA7F2C, SaddleBagPrompt,true)
    PromptRegisterEnd(SaddleBagPrompt)

    local str3 = Lang:t('action.horsebrush')
    BrushPrompt = PromptRegisterBegin()
    PromptSetControlAction(BrushPrompt, Config.Prompt.HorseBrush)
    str3 = CreateVarString(10, 'LITERAL_STRING', str3)
    PromptSetText(BrushPrompt, str3)
    PromptSetEnabled(BrushPrompt, 1)
    PromptSetVisible(BrushPrompt, 1)
    PromptSetStandardMode(BrushPrompt,1)
    PromptSetGroup(BrushPrompt, HorsePrompts)
    Citizen.InvokeNative(0xC5F428EE08FA7F2C, BrushPrompt,true)
    PromptRegisterEnd(BrushPrompt)

end

------------------------------------
-- get closest stable to store horse
------------------------------------
local function SetClosestStableLocation()
    local pos = GetEntityCoords(cache.ped, true)
    local current = nil
    local dist = nil

    for k, v in pairs(Config.StableSettings) do
        local dest = vector3(v.coords.x, v.coords.y, v.coords.z)
        local dist2 = #(pos - dest)

        if current then
            if dist2 < dist then
                current = v.stableid
                dist = dist2
            end
        else
            dist = dist2
            current = v.stableid
        end
    end

    if current ~= closestStable then
        closestStable = current
    end
end

------------------------------------
-- flee horse
------------------------------------
local function Flee()
    TaskAnimalFlee(horsePed, cache.ped, -1)
    Wait(10000)
	if Config.StoreFleedHorse then
		SetClosestStableLocation()
		TriggerServerEvent('rsg-horses:server:fleeStoreHorse', closestStable)
	end
    DeleteEntity(horsePed)
    horsePed = 0
    HorseCalled = false
end

------------------------------------
-- exports
------------------------------------
-- Export for Horse Level checks
exports('CheckHorseLevel', function()
    return horseLevel
end)

-- Export for Horse Bonding Level checks
exports('CheckHorseBondingLevel', function()
    return bondingLevel
end)

-- Export for active horsePed
exports('CheckActiveHorse', function()
    return horsePed
end)

local function PromptCustom()
    local str
    str = VarString(10, 'LITERAL_STRING', 'Rotate Horses')
    RotatePrompt = PromptRegisterBegin()
    PromptSetControlAction(RotatePrompt, Config.Prompt.Rotate[1])
    PromptSetControlAction(RotatePrompt, Config.Prompt.Rotate[2])
    PromptSetText(RotatePrompt, str)
    PromptSetEnabled(RotatePrompt, true)
    PromptSetVisible(RotatePrompt, true)
    PromptSetStandardMode(RotatePrompt, 1)
    PromptSetGroup(RotatePrompt, CustomizePrompt)
    PromptRegisterEnd(RotatePrompt)
end

local DisableCamera = function()
    RenderScriptCams(false, true, 250, 1, 0)
    DestroyCam(Camera, false)
    SetNuiFocus(false, false)
    Customize = false
    for k, v in pairs(entities) do

        TriggerServerEvent('rsg-horses:server:SetPlayerBucket', false, v.ped)

        if v.ped and DoesEntityExist(v.ped) then
            DeleteEntity(v.ped)
        end
        entities[k] = nil
    end
end

local function createCamera(horses, horsesdata)
    local Coords = GetOffsetFromEntityInWorldCoords(horses, 0, 3.5, 0)
    RenderScriptCams(false, false, 0, 1, 0)
    DestroyCam(Camera, false)
    if not DoesCamExist(Camera) then
        Camera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamActive(Camera, true)
        RenderScriptCams(true, false, 0, true, true)
        SetCamCoord(Camera, Coords.x, Coords.y, Coords.z + 1.5)
        SetCamRot(Camera, -15.0, 0.0, GetEntityHeading(horses) + 180)
        Customize = true
        CameraPromptHorse(horses, horsesdata)
        MainMenu(horses, horsesdata)
    end
end

local EnableKeys = { 0x4BC9DABB, 0x470DC190, 0x8F9F9E58, Config.Prompt.Rotate[1], Config.Prompt.Rotate[2], Config.Prompt.BuyHorses}

function CameraPromptHorse(horses, horsesdata)
    CreateThread(function()
        PromptCustom()
        while Customize do
            Wait(0)

            DisableAllControlActions(0)
            for i = 1, #EnableKeys do
                EnableControlAction(0, EnableKeys[i], true)
            end

            local Crds = GetEntityCoords(horses)

            local lightRange = 15.0
            local lightIntensity = 50.0
            DrawLightWithRange(Crds.x - 5.0, Crds.y - 5.0, Crds.z + 1.0, 255, 255, 255, lightRange, lightIntensity)
            local promptlabel = 'Total Price : $' .. CurrentPrice

            local label = VarString(10, 'LITERAL_STRING', promptlabel)
            PromptSetActiveGroupThisFrame(CustomizePrompt, label)

            if IsControlPressed(0, Config.Prompt.Rotate[1]) then
                SetEntityHeading(horses, GetEntityHeading(horses) - 1)
            end

            if IsControlPressed(0, Config.Prompt.Rotate[2]) then
                SetEntityHeading(horses, GetEntityHeading(horses) + 1)
            end
        end
    end)
end

RegisterNetEvent('rsg-horses:client:custShop', function(data)
    local horsesdata = data.player
    local horseped = horsesdata.horse
    for k, v in pairs(Config.StableSettings) do
        if horsesdata.stable == v.stableid then
            DoScreenFadeOut(0)
            repeat Wait(0) until IsScreenFadedOut()
            local ped = SpawnHorses(horseped, v.horsecustom, v.horsecustom.w)
            TriggerServerEvent('rsg-horses:server:SetPlayerBucket', true, ped)
            createCamera(ped, horsesdata)
            DoScreenFadeIn(1000)
            repeat Wait(0) until IsScreenFadedIn()
            entities[k] = { ped = ped }
        end
    end
end)

-- rename horse name command
RegisterCommand('sethorsename', function()
    local input = lib.inputDialog(Lang:t('menu.horse_rename'), {
        {
            type = 'input',
            isRequired = true,
            label = Lang:t('menu.horse_setname'),
            icon = 'fas fa-horse-head'
        },
    })

    if not input then
        return
    end

    TriggerServerEvent('rsg-horses:renameHorse', input[1])
end, false)

RegisterNetEvent('rsg-horses:client:stablemenu', function(stableid)
    lib.registerContext({
        id = 'stable_menu',
        title = Lang:t('menu.stable_menu'),
        options = {
            {
                title = Lang:t('menu.horse_view_horses'),
                description = Lang:t('menu.horse_view_horses_sub'),
                icon = 'fa-solid fa-eye',
                event = 'rsg-horses:client:menu',
                args = { stableid = stableid },
                arrow = true
            },
            {
                title = Lang:t('menu.horse_sell'),
                description = Lang:t('menu.horse_sell_sub'),
                icon = 'fa-solid fa-coins',
                event = 'rsg-horses:client:MenuDel',
		        args = { stableid = stableid },
                arrow = true
            },
            {
                title = Lang:t('menu.horse_trade'),
                description = Lang:t('menu.horse_trade_sub'),
                icon = 'fa-solid fa-handshake',
                event = 'rsg-horses:client:tradehorse',
                arrow = true
            },
            {
                title = Lang:t('menu.horse_shop'),
                description = Lang:t('menu.horse_shop_sub'),
                event = 'rsg-horses:client:OpenHorseShop',
                icon = 'fa-solid fa-shop',
                arrow = true
            },
            {
                title = Lang:t('menu.horse_store_horse'),
                description = Lang:t('menu.horse_store_horse_sub'),
                icon = 'fa-solid fa-warehouse',
                event = 'rsg-horses:client:storehorse',
                args = { stableid = stableid },
                arrow = true
            },
        }
    })
    lib.showContext("stable_menu")
end)

-- trade horse
local function TradeHorse()
    RSGCore.Functions.TriggerCallback('rsg-horses:server:GetActiveHorse', function(data, newnames)
        if horsePed ~= 0 then
            local player, distance = RSGCore.Functions.GetClosestPlayer()
            if player ~= -1 and distance < 1.5 then
                local playerId = GetPlayerServerId(player)
                local horseId = data.horseid
                TriggerServerEvent('rsg-horses:server:TradeHorse', playerId, horseId)
                RSGCore.Functions.Notify(Lang:t('success.horse_traded'), 'success', 7500)
            else
                RSGCore.Functions.Notify(Lang:t('error.no_nearby_player'), 'success', 7500)
            end
        end
    end)
end

-- place on ground properly
local function PlacePedOnGroundProperly(hPed)
    local playerPed = PlayerPedId()
    local howfar = math.random(15, 30)
    local x, y, z = table.unpack(GetEntityCoords(playerPed))
    local found, groundz, normal = GetGroundZAndNormalFor_3dCoord(x - howfar, y, z)

    if found then
        SetEntityCoordsNoOffset(hPed, x - howfar, y, groundz + normal.z, true)
    end
end

-- calculate horse bonding levels
local function BondingLevels()
    local maxBonding = GetMaxAttributePoints(horsePed, 7)
    local currentBonding = GetAttributePoints(horsePed, 7)
    local thirdBonding = maxBonding / 3

    if currentBonding >= maxBonding then
        bondingLevel = 4
    end

    if currentBonding >= thirdBonding and thirdBonding * 2 > currentBonding then
        bondingLevel = 2
    end

    if currentBonding >= thirdBonding * 2 and maxBonding > currentBonding then
        bondingLevel = 3
    end

    if thirdBonding > currentBonding then
        bondingLevel = 1
    end
end

function getComponentHash(category, value)
    if Components[category] then
        for _, item in ipairs(Components[category]) do
            if item.hashid == value then
                return item.hash
            end
        end
    end
    return 0
end

-- spawn horse
local function SpawnHorse()
    RSGCore.Functions.TriggerCallback('rsg-horses:server:GetActiveHorse', function(data)
        if (data) then
            local ped = PlayerPedId()
            local player = PlayerId()
            local model = GetHashKey(data.horse)
            local location = GetEntityCoords(ped)
            local x, y, z = table.unpack(location)
            local _, nodePosition = GetClosestVehicleNode(x - 15, y, z, 0, 3.0, 0.0)
            local distance = math.floor(#(nodePosition - location))
            local onRoad = false

            if distance < 50 then
                onRoad = true
            end

            if Config.SpawnOnRoadOnly and not onRoad then
                RSGCore.Functions.Notify(Lang:t('error.near_road'), 'error')
                return
            end

            if (location) then
                while not HasModelLoaded(model) do
                    RequestModel(model)
                    Wait(10)
                end

                local heading = 300

                getControlOfEntity(horsePed)

                if horseBlip then
                    RemoveBlip(horseBlip)
                end

                SetEntityAsMissionEntity(horsePed, true, true)
                DeleteEntity(horsePed)
                DeletePed(horsePed)
                SetEntityAsNoLongerNeeded(horsePed)

                horsePed = 0

                if onRoad then
                    horsePed = CreatePed(model, nodePosition, heading, true, true, 0, 0)
                    SetEntityCanBeDamaged(horsePed, false)
                    Citizen.InvokeNative(0x9587913B9E772D29, horsePed, false)
                    onRoad = false
                else
                    horsePed = CreatePed(model, location.x - 10, location.y, location.z, heading, true, true, 0, 0)
                    SetEntityCanBeDamaged(horsePed, false)
                    Citizen.InvokeNative(0x9587913B9E772D29, horsePed, false)
                    PlacePedOnGroundProperly(horsePed)
                end

                while not DoesEntityExist(horsePed) do
                    Wait(10)
                end

                getControlOfEntity(horsePed)

                Citizen.InvokeNative(0x283978A15512B2FE, horsePed, true)                    -- SetRandomOutfitVariation
                horseBlip = Citizen.InvokeNative(0x23F74C2FDA6E7C61, -1230993421, horsePed) -- BlipAddForEntity
                Citizen.InvokeNative(0x9CB1A1623062F402, horseBlip, data.name)              -- SetBlipName
                Citizen.InvokeNative(0x931B241409216C1F, ped, horsePed, true)               -- SetPedOwnsAnimal

                SetModelAsNoLongerNeeded(model)
                SetEntityAsNoLongerNeeded(horsePed)
                SetEntityAsMissionEntity(horsePed, true)
                SetEntityCanBeDamaged(horsePed, true)
                SetPedNameDebug(horsePed, data.name)
                SetPedPromptName(horsePed, data.name)

                -- set horse dirt
                Citizen.InvokeNative(0x5DA12E025D47D4E5, horsePed, 16, data.dirt)

                horseComps[data.horseid] = json.decode(data.components)

                if not horseComps[data.horseid] then
                    horseComps[data.horseid] = {}
                end
    
                for category, value in pairs(horseComps[data.horseid]) do
                    local hash = getComponentHash(category, value)
                    if hash ~= 0 then
                        Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed, tonumber(hash), true, true, true)
                    end
                end

                UpdatePedVariation(horsePed)

                SetPedConfigFlag(horsePed, 297, true)                                                          -- PCF_ForceInteractionLockonOnTargetPed
                Citizen.InvokeNative(0xCC97B29285B1DC3B, horsePed, 1)                                          -- SetAnimalMood

                -- set horse xp and gender
                horsexp = data.horsexp
                horsegender = data.gender

                -- set horse health/stamina/ability/speed/acceleration (increased by horse training)
                local hValue = 0
                local overPower = false

                if horsexp <= 99 then
                    hValue = Config.Level1
                    horseLevel = 1
                    goto continue
                end
                if horsexp >= 100 and horsexp <= 199 then
                    hValue = Config.Level2
                    horseLevel = 2
                    goto continue
                end
                if horsexp >= 200 and horsexp <= 299 then
                    hValue = Config.Level3
                    horseLevel = 3
                    goto continue
                end
                if horsexp >= 300 and horsexp <= 399 then
                    hValue = Config.Level4
                    horseLevel = 4
                    goto continue
                end
                if horsexp >= 400 and horsexp <= 499 then
                    hValue = Config.Level5
                    horseLevel = 5
                    goto continue
                end
                if horsexp >= 500 and horsexp <= 999 then
                    hValue = Config.Level6
                    horseLevel = 6
                    goto continue
                end
                if horsexp >= 1000 and horsexp <= 1999 then
                    hValue = Config.Level7
                    horseLevel = 7
                    goto continue
                end
                if horsexp >= 2000 and horsexp <= 2999 then
                    hValue = Config.Level8
                    horseLevel = 8
                    goto continue
                end
                if horsexp >= 3000 and horsexp <= 3999 then
                    hValue = Config.Level9
                    horseLevel = 9
                    goto continue
                end
                if horsexp >= 4000 then
                    hValue = Config.Level10
                    horseLevel = 10
                    overPower = true
                end

                ::continue::

                SetAttributePoints(horsePed, 0, hValue) -- HEALTH (0-2000)
                SetAttributePoints(horsePed, 1, hValue) -- STAMINA (0-2000)
                SetAttributePoints(horsePed, 4, hValue) -- AGILITY (0-2000)
                SetAttributePoints(horsePed, 5, hValue) -- SPEED (0-2000)
                SetAttributePoints(horsePed, 6, hValue) -- ACCELERATION (0-2000)

                -- overpower settings
                if overPower then
                    EnableAttributeOverpower(horsePed, 0, 5000.0)                       -- health overpower
                    EnableAttributeOverpower(horsePed, 1, 5000.0)                       -- stamina overpower
                    local setoverpower = data.horsexp + .0                              -- convert overpower to float value
                    Citizen.InvokeNative(0xF6A7C08DF2E28B28, horsePed, 0, setoverpower) -- set health with overpower
                    Citizen.InvokeNative(0xF6A7C08DF2E28B28, horsePed, 1, setoverpower) -- set stamina with overpower
                end
                -- end of overpower settings
                -- end set horse health/stamina/ability/speed/acceleration (increased by horse training)

                -- horse bonding level: start
                local bond = Config.MaxBondingLevel
                local bond1 = bond * 0.25
                local bond2 = bond * 0.50
                local bond3 = bond * 0.75

                if horsexp <= bond * 0.25 then -- level 1 (0 -> 1250)
                    horseBonding = 1
                end

                if horsexp > bond1 and horsexp <= bond2 then -- level 2 (1250 -> 2500)
                    horseBonding = 817
                end

                if horsexp > bond2 and horsexp <= bond3 then -- level 3 (2500 -> 3750)
                    horseBonding = 1634
                end

                if horsexp > bond3 then -- level 4 (3750 -> 5000)
                    horseBonding = 2450
                end

                Citizen.InvokeNative(0x09A59688C26D88DF, horsePed, 7, horseBonding)

                BondingLevels()
                -- horse bonding level: end

                local faceFeature = 0.0

                -- set gender of horse
                if horsegender ~= 'male' then
                    faceFeature = 1.0
                end

                Citizen.InvokeNative(0xB8B6430EAD2D2437, horsePed, joaat('PLAYER_HORSE')) -- SetPedPersonality
                Citizen.InvokeNative(0x5653AB26C82938CF, horsePed, 41611, faceFeature)
                Citizen.InvokeNative(0xCC8CA3E88256E58F, horsePed, false, true, true, true, false)

                -- ModifyPlayerUiPromptForPed / Horse Target Prompts / (Block = 0, Hide = 1, Grey Out = 2)
                --Citizen.InvokeNative(0xA3DB37EDF9A74635, player, horsePed, 35, 1, true) -- TARGET_INFO
                Citizen.InvokeNative(0xA3DB37EDF9A74635, player, horsePed, 49, 1, true) -- HORSE_BRUSH
                Citizen.InvokeNative(0xA3DB37EDF9A74635, player, horsePed, 50, 1, true) -- HORSE_FEED

                HorsePrompts = PromptGetGroupIdForTargetEntity(horsePed)

                SetupHorsePrompts()

                moveHorseToPlayer()

                Wait(5000)

                horseSpawned = true
                HorseCalled = true

                if Config.Automount == true then
                    TaskMountAnimal(PlayerPedId(), horsePed, 10000, -1, 1.0, 1, 0, 0)
                end
            end
        end
    end)
end

----------------------------------------------------------------------------------------------------

local function IsPedReadyToRender(...)
    return Citizen.InvokeNative(0xA0BC8FAED8CFEB3C, ...)
end

function UpdatePedVariation(ped)
    Citizen.InvokeNative(0x704C908E9C405136, ped)
    Citizen.InvokeNative(0xCC8CA3E88256E58F, ped, false, true, true, true, false)
    while not IsPedReadyToRender(ped) do
        Wait(1)
    end
end

function CalculatePrice(comp, initial)
    local price = 0

    for category, value in pairs(comp) do
        if Config.PriceComponent[category] and value > 0 and (not initial or initial[category] ~= value) then
            price = price + Config.PriceComponent[category]
        end
    end

    return price
end

function MainMenu(horses, horsedata)
    MenuData.CloseAll()

    local horseid = horsedata.horseid

    if not horseComps[horseid] then
        horseComps[horseid] = {}
        if horsedata.components and horsedata.components ~= "" then
            local success, result = pcall(json.decode, horsedata.components)
            if success then
                horseComps[horseid] = result
            else
                print("Error decoding components: " .. result)
            end
        end
    end

    initialHorseComps = table.copy(horseComps[horseid])  -- Create a deep copy of horseComps for this horse

    -- Terapkan komponen ke kuda
    for category, value in pairs(horseComps[horseid]) do
        local hash = getComponentHash(category, value)
        if hash ~= 0 then
            Citizen.InvokeNative(0xD3A7B003ED343FD9, horses, tonumber(hash), true, true, true)
        end
    end
    local elements = {
        { label = "Horse Component", value = 'component' },
        { label = "Buy Component",   value = 'buy', },
    }
    MenuData.Open('default', GetCurrentResourceName(), 'main_character_creator_menu',
        {
            title = Lang:t('menu.horse_customization'),
            subtext = '',
            align = 'top-left',
            elements = elements,
            itemHeight = "4vh"
        }, function(data, menu)
            if data.current.value == 'component' then
                CustomHorse(horses, horsedata)
            elseif data.current.value == 'buy' then
                TriggerServerEvent('rsg-horses:server:SaveComponent', horseComps[horsedata.horseid], horsedata, CurrentPrice)
                DisableCamera()
                CurrentPrice = 0       -- Reset CurrentPrice when closing the menu
                initialHorseComps = {} -- Clear initialHorseComps
                menu.close()
            end
        end,
        function(_, menu)
            DisableCamera()
            CurrentPrice = 0       -- Reset CurrentPrice when closing the menu
            initialHorseComps = {} -- Clear initialHorseComps
            menu.close()
        end)
end

function CustomHorse(horses, data)
    MenuData.CloseAll()
    CurrentPrice = 0
    local horseid = data.horseid

    local elements = {}

    for k, v in pairs(Components) do
        local categoryHashes = {}
        for i, item in ipairs(v) do
            categoryHashes[i] = item.hash
        end
        
        elements[#elements + 1] = {
            label = k,
            value = horseComps[horseid][k] or 0,
            type = 'slider',
            min = 0,
            max = #v,
            category = k,
            hashes = categoryHashes,
        }
    end

    MenuData.Open('default', GetCurrentResourceName(), 'horse_menu',
        {
            title    = Lang:t('menu.horse_customization'),
            subtext  = '',
            align    = 'top-left',
            elements = elements,
        }, function(data, _)
            if horseComps[horseid][data.current.category] ~= data.current.value then
                horseComps[horseid][data.current.category] = data.current.value

                if data.current.value > 0 then
                    local currentHash = data.current.hashes[data.current.value]
                    Citizen.InvokeNative(0xD3A7B003ED343FD9, horses, tonumber(currentHash), true, true, true)
                    UpdatePedVariation(horses)
                else
                    local hash = Config.ComponentHash[data.current.category]
                    if hash then
                        Citizen.InvokeNative(0xD710A5007C2AC539, horses, hash, 0)
                        Citizen.InvokeNative(0xCC8CA3E88256E58F, horses, 0, 1, 1, 1, 0)
                        UpdatePedVariation(horses)
                    end
                end
            end
            local newPrice = CalculatePrice(horseComps[horseid], initialHorseComps)
            if CurrentPrice ~= newPrice then
                CurrentPrice = newPrice
            end
        end,
        function(_, menu)
            MainMenu(horses, data)
        end)
end

-- Helper function to create a deep copy of a table
function table.copy(t)
    local u = {}
    for k, v in pairs(t) do
        u[k] = type(v) == "table" and table.copy(v) or v
    end
    return setmetatable(u, getmetatable(t))
end

----------------------------------------------------------------------------------------------------

-- move horse to player
function moveHorseToPlayer()
    Citizen.CreateThread(function()
        Citizen.InvokeNative(0x6A071245EB0D1882, horsePed, PlayerPedId(), -1, 7.2, 2.0, 0, 0)
        while horseSpawned == true do
            local coords = GetEntityCoords(PlayerPedId())
            local horseCoords = GetEntityCoords(horsePed)
            local distance = #(coords - horseCoords)
            if (distance < 7.0) then
                ClearPedTasks(horsePed, true, true)
                horseSpawned = false
            else
                HorseCalled = false
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

CreateThread(function()
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
        DestroyAllCams(true)
        DisableCamera()
        MenuData.CloseAll()
        if (horsePed ~= 0) then
            DeletePed(horsePed)
            SetEntityAsNoLongerNeeded(horsePed)
        end
    end
end)

CreateThread(function()
    for key, value in pairs(Config.StableSettings) do
        local StablesBlip = BlipAddForCoords(1664425300, value.coords)
        SetBlipSprite(StablesBlip, joaat(Config.Blip.blipSprite), true)
        SetBlipScale(StablesBlip, Config.Blip.blipScale)
        SetBlipName(StablesBlip, Config.Blip.blipName)
    end
end)

local HorseId = nil

RegisterNetEvent('rsg-horses:client:SpawnHorse', function(data)
    HorseId = data.player.id
    TriggerServerEvent("rsg-horses:server:SetHoresActive", data.player.id)
    RSGCore.Functions.Notify(Lang:t('success.horse_active'), 'success', 7500)
end)

AddEventHandler('rsg-horses:client:FleeHorse', function()
    if horsePed then
        getControlOfEntity(horsePed)

        if horseBlip then
            RemoveBlip(horseBlip)
        end

        SetEntityAsMissionEntity(horsePed, true, true)
        DeleteEntity(horsePed)
        DeletePed(horsePed)
        SetEntityAsNoLongerNeeded(horsePed)

        horsePed = 0
        HorseCalled = false
    end
end)

RegisterNetEvent('rsg-horses:client:storehorse', function(data)
    if (horsePed ~= 0) then
        TriggerServerEvent('rsg-horses:server:SetHoresUnActive', HorseId, data.stableid)
        RSGCore.Functions.Notify(Lang:t('success.storing_horse'), 'success', 7500)
        Flee()
        HorseCalled = false
    else
        RSGCore.Functions.Notify(Lang:t('error.no_horse_out'), 'error', 7500)
    end
end)

RegisterNetEvent("rsg-horses:client:tradehorse", function(data)
    RSGCore.Functions.TriggerCallback('rsg-horses:server:GetActiveHorse', function(data, newnames)
        if (horsePed ~= 0) then
            TradeHorse()
            Flee()
            HorseCalled = false
        else
            RSGCore.Functions.Notify(Lang:t('error.no_horse_out'), 'error', 7500)
        end
    end)
end)

local function HorseOptions(data)
    local menu = {
        {
            title = 'Ride Horse',
            description = 'Ride This Horse',
            icon = 'horse',
            event = 'rsg-horses:client:SpawnHorse',
            args = { player = data },
            arrow = true
        },
        {
            title = Lang:t('menu.horse_customize'),
            description = Lang:t('menu.horse_customize_sub'),
            icon = 'fa-solid fa-screwdriver-wrench',
            event = 'rsg-horses:client:custShop',
            args = { player = data },
            arrow = true
        },
    }

    lib.registerContext({
        id = 'horses_options',
        title = Lang:t('menu.horse_view_horses'),
        position = 'top-right',
        menu = 'horses_view',
        onBack = function() end,
        options = menu
    })
    lib.showContext('horses_options')
end

-- horse menu
RegisterNetEvent('rsg-horses:client:menu', function(data)
    local horses = lib.callback.await('rsg-horses:server:GetHorse', false, data.stableid)

    if #horses <= 0 then
        RSGCore.Functions.Notify(Lang:t('error.no_horses'), 'error')
        return
    end

    local options = {}

    for k, v in pairs(horses) do
        options[#options + 1] = {
            title = v.name,
            description = Lang:t('menu.my_horse_gender') .. v.gender .. Lang:t('menu.my_horse_xp') .. v.horsexp .. Lang:t('menu.my_horse_active') .. v.active,
            icon = 'fa-solid fa-horse',
            arrow = true,
            onSelect = function()
                HorseOptions(v)
            end
        }
    end

    lib.registerContext({
        id = 'horses_view',
        title = Lang:t('menu.horse_view_horses'),
        position = 'top-right',
        menu = 'stable_menu',
        onBack = function() end,
        options = options
    })
    lib.showContext('horses_view')
end)

-- sell horse menu
RegisterNetEvent('rsg-horses:client:MenuDel', function(data)
    local horses = lib.callback.await('rsg-horses:server:GetHorse', false, data.stableid)

    if #horses <= 0 then
        RSGCore.Functions.Notify(Lang:t('error.no_horses'), 'error')
        return
    end

    local options = {}
    for k, v in pairs(horses) do
        options[#options + 1] = {
            title = v.name,
            description = Lang:t('menu.sell_your_horse'),
            icon = 'fa-solid fa-horse',
            serverEvent = 'rsg-horses:server:deletehorse',
            args = { horseid = v.id },
            arrow = true
        }
    end
    lib.registerContext({
        id = 'sellhorse_menu',     -- Corrected the context ID here
        title = Lang:t('menu.sell_horse_menu'),
        position = 'top-right',
        menu = 'stable_menu',
        onBack = function() end,
        options = options
    })
    lib.showContext('sellhorse_menu')     -- Use the correct context ID here
end)
-------------------------------------------------------------------------------

-- call / flee horse
CreateThread(function()
    while true do
        Wait(0)

        if Citizen.InvokeNative(0x91AEF906BCA88877, 0, RSGCore.Shared.Keybinds['H']) then -- call horse
            RSGCore.Functions.GetPlayerData(function(PlayerData)
                if PlayerData.metadata["injail"] == 0 then
                    local coords = GetEntityCoords(PlayerPedId())
                    local horseCoords = GetEntityCoords(horsePed)
                    local distance = #(coords - horseCoords)

                    if not HorseCalled and (distance > 100.0) then
                        SpawnHorse()
                        Wait(3000) -- Spam protect
                    else
                        moveHorseToPlayer()
                    end
                end
            end)
        end

        local size = GetNumberOfEvents(0)
        if size > 0 then
            for i = 0, size - 1 do
                local eventAtIndex = GetEventAtIndex(0, i)
                if eventAtIndex == `EVENT_PLAYER_PROMPT_TRIGGERED` then
                    local eventDataSize = 10
                    local eventDataStruct = DataView.ArrayBuffer(8*eventDataSize) -- buffer must be 8*eventDataSize or bigger
                    for a = 0, eventDataSize -1 do
                      eventDataStruct:SetInt32(8*a ,0)
                    end
                    local is_data_exists = Citizen.InvokeNative(0x57EC5FA4D4D6AFCA, 0, i, eventDataStruct:Buffer(), eventDataSize)

                    if is_data_exists then

                        if eventDataStruct:GetInt32(0) == 33 then
                            if horsePed == eventDataStruct:GetInt32(16) then
                                Flee()
                            end
                        end
                    end
                end
            end
        end
    end
end)

function HorseActions(target, dict, anim)
    if not target then return end
    if not IsEntityPlayingAnim(target, dict, anim, 3) then
        if not HasAnimDictLoaded(dict) then
            RequestAnimDict(dict)
        end
        if not HasAnimDictLoaded("amb_creature_mammal@world_horse_resting@stand_enter") then
            local dictz = "amb_creature_mammal@world_horse_resting@stand_enter"
            RequestAnimDict(dictz)
        end
        TaskPlayAnim(target, "amb_creature_mammal@world_horse_resting@stand_enter", "enter", 1.0, 1.0, -1, 2, 0.0, false, false, false, '', false)
        Citizen.Wait(3000)
        TaskPlayAnim(target, dict, anim, 1.0, 1.0, -1, 2, 0.0, false, false, false, '', false)
    else
        if not HasAnimDictLoaded("amb_creature_mammal@world_horse_resting@quick_exit") then
            local dictx = "amb_creature_mammal@world_horse_resting@quick_exit"
            RequestAnimDict(dictx)
        end
        TaskPlayAnim(target, "amb_creature_mammal@world_horse_resting@quick_exit", "quick_exit", 1.0, 1.0, -1, 2, 0.0, false, false, false, '', false)
        Citizen.Wait(3000)
        ClearPedTasks(target)
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        if horsePed ~= nil then
            if Citizen.InvokeNative(0xC92AC953F0A982AE, HorseLayPrompts) then
                if horsexp >= Config.TrickXp.Lay then
                    HorseActions(horsePed, 'amb_creature_mammal@world_horse_resting@stand_enter', 'base')
                end
            end
            if Citizen.InvokeNative(0xC92AC953F0A982AE, HorsePLayPrompts) then
                if horsexp >= Config.TrickXp.Play then
                    HorseActions(horsePed, 'amb_creature_mammal@world_horse_wallow_shake@idle', 'idle_a')
                end
            end
            if Citizen.InvokeNative(0xC92AC953F0A982AE, SaddleBagPrompt) then
                TriggerEvent('rsg-horses:client:inventoryHorse')
            end
            if Citizen.InvokeNative(0xC92AC953F0A982AE, BrushPrompt) then
                TriggerServerEvent("rsg-horses:server:brushhorse", "horsebrush")
            end
        end
    end
end)

-------------------------------------------------------------------------------

-- horse inventory
RegisterNetEvent('rsg-horses:client:inventoryHorse', function()
    RSGCore.Functions.TriggerCallback('rsg-horses:server:GetActiveHorse', function(data)
        if horsePed == 0 then
            RSGCore.Functions.Notify(Lang:t('error.no_horse_out'), 'error', 7500)
            return
        end

        local horsestash = data.name .. ' ' .. data.horseid
        local invWeight = 0
        local invSlots = 0

        if horsexp <= 99 then
            invWeight = Config.Level1InvWeight
            invSlots = Config.Level1InvSlots
            goto continue
        end
        if horsexp >= 100 and horsexp <= 199 then
            invWeight = Config.Level2InvWeight
            invSlots = Config.Level2InvSlots
            goto continue
        end
        if horsexp >= 200 and horsexp <= 299 then
            invWeight = Config.Level3InvWeight
            invSlots = Config.Level3InvSlots
            goto continue
        end
        if horsexp >= 300 and horsexp <= 399 then
            invWeight = Config.Level4InvWeight
            invSlots = Config.Level4InvSlots
            goto continue
        end
        if horsexp >= 400 and horsexp <= 499 then
            invWeight = Config.Level5InvWeight
            invSlots = Config.Level5InvSlots
            goto continue
        end
        if horsexp >= 500 and horsexp <= 999 then
            invWeight = Config.Level6InvWeight
            invSlots = Config.Level6InvSlots
            goto continue
        end
        if horsexp >= 1000 and horsexp <= 1999 then
            invWeight = Config.Level7InvWeight
            invSlots = Config.Level7InvSlots
            goto continue
        end
        if horsexp >= 2000 and horsexp <= 2999 then
            invWeight = Config.Level8InvWeight
            invSlots = Config.Level8InvSlots
            goto continue
        end
        if horsexp >= 3000 and horsexp <= 3999 then
            invWeight = Config.Level9InvWeight
            invSlots = Config.Level9InvSlots
            goto continue
        end
        if horsexp > 4000 then
            invWeight = Config.Level10InvWeight
            invSlots = Config.Level10InvSlots
        end

        ::continue::

        TriggerServerEvent("inventory:server:OpenInventory", "stash", horsestash,
            { maxweight = invWeight, slots = invSlots, })
        TriggerEvent("inventory:client:SetCurrentStash", horsestash)
    end)
end)

-------------------------------------------------------------------------------

-- player equip horse lantern
RegisterNetEvent('rsg-horses:client:equipHorseLantern')
AddEventHandler('rsg-horses:client:equipHorseLantern', function()
    local hasItem = RSGCore.Functions.HasItem('horselantern', 1)

    if not hasItem then
        RSGCore.Functions.Notify(Lang:t('error.no_lantern'), 'error')
        return
    end

    local pcoords = GetEntityCoords(PlayerPedId())
    local hcoords = GetEntityCoords(horsePed)
    local distance = #(pcoords - hcoords)

    if distance > 2.0 then
        RSGCore.Functions.Notify(Lang:t('error.need_to_be_closer'), 'error')
        return
    end

    if lanternUsed then
        lanternUsed = false
        Wait(5000)
    end

    if lanternequiped == false then
        Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed, 0x635E387C, true, true, true)

        lanternequiped = true
        lanternUsed = true

        RSGCore.Functions.Notify(Lang:t('primary.lantern_equiped'), 'horse', 3000)
        return
    end

    if lanternequiped == true then
        Citizen.InvokeNative(0xD710A5007C2AC539, horsePed, 0x1530BE1C, 0)
        Citizen.InvokeNative(0xCC8CA3E88256E58F, horsePed, 0, 1, 1, 1, 0)

        lanternequiped = false
        lanternUsed = true

        RSGCore.Functions.Notify(Lang:t('primary.lantern_removed'), 'horse', 3000)
        return
    end
end)

-------------------------------------------------------------------------------

-- player equip horse holster
RegisterNetEvent('rsg-horses:client:equipHorseHolster')
AddEventHandler('rsg-horses:client:equipHorseHolster', function()
    local hasItem = RSGCore.Functions.HasItem('horseholster', 1)
    if not hasItem then
        RSGCore.Functions.Notify(Lang:t('error.no_holster'), 'error')
        return
    end

    local pcoords = GetEntityCoords(PlayerPedId())
    local hcoords = GetEntityCoords(horsePed)
    local distance = #(pcoords - hcoords)

    if distance > 2.0 then
        RSGCore.Functions.Notify(Lang:t('error.need_to_be_closer'), 'error')
        return
    end

    if holsterUsed then
        holsterUsed = false
        Wait(5000)
    end

    if holsterequiped == false then
        Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed, 0xF772CED6, true, true, true)

        holsterequiped = true
        holsterUsed = true

        RSGCore.Functions.Notify(Lang:t('primary.holster_equiped'), 'horse', 3000)
        return
    end

    if holsterequiped == true then
        Citizen.InvokeNative(0xD710A5007C2AC539, horsePed, -1408210128, 0)
        Citizen.InvokeNative(0xCC8CA3E88256E58F, horsePed, 0, 1, 1, 1, 0)

        holsterequiped = false
        holsterUsed = true

        RSGCore.Functions.Notify(Lang:t('primary.holster_removed'), 'horse', 3000)
        return
    end
end)

-------------------------------------------------------------------------------

-- player feed horse
RegisterNetEvent('rsg-horses:client:playerfeedhorse')
AddEventHandler('rsg-horses:client:playerfeedhorse', function(itemName)
    local pcoords = GetEntityCoords(PlayerPedId())
    local hcoords = GetEntityCoords(horsePed)

    if #(pcoords - hcoords) > 2.0 then
        RSGCore.Functions.Notify(Lang:t('error.need_to_be_closer'), 'error')
        return
    end

    if Config.HorseFeed[itemName] ~= nil then
        if Config.HorseFeed[itemName]["ismedicine"] ~= nil then
            if Config.HorseFeed[itemName]["ismedicine"] == true then
                -- is medicine
                Citizen.InvokeNative(0xCD181A959CFDD7F4, PlayerPedId(), horsePed, -1355254781, 0, 0) -- TaskAnimalInteraction

                Wait(5000)

                local medicineHash = "consumable_horse_stimulant"
                if Config.HorseFeed[itemName]["medicineHash"] ~= nil then medicineHash = Config.HorseFeed[itemName]
                    ["medicineHash"] end
                TaskAnimalInteraction(PlayerPedId(), horsePed, -1355254781, GetHashKey(medicineHash), 0)

                local valueHealth = Citizen.InvokeNative(0x36731AC041289BB1, horsePed, 0)
                local valueStamina = Citizen.InvokeNative(0x36731AC041289BB1, horsePed, 1)

                if not tonumber(valueHealth) then valueHealth = 0 end
                if not tonumber(valueStamina) then valueStamina = 0 end
                Citizen.Wait(3500)
                Citizen.InvokeNative(0xC6258F41D86676E0, horsePed, 0, valueHealth + Config.HorseFeed[itemName]["health"])
                Citizen.InvokeNative(0xC6258F41D86676E0, horsePed, 1,
                    valueStamina + Config.HorseFeed[itemName]["stamina"])


                Citizen.InvokeNative(0xF6A7C08DF2E28B28, horsePed, 0, 1000.0)
                Citizen.InvokeNative(0xF6A7C08DF2E28B28, horsePed, 1, 1000.0)

                Citizen.InvokeNative(0x50C803A4CD5932C5, true) --core
                Citizen.InvokeNative(0xD4EE21B7CC7FD350, true) --core

                PlaySoundFrontend("Core_Fill_Up", "Consumption_Sounds", true, 0)
            elseif Config.HorseFeed[itemName]["ismedicine"] == false then
                -- is not medicine
                Citizen.InvokeNative(0xCD181A959CFDD7F4, PlayerPedId(), horsePed, -224471938, 0, 0) -- TaskAnimalInteraction

                Wait(5000)

                local horseHealth = Citizen.InvokeNative(0x36731AC041289BB1, horsePed, 0)  -- GetAttributeCoreValue (Health)
                local newHealth = horseHealth + Config.HorseFeed[itemName]["health"]
                local horseStamina = Citizen.InvokeNative(0x36731AC041289BB1, horsePed, 1) -- GetAttributeCoreValue (Stamina)
                local newStamina = horseStamina + Config.HorseFeed[itemName]["stamina"]

                Citizen.InvokeNative(0xC6258F41D86676E0, horsePed, 0, newHealth)  -- SetAttributeCoreValue (Health)
                Citizen.InvokeNative(0xC6258F41D86676E0, horsePed, 1, newStamina) -- SetAttributeCoreValue (Stamina)

                PlaySoundFrontend("Core_Fill_Up", "Consumption_Sounds", true, 0)
            else
                -- have invalid config
                RSGCore.Functions.Notify("[FEED] Feed: " .. itemName .. " have INVALID ismedicine config!", 'error')
            end
        else
            RSGCore.Functions.Notify("[FEED] Feed: " .. itemName .. " do not have ismedicine config!", 'error')
        end
    else
        RSGCore.Functions.Notify("[FEED] Feed: " .. itemName .. " do not exits!", 'error')
    end
end)

-- player brush horse
RegisterNetEvent('rsg-horses:client:playerbrushhorse')
AddEventHandler('rsg-horses:client:playerbrushhorse', function(itemName)
    local pcoords = GetEntityCoords(PlayerPedId())
    local hcoords = GetEntityCoords(horsePed)

    if #(pcoords - hcoords) > 2.0 then
        RSGCore.Functions.Notify(Lang:t('error.need_to_be_closer'), 'error')
        return
    end

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

local RequestControl = function(entity)
    local type = GetEntityType(entity)

    if type < 1 or type > 3 then return end

    NetworkRequestControlOfEntity(entity)
end

local loadAnimDict = function(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

-- Player revive horse
RegisterNetEvent("rsg-horses:client:revivehorse")
AddEventHandler("rsg-horses:client:revivehorse", function(item, data)
    local playerPed = PlayerPedId()
    local playercoords = GetEntityCoords(playerPed)
    local horsecoords = GetEntityCoords(horsePed)
    local distance = #(playercoords - horsecoords)

    if horsePed == 0 then
        RSGCore.Functions.Notify(Lang:t('error.no_horse_out'), 'error')

        return
    end

    if IsEntityDead(horsePed) then
        if distance > 1.5 then
            RSGCore.Functions.Notify(Lang:t('error.horse_too_far'), 'error')

            return
        end

        RequestControl(horsePed)

        local healAnim1Dict1 = "mech_skin@sample@base"
        local healAnim1 = "sample_low"

        loadAnimDict(healAnim1Dict1)

        ClearPedTasks(playerPed)
        ClearPedSecondaryTask(playerPed)
        ClearPedTasksImmediately(playerPed)
        FreezeEntityPosition(playerPed, false)
        SetCurrentPedWeapon(playerPed, `WEAPON_UNARMED`, true)
        TaskPlayAnim(playerPed, healAnim1Dict1, healAnim1, 1.0, 1.0, -1, 0, false, false, false)

        RSGCore.Functions.Progressbar("reviving-horse", Lang:t('menu.reviving_horse'), 3000, false, true,
            {
                disableMovement = true,
                disableCarMovement = false,
                disableMouse = false,
                disableCombat = true,
            }, {}, {}, {}, function() -- Done
                ClearPedTasks(playerPed)
                FreezeEntityPosition(playerPed, false)
                TriggerServerEvent('rsg-horses:server:revivehorse', item)
                SpawnHorse()
            end)
    else
        RSGCore.Functions.Notify(Lang:t('error.horse_not_injured_dead'), 'error')
    end
end)

-------------------------------------------------------------------------------

local horsebusy = false
local candoaction = false

Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local dist = #(GetEntityCoords(playerPed) - GetEntityCoords(horsePed))
        local ZoneTypeId = 1
        local x, y, z = table.unpack(GetEntityCoords(PlayerPedId()))
        local town = Citizen.InvokeNative(0x43AD8FC02B429D33, x, y, z, ZoneTypeId)
        if town == false then
            candoaction = true
        end
        if horsePed ~= 0 and horsebusy and dist < 12 then
            if Citizen.InvokeNative(0x57AB4A3080F85143, horsePed) then -- IsPedUsingAnyScenario
                ClearPedTasks(horsePed)
                horsebusy = false
            end
        end
        if horsePed ~= 0 and not horsebusy and dist > 12 and horseSpawned and candoaction then
            if not Citizen.InvokeNative(0xAAB0FE202E9FC9F0, horsePed, -1) then -- IsMountSeatFree
                return
            end
            Citizen.InvokeNative(0x524B54361229154F, horsePed, joaat('WORLD_ANIMAL_HORSE_RESTING_DOMESTIC'), -1, true, 0,
                GetEntityHeading(horsePed), false)                                                                                                           -- TaskStartScenarioInPlaceHash
            horsebusy = true
        end
        Wait(sleep)
    end
end)

-- save horse attributes 
Citizen.CreateThread(function()
    while true do
        local sleep = 5000
        local horsedirt = Citizen.InvokeNative(0x147149F2E909323C, horsePed, 16, Citizen.ResultAsInteger())
        if horsePed ~= 0 then
            TriggerServerEvent('rsg-horses:server:sethorseAttributes', horsedirt)
        end
        Wait(sleep)
    end
end)

-------------------------------------------------------------------------------

RegisterNetEvent('rsg-horses:client:OpenHorseShop')
AddEventHandler('rsg-horses:client:OpenHorseShop', function()
    local ShopItems = {}

    ShopItems.label = Lang:t('menu.horse_shop')
    ShopItems.items = Config.HorseShop
    ShopItems.slots = #Config.HorseShop
    TriggerServerEvent("inventory:server:OpenInventory", "shop", "HorseShop_" .. math.random(1, 99), ShopItems)
end)

-------------------------------------------------------------------------------

RegisterNetEvent('rsg-horses:client:gethorselocation', function()

    RSGCore.Functions.TriggerCallback('rsg-horses:server:GetAllHorses', function(results)

        if results ~= nil then
            local options = {}
            for i = 1, #results do
                local results = results[i]
                options[#options + 1] = {
                    title = 'Horse: '..results.name,
                    description = 'is stabled in '..results.stable..' active: '..results.active,
                    icon = 'fa-solid fa-horse',
                }
            end
            lib.registerContext({
                id = 'showhorse_menu',
                title = 'Find Your Horse',
                position = 'top-right',
                options = options
            })
            lib.showContext('showhorse_menu')
        else
            RSGCore.Functions.Notify('no horses', 'error')
        end

    end)

end)
