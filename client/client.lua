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
local IsBeingRevived = false
local horsexp = 0
local horsegender = nil
local horseBonding = 0
local bondingLevel = 0
local horseLevel = 0


local function CalculateHorseLevel(xp)
    if xp <= 99 then return 1
    elseif xp >= 100 and xp <= 199 then return 2
    elseif xp >= 200 and xp <= 299 then return 3
    elseif xp >= 300 and xp <= 399 then return 4
    elseif xp >= 400 and xp <= 499 then return 5
    elseif xp >= 500 and xp <= 999 then return 6
    elseif xp >= 1000 and xp <= 1399 then return 7
    elseif xp >= 1400 and xp <= 1699 then return 8
    elseif xp >= 1700 and xp <= 1899 then return 9
    else return 10 end
end

local function GetLevelProgress(xp)
    local levels = {
        {min = 0,    max = 99,    level = 1},
        {min = 100,  max = 199,   level = 2},
        {min = 200,  max = 299,   level = 3},
        {min = 300,  max = 399,   level = 4},
        {min = 400,  max = 499,   level = 5},
        {min = 500,  max = 999,   level = 6},
        {min = 1000, max = 1399,  level = 7},
        {min = 1400, max = 1699,  level = 8},
        {min = 1700, max = 1899,  level = 9},
        {min = 1900, max = 99999, level = 10}
    }
    for _, range in ipairs(levels) do
        if xp >= range.min and xp <= range.max then
            local progress = ((xp - range.min) / (range.max - range.min + 1)) * 100
            return range.level, math.floor(progress)
        end
    end
    return 10, 100
end


local lanternequiped  = false
local lanternUsed     = false
local holsterequiped  = false
local storedWeaponHash = nil

-------------------
-- prompts
-------------------
local HorsePrompts
local HorseLayPrompts

local HorsePLayPrompts


closestStable     = nil
local Customize         = false
local RotatePrompt
local CustomizePrompt   = GetRandomIntInRange(0, 0xffffff)
local Components        = lib.load('shared.horse_comp')
local CurrentPrice      = 0
local initialHorseComps = {}
local initialHorseCoat  = nil
-- NUI Customization state
local CustomizeHorseId  = nil
local CustomizeHorsePed = nil
lib.locale()

MenuData = {}
TriggerEvent('rsg-menubase:getData', function(call)
    MenuData = call
end)

------------------------------------
-- NUI helper functions
------------------------------------
local function GetPlayerMoney()
    local PlayerData = RSGCore.Functions.GetPlayerData()
    if not PlayerData or not PlayerData.money then return 0, 0 end
    return PlayerData.money.cash or 0, PlayerData.money.gold or 0
end

-- Tracks whether the shop NUI is currently open, so live money updates
-- (e.g. RSGCore:Client:OnMoneyChange) are only pushed while a screen is visible.
local nuiIsOpen = false

-- NUI locale (loads the full active-language table once and pushes it to the NUI)
local NuiLocale = nil

local function LoadNuiLocale()
    if NuiLocale then return NuiLocale end
    local activeLangCode = GetConvar('ox:locale', 'en')
    local raw = LoadResourceFile(GetCurrentResourceName(), ('locales/%s.json'):format(activeLangCode))
    if not raw then
        raw = LoadResourceFile(GetCurrentResourceName(), 'locales/en.json')
    end
    local ok, decoded = pcall(json.decode, raw or '{}')
    NuiLocale = (ok and decoded) or {}
    return NuiLocale
end

local function OpenNui(action, data)
    local cash, gold = GetPlayerMoney()
    local msg = {
        action = action,
        stableId = closestStable,
        money = {
            cash = cash,
            gold = gold
        },
    }
    if data then
        for k, v in pairs(data) do
            msg[k] = v
        end
    end
    SendNUIMessage(msg)
    SendNUIMessage({ action = 'setLocale', locale = LoadNuiLocale() })
    SetNuiFocus(true, true)
    nuiIsOpen = true
end

-- Keeps the NUI's displayed cash/gold live while any shop screen is open,
-- so the buy-horse affordability check never shows stale funds.
RegisterNetEvent('RSGCore:Client:OnMoneyChange', function(moneytype, amount, operation)
    if not nuiIsOpen then return end
    local cash, gold = GetPlayerMoney()
    SendNUIMessage({ action = 'updateMoney', cash = cash, gold = gold })
end)

local function SendNuiNotify(type, title, message)
    SendNUIMessage({
        action = 'showNotification',
        type = type,
        title = title,
        message = message
    })
end

local function SendNuiSuccess(message)
    SendNUIMessage({
        action = 'showSuccess',
        message = message
    })
end

------------------------------------
-- NUI callbacks
------------------------------------
RegisterNUICallback('closeUI', function(_, cb)
    CloseShowroom()
    SetNuiFocus(false, false)
    nuiIsOpen = false
    cb('ok')
end)

RegisterNUICallback('stableAction', function(data, cb)
    local action = data.action
    cb('ok')

    if action == 'view' then
        TriggerEvent('rsg-horses:client:menu', { stableid = data.stableId })
    elseif action == 'sell' then
        TriggerEvent('rsg-horses:client:MenuDel', { stableid = data.stableId })
    elseif action == 'move' then
        TriggerEvent('rsg-horses:client:movehorse', { stableid = data.stableId })
    elseif action == 'trade' then
        TriggerEvent('rsg-horses:client:tradehorse')
    elseif action == 'shop' then
        TriggerEvent('rsg-horses:client:OpenHorseShop')
    elseif action == 'buy' then
        if closestStable ~= 'valentine' then
            SendNuiNotify('error', locale('cl_error_buy_valentine_only'), '')
            return
        end
        TriggerEvent('rsg-horses:client:OpenBuyHorse')
    elseif action == 'store' then
        TriggerEvent('rsg-horses:client:storehorse', { stableid = data.stableId })
    elseif action == 'breed' then
        if Config.Breeding and Config.Breeding.requiredJob then
            local PlayerData = RSGCore.Functions.GetPlayerData()
            if not PlayerData or not PlayerData.job or PlayerData.job.name ~= Config.Breeding.requiredJob then
                SendNuiNotify('error', locale('err_breeder_required'), '')
                return
            end
        end
        TriggerEvent('rsg-horses:client:breedhorse')
    elseif action == 'customize' then
        if closestStable ~= 'valentine' then
            SendNuiNotify('error', locale('cl_error_customize_valentine_only'), '')
            return
        end
        RSGCore.Functions.TriggerCallback('rsg-horses:server:GetActiveHorse', function(horsedata)
            if horsedata then
                TriggerEvent('rsg-horses:client:custShop', { player = horsedata })
            else
                SendNuiNotify('error', locale('cl_error_no_horse_out'), '')
            end
    end)
    end
end)

RegisterNUICallback('previewHorse', function(data, cb)
    SpawnShowroomHorse(data.model)
    cb('ok')
end)

RegisterNUICallback('rotateHorse', function(data, cb)
    cb('ok')
    local direction = data.direction == 'left' and 'left' or 'right'
    -- Customize preview horse takes priority
    if CustomizeHorsePed and DoesEntityExist(CustomizeHorsePed) then
        local heading = GetEntityHeading(CustomizeHorsePed)
        local amount = direction == 'left' and -5 or 5
        SetEntityHeading(CustomizeHorsePed, heading + amount)
        return
    end
    -- Buy-preview showroom horse (lives in showroom.lua, access via getter)
    if GetShowroomHorse and RotateShowroomHorse then
        RotateShowroomHorse(direction)
    end
end)

RegisterNUICallback('selectHorse', function(data, cb)
    cb('ok')
    SendNUIMessage({
        action = 'openHorseOptions',
        horse = data.horse
    })
end)

RegisterNUICallback('horseOption', function(data, cb)
    cb('ok')
    if data.option == 'ride' then
        TriggerEvent('rsg-horses:client:SpawnHorse', { player = data.horse })
    elseif data.option == 'customize' then
        TriggerEvent('rsg-horses:client:custShop', { player = data.horse })
    end
end)

RegisterNUICallback('confirmSell', function(data, cb)
    cb('ok')
    TriggerServerEvent('rsg-horses:server:deletehorse', { horseid = data.horseId })
end)

RegisterNUICallback('selectMoveHorse', function(data, cb)
    cb('ok')
    local currentStableId = data.currentStableId or closestStable
    local options = {}
    for _, stableConfig in pairs(Config.StableSettings) do
        if stableConfig.stableid ~= currentStableId then
            local baseFee = Config.MoveHorseBasePrice
            local feePerMeter = Config.MoveFeePerMeter
            local distance = 1
            for _, sc in pairs(Config.StableSettings) do
                if sc.stableid == currentStableId then
                    distance = #(sc.coords - stableConfig.coords)
                    break
                end
            end
            local cost = math.ceil(baseFee + (distance * feePerMeter))
            options[#options + 1] = {
                stableId = stableConfig.stableid,
                label = stableConfig.stableid:upper(),
                cost = cost
            }
        end
    end
    SendNUIMessage({
        action = 'openMoveDestinations',
        horseId = data.horseId,
        destinations = options
    })
end)

RegisterNUICallback('confirmMove', function(data, cb)
    cb('ok')
    TriggerServerEvent('rsg-horses:server:MoveHorse', data.horseId, data.destStable)
end)

RegisterNUICallback('purchaseItems', function(data, cb)
    cb('ok')
    TriggerServerEvent('rsg-horses:server:buyShopItems', data.items, data.total)
end)

RegisterNUICallback('buyTarget', function(data, cb)
    cb('ok')
    TriggerServerEvent('rsg-horses:server:BuyHorse', data.model, data.stableId, data.name, data.gender)
end)

RegisterNUICallback('buyHorse', function(data, cb)
    cb('ok')
    TriggerServerEvent('rsg-horses:server:BuyHorse', data.model, data.stableId, data.name, data.gender)
end)

RegisterNUICallback('breadcrumbBack', function(data, cb)
    cb('ok')
end)

RegisterNUICallback('openCustomization', function(data, cb)
    cb('ok')
    -- This is handled by the NUI directly, but we can use it to trigger the event
    -- The NUI will call this when user clicks Customize in stable menu
end)

RegisterNUICallback('customizeComponent', function(data, cb)
    cb('ok')
    local category = data.category
    local value = data.value
    local horseid = CustomizeHorseId
    
    if horseid and horseComps[horseid] then
        horseComps[horseid][category] = value
        local Components = lib.load('shared.horse_comp')
        if Components[category] and Components[category][value] then
            local hash = Components[category][value].hash
            Citizen.InvokeNative(0xD3A7B003ED343FD9, CustomizeHorsePed, tonumber(hash), true, true, true)
        elseif value == 0 then
            local hash = Config.ComponentHash[category]
            if hash then
                Citizen.InvokeNative(0xD710A5007C2AC539, CustomizeHorsePed, hash, 0)
                Citizen.InvokeNative(0xCC8CA3E88256E58F, CustomizeHorsePed, 0, 1, 1, 1, 0)
            end
        end
        UpdatePedVariation(CustomizeHorsePed)
        -- Mane/tail style swaps the drawable GUID: re-capture + re-apply saved
        -- mane/tail colour so the colour survives style changes.
        if (category == 'Manes' or category == 'Tails') and horseCoats[horseid] then
            if ManeTailRefreshAfterStyleChange then
                ManeTailRefreshAfterStyleChange(CustomizeHorsePed, horseCoats[horseid])
            elseif ManeTailSaveOriginalAssets then
                ManeTailSaveOriginalAssets(CustomizeHorsePed)
                if ManeTailApply then ManeTailApply(CustomizeHorsePed, horseCoats[horseid]) end
            end
        end
        
        -- Calculate and send price update
        local price = CalculatePrice(horseComps[horseid], initialHorseComps)
            + CalculateCoatPrice(horseCoats[horseid], initialHorseCoat)
        SendNUIMessage({ action = 'updatePrice', price = price })
    end
end)

RegisterNUICallback('customizeCoat', function(data, cb)
    cb('ok')
    local horseid = CustomizeHorseId
    if horseid and horseCoats[horseid] then
        if data.tint0 ~= nil then horseCoats[horseid].tint0 = math.floor(tonumber(data.tint0) or 0) end
        if data.tint1 ~= nil then horseCoats[horseid].tint1 = math.floor(tonumber(data.tint1) or 255) end
        if data.tint2 ~= nil then horseCoats[horseid].tint2 = math.floor(tonumber(data.tint2) or 255) end
        if data.mane ~= nil then horseCoats[horseid].mane = math.floor(tonumber(data.mane) or 0) end
        if data.tail ~= nil then horseCoats[horseid].tail = math.floor(tonumber(data.tail) or 0) end
        horseCoats[horseid].rainbow = false
        CoatApply(CustomizeHorsePed, horseCoats[horseid])

        local price = CalculatePrice(horseComps[horseid], initialHorseComps)
            + CalculateCoatPrice(horseCoats[horseid], initialHorseCoat)
        SendNUIMessage({ action = 'updatePrice', price = price })
    end
end)

RegisterNUICallback('saveCustomization', function(data, cb)
    cb('ok')
    local horseid = data.horseId
    if horseid then
        TriggerServerEvent('rsg-horses:server:SaveComponents', horseComps[horseid], horseid, horseCoats[horseid])
    end
    -- Close customization camera and NUI
    DisableCamera()
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
    CurrentPrice = 0
    initialHorseComps = {}
    initialHorseCoat = nil
    -- Remove the temporary preview horse used during customization.
    if CustomizeHorsePed and DoesEntityExist(CustomizeHorsePed) then
        SetEntityAsMissionEntity(CustomizeHorsePed, true, true)
        DeleteEntity(CustomizeHorsePed)
        SetEntityAsNoLongerNeeded(CustomizeHorsePed)
    end
    CustomizeHorseId = nil
    CustomizeHorsePed = nil
    -- Do NOT auto-respawn the horse here: the player's horse stays "called
    -- away" after customizing/saving. The new customization is only applied
    -- once the player calls their horse out again.
end)

RegisterNUICallback('cancelCustomization', function(data, cb)
    cb('ok')
    local horseid = CustomizeHorseId
    if horseid then
        -- Restore initial components
        horseComps[horseid] = table.copy(data.components or initialHorseComps)
        horseCoats[horseid] = table.copy(data.coat or initialHorseCoat)
        
        -- Re-apply to horse
        for category, value in pairs(horseComps[horseid]) do
            local hash = getComponentHash(category, value)
            if hash ~= 0 then
                Citizen.InvokeNative(0xD3A7B003ED343FD9, CustomizeHorsePed, tonumber(hash), true, true, true)
            end
        end
        CoatApply(CustomizeHorsePed, horseCoats[horseid])
        UpdatePedVariation(CustomizeHorsePed)
    end
    DisableCamera()
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
    CurrentPrice = 0
    initialHorseComps = {}
    initialHorseCoat = nil
    -- Remove the temporary preview horse used during customization.
    if CustomizeHorsePed and DoesEntityExist(CustomizeHorsePed) then
        SetEntityAsMissionEntity(CustomizeHorsePed, true, true)
        DeleteEntity(CustomizeHorsePed)
        SetEntityAsNoLongerNeeded(CustomizeHorsePed)
    end
    CustomizeHorseId = nil
    CustomizeHorsePed = nil
    -- Do NOT auto-respawn: player must call their horse out again to see it.
end)

RegisterNUICallback('closeCustomization', function(data, cb)
    cb('ok')
    -- Same cleanup as cancel
    local horseid = CustomizeHorseId
    if horseid then
        horseComps[horseid] = table.copy(initialHorseComps)
        horseCoats[horseid] = table.copy(initialHorseCoat)
        
        for category, value in pairs(horseComps[horseid]) do
            local hash = getComponentHash(category, value)
            if hash ~= 0 then
                Citizen.InvokeNative(0xD3A7B003ED343FD9, CustomizeHorsePed, tonumber(hash), true, true, true)
            end
        end
        CoatApply(CustomizeHorsePed, horseCoats[horseid])
        UpdatePedVariation(CustomizeHorsePed)
    end
    DisableCamera()
    CurrentPrice = 0
    initialHorseComps = {}
    initialHorseCoat = nil
    -- Remove the temporary preview horse used during customization.
    if CustomizeHorsePed and DoesEntityExist(CustomizeHorsePed) then
        SetEntityAsMissionEntity(CustomizeHorsePed, true, true)
        DeleteEntity(CustomizeHorsePed)
        SetEntityAsNoLongerNeeded(CustomizeHorsePed)
    end
    CustomizeHorseId = nil
    CustomizeHorsePed = nil
    -- Do NOT auto-respawn: player must call their horse out again to see it.
end)

------------------------------------
-- NUI: buy horse
------------------------------------
RegisterNetEvent('rsg-horses:client:OpenBuyHorse', function()
    local HorseSettings = lib.load('shared.horse_settings')
    local stableHorses = {}
    for _, horse in pairs(HorseSettings) do
        stableHorses[#stableHorses + 1] = horse
    end
    OpenNui('openBuyHorse', {
        horses = stableHorses,
        stableId = closestStable,
    })
end)

local weaponItemMap = {
    -- Rifles
    [`WEAPON_RIFLE_SPRINGFIELD`]        = 'weapon_rifle_springfield',
    [`WEAPON_RIFLE_ROLLINGBLOCK`]       = 'weapon_rifle_rollingblock',
    [`WEAPON_RIFLE_BOLTACTION`]         = 'weapon_rifle_boltaction',
    [`WEAPON_RIFLE_VARMINT`]            = 'weapon_rifle_varmint',
    [`WEAPON_RIFLE_ELEPHANT`]           = 'weapon_rifle_elephant',
    [`WEAPON_RIFLE_CARCANO`]            = 'weapon_rifle_carcano',
    [`WEAPON_RIFLE_LANCASTER`]          = 'weapon_rifle_lancaster',
    [`WEAPON_RIFLE_HENRY`]              = 'weapon_rifle_henry',
    -- Shotguns
    [`WEAPON_SHOTGUN_DOUBLEBARREL`]     = 'weapon_shotgun_doublebarrel',
    [`WEAPON_SHOTGUN_SEMIAUTO`]         = 'weapon_shotgun_semiauto',
    [`WEAPON_SHOTGUN_PUMP`]             = 'weapon_shotgun_pump',
    [`WEAPON_SHOTGUN_REPEATING`]        = 'weapon_shotgun_repeating',
    [`WEAPON_SHOTGUN_SAWNOFF`]          = 'weapon_shotgun_sawnoff',
    -- Bows
    [`WEAPON_BOW`]                      = 'weapon_bow',
    [`WEAPON_BOW_IMPROVED`]             = 'weapon_bow_improved',
    -- Repeaters
    [`WEAPON_REPEATER_CARBINE`]         = 'weapon_repeater_carbine',
    [`WEAPON_REPEATER_WINCHESTER`]      = 'weapon_repeater_winchester',
    [`WEAPON_REPEATER_EVANS`]           = 'weapon_repeater_evans',
}

local longarms = {
    -- Rifles
    [`WEAPON_RIFLE_SPRINGFIELD`]        = true,
    [`WEAPON_RIFLE_ROLLINGBLOCK`]       = true,
    [`WEAPON_RIFLE_BOLTACTION`]         = true,
    [`WEAPON_RIFLE_VARMINT`]            = true,
    [`WEAPON_RIFLE_ELEPHANT`]           = true,
    [`WEAPON_RIFLE_CARCANO`]            = true,
    [`WEAPON_RIFLE_LANCASTER`]          = true,
    [`WEAPON_RIFLE_HENRY`]              = true,
    -- Shotguns
    [`WEAPON_SHOTGUN_DOUBLEBARREL`]     = true,
    [`WEAPON_SHOTGUN_SEMIAUTO`]         = true,
    [`WEAPON_SHOTGUN_PUMP`]             = true,
    [`WEAPON_SHOTGUN_REPEATING`]        = true,
    [`WEAPON_SHOTGUN_SAWNOFF`]          = true,
    -- Bows
    [`WEAPON_BOW`]                      = true,
    [`WEAPON_BOW_IMPROVED`]             = true,
    -- Repeaters
    [`WEAPON_REPEATER_CARBINE`]         = true,
    [`WEAPON_REPEATER_WINCHESTER`]      = true,
    [`WEAPON_REPEATER_EVANS`]           = true,
}

local storedWeaponObject = nil

-----------------------------------
-- foal scale / growth system
-----------------------------------
local function ComputeHorseScale(ageSeconds)
    if not Config.Growth or not Config.Growth.enabled then return 1.0 end
    local minScale = Config.Growth.minScale or 0.4
    local adultSeconds = (Config.Growth.growthMinutesToAdult or 120) * 60
    if adultSeconds <= 0 then return 1.0 end
    local t = math.max(0.0, math.min(1.0, ageSeconds / adultSeconds))
    return minScale + (1.0 - minScale) * t
end

local function ApplyHorseScale(ped, ageSeconds)
    if not DoesEntityExist(ped) then return end
    local scale = ComputeHorseScale(ageSeconds)
    SetPedScale(ped, scale)
end

local function GetHorseAgeLabel(ageSeconds)
    if not ageSeconds or ageSeconds <= 0 then return 'Newborn' end
    local mins = ageSeconds / 60
    local hours = mins / 60
    if hours >= 1 then
        return ('%.1f hours'):format(hours)
    end
    return ('%.0f minutes'):format(mins)
end

local function GetHorseGrowthPercent(ageSeconds)
    if not Config.Growth or not Config.Growth.enabled then return 100 end
    local adultSeconds = (Config.Growth.growthMinutesToAdult or 120) * 60
    if adultSeconds <= 0 then return 100 end
    return math.min(100, math.floor(((ageSeconds or 0) / adultSeconds) * 100))
end

local function AttachWeaponPropToHorse(weaponHash)
    
    if storedWeaponObject and DoesEntityExist(storedWeaponObject) then
        DeleteObject(storedWeaponObject)
        storedWeaponObject = nil
    end

   
    local weaponModel = GetWeapontypeModel(weaponHash)

    if weaponModel == 0 then
        print('[rsg-horses] No model found for weapon hash:', weaponHash)
        return false
    end

   
    RequestModel(weaponModel)
    local timeout = 1000
    while not HasModelLoaded(weaponModel) and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end

    if not HasModelLoaded(weaponModel) then
        print('[rsg-horses] Failed to load weapon model')
        return false
    end

    
    local coords = GetEntityCoords(horsePed)
    storedWeaponObject = CreateObject(weaponModel, coords.x, coords.y, coords.z, true, true, false)

    if not storedWeaponObject or storedWeaponObject == 0 then
        print('[rsg-horses] Failed to create weapon object')
        return false
    end

   
    local boneIndex = GetEntityBoneIndexByName(horsePed, 'SKEL_Spine3')

    AttachEntityToEntity(
        storedWeaponObject,
        horsePed,
        boneIndex,
        0.15, -0.4, 0.05,    -- offset x, y, z
        90.0, 0.0, 0.0,      -- rotation x, y, z
        false, false, false, false, 2, true, 0
    )

    SetModelAsNoLongerNeeded(weaponModel)

    return true
end

local function RemoveWeaponPropFromHorse()
    if storedWeaponObject and DoesEntityExist(storedWeaponObject) then
        DeleteObject(storedWeaponObject)
        storedWeaponObject = nil
    end
end
local function StowWeaponOnHorse(forcedWeaponHash)
    local playerPed = PlayerPedId()
    local weaponHash = forcedWeaponHash

    if not weaponHash or weaponHash == 0 then
        local result, wh = GetCurrentPedWeapon(playerPed, true, 0, true)

        if not result or wh == joaat('WEAPON_UNARMED') then
            lib.notify({
                title = locale('cl_holster_title'),
                description = locale('cl_holster_error_no_weapon'),
                type = 'error',
                duration = 3000
            })
            return
        end

        weaponHash = wh
    end

    if not longarms[weaponHash] then
        lib.notify({
            title = locale('cl_holster_title'),
            description = locale('cl_holster_error_not_longarm'),
            type = 'error',
            duration = 3000
        })
        return
    end

    local weaponName = weaponItemMap[weaponHash]

    if not weaponName then
        print('[rsg-horses] Unknown weapon hash:', weaponHash)
        lib.notify({
            title = locale('cl_holster_title'),
            description = locale('cl_holster_error_not_configured'),
            type = 'error',
            duration = 3000
        })
        return
    end

    
    RSGCore.Functions.TriggerCallback('rsg-horses:server:getWeaponData', function(weaponData)
        if not weaponData then
            lib.notify({
                title = locale('cl_holster_title'),
                description = locale('cl_holster_error_no_weapon_data'),
                type = 'error',
                duration = 3000
            })
            return
        end

       
        Citizen.InvokeNative(0xE9BD19F8121ADE3E, playerPed, weaponHash, horsePed)
        Wait(100)
        Citizen.InvokeNative(0x14FF0C2545527F9B, horsePed, weaponHash, playerPed)

        Citizen.InvokeNative(0xB832F1A686B9B810, playerPed, true, 0)

        
        RemoveWeaponFromPed(playerPed, weaponHash, true, 0)

        
        TriggerServerEvent('rsg-horses:server:storeHorseWeapon', weaponHash, weaponName, weaponData)

        
        storedWeaponHash = weaponHash

        lib.notify({
            title = locale('cl_holster_title'),
            description = locale('cl_holster_success_weapon_stored'),
            type = 'success',
            duration = 3000
        })
    end, weaponName)
end

local function RetrieveWeaponFromHorse()
    local playerPed = PlayerPedId()

    RSGCore.Functions.TriggerCallback('rsg-horses:server:getHorseWeapon', function(data)
        if not data or not data.weaponHash then
            lib.notify({
                title = locale('cl_holster_title'),
                description = locale('cl_holster_error_no_weapon_stored'),
                type = 'error',
                duration = 3000
            })
            return
        end

        
        Citizen.InvokeNative(0xD4C6E24D955FF061, horsePed)
        Citizen.InvokeNative(0xB832F1A686B9B810, playerPed, false, 0)

       
        TriggerServerEvent('rsg-horses:server:retrieveHorseWeapon')

        
        storedWeaponHash = nil

        lib.notify({
            title = locale('cl_holster_title'),
            description = locale('cl_holster_success_weapon_retrieved'),
            type = 'success',
            duration = 3000
        })
    end)
end


RegisterNetEvent('rsg-horses:client:equipRetrievedWeapon')
AddEventHandler('rsg-horses:client:equipRetrievedWeapon', function(weaponHash)
    local playerPed = PlayerPedId()

    
    Wait(500)

    
    GiveWeaponToPed(playerPed, weaponHash, 999, true, true, 0, false, 0.5, 1.0, 0, false, 0, false)

    
    SetCurrentPedWeapon(playerPed, weaponHash, true, 0, false, false)
end)

------------------------------------
-- prompts setup
------------------------------------
function SetupHorsePrompts()
    if horsexp >= Config.TrickXp.Lay and not HorseLayPrompts then
        local string = locale('cl_action_lay')
        HorseLayPrompts = PromptRegisterBegin()
        PromptSetControlAction(HorseLayPrompts, Config.Prompt.HorseLay)
        string = CreateVarString(10, 'LITERAL_STRING', string)
        PromptSetText(HorseLayPrompts, string)
        PromptSetEnabled(HorseLayPrompts, 1)
        PromptSetVisible(HorseLayPrompts, 1)
        PromptSetStandardMode(HorseLayPrompts, 1)
        PromptSetGroup(HorseLayPrompts, HorsePrompts)
        Citizen.InvokeNative(0xC5F428EE08FA7F2C, HorseLayPrompts, true)
        PromptRegisterEnd(HorseLayPrompts)
    end

    if horsexp >= Config.TrickXp.Play then
        local string2 = locale('cl_action_play')
        HorsePLayPrompts = PromptRegisterBegin()
        PromptSetControlAction(HorsePLayPrompts, Config.Prompt.HorsePlay)
        string2 = CreateVarString(10, 'LITERAL_STRING', string2)
        PromptSetText(HorsePLayPrompts, string2)
        PromptSetEnabled(HorsePLayPrompts, 1)
        PromptSetVisible(HorsePLayPrompts, 1)
        PromptSetStandardMode(HorsePLayPrompts, 1)
        PromptSetGroup(HorsePLayPrompts, HorsePrompts)
        Citizen.InvokeNative(0xC5F428EE08FA7F2C, HorsePLayPrompts, true)
        PromptRegisterEnd(HorsePLayPrompts)
    end
end

local function SetupHorseTarget()
    if not Config.EnableTarget then return end
    pcall(function()
        exports.ox_target:addLocalEntity(horsePed, {
            
            {
                name     = 'horse_lantern',
                icon     = 'fa-solid fa-lightbulb',
                label    = locale('cl_action_lantern'),
                distance = 2.5,
                onSelect = function()
                    local hasItem = RSGCore.Functions.HasItem('horse_lantern', 1)
                    if not hasItem then
                        lib.notify({ title = locale('cl_error_no_lantern'), type = 'error', duration = 7000 })
                        return
                    end
                    if lanternequiped == false then
                        Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed, 0x635E387C, true, true, true)
                        lanternequiped = true
                        lanternUsed    = true
                        lib.notify({ title = locale('cl_primary_lantern_equiped'), type = 'info', duration = 7000 })
                    else
                        Citizen.InvokeNative(0xD710A5007C2AC539, horsePed, 0x1530BE1C, 0)
                        Citizen.InvokeNative(0xCC8CA3E88256E58F, horsePed, 0, 1, 1, 1, 0)
                        lanternequiped = false
                        lanternUsed    = true
                        lib.notify({ title = locale('cl_primary_lantern_removed'), type = 'info', duration = 7000 })
                    end
                end,
            },

            
            {
                name     = 'horse_holster_equip',
                icon     = 'fa-solid fa-vest',
                label    = holsterequiped and locale('cl_holster_label_remove') or locale('cl_holster_label_equip'),
                distance = 2.5,
                onSelect = function()
                    TriggerEvent('rsg-horses:client:equipHorseHolster')
                end,
            },

            
            {
                name      = 'horse_holster_weapon',
                icon      = 'fa-solid fa-gun',
                label     = storedWeaponHash and locale('cl_holster_label_retrieve') or locale('cl_holster_label_store'),
                distance  = 2.5,
                canInteract = function()
                    
                    return holsterequiped == true
                end,
                onSelect = function()
                    if not storedWeaponHash then
                        StowWeaponOnHorse()
                    else
                        RetrieveWeaponFromHorse()
                    end
                end,
            },

            
            {
                name     = 'horse_inventory',
                icon     = 'fa-solid fa-bag-shopping',
                label    = locale('cl_action_saddlebag'),
                distance = 2.5,
                onSelect = function()
                    TriggerEvent('rsg-horses:client:inventoryHorse')
                end,
            },
        })
    end)
end

local function RemoveHorseTarget()
    if not Config.EnableTarget then return end
    pcall(function()
        exports.ox_target:removeLocalEntity(horsePed, {
            'horse_lantern',
            'horse_holster_equip',
            'horse_holster_weapon'
        })
    end)
end

------------------------------------
-- get closest stable
------------------------------------
local function SetClosestStableLocation()
    local pos     = GetEntityCoords(cache.ped, true)
    local current = nil
    local dist    = nil

    for k, v in pairs(Config.StableSettings) do
        local dest  = vector3(v.coords.x, v.coords.y, v.coords.z)
        local dist2 = #(pos - dest)
        if current then
            if dist2 < dist then
                current = v.stableid
                dist    = dist2
            end
        else
            dist    = dist2
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
    RemoveHorseTarget()
    SetEntityAsMissionEntity(horsePed, true, true)
    DeleteEntity(horsePed)
    SetEntityAsNoLongerNeeded(horsePed)
    horsePed    = 0
    HorseCalled = false
    if horseBlip then RemoveBlip(horseBlip) horseBlip = nil end
end

------------------------------------
-- exports
------------------------------------
exports('CheckHorseLevel', function()
    return horseLevel
end)

exports('CheckHorseBondingLevel', function()
    return bondingLevel
end)

exports('CheckActiveHorse', function()
    return horsePed
end)

------------------------------------
-- customize horse
------------------------------------
local function PromptCustom()
    local str = VarString(10, 'LITERAL_STRING', locale('cl_custom_rotate_horse'))
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

function DisableCamera()
    if CoatStopRainbow then CoatStopRainbow() end
    RenderScriptCams(false, true, 1000, 1, 0)
    DestroyCam(Camera, false)
    DestroyAllCams(true)
    DisplayHud(true)
    DisplayRadar(true)
    Citizen.InvokeNative(0x4D51E59243281D80, PlayerId(), true, 0, false)
    Customize = false
    for k, v in pairs(entities) do
        TriggerServerEvent('rsg-horses:server:SetPlayerBucket', false, v.ped)
        if v.ped and DoesEntityExist(v.ped) then
            DeleteEntity(v.ped)
        end
        entities[k] = nil
    end
end

local function CameraPromptHorse(horses)
    local promptLabel    = locale('cl_custom_price') .. ' : $'
    local lightRange     = 15.0
    local lightIntensity = 50.0
    local rotateLeft     = Config.Prompt.Rotate[1]
    local rotateRight    = Config.Prompt.Rotate[2]

    CreateThread(function()
        PromptCustom()
        while Customize do
            Wait(0)
            local crds = GetEntityCoords(horses)
            DrawLightWithRange(crds.x - 5.0, crds.y - 5.0, crds.z + 1.0, 255, 255, 255, lightRange, lightIntensity)
            local label = VarString(10, 'LITERAL_STRING', promptLabel .. CurrentPrice)
            PromptSetActiveGroupThisFrame(CustomizePrompt, label)
            local heading = GetEntityHeading(horses)
            if IsControlPressed(2, rotateLeft) then
                SetEntityHeading(horses, heading - 1)
            elseif IsControlPressed(2, rotateRight) then
                SetEntityHeading(horses, heading + 1)
            end
        end
    end)
end

local function createCamera(horses, horsesdata, skipMenu)
    local Coords = GetOffsetFromEntityInWorldCoords(horses, 0, 3.5, 0)
    RenderScriptCams(false, false, 0, 1, 0)
    DestroyCam(Camera, false)
    if not DoesCamExist(Camera) then
        Camera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamActive(Camera, true)
        RenderScriptCams(true, false, 3000, true, true)
        SetCamCoord(Camera, Coords.x, Coords.y, Coords.z + 1.5)
        SetCamRot(Camera, -15.0, 0.0, GetEntityHeading(horses) + 180)
        Customize = true
        if not skipMenu then
            CameraPromptHorse(horses)
            MainMenu(horses, horsesdata)
        else
            -- NUI customize flow: CameraPromptHorse (which also draws the fill
            -- light) is skipped here, so run a light-only thread instead --
            -- same values as the buy-preview showroom light.
            CreateThread(function()
                while Customize and DoesEntityExist(horses) do
                    Wait(0)
                    local crds = GetEntityCoords(horses)
                    DrawLightWithRange(crds.x - 5.0, crds.y - 5.0, crds.z + 1.0, 255, 255, 255, 15.0, 50.0)
                end
            end)
        end
        Citizen.InvokeNative(0x4D51E59243281D80, PlayerId(), false, 0, true)
        DisplayHud(false)
        DisplayRadar(false)
    end
end

RegisterNetEvent('rsg-horses:client:custShop', function(data)
    if (horsePed == 0) then
        lib.notify({ title = locale('cl_error_no_horse_out'), type = 'error', duration = 7000 })
        return
    end
    local horsesdata = data.player
    if not horsesdata then return end

    -- Normalise NUI/server field names so customization always has the same data.
    horsesdata.horseid = horsesdata.horseid or horsesdata.id or horsesdata.horseId
    horsesdata.stable  = horsesdata.stable or horsesdata.stableid or horsesdata.stableId
    local horseped     = horsesdata.horse or horsesdata.model
    for k, v in pairs(Config.StableSettings) do
        if horsesdata.stable == v.stableid then
            DoScreenFadeOut(0)
            repeat Wait(0) until IsScreenFadedOut()
            local ped = SpawnHorses(horseped, v.horsecustom, v.horsecustom.w)
            DeleteEntity(horsePed)
            horsePed    = 0
            HorseCalled = false
            TriggerServerEvent('rsg-horses:server:SetPlayerBucket', true, ped)
            
            -- Store customization state for NUI callbacks
            CustomizeHorseId = horsesdata.horseid
            CustomizeHorsePed = ped
            
            -- Always (re)load horseComps and horseCoats from the server-provided
            -- data so the customize screen reflects the horse's actual saved
            -- customization, rather than trusting a stale in-memory cache.
            horseComps[CustomizeHorseId] = {}
            if horsesdata.components and horsesdata.components ~= "" then
                local success, result = pcall(json.decode, horsesdata.components)
                if success and type(result) == 'table' then
                    horseComps[CustomizeHorseId] = result
                end
            end
            horseCoats[CustomizeHorseId] = CoatNormalize(horsesdata.coat)
            
            -- Save initial state for cancel/restore
            initialHorseComps = table.copy(horseComps[CustomizeHorseId])
            initialHorseCoat = table.copy(horseCoats[CustomizeHorseId])
            
            -- Apply current components to the preview horse
            for category, value in pairs(horseComps[CustomizeHorseId]) do
                local hash = getComponentHash(category, value)
                if hash ~= 0 then
                    Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, tonumber(hash), true, true, true)
                end
            end
            -- Wait until the ped is ready to render before capturing + applying
            -- the saved coat. Without this the initial apply silently fails and
            -- the preview shows default colours until the first arrow move.
            local readyTries = 0
            while not Citizen.InvokeNative(0xA0BC8FAED8CFEB3C, ped) and readyTries < 100 do
                Wait(50)
                readyTries = readyTries + 1
                if not DoesEntityExist(ped) then break end
            end
            CoatSaveOriginalAssets(ped)
            CoatApply(ped, horseCoats[CustomizeHorseId])
            UpdatePedVariation(ped)
            -- Re-apply once after variation settles so mane/tail tints stick
            -- on freshly streamed drawables.
            if horseCoats[CustomizeHorseId] then
                CoatApply(ped, horseCoats[CustomizeHorseId])
            end

            -- Build categories data for NUI
            local Components = lib.load('shared.horse_comp')
            local categoryIcons = {
                Blankets = 'icons/horse_blankets.png',
                Saddles = 'icons/horse_saddles.png',
                Horns = 'icons/saddle_horns.png',
                Saddlebags = 'icons/horse_saddlebags.png',
                Stirrups = 'icons/saddle_stirrups.png',
                Bedrolls = 'icons/horse_bedrolls.png',
                Tails = 'icons/horse_tails.png',
                Manes = 'icons/horse_manes.png',
            }
            local categories = {}
            for catName, catItems in pairs(Components) do
                if type(catItems) == 'table' and #catItems > 0 then
                    categories[#categories + 1] = {
                        category = catName,
                        items = catItems,
                        currentValue = horseComps[CustomizeHorseId][catName] or 0,
                        maxValue = #catItems,
                        icon = categoryIcons[catName] or 'icons/generic_horse_mod.png'
                    }
                end
            end
            
            createCamera(ped, horsesdata, true)
            DoScreenFadeIn(1000)
            repeat Wait(0) until IsScreenFadedIn()
            entities[k] = { ped = ped }
            
            -- Open NUI customization screen AFTER fade in
            local cash, gold = GetPlayerMoney()
            local originalMarking = CoatGetOriginalMarking and CoatGetOriginalMarking() or nil
            SendNUIMessage({
                action = 'openCustomization',
                horseId = CustomizeHorseId,
                categories = categories,
                components = horseComps[CustomizeHorseId],
                coat = horseCoats[CustomizeHorseId],
                hasMarkings = originalMarking == nil or originalMarking ~= 255,
                originalMarking = originalMarking,
                maneTailSupported = (ManeTailHasSupport and ManeTailHasSupport(ped)) or true,
                prices = {
                    component = 10,
                    coat = (Config.Coat and Config.Coat.Price) or 100
                },
                money = { cash = cash, gold = gold }
            })
            SendNUIMessage({ action = 'setLocale', locale = LoadNuiLocale() })
            SetNuiFocus(true, true)
        end
    end
end)

------------------------------------
-- rename horse
------------------------------------
RegisterCommand('sethorsename', function()
    local input = lib.inputDialog(locale('cl_menu_horse_rename'), {
        {
            type       = 'input',
            isRequired = true,
            label      = locale('cl_menu_horse_setname'),
            icon       = 'fas fa-horse-head'
        },
    })
    if not input then return end
    TriggerServerEvent('rsg-horses:renameHorse', input[1])
end, false)

------------------------------------
-- stables
------------------------------------
RegisterNetEvent('rsg-horses:client:stablemenu', function(stableid)
    closestStable = stableid
    OpenNui('openStableMenu')
end)

------------------------------------
-- trade horse
------------------------------------
local function TradeHorse()
    RSGCore.Functions.TriggerCallback('rsg-horses:server:GetActiveHorse', function(data, newnames)
        if horsePed ~= 0 then
            local player, distance = RSGCore.Functions.GetClosestPlayer()
            if player ~= -1 and distance < 1.5 then
                local playerId = GetPlayerServerId(player)
                local horseId  = data.horseid
                TriggerServerEvent('rsg-horses:server:TradeHorse', playerId, horseId)
                lib.notify({ title = locale('cl_success_horse_traded'), type = 'success', duration = 7000 })
            else
                lib.notify({ title = locale('cl_error_no_nearby_player'), type = 'error', duration = 7000 })
            end
        end
    end)
end

local function PlacePedOnGroundProperly(hPed)
    local howfar          = math.random(15, 30)
    local x, y, z        = table.unpack(GetEntityCoords(cache.ped))
    local found, groundz, normal = GetGroundZAndNormalFor_3dCoord(x - howfar, y, z)
    if found then
        SetEntityCoordsNoOffset(hPed, x - howfar, y, groundz + normal.z, true)
    end
end

local function BondingLevels()
    local maxBonding     = GetMaxAttributePoints(horsePed, 7)
    local currentBonding = GetAttributePoints(horsePed, 7)
    local thirdBonding   = maxBonding / 3

    if currentBonding >= maxBonding                                         then bondingLevel = 4 end
    if currentBonding >= thirdBonding and thirdBonding * 2 > currentBonding then bondingLevel = 2 end
    if currentBonding >= thirdBonding * 2 and maxBonding > currentBonding   then bondingLevel = 3 end
    if thirdBonding > currentBonding                                         then bondingLevel = 1 end
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

------------------------------------
-- spawn horse
------------------------------------
local function SpawnHorse()
    RSGCore.Functions.TriggerCallback('rsg-horses:server:GetActiveHorse', function(data)
        if (data) then
            local player          = PlayerId()
            local model           = GetHashKey(data.horse)
            local location        = GetEntityCoords(cache.ped)
            local x, y, z        = table.unpack(location)
            local _, nodePosition = GetClosestVehicleNode(x - 15, y, z, 0, 3.0, 0.0)
            local distance        = math.floor(#(nodePosition - location))
            local onRoad          = false

            if distance < 50 then onRoad = true end

            if Config.SpawnOnRoadOnly and not onRoad then
                lib.notify({ title = locale('cl_error_near_road'), type = 'error', duration = 7000 })
                return
            end

            if (location) then
                while not HasModelLoaded(model) do
                    RequestModel(model)
                    Wait(10)
                end

                local heading   = 300
                local prevhorse = horsePed
                if prevhorse ~= 0 and DoesEntityExist(prevhorse) then
                    getControlOfEntity(prevhorse)
                    if horseBlip then RemoveBlip(horseBlip) horseBlip = nil end
                    SetEntityAsMissionEntity(prevhorse, true, true)
                    DeleteEntity(prevhorse)
                    DeletePed(prevhorse)
                    SetEntityAsNoLongerNeeded(prevhorse)
                    prevhorse = 0
                end

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

                local horseFlags = {
                    [6]   = true,  [113] = false, [136] = false,
                    [208] = true,  [209] = true,  [211] = true,
                    [277] = true,  [297] = true,  [300] = false,
                    [301] = false, [312] = false, [319] = true,
                    [400] = true,  [412] = false, [419] = false,
                    [438] = false, [439] = false, [440] = false,
                    [561] = true
                }
                for flag, val in pairs(horseFlags) do
                    Citizen.InvokeNative(0x1913FE4CBF41C463, horsePed, flag, val)
                end

                local horseTunings = { 24, 25, 48 }
                for _, flag in ipairs(horseTunings) do
                    Citizen.InvokeNative(0x1913FE4CBF41C463, horsePed, flag, false)
                end

                horseBlip = Citizen.InvokeNative(0x23F74C2FDA6E7C61, -1230993421, horsePed)
                Citizen.InvokeNative(0x9CB1A1623062F402, horseBlip, data.name)
                Citizen.InvokeNative(0x283978A15512B2FE, horsePed, true)
                Citizen.InvokeNative(0xFE26E4609B1C3772, horsePed, "HorseCompanion", true)
                Citizen.InvokeNative(0xA691C10054275290, cache.ped, horsePed, 0)
                Citizen.InvokeNative(0x931B241409216C1F, cache.ped, horsePed, false)
                Citizen.InvokeNative(0xED1C764997A86D5A, cache.ped, horsePed)
                Citizen.InvokeNative(0xB8B6430EAD2D2437, horsePed, GetHashKey('PLAYER_HORSE'))
                Citizen.InvokeNative(0xDF93973251FB2CA5, player, true)
                if not Config.AllowTwoPlayersRide then
                    Citizen.InvokeNative(0xe6d4e435b56d5bd0, player, horsePed)
                end
                Citizen.InvokeNative(0xAEB97D84CDF3C00B, horsePed, false)
                Citizen.InvokeNative(0xB832F1A686B9B810, cache.ped, true, 0)
                Citizen.InvokeNative(0x6734F0A6A52C371C, player, 431)
                Citizen.InvokeNative(0x024EC9B649111915, horsePed, true)
                Citizen.InvokeNative(0xEB8886E1065654CD, horsePed, 10, "ALL", 0)
                SetModelAsNoLongerNeeded(model)
                SetEntityAsNoLongerNeeded(horsePed)
                SetEntityAsMissionEntity(horsePed, true)
                SetEntityCanBeDamaged(horsePed, true)
                SetPedNameDebug(horsePed, data.name)
                SetPedPromptName(horsePed, data.name)
                Citizen.InvokeNative(0xCC97B29285B1DC3B, horsePed, 1)
                Citizen.InvokeNative(0x5DA12E025D47D4E5, horsePed, 16, data.dirt)

                horseComps[data.horseid] = json.decode(data.components)
                if not horseComps[data.horseid] then
                    horseComps[data.horseid] = {}
                end

                for category, value in pairs(horseComps[data.horseid]) do
                    local hash = getComponentHash(category, value)
                    if hash ~= 0 then
                        Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed, tonumber(hash), true, true, true)
                        if not Config.AllowTwoPlayersRide then
                            Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed, 0xF772CED6, true, true, true)
                        end
                    end
                end

                UpdatePedVariation(horsePed)

                -- Apply foal scaling AFTER UpdatePedVariation so it isn't reset
                if Config.Growth and Config.Growth.enabled and data.age_seconds then
                    ApplyHorseScale(horsePed, data.age_seconds)
                end

                -- Apply saved coat color / markings (merged from horse_markings)
                if data.coat ~= nil and data.coat ~= '' then
                    local coatData = CoatNormalize(data.coat)
                    horseCoats[data.horseid] = coatData
                    CoatSaveOriginalAssets(horsePed)
                    CoatApply(horsePed, coatData)
                end

                horsexp     = data.horsexp
                horsegender = data.gender

                local hValue    = 0
                local overPower = false

                if horsexp <= 99                               then hValue = Config.Level1  horseLevel = 1  goto continue end
                if horsexp >= 100  and horsexp <= 199          then hValue = Config.Level2  horseLevel = 2  goto continue end
                if horsexp >= 200  and horsexp <= 299          then hValue = Config.Level3  horseLevel = 3  goto continue end
                if horsexp >= 300  and horsexp <= 399          then hValue = Config.Level4  horseLevel = 4  goto continue end
                if horsexp >= 400  and horsexp <= 499          then hValue = Config.Level5  horseLevel = 5  goto continue end
                if horsexp >= 500  and horsexp <= 999          then hValue = Config.Level6  horseLevel = 6  goto continue end
                if horsexp >= 1000 and horsexp <= 1399         then hValue = Config.Level7  horseLevel = 7  goto continue end
                if horsexp >= 1400 and horsexp <= 1699         then hValue = Config.Level8  horseLevel = 8  goto continue end
                if horsexp >= 1700 and horsexp <= 1899         then hValue = Config.Level9  horseLevel = 9  goto continue end
                if horsexp >= 1900 then hValue = Config.Level10 horseLevel = 10 overPower = true end

                ::continue::

                SetAttributePoints(horsePed, 0, hValue)
                SetAttributePoints(horsePed, 1, hValue)
                SetAttributePoints(horsePed, 4, hValue)
                SetAttributePoints(horsePed, 5, hValue)
                SetAttributePoints(horsePed, 6, hValue)

                if overPower then
                    EnableAttributeOverpower(horsePed, 0, 5000.0)
                    EnableAttributeOverpower(horsePed, 1, 5000.0)
                    local setoverpower = data.horsexp + .0
                    Citizen.InvokeNative(0xF6A7C08DF2E28B28, horsePed, 0, setoverpower)
                    Citizen.InvokeNative(0xF6A7C08DF2E28B28, horsePed, 1, setoverpower)
                end

                -- bonding tiers scale to the XP cap (default 2000) so max XP = max bonding
                local bond  = (Config.HorseXp and Config.HorseXp.MaxXp) or 2000
                local bond1 = bond * 0.25
                local bond2 = bond * 0.50
                local bond3 = bond * 0.75

                if horsexp <= bond * 0.25               then horseBonding = 1    end
                if horsexp > bond1 and horsexp <= bond2  then horseBonding = 817  end
                if horsexp > bond2 and horsexp <= bond3  then horseBonding = 1634 end
                if horsexp > bond3                       then horseBonding = 2450 end

                Citizen.InvokeNative(0x09A59688C26D88DF, horsePed, 7, horseBonding)
                BondingLevels()

                local faceFeature = 0.0
                if horsegender ~= 'male' then faceFeature = 1.0 end

                Citizen.InvokeNative(0x5653AB26C82938CF, horsePed, 41611, faceFeature)
                Citizen.InvokeNative(0xCC8CA3E88256E58F, horsePed, false, true, true, true, false)

                
                Citizen.InvokeNative(0xA3DB37EDF9A74635, player, horsePed, 28, 1, true) -- HORSE_ITEMS   (hidden)
                Citizen.InvokeNative(0xA3DB37EDF9A74635, player, horsePed, 45, 1, true) -- HORSE_WEAPONS (hidden until holster equipped)
                Citizen.InvokeNative(0xA3DB37EDF9A74635, player, horsePed, 49, 1, true) -- HORSE_BRUSH   (hidden)
                Citizen.InvokeNative(0xA3DB37EDF9A74635, player, horsePed, 50, 1, true) -- HORSE_FEED    (hidden)

                
                holsterequiped  = false
                storedWeaponHash = nil

                HorsePrompts = PromptGetGroupIdForTargetEntity(horsePed)
                HorseLayPrompts = nil
                HorsePLayPrompts = nil
                SetupHorsePrompts()
                moveHorseToPlayer()

                Wait(5000)

                horseSpawned = true
                HorseCalled  = true

               
                RSGCore.Functions.TriggerCallback('rsg-horses:server:getHorseWeapon', function(data)
                    -- server returns a table {weaponHash, weaponName, weaponData};
                    -- accept a bare hash too for backwards compat
                    local weaponHash = nil
                    if type(data) == 'table' then
                        weaponHash = data.weaponHash
                    elseif type(data) == 'number' then
                        weaponHash = data
                    end
                    if weaponHash and horsePed ~= 0 then
                        storedWeaponHash = weaponHash
                        holsterequiped   = true

                       
                        Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed, 0xF772CED6, true, true, true)
                        Citizen.InvokeNative(0xCC8CA3E88256E58F, horsePed, false, true, true, true, false)

                        
                        Citizen.InvokeNative(0xE9BD19F8121ADE3E, PlayerPedId(), weaponHash, horsePed)
                        Wait(100)
                        Citizen.InvokeNative(0x14FF0C2545527F9B, horsePed, weaponHash, PlayerPedId())

                        
                        Citizen.InvokeNative(0xA3DB37EDF9A74635, player, horsePed, 45, 0, true)
                    end
                end)

                if Config.Automount == true then
                    TaskMountAnimal(cache.ped, horsePed, 10000, -1, 1.0, 1, 0, 0)
                end

                SetupHorseTarget()
            end
        end
    end)
end



--------------------------------------
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


function MainMenu(horses, horsedata)
    MenuData.CloseAll()

    -- Horse data can come from the server (horseid) or the NUI (id/horseId).
    -- Always normalise it before using it as a table key.
    local horseid = horsedata and (horsedata.horseid or horsedata.id or horsedata.horseId)
    if not horseid then
        print('^1[rsg-horses] Customization failed: missing horse ID in horse data.^7')
        return
    end
    horsedata.horseid = horseid

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

    initialHorseComps = table.copy(horseComps[horseid])

    -- coat color / markings (merged from horse_markings): init from DB row, else defaults
    if not horseCoats[horseid] then
        horseCoats[horseid] = CoatNormalize(horsedata.coat)
    end
    initialHorseCoat = table.copy(horseCoats[horseid])
    CoatSaveOriginalAssets(horses)
    CoatApply(horses, horseCoats[horseid])

    for category, value in pairs(horseComps[horseid]) do
        local hash = getComponentHash(category, value)
        if hash ~= 0 then
            Citizen.InvokeNative(0xD3A7B003ED343FD9, horses, tonumber(hash), true, true, true)
        end
    end

    local elements = {
        { label = locale('cl_menu_horse_customization_component'), value = 'component' },
        { label = locale('cl_menu_horse_customization_coat'),      value = 'coat' },
        { label = locale('cl_menu_horse_customization_buy'),       value = 'buy' },
    }

    MenuData.Open('default', GetCurrentResourceName(), 'main_character_creator_menu',
        {
            title      = locale('cl_menu_horse_customization'),
            subtext    = '',
            align      = 'top-left',
            elements   = elements,
            itemHeight = "4vh"
        },
        function(data, menu)
            if data.current.value == 'component' then
                CustomHorse(horses, horsedata)
            elseif data.current.value == 'coat' then
                CustomCoat(horses, horsedata)
            elseif data.current.value == 'buy' then
                TriggerServerEvent('rsg-horses:server:SaveComponents', horseComps[horsedata.horseid], horsedata.horseid, horseCoats[horsedata.horseid])
                DisableCamera()
                CurrentPrice      = 0
                initialHorseComps = {}
                initialHorseCoat  = nil
                menu.close()
            end
        end,
        function(_, menu)
            -- restore preview coat if player exits without buying
            if initialHorseCoat and horses and DoesEntityExist(horses) then
                local hid = horsedata.horseid
                horseCoats[hid] = table.copy(initialHorseCoat)
                CoatApply(horses, horseCoats[hid])
            end
            DisableCamera()
            CurrentPrice      = 0
            initialHorseComps = {}
            initialHorseCoat  = nil
            menu.close()
        end)
end

function CustomHorse(horses, data)
    MenuData.CloseAll()
    local horseid = data.horseid
    CurrentPrice = CalculatePrice(horseComps[horseid] or {}, initialHorseComps)
        + CalculateCoatPrice(horseCoats[horseid], initialHorseCoat)
    local elements = {}

    for k, v in pairs(Components) do
        local categoryHashes = {}
        for i, item in ipairs(v) do
            categoryHashes[i] = item.hash
        end
        elements[#elements + 1] = {
            label    = k,
            value    = horseComps[horseid][k] or 0,
            type     = 'slider',
            min      = 0,
            max      = #v,
            category = k,
            hashes   = categoryHashes,
        }
    end

    local resource = GetCurrentResourceName()
    MenuData.Open('default', resource, 'horse_menu',
        {
            title    = locale('cl_menu_horse_customization'),
            subtext  = '',
            align    = 'top-left',
            elements = elements,
        },
        function(data, _)
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
                + CalculateCoatPrice(horseCoats[horseid], initialHorseCoat)
            if CurrentPrice ~= newPrice then
                CurrentPrice = newPrice
            end
        end,
        function(_, menu)
            MainMenu(horses, data)
        end)
end

------------------------------------
-- coat color / markings menu (merged from horse_markings test resource)
-- tint0 = main colour 0-254, tint1 = marking 0-255, tint2 = nose 0-255
------------------------------------
function CustomCoat(horses, data)
    MenuData.CloseAll()
    local horseid = data.horseid
    if not horseCoats[horseid] then
        horseCoats[horseid] = CoatNormalize(data.coat)
    end
    if not initialHorseCoat then
        initialHorseCoat = table.copy(horseCoats[horseid])
    end
    CurrentPrice = CalculatePrice(horseComps[horseid] or {}, initialHorseComps)
        + CalculateCoatPrice(horseCoats[horseid], initialHorseCoat)

    local coat = horseCoats[horseid]
    local elements = {
        {
            label    = locale('cl_menu_horse_customization_coat_main'),
            value    = coat.tint0 or 0,
            type     = 'slider',
            min      = 0,
            max      = 254,
            category = 'tint0',
        },
        {
            label    = locale('cl_menu_horse_customization_coat_marking'),
            value    = (coat.tint1 == nil) and 255 or coat.tint1,
            type     = 'slider',
            min      = 0,
            max      = 255,
            category = 'tint1',
        },
        {
            label    = locale('cl_menu_horse_customization_coat_nose'),
            value    = (coat.tint2 == nil) and 255 or coat.tint2,
            type     = 'slider',
            min      = 0,
            max      = 255,
            category = 'tint2',
        },
    }

    local resource = GetCurrentResourceName()
    MenuData.Open('default', resource, 'horse_coat_menu',
        {
            title    = locale('cl_menu_horse_customization_coat'),
            subtext  = '',
            align    = 'top-left',
            elements = elements,
        },
        function(change, _)
            local cat = change.current.category
            if cat == 'tint0' or cat == 'tint1' or cat == 'tint2' then
                horseCoats[horseid][cat] = change.current.value
                horseCoats[horseid].rainbow = false
                CoatApply(horses, horseCoats[horseid])
            end
            local newPrice = CalculatePrice(horseComps[horseid] or {}, initialHorseComps)
                + CalculateCoatPrice(horseCoats[horseid], initialHorseCoat)
            if CurrentPrice ~= newPrice then
                CurrentPrice = newPrice
            end
        end,
        function(_, menu)
            MainMenu(horses, data)
        end)
end

function table.copy(t)
    local u = {}
    for k, v in pairs(t) do
        u[k] = type(v) == "table" and table.copy(v) or v
    end
    return setmetatable(u, getmetatable(t))
end

------------------------------------
-- move horse to player
------------------------------------
function moveHorseToPlayer()
    Citizen.CreateThread(function()
        Citizen.InvokeNative(0x6A071245EB0D1882, horsePed, cache.ped, -1, 7.2, 2.0, 0, 0)
        while horseSpawned == true do
            local coords      = GetEntityCoords(cache.ped)
            local horseCoords = GetEntityCoords(horsePed)
            local distance    = #(coords - horseCoords)
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
            if (timeoutTimer == 0) then timeout = false end
            timeoutTimer = timeoutTimer - 1
            Wait(1000)
        end
        Wait(0)
    end
end)

------------------------------------
-- on resource stop
------------------------------------
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    DestroyAllCams(true)
    DisableCamera()
    MenuData.CloseAll()
    if (horsePed ~= 0) then
        RemoveHorseTarget()
        DeletePed(horsePed)
        SetEntityAsNoLongerNeeded(horsePed)
    end
end)

local HorseId = nil

RegisterNetEvent('rsg-horses:client:SpawnHorse', function(data)
    -- Handle both direct call (no args) and event call with data
    if data and data.player and data.player.id then
        HorseId = data.player.id
        if horsePed ~= 0 then
            RemoveHorseTarget()
            DeletePed(horsePed)
            SetEntityAsNoLongerNeeded(horsePed)
            horsePed = 0
        end
        TriggerServerEvent("rsg-horses:server:SetHoresActive", data.player.id)
        lib.notify({ title = locale('cl_success_title'), description = locale('cl_success_horse_active'), type = 'success', duration = 7000 })
    else
        -- Called without data (e.g., after customization), just respawn active horse
        SpawnHorse()
    end
end)

-----------------------------------
-- growth update thread
-----------------------------------
CreateThread(function()
    while true do
        Wait(30000)
        if horsePed ~= 0 and DoesEntityExist(horsePed) and HorseId then
            RSGCore.Functions.TriggerCallback('rsg-horses:server:GetActiveHorse', function(data)
                if data and data.age_seconds and Config.Growth and Config.Growth.enabled then
                    ApplyHorseScale(horsePed, data.age_seconds)
                end
            end)
        end
    end
end)

AddEventHandler('rsg-horses:client:FleeHorse', function()
    if horsePed ~= 0 and DoesEntityExist(horsePed) then
        getControlOfEntity(horsePed)
        if horseBlip then RemoveBlip(horseBlip) horseBlip = nil end
        RemoveHorseTarget()
        SetEntityAsMissionEntity(horsePed, true, true)
        DeleteEntity(horsePed)
        DeletePed(horsePed)
        SetEntityAsNoLongerNeeded(horsePed)
        horsePed    = 0
        HorseCalled = false
    end
end)

RegisterNetEvent('rsg-horses:client:storehorse', function(data)
    if (horsePed ~= 0) then
        TriggerServerEvent('rsg-horses:server:SetHoresUnActive', HorseId, data.stableid)
        lib.notify({ title = locale('cl_success_storing_horse'), type = 'success', duration = 7000 })
        Flee()
        HorseCalled = false
    else
        lib.notify({ title = locale('cl_error_no_horse_out'), type = 'error', duration = 7000 })
    end
end)

RegisterNetEvent("rsg-horses:client:tradehorse", function(data)
    RSGCore.Functions.TriggerCallback('rsg-horses:server:GetActiveHorse', function(data, newnames)
        if (horsePed ~= 0) then
            TradeHorse()
            Flee()
            HorseCalled = false
        else
            lib.notify({ title = locale('cl_error_no_horse_out'), type = 'error', duration = 7000 })
        end
    end)
end)

------------------------------------
-- menu options
------------------------------------
local function HorseOptions(data)
    SendNUIMessage({
        action = 'openHorseOptions',
        horse = data
    })
end

RegisterNetEvent('rsg-horses:client:menu', function(data)
    local horses = lib.callback.await('rsg-horses:server:GetHorse', false, data.stableid)

    if #horses <= 0 then
        SendNuiNotify('error', locale('cl_error_no_horses'), '')
        return
    end

    local horseList = {}
    for k, v in pairs(horses) do
        horseList[#horseList + 1] = {
            id = v.id,
            name = v.name,
            horse = v.horse,
            stable = v.stable,
            gender = v.gender,
            horsexp = v.horsexp,
            level = CalculateHorseLevel(v.horsexp),
            active = v.active,
            dirt = v.dirt or 0
        }
    end

    SendNUIMessage({
        action = 'openHorseList',
        horses = horseList
    })
end)

RegisterNetEvent('rsg-horses:client:MenuDel', function(data)
    local horses = lib.callback.await('rsg-horses:server:GetHorse', false, data.stableid)

    if #horses <= 0 then
        SendNuiNotify('error', locale('cl_error_no_horses'), '')
        return
    end

    local horseList = {}
    for k, v in pairs(horses) do
        local HorseSettings = lib.load('shared.horse_settings')
        local sellPrice = 0
        for _, horseSetting in pairs(HorseSettings) do
            if horseSetting.horsemodel == v.horse then
                sellPrice = horseSetting.horseprice * 0.5
                break
            end
        end

        horseList[#horseList + 1] = {
            id = v.id,
            name = v.name,
            horse = v.horse,
            gender = v.gender,
            horsexp = v.horsexp,
            level = CalculateHorseLevel(v.horsexp),
            sellPrice = sellPrice,
            dirt = v.dirt or 0
        }
    end

    SendNUIMessage({
        action = 'openSellHorse',
        horses = horseList
    })
end)

------------------------------------
-- move horse menu
------------------------------------
RegisterNetEvent('rsg-horses:client:movehorse', function(data)
    local horses = lib.callback.await('rsg-horses:server:GetHorse', false, data.stableid)

    if #horses <= 0 then
        SendNuiNotify('error', locale('cl_error_no_horses'), '')
        return
    end

    local horseList = {}
    for k, v in pairs(horses) do
        horseList[#horseList + 1] = {
            id = v.id,
            name = v.name,
            horse = v.horse,
            gender = v.gender,
            horsexp = v.horsexp,
            level = CalculateHorseLevel(v.horsexp),
            active = v.active,
            stable = data.stableid,
            dirt = v.dirt or 0
        }
    end

    SendNUIMessage({
        action = 'openMoveSelect',
        horses = horseList,
        currentStableId = data.stableid
    })
end)

------------------------------------
-- move horse destination
------------------------------------
function SelectDestinationStable(horseId, currentStableId)
    local currentStable = nil
    for _, stableConfig in pairs(Config.StableSettings) do
        if stableConfig.stableid == currentStableId then
            currentStable = stableConfig
            break
        end
    end

    local options = {}
    for _, stableConfig in pairs(Config.StableSettings) do
        if stableConfig.stableid ~= currentStableId then
            local baseFee = Config.MoveHorseBasePrice
            local feePerMeter = Config.MoveFeePerMeter
            local distance = #(currentStable.coords - stableConfig.coords)
            local cost = math.ceil(baseFee + (distance * feePerMeter))
            options[#options + 1] = {
                stableId = stableConfig.stableid,
                label = stableConfig.stableid:upper(),
                cost = cost
            }
        end
    end

    SendNUIMessage({
        action = 'openMoveDestinations',
        horseId = horseId,
        destinations = options
    })
end

------------------------------------
-- breed horse menu
------------------------------------
RegisterNetEvent('rsg-horses:client:breedhorse', function()
    local horses = lib.callback.await('rsg-horses:server:GetPlayerHorses', false)
    if not horses or #horses == 0 then
        SendNuiNotify('error', locale('cl_error_breed_no_horses'), '')
        return
    end

    local mares = {}
    for _, horse in ipairs(horses) do
        if horse.gender == 'female' then
            mares[#mares + 1] = horse
        end
    end

    if #mares == 0 then
        SendNuiNotify('error', locale('cl_error_breed_no_mare'), '')
        return
    end

    SendNUIMessage({
        action = 'openBreedMareSelect',
        horses = mares
    })
end)

RegisterNUICallback('selectBreedingMare', function(data, cb)
    cb('ok')
    local horses = lib.callback.await('rsg-horses:server:GetPlayerHorses', false)
    if not horses then return end

    local stallions = {}
    for _, horse in ipairs(horses) do
        if horse.gender == 'male' and horse.id ~= data.mareId then
            stallions[#stallions + 1] = horse
        end
    end

    if #stallions == 0 then
        SendNuiNotify('error', locale('cl_error_breed_no_stallion'), '')
        return
    end

    SendNUIMessage({
        action = 'openBreedStallionSelect',
        horses = stallions,
        mareId = data.mareId
    })
end)

RegisterNUICallback('confirmBreed', function(data, cb)
    cb('ok')
    TriggerServerEvent('rsg-horses:server:breedHorse', data.mareId, data.stallionId)
end)

------------------------------------
-- horse death detection
------------------------------------
CreateThread(function()
    while true do
        Wait(1000)
        if horsePed ~= 0 and DoesEntityExist(horsePed) then
            local horseHealth   = GetEntityHealth(horsePed)
            local maxHealth     = GetEntityMaxHealth(horsePed)
            local healthPercent = (horseHealth / maxHealth) * 100

            if healthPercent < 20 and healthPercent > 0 and not IsBeingRevived then
                lib.notify({
                    title       = locale('cl_warning_title'),
                    description = locale('cl_warning_horse_critical'),
                    type        = 'warning',
                    duration    = 7000
                })
            end

            if IsEntityDead(horsePed) and not IsBeingRevived then
                Wait(Config.DeathGracePeriod)

                if IsEntityDead(horsePed) then
                    RSGCore.Functions.TriggerCallback('rsg-horses:server:GetActiveHorse', function(data)
                        if data then
                            lib.notify({ title = locale('cl_error_horse_died'), type = 'error', duration = 7000 })
                            TriggerServerEvent('rsg-horses:server:HorseDied', data.horseid, data.name)

                            if horseBlip then RemoveBlip(horseBlip) horseBlip = nil end
                            RemoveHorseTarget()
                            SetEntityAsMissionEntity(horsePed, true, true)
                            DeleteEntity(horsePed)
                            SetEntityAsNoLongerNeeded(horsePed)
                            horsePed        = 0
                            HorseCalled     = false
                            horseSpawned    = false
                            holsterequiped  = false
                            storedWeaponHash = nil
                        end
                    end)
                end
            end
        end
    end
end)

------------------------------------
-- loop call / flee horse
------------------------------------
CreateThread(function()
    while true do
        Wait(0)

        if Citizen.InvokeNative(0x91AEF906BCA88877, 0, RSGCore.Shared.Keybinds['H']) then
            RSGCore.Functions.GetPlayerData(function(PlayerData)
                if PlayerData.metadata["injail"] == 0 and not PlayerData.metadata["isdead"] then
                    local coords      = GetEntityCoords(cache.ped)
                    local horseCoords = GetEntityCoords(horsePed)
                    local distance    = #(coords - horseCoords)

                    if not HorseCalled and (distance > 100.0) then
                        SpawnHorse()
                        Wait(3000)
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
                    local eventDataSize   = 10
                    local eventDataStruct = DataView.ArrayBuffer(8 * eventDataSize)
                    for a = 0, eventDataSize - 1 do
                        eventDataStruct:SetInt32(8 * a, 0)
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
        if not HasAnimDictLoaded(dict) then RequestAnimDict(dict) end
        if not HasAnimDictLoaded("amb_creature_mammal@world_horse_resting@stand_enter") then
            RequestAnimDict("amb_creature_mammal@world_horse_resting@stand_enter")
        end
        TaskPlayAnim(target, "amb_creature_mammal@world_horse_resting@stand_enter", "enter", 1.0, 1.0, -1, 2, 0.0, false, false, false, '', false)
        Citizen.Wait(3000)
        TaskPlayAnim(target, dict, anim, 1.0, 1.0, -1, 2, 0.0, false, false, false, '', false)
    else
        if not HasAnimDictLoaded("amb_creature_mammal@world_horse_resting@quick_exit") then
            RequestAnimDict("amb_creature_mammal@world_horse_resting@quick_exit")
        end
        TaskPlayAnim(target, "amb_creature_mammal@world_horse_resting@quick_exit", "quick_exit", 1.0, 1.0, -1, 2, 0.0, false, false, false, '', false)
        Citizen.Wait(3000)
        ClearPedTasks(target)
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        if horsePed ~= 0 and DoesEntityExist(horsePed) then
            local pcoords = GetEntityCoords(cache.ped)
            local hcoords = GetEntityCoords(horsePed)
            local dist = #(pcoords - hcoords)
            if Citizen.InvokeNative(0xC92AC953F0A982AE, HorseLayPrompts) then
                if horsexp >= Config.TrickXp.Lay then
                    HorseActions(horsePed, 'amb_creature_mammal@world_horse_resting@stand_enter', 'base')
                end
            end
            if Citizen.InvokeNative(0xC92AC953F0A982AE, HorsePLayPrompts) then
    if horsexp >= Config.TrickXp.Play and not HorsePLayPrompts then
                    HorseActions(horsePed, 'amb_creature_mammal@world_horse_wallow_shake@idle', 'idle_a')
                end
            end
        end
    end
end)

------------------------------------
-- horse inventory
------------------------------------
RegisterNetEvent('rsg-horses:client:inventoryHorse', function()
    RSGCore.Functions.TriggerCallback('rsg-horses:server:GetActiveHorse', function(data)
        if horsePed == 0 then
            lib.notify({ title = locale('cl_error_no_horse_out'), type = 'error', duration = 7000 })
            return
        end
        TriggerServerEvent('rsg-horses:server:openhorseinventory', data.horseid)
    end)
end)

------------------------------------
-- player equip horse lantern
------------------------------------
RegisterNetEvent('rsg-horses:client:equipHorseLantern')
AddEventHandler('rsg-horses:client:equipHorseLantern', function()
    local hasItem = RSGCore.Functions.HasItem('horse_lantern', 1)

    if not hasItem then
        lib.notify({ title = locale('cl_error_no_lantern'), type = 'error', duration = 7000 })
        return
    end

    local pcoords  = GetEntityCoords(cache.ped)
    local hcoords  = GetEntityCoords(horsePed)
    local distance = #(pcoords - hcoords)

    if distance > 2.0 then
        lib.notify({ title = locale('cl_error_need_to_be_closer'), type = 'error', duration = 7000 })
        return
    end

    if lanternUsed then
        lanternUsed = false
        Wait(5000)
    end

    if lanternequiped == false then
        Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed, 0x635E387C, true, true, true)
        lanternequiped = true
        lanternUsed    = true
        lib.notify({ title = locale('cl_primary_lantern_equiped'), type = 'info', duration = 7000 })
        return
    end

    if lanternequiped == true then
        Citizen.InvokeNative(0xD710A5007C2AC539, horsePed, 0x1530BE1C, 0)
        Citizen.InvokeNative(0xCC8CA3E88256E58F, horsePed, 0, 1, 1, 1, 0)
        lanternequiped = false
        lanternUsed    = true
        lib.notify({ title = locale('cl_primary_lantern_removed'), type = 'info', duration = 7000 })
        return
    end
end)

------------------------------------
-- player equip horse holster
------------------------------------
RegisterNetEvent('rsg-horses:client:equipHorseHolster')
AddEventHandler('rsg-horses:client:equipHorseHolster', function()
    local playerPed = PlayerPedId()

    if not horsePed or horsePed == 0 or not DoesEntityExist(horsePed) then
        lib.notify({
            title       = locale('cl_holster_title'),
            description = locale('cl_holster_error_no_horse_nearby'),
            type        = 'error',
            duration    = 3000
        })
        return
    end

    local hasItem = RSGCore.Functions.HasItem('horse_holster', 1)
    if not hasItem then
        lib.notify({
            title       = locale('cl_holster_title'),
            description = locale('cl_holster_error_no_holster_item'),
            type        = 'error',
            duration    = 3000
        })
        return
    end

    local pcoords  = GetEntityCoords(playerPed)
    local hcoords  = GetEntityCoords(horsePed)
    local distance = #(pcoords - hcoords)

    if distance > 2.0 then
        lib.notify({
            title       = locale('cl_holster_title'),
            description = locale('cl_holster_error_too_far'),
            type        = 'error',
            duration    = 3000
        })
        return
    end

    local player = PlayerId()

    if not holsterequiped then
        
        Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed, 0xF772CED6, true, true, true)
        Citizen.InvokeNative(0xCC8CA3E88256E58F, horsePed, false, true, true, true, false)

       
        Citizen.InvokeNative(0xA3DB37EDF9A74635, player, horsePed, 45, 0, true)
        Citizen.InvokeNative(0xB832F1A686B9B810, PlayerPedId(), true, 0)

        holsterequiped = true

        lib.notify({
            title       = locale('cl_holster_title'),
            description = locale('cl_holster_success_equipped'),
            type        = 'success',
            duration    = 3000
        })
    else
        
        if storedWeaponHash then
            RetrieveWeaponFromHorse()
        end

        
        Citizen.InvokeNative(0xD710A5007C2AC539, horsePed, -1408210128, 0)
        Citizen.InvokeNative(0xCC8CA3E88256E58F, horsePed, false, true, true, true, false)

        
        Citizen.InvokeNative(0xA3DB37EDF9A74635, player, horsePed, 45, 1, true)
        Citizen.InvokeNative(0xB832F1A686B9B810, PlayerPedId(), false, 0)

        holsterequiped = false

        lib.notify({
            title       = locale('cl_holster_title'),
            description = locale('cl_holster_success_removed'),
            type        = 'error',
            duration    = 3000
        })
    end
end)


RegisterNetEvent('rsg-horses:client:horseWeaponInteract')
AddEventHandler('rsg-horses:client:horseWeaponInteract', function()
    if not holsterequiped then
        lib.notify({
            title       = locale('cl_holster_title'),
            description = locale('cl_holster_error_not_equipped'),
            type        = 'error',
            duration    = 3000
        })
        return
    end

    local pcoords  = GetEntityCoords(PlayerPedId())
    local hcoords  = GetEntityCoords(horsePed)
    local distance = #(pcoords - hcoords)

    if distance > 2.0 then
        lib.notify({
            title       = locale('cl_holster_title'),
            description = locale('cl_holster_error_too_far'),
            type        = 'error',
            duration    = 3000
        })
        return
    end

    
    if not storedWeaponHash then
        StowWeaponOnHorse()
    else
        RetrieveWeaponFromHorse()
    end
end)

------------------------------------
-- player feed horse
------------------------------------
RegisterNetEvent('rsg-horses:client:playerfeedhorse')
AddEventHandler('rsg-horses:client:playerfeedhorse', function(itemName)
    local pcoords = GetEntityCoords(cache.ped)
    local hcoords = GetEntityCoords(horsePed)

    if horsePed == 0 or not DoesEntityExist(horsePed) then
        lib.notify({ title = locale('cl_error_no_horse_out'), type = 'error', duration = 7000 })
        return
    end

    if #(pcoords - hcoords) > 2.0 then
        lib.notify({ title = locale('cl_error_need_to_be_closer'), type = 'error', duration = 7000 })
        return
    end

    if Config.HorseFeed[itemName] ~= nil then
        if Config.HorseFeed[itemName]["ismedicine"] ~= nil then
            if Config.HorseFeed[itemName]["ismedicine"] == true then
                Citizen.InvokeNative(0xCD181A959CFDD7F4, cache.ped, horsePed, -1355254781, 0, 0)
                local medicineHash = "consumable_horse_stimulant"
                if Config.HorseFeed[itemName]["medicineHash"] ~= nil then
                    medicineHash = Config.HorseFeed[itemName]["medicineHash"]
                end
                TaskAnimalInteraction(cache.ped, horsePed, -1355254781, GetHashKey(medicineHash), 0)

                local valueHealth  = Citizen.InvokeNative(0x36731AC041289BB1, horsePed, 0)
                local valueStamina = Citizen.InvokeNative(0x36731AC041289BB1, horsePed, 1)

                if not tonumber(valueHealth)  then valueHealth  = 0 end
                if not tonumber(valueStamina) then valueStamina = 0 end

                Citizen.Wait(3500)
                Citizen.InvokeNative(0xC6258F41D86676E0, horsePed, 0, valueHealth  + Config.HorseFeed[itemName]["health"])
                Citizen.InvokeNative(0xC6258F41D86676E0, horsePed, 1, valueStamina + Config.HorseFeed[itemName]["stamina"])
                Citizen.InvokeNative(0xF6A7C08DF2E28B28, horsePed, 0, 1000.0)
                Citizen.InvokeNative(0xF6A7C08DF2E28B28, horsePed, 1, 1000.0)
                Citizen.InvokeNative(0x50C803A4CD5932C5, true)
                Citizen.InvokeNative(0xD4EE21B7CC7FD350, true)
                PlaySoundFrontend("Core_Fill_Up", "Consumption_Sounds", true, 0)
                TriggerServerEvent('rsg-horses:server:AddHorseXp', itemName)

            elseif Config.HorseFeed[itemName]["ismedicine"] == false then
                Citizen.InvokeNative(0xCD181A959CFDD7F4, cache.ped, horsePed, -224471938, 0, 0)
                Wait(5000)

                local horseHealth  = Citizen.InvokeNative(0x36731AC041289BB1, horsePed, 0)
                local horseStamina = Citizen.InvokeNative(0x36731AC041289BB1, horsePed, 1)

                if not tonumber(horseHealth)  then horseHealth  = 0 end
                if not tonumber(horseStamina) then horseStamina = 0 end

                Citizen.InvokeNative(0xC6258F41D86676E0, horsePed, 0, horseHealth  + Config.HorseFeed[itemName]["health"])
                Citizen.InvokeNative(0xC6258F41D86676E0, horsePed, 1, horseStamina + Config.HorseFeed[itemName]["stamina"])
                PlaySoundFrontend("Core_Fill_Up", "Consumption_Sounds", true, 0)
                TriggerServerEvent('rsg-horses:server:AddHorseXp', itemName)

                RSGCore.Functions.TriggerCallback('rsg-horses:server:GetActiveHorse', function(data)
                    if data then
                        lib.notify({
                            title       = locale('cl_horse_fed_title'),
                            description = string.format(locale('cl_horse_fed_desc'), data.name, Config.HorseFeed[itemName]["health"], Config.HorseFeed[itemName]["stamina"]),
                            type        = 'success',
                            duration    = 5000
                        })
                    end
                end)
            else
                lib.notify({ title = locale('cl_error_feed') .. ' ' .. itemName .. ' ' .. locale('cl_error_feed_invalid'), type = 'error', duration = 7000 })
            end
        else
            lib.notify({ title = locale('cl_error_feed') .. ' ' .. itemName .. ' ' .. locale('cl_error_feed_no_med'), type = 'error', duration = 7000 })
        end
    else
        lib.notify({ title = locale('cl_error_feed') .. ' ' .. itemName .. ' ' .. locale('cl_error_feed_no_exist'), type = 'error', duration = 7000 })
    end
end)

------------------------------------
-- player brush horse
------------------------------------
RegisterNetEvent('rsg-horses:client:playerbrushhorse')
AddEventHandler('rsg-horses:client:playerbrushhorse', function(itemName)
    if horsePed == 0 or not DoesEntityExist(horsePed) then
        lib.notify({ title = locale('cl_error_no_horse_out'), type = 'error', duration = 7000 })
        return
    end

    local pcoords  = GetEntityCoords(cache.ped)
    local hcoords  = GetEntityCoords(horsePed)

    if #(pcoords - hcoords) > 2.0 then
        lib.notify({ title = locale('cl_error_need_to_be_closer'), type = 'error', duration = 7000 })
        return
    end

    Citizen.InvokeNative(0xCD181A959CFDD7F4, cache.ped, horsePed, `INTERACTION_BRUSH`, 0, 0)
    Wait(8000)
    Citizen.InvokeNative(0xE3144B932DFDFF65, horsePed, 0.0, -1, 1, 1)
    ClearPedEnvDirt(horsePed)
    ClearPedDamageDecalByZone(horsePed, 10, "ALL")
    ClearPedBloodDamage(horsePed)
    Citizen.InvokeNative(0xD8544F6260F5F01E, horsePed, 10)
    PlaySoundFrontend("Core_Fill_Up", "Consumption_Sounds", true, 0)
    TriggerServerEvent('rsg-horses:server:AddHorseXp', 'brush')
end)

------------------------------------
-- horse xp gained (keeps local xp/level in sync without respawn)
------------------------------------
RegisterNetEvent('rsg-horses:client:horseXpUpdated')
AddEventHandler('rsg-horses:client:horseXpUpdated', function(newXp, amount)
    horsexp = tonumber(newXp) or horsexp
    horseLevel = CalculateHorseLevel(horsexp)
    -- unlock trick prompts without needing a respawn, but avoid duplicates
    if horsexp >= Config.TrickXp.Lay and not HorseLayPrompts then
        SetupHorsePrompts()
    elseif horsexp >= Config.TrickXp.Play and not HorsePLayPrompts then
        SetupHorsePrompts()
    end
end)

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

------------------------------------
-- player revive horse
------------------------------------
RegisterNetEvent("rsg-horses:client:revivehorse")
AddEventHandler("rsg-horses:client:revivehorse", function(item, data)
    local playercoords = GetEntityCoords(cache.ped)
    local horsecoords  = GetEntityCoords(horsePed)
    local distance     = #(playercoords - horsecoords)

    if horsePed == 0 then
        lib.notify({ title = locale('cl_error_no_horse_out'), type = 'error', duration = 7000 })
        return
    end

    if IsEntityDead(horsePed) then
        if distance > 1.5 then
            lib.notify({ title = locale('cl_error_horse_too_far'), type = 'error', duration = 7000 })
            return
        end

        IsBeingRevived = true
        RequestControl(horsePed)

        local healAnim1Dict1 = "mech_skin@sample@base"
        local healAnim1      = "sample_low"

        loadAnimDict(healAnim1Dict1)

        ClearPedTasks(cache.ped)
        ClearPedSecondaryTask(cache.ped)
        ClearPedTasksImmediately(cache.ped)
        FreezeEntityPosition(cache.ped, false)
        SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
        TaskPlayAnim(cache.ped, healAnim1Dict1, healAnim1, 1.0, 1.0, -1, 0, false, false, false)
        Wait(3000)
        ClearPedTasks(cache.ped)
        FreezeEntityPosition(cache.ped, false)
        IsBeingRevived = false
        SpawnHorse()
    else
        IsBeingRevived = false
        lib.notify({ title = locale('cl_error_horse_not_injured_dead'), type = 'error', duration = 7000 })
    end
end)

--------------------------------------
-- actions horse in town
------------------------------------
local horsebusy   = false
local candoaction = false

Citizen.CreateThread(function()
    while true do
        local sleep    = 1000
        local dist     = #(GetEntityCoords(cache.ped) - GetEntityCoords(horsePed))
        local ZoneTypeId = 1
        local x, y, z = table.unpack(GetEntityCoords(cache.ped))
        local town     = Citizen.InvokeNative(0x43AD8FC02B429D33, x, y, z, ZoneTypeId)

        if town == false then candoaction = true end

        if horsePed ~= 0 and horsebusy and dist < 12 then
            if Citizen.InvokeNative(0x57AB4A3080F85143, horsePed) then
                ClearPedTasks(horsePed)
                horsebusy = false
            end
        end

        if horsePed ~= 0 and not horsebusy and dist > 12 and horseSpawned and candoaction then
            -- NOTE: was `return` here, which permanently killed this while-true thread
            -- the first time the native returned false. Skip this pass instead.
            if Citizen.InvokeNative(0xAAB0FE202E9FC9F0, horsePed, -1) then
                Citizen.InvokeNative(0x524B54361229154F, horsePed, joaat('WORLD_ANIMAL_HORSE_RESTING_DOMESTIC'), -1, true, 0, GetEntityHeading(horsePed), false)
                horsebusy = true
            end
        end

        Wait(sleep)
    end
end)

------------------------------------
-- save horse attributes
------------------------------------
Citizen.CreateThread(function()
    while true do
        local sleep     = 5000
        local horsedirt = Citizen.InvokeNative(0x147149F2E909323C, horsePed, 16, Citizen.ResultAsInteger())
        if horsePed ~= 0 then
            TriggerServerEvent('rsg-horses:server:sethorseAttributes', horsedirt)
        end
        Wait(sleep)
    end
end)

------------------------------------
-- shop store
------------------------------------
RegisterNetEvent('rsg-horses:client:OpenHorseShop')
AddEventHandler('rsg-horses:client:OpenHorseShop', function()
    TriggerServerEvent('rsg-horses:server:openShop')
end)

------------------------------------
-- get horse location
------------------------------------
RegisterNetEvent('rsg-horses:client:gethorselocation', function()
    RSGCore.Functions.TriggerCallback('rsg-horses:server:GetAllHorses', function(results)
        if results ~= nil then
            local msg = locale('cl_horse_find') .. '\n'
            for i = 1, #results do
                local result = results[i]
                msg = msg .. '\n' .. locale('cl_horse') .. ': ' .. result.name .. ' | ' .. locale('cl_horse_is_stabled') .. ' ' .. result.stable .. ' | ' .. locale('cl_horse_active') .. ': ' .. (result.active == 1 and 'Yes' or 'No')
            end
            SendNuiNotify('info', locale('cl_horse_find'), msg)
        else
            SendNuiNotify('error', locale('cl_error_horse_no'), '')
        end
    end)
end)