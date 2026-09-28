-- Wild horse (tame / sell / save) client, merged from rsg-wildhorse v1.0.3.
-- Sell or stable a tamed wild horse at frontier sellers. All settings live
-- under Config.WildHorse (shared/wildhorse_config.lua); strings use the
-- stable ox_lib locale with wh_ keys (locales/en.json, pt-br.json).
local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

local selling = false
local cooldown = false
local cooldowntimer = 0
local wildhorseBlips = {}

-------------------------------------------------------------------------------------------
-- prompts and blips if needed
-------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
    for _, v in pairs(Config.WildHorse.SellWildHorseLocations) do
        exports['rsg-core']:createPrompt(v.location, v.coords, RSGCore.Shared.Keybinds[Config.WildHorse.Keybind], locale('wh_menu_open')..v.name, {
            type = 'client',
            event = 'rsg-sellwildhorse:client:menu',
            args = { v.name },
        })
        if v.showblip == true then
            local SellWildHorseBlip = BlipAddForCoords(1664425300, v.coords)
            SetBlipSprite(SellWildHorseBlip,  joaat(Config.WildHorse.Blip.blipSprite), true)
            SetBlipScale(SellWildHorseBlip, Config.WildHorse.Blip.blipScale)
            SetBlipName(SellWildHorseBlip, Config.WildHorse.Blip.blipName)
            wildhorseBlips[#wildhorseBlips + 1] = SellWildHorseBlip
        end
    end
end)

-- Sell Wild Horse Menu
RegisterNetEvent('rsg-sellwildhorse:client:menu', function(name)
    if selling then return end

    if Config.WildHorse.EnableCooldown and cooldowntimer > 0 then
        local timer = cooldowntimer
        local unit = locale('wh_cooldown_seconds')

        if cooldowntimer > 60 then
            timer = math.floor(cooldowntimer / 60)
            unit = locale('wh_cooldown_minutes')
        end

        lib.notify({
            title = locale('wh_title'),
            description = locale('wh_error_cooldown'):format(timer, unit),
            type = 'error',
            duration = 3000
        })

        return
    end

    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'wh-open', title = name })
end)

-- Sell Horse Event
AddEventHandler('rsg-sellwildhorse:client:sellhorse', function()
    local ped = PlayerPedId()
    local horse = Citizen.InvokeNative(0xE7E11B8DCBED1058, ped)
    local myhorse = exports['rsg-horses']:CheckActiveHorse()
    local model = GetEntityModel(horse)
    local owner = Citizen.InvokeNative(0xF103823FFE72BB49, horse)
    selling = true

    if Config.WildHorse.Debug then
        print("Rider    : "..tostring(ped))
        print("Horse    : "..tostring(horse))
        print("Model    : "..tostring(model))
        print("Owner    : "..tostring(owner))
    end

    if not horse or horse == 0 then
        lib.notify({
            title = locale('wh_title'),
            description = locale('wh_error_no_horse_sell'),
            type = 'error',
            duration = 3000
        })

        Wait(3000)

        selling = false

        return
    end

    if not owner or owner ~= ped then
        lib.notify({
            title = locale('wh_title'),
            description = locale('wh_error_not_tamed'),
            type = 'error',
            duration = 3000
        })

        Wait(3000)

        selling = false

        return
    end

    if myhorse ~= 0 and horse == myhorse then -- only block the player's own stable horse
        lib.notify({
            title = locale('wh_title'),
            description = locale('wh_error_owned_horse'),
            type = 'error',
            duration = 3000
        })

        Wait(3000)

        selling = false

        return
    end

    -- quick client-side check so we don't run the appraisal for a horse the seller won't buy
    local known = false
    for i = 1, #Config.WildHorse.Horse do
        if Config.WildHorse.Horse[i].model == model then known = true break end
    end
    if not known then
        lib.notify({ title = locale('wh_title'), description = locale('wh_error_invalid_model'), type = 'error', duration = 3000 })
        selling = false
        return
    end

    SendNUIMessage({ action = 'wh-progressStart', duration = Config.WildHorse.SellTime })

    local sellStart = GetGameTimer()
    local sellDuration = tonumber(Config.WildHorse.SellTime) or 5000
    local cancelled = false

    while (GetGameTimer() - sellStart) < sellDuration do
        Wait(0)
        -- keep the player in place while the appraisal runs
        DisableControlAction(0, 0x07CE1E61, true) -- sprint
        DisableControlAction(0, 0x8FFC75D6, true) -- jump
        DisableControlAction(0, 0xD9D0E1C0, true) -- attack
        DisableControlAction(0, 0xF84FA74F, true) -- aim
        DisableControlAction(0, 0xB238FE0B, true) -- melee attack
        DisableControlAction(0, 0xC1989F95, true) -- melee alternate
        DisableControlAction(0, 0xAC4BD4FE, true) -- weapon wheel
        FreezeEntityPosition(ped, true)
        if IsControlJustPressed(0, 322) then -- ESC cancels
            cancelled = true
            break
        end
    end

    FreezeEntityPosition(ped, false)
    SendNUIMessage({ action = 'wh-progressStop' })

    if cancelled then
        lib.notify({ title = locale('wh_title'), description = locale('wh_appraisal_cancelled'), type = 'error', duration = 2500 })
        selling = false
        return
    end

    -- server validates the entity, decides the reward and deletes the horse
    TriggerServerEvent('rsg-sellwildhorse:server:reward', NetworkGetNetworkIdFromEntity(horse))
    if Config.WildHorse.EnableCooldown then
        TriggerEvent('rsg-sellwildhorse:client:Cooldown')
    end
    Wait(3000)
    selling = false
end)

AddEventHandler('rsg-sellwildhorse:client:Cooldown', function()
    if cooldown then return end

    CreateThread(function()
        cooldowntimer = Config.WildHorse.Cooldown
        cooldown = true

        while true do
            Wait(1000)

            cooldowntimer = cooldowntimer - 1

            if cooldowntimer <= 0 then
                cooldowntimer = 0
                cooldown = false

                return
            end
        end
    end)
end)

if Config.WildHorse.Debug then
    RegisterNetEvent('rsg-sellwildhorse:client:SetHorseAsWild')
    AddEventHandler('rsg-sellwildhorse:client:SetHorseAsWild', function()
        local ped = PlayerPedId()
        local mount = GetMount(ped)

        if mount then
            Citizen.InvokeNative(0xAEB97D84CDF3C00B, mount, true)
        end
    end)
end

-- Cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    FreezeEntityPosition(PlayerPedId(), false)
    SendNUIMessage({ action = 'wh-progressStop' })

    for i = 1, #wildhorseBlips do
        if wildhorseBlips[i] then
            RemoveBlip(wildhorseBlips[i])
        end
    end
    wildhorseBlips = {}
end)

-- Save Wild Horse Event (Client-Side)
AddEventHandler('rms-wildhorsestable:client:wildhorsestable', function()
    local ped = PlayerPedId()
    local horse = Citizen.InvokeNative(0xE7E11B8DCBED1058, ped)
    local myhorse = exports['rsg-horses']:CheckActiveHorse()
    local model = GetEntityModel(horse)
    local owner = Citizen.InvokeNative(0xF103823FFE72BB49, horse)

    if Config.WildHorse.Debug then
        print('[rsg-horses] Wild horse save attempt:')
        print('  Rider : ' .. tostring(ped))
        print('  Horse : ' .. tostring(horse))
        print('  Model : ' .. tostring(model))
        print('  Owner : ' .. tostring(owner))
    end

    -- Validate horse exists
    if not horse or horse == 0 then
        lib.notify({
            title = locale('wh_title'),
            description = locale('wh_error_no_horse_save'),
            type = 'error',
            duration = 3000
        })
        return
    end

    -- Validate horse is tamed (owner must be the player ped)
    if not owner or owner ~= ped then
        lib.notify({
            title = locale('wh_title'),
            description = locale('wh_error_not_tamed'),
            type = 'error',
            duration = 3000
        })
        return
    end

    -- Validate player is not on their own registered horse
    if myhorse ~= 0 and horse == myhorse then -- only block the player's own stable horse
        lib.notify({
            title = locale('wh_title'),
            description = locale('wh_error_owned_horse'),
            type = 'error',
            duration = 3000
        })
        return
    end

    -- Use ox_lib input dialog instead of native keyboard for better UX
    local input = lib.inputDialog(locale('wh_dialog_title'), {
        {
            type = 'input',
            label = locale('wh_dialog_name'),
            description = locale('wh_dialog_name_desc'),
            required = true,
            min = 1,
            max = 30,
        },
        {
            type = 'select',
            label = locale('wh_dialog_gender'),
            description = locale('wh_dialog_gender_desc'),
            required = true,
            options = {
                { value = 'male',   label = locale('wh_gender_male')   },
                { value = 'female', label = locale('wh_gender_female') },
            }
        },
    })

    -- If player cancelled the dialog
    if not input then
        lib.notify({
            title = locale('wh_title'),
            description = locale('wh_save_cancelled'),
            type = 'error',
            duration = 3000
        })
        return
    end

    local horseName = input[1]
    local gender    = input[2]

    -- Final validation
    if not horseName or horseName == '' or not gender then
        lib.notify({
            title = locale('wh_title'),
            description = locale('wh_error_invalid_name'),
            type = 'error',
            duration = 3000
        })
        return
    end

    lib.notify({
        title = locale('wh_title'),
        description = locale('wh_saving'),
        type = 'inform',
        duration = 3000
    })

    TriggerServerEvent('rms-wildhorsestable:server:WildHorseStable', NetworkGetNetworkIdFromEntity(horse), horseName, gender)
end)

-- NUI callbacks for the merged wild horse panel (stable NUI page).
-- Names are wh-prefixed so they never collide with stable callbacks.
RegisterNUICallback('whClose', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'wh-close' })
    cb('ok')
end)

RegisterNUICallback('whSell', function(_, cb)
    SetNuiFocus(false, false)
    TriggerEvent('rsg-sellwildhorse:client:sellhorse')
    cb('ok')
end)

RegisterNUICallback('whSave', function(_, cb)
    SetNuiFocus(false, false)
    TriggerEvent('rms-wildhorsestable:client:wildhorsestable')
    cb('ok')
end)
