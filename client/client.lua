local RSGCore = exports['rsg-core']:GetCoreObject()
local Components = lib.load('shared.horse_comp')
local HorseSettings = lib.load('shared.horse_settings')
lib.locale()

------------------------------------
-- state
------------------------------------
local horsePed         = 0
local horseBlip        = nil
local horseName        = nil
local horseSpawned     = false -- true while the horse is walking to the player after a call
local IsBeingRevived   = false
local fleeing          = false
local horsexp          = 0
local horseLevel       = 0
local bondingLevel     = 0
local spawnAgeSeconds  = nil   -- age_seconds at spawn, used for local growth scaling
local spawnGameTimer   = 0
local horseComps       = {}
local lanternEquipped  = false
local holsterEquipped  = false
local storedWeaponHash = nil

local HorsePrompts, HorseLayPrompt, HorsePlayPrompt

closestStable = nil -- global: read by showroom.lua

-- customization state
local Camera            = nil
local CustomizeActive   = false
local CustomizeHorseId  = nil
local CustomizeHorsePed = nil
local initialHorseComps = {}

local HOLSTER_COMPONENT = 0xF772CED6
local LANTERN_COMPONENT = 0x635E387C

local CATEGORY_ICONS = {
    Blankets   = 'icons/horse_blankets.png',
    Saddles    = 'icons/horse_saddles.png',
    Horns      = 'icons/saddle_horns.png',
    Saddlebags = 'icons/horse_saddlebags.png',
    Stirrups   = 'icons/saddle_stirrups.png',
    Bedrolls   = 'icons/horse_bedrolls.png',
    Tails      = 'icons/horse_tails.png',
    Manes      = 'icons/horse_manes.png',
}

local HorsePrices = {}
for _, v in pairs(HorseSettings) do
    HorsePrices[v.horsemodel] = v.horseprice
end

------------------------------------
-- small helpers
------------------------------------
local function Notify(description, nType, title, duration)
    lib.notify({ title = title, description = description, type = nType or 'inform', duration = duration or 5000 })
end

local function HorseExists()
    return horsePed ~= 0 and DoesEntityExist(horsePed)
end

local function DistanceToHorse()
    if not HorseExists() then return math.huge end
    return #(GetEntityCoords(cache.ped) - GetEntityCoords(horsePed))
end

function getComponentHash(category, value)
    for _, item in ipairs(Components[category] or {}) do
        if item.hashid == value then return item.hash end
    end
    return 0
end

local function IsPedReadyToRender(ped)
    return Citizen.InvokeNative(0xA0BC8FAED8CFEB3C, ped)
end

function UpdatePedVariation(ped)
    Citizen.InvokeNative(0x704C908E9C405136, ped)
    Citizen.InvokeNative(0xCC8CA3E88256E58F, ped, false, true, true, true, false)
    local tries = 0
    while not IsPedReadyToRender(ped) and tries < 200 do
        Wait(1)
        tries = tries + 1
    end
end

local function ApplyComponents(ped, comps)
    for category, value in pairs(comps or {}) do
        local hash = getComponentHash(category, value)
        if hash ~= 0 then
            Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, tonumber(hash), true, true, true)
        end
    end
end

local function ComputeHorseScale(ageSeconds)
    if not Config.Growth or not Config.Growth.enabled then return 1.0 end
    local minScale = Config.Growth.minScale or 0.4
    local adultSeconds = (Config.Growth.growthMinutesToAdult or 120) * 60
    if adultSeconds <= 0 then return 1.0 end
    local t = math.max(0.0, math.min(1.0, ageSeconds / adultSeconds))
    return minScale + (1.0 - minScale) * t
end

------------------------------------
-- NUI helpers
------------------------------------
local nuiIsOpen = false
local NuiLocale = nil

local function GetPlayerMoney()
    local PlayerData = RSGCore.Functions.GetPlayerData()
    if not PlayerData or not PlayerData.money then return 0, 0 end
    return PlayerData.money.cash or 0, PlayerData.money.gold or 0
end

local function LoadNuiLocale()
    if NuiLocale then return NuiLocale end
    local resource = GetCurrentResourceName()
    local raw = LoadResourceFile(resource, ('locales/%s.json'):format(GetConvar('ox:locale', 'en')))
        or LoadResourceFile(resource, 'locales/en.json')
    local ok, decoded = pcall(json.decode, raw or '{}')
    NuiLocale = (ok and decoded) or {}
    return NuiLocale
end


local function OpenNui(action, data)
    local cash, gold = GetPlayerMoney()
    local msg = { action = action, stableId = closestStable, money = { cash = cash, gold = gold } }
    for k, v in pairs(data or {}) do msg[k] = v end
    SendNUIMessage({ action = 'setLocale', locale = LoadNuiLocale() })
    SendNUIMessage(msg)
    SetNuiFocus(true, true)
    nuiIsOpen = true
end

-- keep displayed funds live while any stable screen is open
RegisterNetEvent('RSGCore:Client:OnMoneyChange', function()
    if not nuiIsOpen then return end
    local cash, gold = GetPlayerMoney()
    SendNUIMessage({ action = 'updateMoney', cash = cash, gold = gold })
end)

------------------------------------
-- horse target (ox_target)
------------------------------------
local TARGET_OPTIONS = { 'horse_lantern', 'horse_holster_equip', 'horse_holster_store', 'horse_holster_retrieve', 'horse_inventory' }

local function RemoveHorseTarget()
    if not Config.EnableTarget or horsePed == 0 then return end
    pcall(function() exports.ox_target:removeLocalEntity(horsePed, TARGET_OPTIONS) end)
end

local function SetupHorseTarget()
    if not Config.EnableTarget then return end
    pcall(function()
        exports.ox_target:addLocalEntity(horsePed, {
            {
                name = 'horse_lantern',
                icon = 'fa-solid fa-lightbulb',
                label = locale('cl_action_lantern'),
                distance = 2.5,
                onSelect = function() TriggerEvent('rsg-horses:client:equipHorseLantern') end,
            },
            {
                name = 'horse_holster_equip',
                icon = 'fa-solid fa-vest',
                label = locale('cl_holster_label_equip'),
                distance = 2.5,
                canInteract = function() return not holsterEquipped end,
                onSelect = function() TriggerEvent('rsg-horses:client:equipHorseHolster') end,
            },
            {
                name = 'horse_holster_store',
                icon = 'fa-solid fa-gun',
                label = locale('cl_holster_label_store'),
                distance = 2.5,
                canInteract = function() return holsterEquipped and not storedWeaponHash end,
                onSelect = function() TriggerEvent('rsg-horses:client:horseWeaponInteract') end,
            },
            {
                name = 'horse_holster_retrieve',
                icon = 'fa-solid fa-gun',
                label = locale('cl_holster_label_retrieve'),
                distance = 2.5,
                canInteract = function() return holsterEquipped and storedWeaponHash ~= nil end,
                onSelect = function() TriggerEvent('rsg-horses:client:horseWeaponInteract') end,
            },
            {
                name = 'horse_inventory',
                icon = 'fa-solid fa-bag-shopping',
                label = locale('cl_action_saddlebag'),
                distance = 2.5,
                onSelect = function() TriggerEvent('rsg-horses:client:inventoryHorse') end,
            },
        })
    end)
end

------------------------------------
-- despawn (single cleanup path for every removal)
------------------------------------
local function DespawnHorse()
    if horseBlip then RemoveBlip(horseBlip) horseBlip = nil end
    if horsePed ~= 0 then
        RemoveHorseTarget()
        if DoesEntityExist(horsePed) then
            NetworkRequestControlOfEntity(horsePed)
            SetEntityAsMissionEntity(horsePed, true, true)
            DeleteEntity(horsePed)
        end
    end
    horsePed         = 0
    horseSpawned     = false
    lanternEquipped  = false
    holsterEquipped  = false
    storedWeaponHash = nil
    HorseLayPrompt   = nil
    HorsePlayPrompt  = nil
end

local function Flee()
    if fleeing or not HorseExists() then return end
    fleeing = true
    CreateThread(function()
        TaskAnimalFlee(horsePed, cache.ped, -1)
        Wait(10000)
        if Config.StoreFleedHorse then
            TriggerServerEvent('rsg-horses:server:fleeStoreHorse')
        end
        DespawnHorse()
        fleeing = false
    end)
end

-- server asks us to drop the horse (traded / sold while out)
RegisterNetEvent('rsg-horses:client:FleeHorse', DespawnHorse)

------------------------------------
-- prompts (tricks)
------------------------------------
local function RegisterTrickPrompt(control, label)
    local prompt = PromptRegisterBegin()
    PromptSetControlAction(prompt, control)
    PromptSetText(prompt, CreateVarString(10, 'LITERAL_STRING', label))
    PromptSetEnabled(prompt, true)
    PromptSetVisible(prompt, true)
    PromptSetStandardMode(prompt, true)
    PromptSetGroup(prompt, HorsePrompts)
    Citizen.InvokeNative(0xC5F428EE08FA7F2C, prompt, true)
    PromptRegisterEnd(prompt)
    return prompt
end

local function SetupHorsePrompts()
    if not HorsePrompts then return end
    if horsexp >= Config.TrickXp.Lay and not HorseLayPrompt then
        HorseLayPrompt = RegisterTrickPrompt(Config.Prompt.HorseLay, locale('cl_action_lay'))
    end
    if horsexp >= Config.TrickXp.Play and not HorsePlayPrompt then
        HorsePlayPrompt = RegisterTrickPrompt(Config.Prompt.HorsePlay, locale('cl_action_play'))
    end
end

------------------------------------
-- exports
------------------------------------
exports('CheckHorseLevel', function() return horseLevel end)
exports('CheckHorseBondingLevel', function() return bondingLevel end)
exports('CheckActiveHorse', function() return horsePed end)

------------------------------------
-- server -> client interaction check (used before consuming items)
------------------------------------
lib.callback.register('rsg-horses:client:canInteract', function(mode)
    if not HorseExists() then
        Notify(locale('cl_error_no_horse_out'), 'error')
        return false
    end
    if DistanceToHorse() > (Config.InteractDistance or 2.5) then
        Notify(locale('cl_error_need_to_be_closer'), 'error')
        return false
    end
    local dead = IsEntityDead(horsePed)
    if mode == 'dead' and not dead then
        Notify(locale('cl_error_horse_not_injured_dead'), 'error')
        return false
    end
    if mode == 'alive' and dead then
        return false
    end
    return true
end)

------------------------------------
-- bonding
------------------------------------
local function UpdateBondingLevel()
    local maxBonding = GetMaxAttributePoints(horsePed, 7)
    local current    = GetAttributePoints(horsePed, 7)
    local third      = maxBonding / 3
    if current >= maxBonding then bondingLevel = 4
    elseif current >= third * 2 then bondingLevel = 3
    elseif current >= third then bondingLevel = 2
    else bondingLevel = 1 end
end

------------------------------------
-- walk to player after a call
------------------------------------
local function MoveHorseToPlayer()
    if horseSpawned then return end -- a walker thread is already running
    horseSpawned = true
    CreateThread(function()
        Citizen.InvokeNative(0x6A071245EB0D1882, horsePed, cache.ped, -1, 7.2, 2.0, 0, 0)
        while horseSpawned and HorseExists() do
            if DistanceToHorse() < 7.0 then
                ClearPedTasks(horsePed, true, true)
                break
            end
            Wait(1000)
        end
        horseSpawned = false
    end)
end

------------------------------------
-- spawn
------------------------------------
local function ApplyHorseStats(data)
    horsexp    = tonumber(data.horsexp) or 0
    horseLevel = GetHorseLevel(horsexp)
    local hValue = GetHorseAttributeValue(horsexp)

    for _, attr in ipairs({ 0, 1, 4, 5, 6 }) do
        SetAttributePoints(horsePed, attr, hValue)
    end

    if horseLevel >= 10 then
        EnableAttributeOverpower(horsePed, 0, 5000.0)
        EnableAttributeOverpower(horsePed, 1, 5000.0)
        Citizen.InvokeNative(0xF6A7C08DF2E28B28, horsePed, 0, horsexp + 0.0)
        Citizen.InvokeNative(0xF6A7C08DF2E28B28, horsePed, 1, horsexp + 0.0)
    end

    -- bonding tiers scale to the XP cap so max XP = max bonding
    local maxXp = (Config.HorseXp and Config.HorseXp.MaxXp) or 2000
    local bond = 1
    if horsexp > maxXp * 0.75 then bond = 2450
    elseif horsexp > maxXp * 0.50 then bond = 1634
    elseif horsexp > maxXp * 0.25 then bond = 817 end
    Citizen.InvokeNative(0x09A59688C26D88DF, horsePed, 7, bond)
    UpdateBondingLevel()
end

local function SpawnHorse()
    local data = lib.callback.await('rsg-horses:server:GetActiveHorse', false)
    if not data then
        return Notify(locale('sv_error_no_active_horse'), 'error')
    end

    local location = GetEntityCoords(cache.ped)
    local _, nodePosition = GetClosestVehicleNode(location.x - 15, location.y, location.z, 0, 3.0, 0.0)
    local onRoad = #(nodePosition - location) < 50

    if Config.SpawnOnRoadOnly and not onRoad then
        return Notify(locale('cl_error_near_road'), 'error')
    end

    local model = joaat(data.horse)
    if not lib.requestModel(model, 10000) then return end

    DespawnHorse()

    if onRoad then
        horsePed = CreatePed(model, nodePosition.x, nodePosition.y, nodePosition.z, 300.0, true, true, 0, 0)
    else
        horsePed = CreatePed(model, location.x - 10, location.y, location.z, 300.0, true, true, 0, 0)
        local found, groundz, normal = GetGroundZAndNormalFor_3dCoord(location.x - 15, location.y, location.z)
        if found then SetEntityCoordsNoOffset(horsePed, location.x - 15, location.y, groundz + normal.z, true) end
    end

    local tries = 0
    while not DoesEntityExist(horsePed) and tries < 200 do Wait(10) tries = tries + 1 end
    if not DoesEntityExist(horsePed) then horsePed = 0 return end

    -- lets the server refuse to sell/stable this ped as a "wild" horse
    Entity(horsePed).state:set('rsgHorseOwner', true, true)

    local player = PlayerId()
    for flag, val in pairs({
        [6] = true, [113] = false, [136] = false, [208] = true, [209] = true, [211] = true,
        [277] = true, [297] = true, [300] = false, [301] = false, [312] = false, [319] = true,
        [400] = true, [412] = false, [419] = false, [438] = false, [439] = false, [440] = false,
        [561] = true, [24] = false, [25] = false, [48] = false,
    }) do
        Citizen.InvokeNative(0x1913FE4CBF41C463, horsePed, flag, val)
    end

    horseName = data.name
    horseBlip = Citizen.InvokeNative(0x23F74C2FDA6E7C61, -1230993421, horsePed)
    Citizen.InvokeNative(0x9CB1A1623062F402, horseBlip, data.name)
    Citizen.InvokeNative(0x283978A15512B2FE, horsePed, true)
    Citizen.InvokeNative(0xFE26E4609B1C3772, horsePed, 'HorseCompanion', true)
    Citizen.InvokeNative(0xA691C10054275290, cache.ped, horsePed, 0)
    Citizen.InvokeNative(0x931B241409216C1F, cache.ped, horsePed, false)
    Citizen.InvokeNative(0xED1C764997A86D5A, cache.ped, horsePed)
    Citizen.InvokeNative(0xB8B6430EAD2D2437, horsePed, `PLAYER_HORSE`)
    Citizen.InvokeNative(0xDF93973251FB2CA5, player, true)
    if not Config.AllowTwoPlayersRide then
        Citizen.InvokeNative(0xE6D4E435B56D5BD0, player, horsePed)
    end
    Citizen.InvokeNative(0xAEB97D84CDF3C00B, horsePed, false)
    Citizen.InvokeNative(0xB832F1A686B9B810, cache.ped, true, 0)
    Citizen.InvokeNative(0x6734F0A6A52C371C, player, 431)
    Citizen.InvokeNative(0x024EC9B649111915, horsePed, true)
    Citizen.InvokeNative(0xEB8886E1065654CD, horsePed, 10, 'ALL', 0)
    SetModelAsNoLongerNeeded(model)
    SetEntityAsMissionEntity(horsePed, true, true)
    SetEntityCanBeDamaged(horsePed, true)
    SetPedNameDebug(horsePed, data.name)
    SetPedPromptName(horsePed, data.name)
    Citizen.InvokeNative(0xCC97B29285B1DC3B, horsePed, 1)
    Citizen.InvokeNative(0x5DA12E025D47D4E5, horsePed, 16, data.dirt or 0)

    local ok, comps = pcall(json.decode, data.components or '{}')
    horseComps[data.horseid] = (ok and type(comps) == 'table') and comps or {}
    ApplyComponents(horsePed, horseComps[data.horseid])
    if not Config.AllowTwoPlayersRide and next(horseComps[data.horseid]) then
        Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed, HOLSTER_COMPONENT, true, true, true)
    end
    UpdatePedVariation(horsePed)

    -- foal scale must be applied after UpdatePedVariation or it gets reset
    spawnAgeSeconds = tonumber(data.age_seconds)
    spawnGameTimer  = GetGameTimer()
    if spawnAgeSeconds then SetPedScale(horsePed, ComputeHorseScale(spawnAgeSeconds)) end

    if data.coat and data.coat ~= '' then
        horseCoats[data.horseid] = CoatNormalize(data.coat)
        CoatSaveOriginalAssets(horsePed)
        CoatApply(horsePed, horseCoats[data.horseid])
    end

    ApplyHorseStats(data)

    Citizen.InvokeNative(0x5653AB26C82938CF, horsePed, 41611, data.gender == 'male' and 0.0 or 1.0)
    Citizen.InvokeNative(0xCC8CA3E88256E58F, horsePed, false, true, true, true, false)

    -- hide native horse-wheel items we handle ourselves (weapons re-enabled when a holster is fitted)
    for _, slot in ipairs({ 28, 45, 49, 50 }) do
        Citizen.InvokeNative(0xA3DB37EDF9A74635, player, horsePed, slot, 1, true)
    end

    HorsePrompts = PromptGetGroupIdForTargetEntity(horsePed)
    SetupHorsePrompts()
    MoveHorseToPlayer()

    -- restore a weapon still stored in the holster
    local weaponHash = lib.callback.await('rsg-horses:server:getHorseWeapon', false)
    if weaponHash and HorseExists() then
        storedWeaponHash = weaponHash
        holsterEquipped  = true
        Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed, HOLSTER_COMPONENT, true, true, true)
        Citizen.InvokeNative(0xCC8CA3E88256E58F, horsePed, false, true, true, true, false)
        Citizen.InvokeNative(0x14FF0C2545527F9B, horsePed, weaponHash, cache.ped)
        Citizen.InvokeNative(0xA3DB37EDF9A74635, player, horsePed, 45, 0, true)
    end

    if Config.Automount then
        TaskMountAnimal(cache.ped, horsePed, 10000, -1, 1.0, 1, 0, 0)
    end

    SetupHorseTarget()
end

------------------------------------
-- stable NUI callbacks
------------------------------------
-- NUI-side validation messages are shown through ox_lib, same as everything else
local NOTIFY_TYPES = { success = 'success', error = 'error', warning = 'warning', inform = 'inform', info = 'inform' }
RegisterNUICallback('notify', function(data, cb)
    cb('ok')
    if type(data) ~= 'table' or type(data.title) ~= 'string' then return end
    Notify(type(data.message) == 'string' and data.message ~= '' and data.message or nil, NOTIFY_TYPES[data.type] or 'inform', data.title)
end)
RegisterNUICallback('closeUI', function(_, cb)
    cb('ok')
    CloseShowroom()
    SetNuiFocus(false, false)
    nuiIsOpen = false
end)

RegisterNUICallback('stableAction', function(data, cb)
    cb('ok')
    local action = data.action

    if action == 'view' then
        TriggerEvent('rsg-horses:client:menu', { stableid = closestStable })
    elseif action == 'sell' then
        TriggerEvent('rsg-horses:client:MenuDel', { stableid = closestStable })
    elseif action == 'move' then
        TriggerEvent('rsg-horses:client:movehorse', { stableid = closestStable })
    elseif action == 'trade' then
        TriggerEvent('rsg-horses:client:tradehorse')
    elseif action == 'shop' then
        TriggerServerEvent('rsg-horses:server:openShop')
    elseif action == 'store' then
        TriggerEvent('rsg-horses:client:storehorse', { stableid = closestStable })
    elseif action == 'buy' then
        if closestStable ~= 'valentine' then
            return Notify(locale('cl_error_buy_valentine_only'), 'error')
        end
        TriggerEvent('rsg-horses:client:OpenBuyHorse')
    elseif action == 'breed' then
        local job = Config.Breeding and Config.Breeding.requiredJob
        local PlayerData = RSGCore.Functions.GetPlayerData()
        if job and (not PlayerData.job or PlayerData.job.name ~= job) then
            return Notify(locale('err_breeder_required'), 'error')
        end
        TriggerEvent('rsg-horses:client:breedhorse')
    elseif action == 'customize' then
        if closestStable ~= 'valentine' then
            return Notify(locale('cl_error_customize_valentine_only'), 'error')
        end
        local horsedata = lib.callback.await('rsg-horses:server:GetActiveHorse', false)
        if not horsedata then
            return Notify(locale('sv_error_no_active_horse'), 'error')
        end
        TriggerEvent('rsg-horses:client:custShop', { player = horsedata })
    end
end)

RegisterNUICallback('previewHorse', function(data, cb)
    cb('ok')
    SpawnShowroomHorse(data.model)
end)

RegisterNUICallback('rotateHorse', function(data, cb)
    cb('ok')
    local direction = data.direction == 'left' and 'left' or 'right'
    if CustomizeHorsePed and DoesEntityExist(CustomizeHorsePed) then
        SetEntityHeading(CustomizeHorsePed, GetEntityHeading(CustomizeHorsePed) + (direction == 'left' and -5 or 5))
    else
        RotateShowroomHorse(direction)
    end
end)

RegisterNUICallback('selectHorse', function(data, cb)
    cb('ok')
    SendNUIMessage({ action = 'openHorseOptions', horse = data.horse })
end)

RegisterNUICallback('horseOption', function(data, cb)
    cb('ok')
    if data.option == 'ride' and data.horse then
        TriggerEvent('rsg-horses:client:SpawnHorse', { player = data.horse })
    end
end)

RegisterNUICallback('confirmSell', function(data, cb)
    cb('ok')
    TriggerServerEvent('rsg-horses:server:deletehorse', data.horseId)
end)

RegisterNUICallback('selectMoveHorse', function(data, cb)
    cb('ok')
    local current = GetStableConfig(data.currentStableId or closestStable)
    if not current then return end
    local options = {}
    for _, stable in pairs(Config.StableSettings) do
        if stable.stableid ~= current.stableid then
            options[#options + 1] = {
                stableId = stable.stableid,
                label = stable.stableid:upper(),
                cost = CalculateHorseMovePrice(current.coords, stable.coords),
            }
        end
    end
    table.sort(options, function(a, b) return a.cost < b.cost end)
    SendNUIMessage({ action = 'openMoveDestinations', horseId = data.horseId, destinations = options })
end)

RegisterNUICallback('confirmMove', function(data, cb)
    cb('ok')
    TriggerServerEvent('rsg-horses:server:MoveHorse', data.horseId, data.destStable)
end)

RegisterNUICallback('buyHorse', function(data, cb)
    cb('ok')
    TriggerServerEvent('rsg-horses:server:BuyHorse', data.model, closestStable, data.name, data.gender)
end)

------------------------------------
-- customization (NUI)
------------------------------------
local function CurrentCustomizePrice()
    return CalculatePrice(horseComps[CustomizeHorseId], initialHorseComps)
        + CalculateCoatPrice(horseCoats[CustomizeHorseId], initialHorseCoat)
end

local function EndCustomization(restore)
    local horseid = CustomizeHorseId
    if restore and horseid and CustomizeHorsePed and DoesEntityExist(CustomizeHorsePed) then
        horseComps[horseid] = table.copy(initialHorseComps)
        horseCoats[horseid] = table.copy(initialHorseCoat)
    end

    if CoatStopRainbow then CoatStopRainbow() end
    RenderScriptCams(false, true, 1000, true, false)
    if Camera then DestroyCam(Camera, false) Camera = nil end
    DisplayHud(true)
    DisplayRadar(true)
    Citizen.InvokeNative(0x4D51E59243281D80, PlayerId(), true, 0, false)
    TriggerServerEvent('rsg-horses:server:SetPlayerBucket', false)

    if CustomizeHorsePed and DoesEntityExist(CustomizeHorsePed) then
        DeleteEntity(CustomizeHorsePed)
    end

    CustomizeActive   = false
    CustomizeHorseId  = nil
    CustomizeHorsePed = nil
    initialHorseComps = {}
    initialHorseCoat  = nil
    -- the player's horse stays "called away" - it shows the new look once whistled again
end

RegisterNUICallback('customizeComponent', function(data, cb)
    cb('ok')
    local horseid, ped = CustomizeHorseId, CustomizeHorsePed
    local category, value = data.category, tonumber(data.value)
    if not horseid or not ped or not Components[category] or not value then return end

    horseComps[horseid][category] = value
    local item = Components[category][value]
    if item then
        Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, tonumber(item.hash), true, true, true)
    elseif value == 0 and Config.ComponentHash[category] then
        Citizen.InvokeNative(0xD710A5007C2AC539, ped, Config.ComponentHash[category], 0)
        Citizen.InvokeNative(0xCC8CA3E88256E58F, ped, 0, 1, 1, 1, 0)
    end
    UpdatePedVariation(ped)

    -- a new mane / tail style swaps the drawable: re-apply the saved colour
    if (category == 'Manes' or category == 'Tails') and horseCoats[horseid] and ManeTailRefreshAfterStyleChange then
        ManeTailRefreshAfterStyleChange(ped, horseCoats[horseid])
    end

    SendNUIMessage({ action = 'updatePrice', price = CurrentCustomizePrice() })
end)

RegisterNUICallback('customizeCoat', function(data, cb)
    cb('ok')
    local coat = CustomizeHorseId and horseCoats[CustomizeHorseId]
    if not coat then return end
    for key, fallback in pairs({ tint0 = 0, tint1 = 255, tint2 = 255, mane = 0, tail = 0 }) do
        if data[key] ~= nil then coat[key] = math.floor(tonumber(data[key]) or fallback) end
    end
    coat.rainbow = false
    CoatApply(CustomizeHorsePed, coat)
    SendNUIMessage({ action = 'updatePrice', price = CurrentCustomizePrice() })
end)

RegisterNUICallback('saveCustomization', function(_, cb)
    cb('ok')
    if CustomizeHorseId then
        TriggerServerEvent('rsg-horses:server:SaveComponents', horseComps[CustomizeHorseId], CustomizeHorseId, horseCoats[CustomizeHorseId])
    end
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
    nuiIsOpen = false
    EndCustomization(false)
end)

RegisterNUICallback('cancelCustomization', function(_, cb)
    cb('ok')
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
    nuiIsOpen = false
    EndCustomization(true)
end)

RegisterNUICallback('closeCustomization', function(_, cb)
    cb('ok')
    EndCustomization(true)
end)

RegisterNetEvent('rsg-horses:client:custShop', function(data)
    local horsesdata = data and data.player
    if not horsesdata then return end
    if not HorseExists() then
        return Notify(locale('cl_error_no_horse_out'), 'error')
    end

    -- preview spot = the stable the player is standing at (not the horse's home stable)
    local stable = GetStableConfig(closestStable)
    if not stable or not stable.horsecustom then return end

    local horseid = horsesdata.horseid
    local model = horsesdata.horse
    if not horseid or not model or not lib.requestModel(model, 10000) then return end

    DoScreenFadeOut(300)
    while not IsScreenFadedOut() do Wait(0) end

    DespawnHorse()
    TriggerServerEvent('rsg-horses:server:SetPlayerBucket', true)

    local ped = SpawnHorses(model, stable.horsecustom, stable.horsecustom.w)
    CustomizeHorseId  = horseid
    CustomizeHorsePed = ped
    CustomizeActive   = true

    -- always reload from the server copy so the screen reflects the saved state
    local ok, comps = pcall(json.decode, horsesdata.components or '{}')
    horseComps[horseid] = (ok and type(comps) == 'table') and comps or {}
    horseCoats[horseid] = CoatNormalize(horsesdata.coat)
    initialHorseComps   = table.copy(horseComps[horseid])
    initialHorseCoat    = table.copy(horseCoats[horseid])

    ApplyComponents(ped, horseComps[horseid])

    -- the coat only sticks once the ped is ready to render
    local tries = 0
    while DoesEntityExist(ped) and not IsPedReadyToRender(ped) and tries < 100 do
        Wait(50)
        tries = tries + 1
    end
    CoatSaveOriginalAssets(ped)
    CoatApply(ped, horseCoats[horseid])
    UpdatePedVariation(ped)
    CoatApply(ped, horseCoats[horseid]) -- second pass for freshly streamed mane/tail drawables

    local categories = {}
    for catName, catItems in pairs(Components) do
        if type(catItems) == 'table' and #catItems > 0 then
            categories[#categories + 1] = {
                category     = catName,
                items        = catItems,
                currentValue = horseComps[horseid][catName] or 0,
                maxValue     = #catItems,
                icon         = CATEGORY_ICONS[catName] or 'icons/generic_horse_mod.png',
            }
        end
    end
    table.sort(categories, function(a, b) return a.category < b.category end)

    -- camera
    local camPos = GetOffsetFromEntityInWorldCoords(ped, 0.0, 3.5, 0.0)
    Camera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(Camera, camPos.x, camPos.y, camPos.z + 1.5)
    SetCamRot(Camera, -15.0, 0.0, GetEntityHeading(ped) + 180, 2)
    SetCamActive(Camera, true)
    RenderScriptCams(true, false, 0, true, true)
    Citizen.InvokeNative(0x4D51E59243281D80, PlayerId(), false, 0, true)
    DisplayHud(false)
    DisplayRadar(false)

    CreateThread(function()
        while CustomizeActive and DoesEntityExist(ped) do
            local c = GetEntityCoords(ped)
            DrawLightWithRange(c.x - 5.0, c.y - 5.0, c.z + 1.0, 255, 255, 255, 15.0, 50.0)
            Wait(0)
        end
    end)

    DoScreenFadeIn(1000)

    local originalMarking = CoatGetOriginalMarking and CoatGetOriginalMarking() or nil
    local maneTailSupported = true
    if ManeTailHasSupport then maneTailSupported = ManeTailHasSupport(ped) end

    OpenNui('openCustomization', {
        horseId           = horseid,
        categories        = categories,
        components        = horseComps[horseid],
        coat              = horseCoats[horseid],
        hasMarkings       = originalMarking == nil or originalMarking ~= 255,
        originalMarking   = originalMarking,
        maneTailSupported = maneTailSupported,
        prices            = { components = Config.PriceComponent, coat = Config.Coat.Price or 100 },
    })
end)

------------------------------------
-- buy horse
------------------------------------
RegisterNetEvent('rsg-horses:client:OpenBuyHorse', function()
    local stableHorses = {}
    for _, horse in pairs(HorseSettings) do
        stableHorses[#stableHorses + 1] = horse
    end
    OpenNui('openBuyHorse', { horses = stableHorses })
end)

------------------------------------
-- stable menu + lists
------------------------------------
RegisterNetEvent('rsg-horses:client:stablemenu', function(stableid)
    closestStable = stableid
    OpenNui('openStableMenu')
end)

local function BuildHorseList(horses, extra)
    local list = {}
    for _, v in ipairs(horses) do
        local entry = {
            id      = v.id,
            name    = v.name,
            horse   = v.horse,
            stable  = v.stable,
            gender  = v.gender,
            horsexp = v.horsexp,
            level   = GetHorseLevel(v.horsexp),
            active  = v.active,
            dirt    = v.dirt or 0,
        }
        if extra then extra(entry, v) end
        list[#list + 1] = entry
    end
    return list
end

local function FetchStableHorses(stableid)
    local horses = lib.callback.await('rsg-horses:server:GetHorse', false, stableid)
    if not horses or #horses == 0 then
        Notify(locale('cl_error_no_horses'), 'error')
        return nil
    end
    return horses
end

RegisterNetEvent('rsg-horses:client:menu', function(data)
    local horses = FetchStableHorses(data.stableid)
    if not horses then return end
    SendNUIMessage({ action = 'openHorseList', horses = BuildHorseList(horses) })
end)

RegisterNetEvent('rsg-horses:client:MenuDel', function(data)
    local horses = FetchStableHorses(data.stableid)
    if not horses then return end
    local mult = Config.SellPriceMultiplier or 0.5
    SendNUIMessage({
        action = 'openSellHorse',
        horses = BuildHorseList(horses, function(entry, v)
            entry.sellPrice = math.floor((HorsePrices[v.horse] or 0) * mult)
        end),
    })
end)

RegisterNetEvent('rsg-horses:client:movehorse', function(data)
    local horses = FetchStableHorses(data.stableid)
    if not horses then return end
    SendNUIMessage({ action = 'openMoveSelect', horses = BuildHorseList(horses), currentStableId = data.stableid })
end)

------------------------------------
-- breeding
------------------------------------
RegisterNetEvent('rsg-horses:client:breedhorse', function()
    local horses = lib.callback.await('rsg-horses:server:GetPlayerHorses', false)
    if not horses or #horses == 0 then
        return Notify(locale('cl_error_breed_no_horses'), 'error')
    end
    local mares = {}
    for _, horse in ipairs(horses) do
        if horse.gender == 'female' then mares[#mares + 1] = horse end
    end
    if #mares == 0 then
        return Notify(locale('cl_error_breed_no_mare'), 'error')
    end
    SendNUIMessage({ action = 'openBreedMareSelect', horses = mares })
end)

RegisterNUICallback('selectBreedingMare', function(data, cb)
    cb('ok')
    local horses = lib.callback.await('rsg-horses:server:GetPlayerHorses', false) or {}
    local stallions = {}
    for _, horse in ipairs(horses) do
        if horse.gender == 'male' and horse.id ~= data.mareId then stallions[#stallions + 1] = horse end
    end
    if #stallions == 0 then
        return Notify(locale('cl_error_breed_no_stallion'), 'error')
    end
    SendNUIMessage({ action = 'openBreedStallionSelect', horses = stallions, mareId = data.mareId })
end)

RegisterNUICallback('confirmBreed', function(data, cb)
    cb('ok')
    TriggerServerEvent('rsg-horses:server:breedHorse', data.mareId, data.stallionId)
end)

------------------------------------
-- set active / store / trade
------------------------------------
RegisterNetEvent('rsg-horses:client:SpawnHorse', function(data)
    if data and data.player and data.player.id then
        DespawnHorse()
        TriggerServerEvent('rsg-horses:server:SetHoresActive', data.player.id)
    else
        SpawnHorse()
    end
end)

-- refresh the open stable list so the new active horse is highlighted
RegisterNetEvent('rsg-horses:client:horseActivated', function(id)
    if nuiIsOpen then SendNUIMessage({ action = 'setActiveHorse', id = id }) end
end)

RegisterNetEvent('rsg-horses:client:storehorse', function(data)
    if not HorseExists() then
        return Notify(locale('cl_error_no_horse_out'), 'error')
    end
    TriggerServerEvent('rsg-horses:server:SetHoresUnActive', data.stableid)
    Notify(locale('cl_success_storing_horse'), 'success')
    Flee()
end)

RegisterNetEvent('rsg-horses:client:tradehorse', function()
    if not HorseExists() then
        return Notify(locale('cl_error_no_horse_out'), 'error')
    end
    local player, distance = RSGCore.Functions.GetClosestPlayer()
    if player == -1 or distance > 3.0 then
        return Notify(locale('cl_error_no_nearby_player'), 'error')
    end
    -- the horse only leaves once the other player accepts (server sends FleeHorse)
    TriggerServerEvent('rsg-horses:server:TradeHorse', GetPlayerServerId(player))
end)

------------------------------------
-- rename
------------------------------------
RegisterCommand('sethorsename', function()
    local input = lib.inputDialog(locale('cl_menu_horse_rename'), {
        { type = 'input', required = true, min = 1, max = 50, label = locale('cl_menu_horse_setname'), icon = 'fas fa-horse-head' },
    })
    if input and input[1] then
        TriggerServerEvent('rsg-horses:renameHorse', input[1])
    end
end, false)

------------------------------------
-- growth (computed locally - no server polling)
------------------------------------
CreateThread(function()
    while true do
        Wait(30000)
        if HorseExists() and spawnAgeSeconds and Config.Growth and Config.Growth.enabled then
            local adult = (Config.Growth.growthMinutesToAdult or 120) * 60
            if spawnAgeSeconds < adult then
                local age = spawnAgeSeconds + (GetGameTimer() - spawnGameTimer) / 1000
                SetPedScale(horsePed, ComputeHorseScale(age))
            end
        end
    end
end)

------------------------------------
-- death detection
------------------------------------
CreateThread(function()
    local warned = false
    while true do
        Wait(1000)
        if HorseExists() and not IsBeingRevived then
            local pct = GetEntityHealth(horsePed) / math.max(GetEntityMaxHealth(horsePed), 1) * 100

            if pct > 0 and pct < 20 then
                if not warned then
                    warned = true
                    Notify(locale('cl_warning_horse_critical'), 'warning', locale('cl_warning_title'), 7000)
                end
            else
                warned = false
            end

            if IsEntityDead(horsePed) then
                local deadPed = horsePed
                Wait(Config.DeathGracePeriod)
                -- still the same horse, still dead and nobody revived it
                if horsePed == deadPed and DoesEntityExist(deadPed) and IsEntityDead(deadPed) and not IsBeingRevived then
                    TriggerServerEvent('rsg-horses:server:HorseDied')
                    DespawnHorse()
                end
                warned = false
            end
        end
    end
end)

------------------------------------
-- whistle (H) / flee prompt
------------------------------------
CreateThread(function()
    local whistleKey = RSGCore.Shared.Keybinds['H']
    while true do
        Wait(0)

        if IsControlJustPressed(0, whistleKey) then
            local PlayerData = RSGCore.Functions.GetPlayerData()
            local meta = PlayerData and PlayerData.metadata or {}
            if meta.injail == 0 and not meta.isdead then
                if DistanceToHorse() > 100.0 then -- no horse out (math.huge) or too far to walk
                    SpawnHorse()
                    Wait(3000)
                else
                    MoveHorseToPlayer()
                end
            end
        end

        -- native "flee" prompt on the horse
        local size = GetNumberOfEvents(0)
        for i = 0, size - 1 do
            if GetEventAtIndex(0, i) == `EVENT_PLAYER_PROMPT_TRIGGERED` then
                local buffer = DataView.ArrayBuffer(8 * 10)
                if Citizen.InvokeNative(0x57EC5FA4D4D6AFCA, 0, i, buffer:Buffer(), 10)
                    and buffer:GetInt32(0) == 33 and horsePed ~= 0 and buffer:GetInt32(16) == horsePed then
                    Flee()
                end
            end
        end
    end
end)

------------------------------------
-- tricks (lay / play)
------------------------------------
local function HorseActions(target, dict, anim)
    if not IsEntityPlayingAnim(target, dict, anim, 3) then
        lib.requestAnimDict('amb_creature_mammal@world_horse_resting@stand_enter')
        lib.requestAnimDict(dict)
        TaskPlayAnim(target, 'amb_creature_mammal@world_horse_resting@stand_enter', 'enter', 1.0, 1.0, -1, 2, 0.0, false, false, false, '', false)
        Wait(3000)
        TaskPlayAnim(target, dict, anim, 1.0, 1.0, -1, 2, 0.0, false, false, false, '', false)
    else
        lib.requestAnimDict('amb_creature_mammal@world_horse_resting@quick_exit')
        TaskPlayAnim(target, 'amb_creature_mammal@world_horse_resting@quick_exit', 'quick_exit', 1.0, 1.0, -1, 2, 0.0, false, false, false, '', false)
        Wait(3000)
        ClearPedTasks(target)
    end
end

CreateThread(function()
    while true do
        if HorseExists() and (HorseLayPrompt or HorsePlayPrompt) then
            Wait(0)
            if HorseLayPrompt and PromptHasStandardModeCompleted(HorseLayPrompt) then
                HorseActions(horsePed, 'amb_creature_mammal@world_horse_resting@stand_enter', 'base')
            elseif HorsePlayPrompt and PromptHasStandardModeCompleted(HorsePlayPrompt) then
                HorseActions(horsePed, 'amb_creature_mammal@world_horse_wallow_shake@idle', 'idle_a')
            end
        else
            Wait(1000)
        end
    end
end)

------------------------------------
-- saddlebag
------------------------------------
RegisterNetEvent('rsg-horses:client:inventoryHorse', function()
    if not HorseExists() then
        return Notify(locale('cl_error_no_horse_out'), 'error')
    end
    if DistanceToHorse() > (Config.InteractDistance or 2.5) + 1.0 then
        return Notify(locale('cl_error_need_to_be_closer'), 'error')
    end
    TriggerServerEvent('rsg-horses:server:openhorseinventory')
end)

------------------------------------
-- lantern
------------------------------------
RegisterNetEvent('rsg-horses:client:equipHorseLantern', function()
    if not HorseExists() then
        return Notify(locale('cl_error_no_horse_out'), 'error')
    end
    if not RSGCore.Functions.HasItem('horse_lantern', 1) then
        return Notify(locale('cl_error_no_lantern'), 'error')
    end
    if DistanceToHorse() > (Config.InteractDistance or 2.5) then
        return Notify(locale('cl_error_need_to_be_closer'), 'error')
    end

    if not lanternEquipped then
        Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed, LANTERN_COMPONENT, true, true, true)
        lanternEquipped = true
        Notify(locale('cl_primary_lantern_equiped'), 'inform')
    else
        Citizen.InvokeNative(0xD710A5007C2AC539, horsePed, 0x1530BE1C, 0)
        Citizen.InvokeNative(0xCC8CA3E88256E58F, horsePed, 0, 1, 1, 1, 0)
        lanternEquipped = false
        Notify(locale('cl_primary_lantern_removed'), 'inform')
    end
end)

------------------------------------
-- holster
------------------------------------
local function HolsterNotify(key, nType)
    Notify(locale(key), nType, locale('cl_holster_title'), 3000)
end

RegisterNetEvent('rsg-horses:client:equipHorseHolster', function()
    if not HorseExists() then return HolsterNotify('cl_holster_error_no_horse_nearby', 'error') end
    if not RSGCore.Functions.HasItem('horse_holster', 1) then return HolsterNotify('cl_holster_error_no_holster_item', 'error') end
    if DistanceToHorse() > (Config.InteractDistance or 2.5) then return HolsterNotify('cl_holster_error_too_far', 'error') end

    local player = PlayerId()
    if not holsterEquipped then
        Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed, HOLSTER_COMPONENT, true, true, true)
        Citizen.InvokeNative(0xCC8CA3E88256E58F, horsePed, false, true, true, true, false)
        Citizen.InvokeNative(0xA3DB37EDF9A74635, player, horsePed, 45, 0, true)
        holsterEquipped = true
        HolsterNotify('cl_holster_success_equipped', 'success')
    else
        if storedWeaponHash then
            return HolsterNotify('cl_holster_error_weapon_stored', 'error')
        end
        Citizen.InvokeNative(0xD710A5007C2AC539, horsePed, -1408210128, 0)
        Citizen.InvokeNative(0xCC8CA3E88256E58F, horsePed, false, true, true, true, false)
        Citizen.InvokeNative(0xA3DB37EDF9A74635, player, horsePed, 45, 1, true)
        holsterEquipped = false
        HolsterNotify('cl_holster_success_removed', 'inform')
    end
end)

RegisterNetEvent('rsg-horses:client:horseWeaponInteract', function()
    if not holsterEquipped then return HolsterNotify('cl_holster_error_not_equipped', 'error') end
    if DistanceToHorse() > (Config.InteractDistance or 2.5) then return HolsterNotify('cl_holster_error_too_far', 'error') end

    if storedWeaponHash then
        TriggerServerEvent('rsg-horses:server:retrieveHorseWeapon')
        return
    end

    local _, weaponHash = GetCurrentPedWeapon(cache.ped, true, 0, true)
    if not weaponHash or weaponHash == `WEAPON_UNARMED` then
        return HolsterNotify('cl_holster_error_no_weapon', 'error')
    end
    if not Config.HolsterWeapons[weaponHash] then
        return HolsterNotify('cl_holster_error_not_longarm', 'error')
    end
    TriggerServerEvent('rsg-horses:server:storeHorseWeapon', weaponHash)
end)

-- server confirmed the item was taken from the inventory
RegisterNetEvent('rsg-horses:client:weaponStored', function(weaponHash)
    if not HorseExists() then return end
    Citizen.InvokeNative(0xE9BD19F8121ADE3E, cache.ped, weaponHash, horsePed)
    Wait(100)
    Citizen.InvokeNative(0x14FF0C2545527F9B, horsePed, weaponHash, cache.ped)
    RemoveWeaponFromPed(cache.ped, weaponHash, true, 0)
    storedWeaponHash = weaponHash
    HolsterNotify('cl_holster_success_weapon_stored', 'success')
end)

-- server confirmed the item is back in the inventory (equip it from there as usual)
RegisterNetEvent('rsg-horses:client:weaponRetrieved', function()
    if HorseExists() then Citizen.InvokeNative(0xD4C6E24D955FF061, horsePed) end
    storedWeaponHash = nil
    HolsterNotify('cl_holster_success_weapon_retrieved', 'success')
end)

------------------------------------
-- feed (item already validated + consumed by the server)
------------------------------------
RegisterNetEvent('rsg-horses:client:playerfeedhorse', function(itemName)
    local feed = Config.HorseFeed[itemName]
    if not feed or not HorseExists() then return end

    if feed.ismedicine then
        TaskAnimalInteraction(cache.ped, horsePed, -1355254781, joaat(feed.medicineHash or 'consumable_horse_stimulant'), 0)
        Wait(3500)
    else
        Citizen.InvokeNative(0xCD181A959CFDD7F4, cache.ped, horsePed, -224471938, 0, 0)
        Wait(5000)
    end
    if not HorseExists() then return end

    local health  = tonumber(Citizen.InvokeNative(0x36731AC041289BB1, horsePed, 0)) or 0
    local stamina = tonumber(Citizen.InvokeNative(0x36731AC041289BB1, horsePed, 1)) or 0
    Citizen.InvokeNative(0xC6258F41D86676E0, horsePed, 0, health + feed.health)
    Citizen.InvokeNative(0xC6258F41D86676E0, horsePed, 1, stamina + feed.stamina)

    if feed.ismedicine then
        Citizen.InvokeNative(0xF6A7C08DF2E28B28, horsePed, 0, 1000.0)
        Citizen.InvokeNative(0xF6A7C08DF2E28B28, horsePed, 1, 1000.0)
        Citizen.InvokeNative(0x50C803A4CD5932C5, true)
        Citizen.InvokeNative(0xD4EE21B7CC7FD350, true)
    end
    PlaySoundFrontend('Core_Fill_Up', 'Consumption_Sounds', true, 0)
    Notify(locale('cl_horse_fed_desc', horseName or '', feed.health, feed.stamina), 'success', locale('cl_horse_fed_title'))
end)

------------------------------------
-- brush (validated by the server)
------------------------------------
RegisterNetEvent('rsg-horses:client:playerbrushhorse', function()
    if not HorseExists() then return end
    Citizen.InvokeNative(0xCD181A959CFDD7F4, cache.ped, horsePed, `INTERACTION_BRUSH`, 0, 0)
    Wait(8000)
    if not HorseExists() then return end
    Citizen.InvokeNative(0xE3144B932DFDFF65, horsePed, 0.0, -1, 1, 1)
    ClearPedEnvDirt(horsePed)
    ClearPedDamageDecalByZone(horsePed, 10, 'ALL')
    ClearPedBloodDamage(horsePed)
    Citizen.InvokeNative(0xD8544F6260F5F01E, horsePed, 10)
    PlaySoundFrontend('Core_Fill_Up', 'Consumption_Sounds', true, 0)
end)

------------------------------------
-- xp sync (no respawn needed)
------------------------------------
RegisterNetEvent('rsg-horses:client:horseXpUpdated', function(newXp)
    horsexp = tonumber(newXp) or horsexp
    horseLevel = GetHorseLevel(horsexp)
    SetupHorsePrompts()
end)

------------------------------------
-- revive (reviver already validated + consumed by the server)
------------------------------------
RegisterNetEvent('rsg-horses:client:revivehorse', function()
    if not HorseExists() or not IsEntityDead(horsePed) then return end
    IsBeingRevived = true
    lib.requestAnimDict('mech_skin@sample@base')
    ClearPedTasksImmediately(cache.ped)
    SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
    TaskPlayAnim(cache.ped, 'mech_skin@sample@base', 'sample_low', 1.0, 1.0, -1, 0, 0, false, false, false)
    Wait(3000)
    ClearPedTasks(cache.ped)
    SpawnHorse()
    IsBeingRevived = false
end)

------------------------------------
-- idle behaviour: horse rests when left alone outside town
------------------------------------
CreateThread(function()
    local resting = false
    while true do
        Wait(1000)
        if HorseExists() then
            local dist = DistanceToHorse()
            local pos = GetEntityCoords(cache.ped)
            local town = Citizen.InvokeNative(0x43AD8FC02B429D33, pos.x, pos.y, pos.z, 1)
            local outOfTown = not town or town == 0

            if resting and dist < 12 and Citizen.InvokeNative(0x57AB4A3080F85143, horsePed) then
                ClearPedTasks(horsePed)
                resting = false
            elseif not resting and dist > 12 and not horseSpawned and outOfTown
                and Citizen.InvokeNative(0xAAB0FE202E9FC9F0, horsePed, -1) then
                Citizen.InvokeNative(0x524B54361229154F, horsePed, `WORLD_ANIMAL_HORSE_RESTING_DOMESTIC`, -1, true, 0, GetEntityHeading(horsePed), false)
                resting = true
            end
        else
            resting = false
        end
    end
end)

------------------------------------
-- persist dirt (only when it changes)
------------------------------------
CreateThread(function()
    local lastDirt = -1
    while true do
        Wait(15000)
        if HorseExists() then
            local dirt = Citizen.InvokeNative(0x147149F2E909323C, horsePed, 16, Citizen.ResultAsInteger())
            if dirt and dirt ~= lastDirt then
                lastDirt = dirt
                TriggerServerEvent('rsg-horses:server:sethorseAttributes', dirt)
            end
        else
            lastDirt = -1
        end
    end
end)

------------------------------------
-- /findhorse
------------------------------------
RegisterNetEvent('rsg-horses:client:gethorselocation', function()
    local results = lib.callback.await('rsg-horses:server:GetAllHorses', false)
    if not results or #results == 0 then
        return Notify(locale('cl_error_horse_no'), 'error')
    end
    local lines = {}
    for i = 1, #results do
        local r = results[i]
        lines[#lines + 1] = locale('cl_horse_location_line', r.name, r.stable, r.active == 1 and locale('cl_yes') or locale('cl_no'))
    end
    Notify(table.concat(lines, '  \n'), 'inform', locale('cl_horse_find'), 10000)
end)

------------------------------------
-- cleanup
------------------------------------
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if CustomizeActive then EndCustomization(true) end
    DespawnHorse()
end)
