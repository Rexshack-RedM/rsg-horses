local RSGCore = exports['rsg-core']:GetCoreObject()
local HorseSettings = lib.load('shared.horse_settings')
lib.locale()

----------------------------------
-- security helpers
----------------------------------
local tradeRequests = {} -- Store pending trade requests

local function VerifyHorseOwnership(citizenid, horseid)
    local result = MySQL.scalar.await('SELECT COUNT(*) FROM player_horses WHERE citizenid = ? AND horseid = ?', {citizenid, horseid})
    return result and result > 0
end

local function ValidateComponents(components)
    local HorseComp = lib.load('shared.horse_comp')
    
    if type(components) ~= "table" then
        return false, "Invalid component type"
    end
    
    for category, value in pairs(components) do
        if not HorseComp[category] then
            return false, "Invalid category: " .. tostring(category)
        end
        
        if type(value) ~= "number" or value < 0 or value > #HorseComp[category] then
            return false, "Invalid component value for " .. category
        end
    end
    
    return true
end

-- coat color / markings validation (merged from horse_markings: tint0 0-254, tint1/tint2 0-255, mane/tail 0-254)
local function ValidateCoat(coat)
    if coat == nil then
        return true
    end
    if type(coat) ~= 'table' then
        return false, locale('sv_error_invalid_coat_type')
    end
    local t0 = tonumber(coat.tint0) or 0
    local t1 = tonumber(coat.tint1)
    local t2 = tonumber(coat.tint2)
    if t1 == nil then t1 = 255 end
    if t2 == nil then t2 = 255 end
    local mane = tonumber(coat.mane)
    local tail = tonumber(coat.tail)
    if mane == nil then mane = t0 end
    if tail == nil then tail = t0 end
    if t0 < 0 or t0 > 254 then
        return false, 'Invalid coat tint0 (0-254)'
    end
    if t1 < 0 or t1 > 255 then
        return false, 'Invalid coat tint1 (0-255)'
    end
    if t2 < 0 or t2 > 255 then
        return false, 'Invalid coat tint2 (0-255)'
    end
    if mane < 0 or mane > 254 then
        return false, 'Invalid mane colour (0-254)'
    end
    if tail < 0 or tail > 254 then
        return false, 'Invalid tail colour (0-254)'
    end
    return true
end

----------------------------------
-- commands
----------------------------------
RSGCore.Commands.Add('findhorse', locale('sv_command_find'), {}, false, function(source)
    local src = source
    TriggerClientEvent('rsg-horses:client:gethorselocation', src)
end)

RSGCore.Commands.Add('accepttrade', locale('sv_command_accept_trade'), {}, false, function(source)
    local src = source
    local trade = tradeRequests[src]
    
    if not trade then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_no_trade_request'), type = 'error', duration = 5000 })
        return
    end
    
    TriggerServerEvent('rsg-horses:server:AcceptTrade', trade.from)
end)

----------------------------------
-- get all horses
----------------------------------
RSGCore.Functions.CreateCallback('rsg-horses:server:GetAllHorses', function(source, cb)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local horses = MySQL.query.await('SELECT * FROM player_horses WHERE citizenid=@citizenid', { ['@citizenid'] = Player.PlayerData.citizenid })    
    if horses[1] ~= nil then
        cb(horses)
    else
        cb(nil)
    end
end)

----------------------------------
-- horse use items
----------------------------------
-- brush horse
RSGCore.Functions.CreateUseableItem('horse_brush', function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    TriggerClientEvent('rsg-horses:client:playerbrushhorse', source, item.name)
    SendDiscordLog('horses', 'Horse Brushed', 'Player used ' .. item.name .. ' to brush their active horse.', WebhookColors.info, nil, source)
end)

-- player horselantern
RSGCore.Functions.CreateUseableItem('horse_lantern', function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    TriggerClientEvent('rsg-horses:client:equipHorseLantern', source, item.name)
end)

 -- horse stimulant
 RSGCore.Functions.CreateUseableItem('horse_stimulant', function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('rsg-horses:client:playerfeedhorse', source, item.name)
        SendDiscordLog('horses', 'Horse Fed', 'Player fed their active horse with ' .. item.name .. '.', WebhookColors.info, nil, source)
    end
end)

-- feed horse carrot
RSGCore.Functions.CreateUseableItem('horsecarrot', function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('rsg-horses:client:playerfeedhorse', source, item.name)
        SendDiscordLog('horses', 'Horse Fed', 'Player fed their active horse with ' .. item.name .. '.', WebhookColors.info, nil, source)
    end
end)

 -- feed apple
 RSGCore.Functions.CreateUseableItem('horseapple', function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('rsg-horses:client:playerfeedhorse', source, item.name)
        SendDiscordLog('horses', 'Horse Fed', 'Player fed their active horse with ' .. item.name .. '.', WebhookColors.info, nil, source)
    end
end)
-- player horseholster
RSGCore.Functions.CreateUseableItem("horse_holster", function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    TriggerClientEvent("rsg-horses:client:equipHorseHolster", source, item.name)
end)

-- feed horse sugarcube
RSGCore.Functions.CreateUseableItem('sugarcube', function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('rsg-horses:client:playerfeedhorse', source, item.name)
        SendDiscordLog('horses', 'Horse Fed', 'Player fed their active horse with ' .. item.name .. '.', WebhookColors.info, nil, source)
    end
end)

-- feed horse haysnack
RSGCore.Functions.CreateUseableItem('hay', function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('rsg-horses:client:playerfeedhorse', source, item.name)
        SendDiscordLog('horses', 'Horse Fed', 'Player fed their active horse with ' .. item.name .. '.', WebhookColors.info, nil, source)
    end
end)



----------------------------------
-- horse reviver
----------------------------------
RSGCore.Functions.CreateUseableItem('horse_reviver', function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    if not Player then return end

    local cid = Player.PlayerData.citizenid
    local result = MySQL.query.await('SELECT * FROM player_horses WHERE citizenid=@citizenid AND active=@active', { ['@citizenid'] = cid, ['@active'] = 1 })

    if not result[1] then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_no_active_horse'), type = 'error', duration = 5000 })
        return
    end

    
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item.name], 'remove', 1)
        TriggerClientEvent('rsg-horses:client:revivehorse', src, item, result[1])
        SendDiscordLog('horses', 'Horse Revived', 'Player revived their active horse (' .. tostring(result[1].name) .. ') using ' .. item.name .. '.', WebhookColors.info, {
            { name = 'Horse', value = tostring(result[1].name), inline = true },
        }, src)
    end
end)

----------------------------------
-- buy & active
----------------------------------
RegisterServerEvent('rsg-horses:server:BuyHorse', function(model, stable, horsename, gender)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

   
    if not horsename or type(horsename) ~= "string" then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_invalid_horse_name'), type = 'error', duration = 5000 })
        return
    end
    horsename = string.gsub(horsename, "[^%w%s%-_]", "")
    if #horsename < 1 or #horsename > 50 then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_horse_name_length'), type = 'error', duration = 5000 })
        return
    end

    local horseInfo = nil
    for k,v in pairs(HorseSettings) do
        if v.horsemodel == model then
            horseInfo = v
            break
        end
    end

    if not horseInfo then
        warn(('rsg-horses: Buy Horse. Unexpected horse model %s'):format(model))
        return
    end

    local price = horseInfo.horseprice
    
    
    if not Player.Functions.RemoveMoney('cash', price) then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_no_cash'), type = 'error', duration = 5000 })
        return
    end
    
   
    local horseid = GenerateHorseid()
    local adultAge = (Config.Growth.growthMinutesToAdult or 120) * 60
    MySQL.insert('INSERT INTO player_horses(stable, citizenid, horseid, name, horse, gender, active, born, age_seconds) VALUES(@stable, @citizenid, @horseid, @name, @horse, @gender, @active, @born, @age_seconds)', {
        ['@stable'] = stable,
        ['@citizenid'] = Player.PlayerData.citizenid,
        ['@horseid'] = horseid,
        ['@name'] = horsename,
        ['@horse'] = model,
        ['@gender'] = gender,
        ['@active'] = false,
        ['@born'] = os.time(),
        ['@age_seconds'] = adultAge
    })
    
    TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_success_horse_owned'), type = 'success', duration = 5000 })

    SendDiscordLog('economy', 'Horse Purchased', horsename .. ' (' .. model .. ') bought for the ' .. tostring(stable) .. ' stable.', WebhookColors.success, {
        { name = 'Horse Name', value = horsename, inline = true },
        { name = 'Model', value = model, inline = true },
        { name = 'Price', value = '$' .. tostring(price), inline = true },
        { name = 'Stable', value = tostring(stable), inline = true },
    }, src)
end)

RegisterServerEvent('rsg-horses:server:storeHorseWeapon')
AddEventHandler('rsg-horses:server:storeHorseWeapon', function(weaponHash, weaponName, weaponData)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid

    -- SECURITY: weaponName/weaponData are client-supplied. Never trust them
    -- for storage until the item has actually been verified to exist in the
    -- claimed slot and successfully removed from the player's inventory,
    -- otherwise a client could conjure an arbitrary weapon (with arbitrary
    -- serial/info) out of thin air via retrieveHorseWeapon.
    if type(weaponName) ~= 'string' or type(weaponData) ~= 'table' or type(weaponData.slot) ~= 'number' then
        SendDiscordLog('security', 'Invalid storeHorseWeapon Payload', 'Player sent a malformed weapon store payload.', WebhookColors.warning, {
            { name = 'weaponName type', value = type(weaponName), inline = true },
            { name = 'weaponData type', value = type(weaponData), inline = true },
        }, src)
        return
    end

    local slotItem = Player.Functions.GetItemBySlot(weaponData.slot)
    if not slotItem or slotItem.name ~= weaponName then
        SendDiscordLog('security', 'Weapon Slot Mismatch Rejected', 'Claimed weapon did not match the item actually in the given slot.', WebhookColors.warning, {
            { name = 'Claimed Weapon', value = tostring(weaponName), inline = true },
            { name = 'Slot', value = tostring(weaponData.slot), inline = true },
            { name = 'Actual Slot Item', value = slotItem and slotItem.name or 'empty', inline = true },
        }, src)
        return
    end

    if not Player.Functions.RemoveItem(weaponName, 1, weaponData.slot) then
        return
    end

    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[weaponName], 'remove', 1)

    local weaponDataJson = json.encode({
        name = weaponData.name,
        info = weaponData.info,
        serial = weaponData.serial
    })

    MySQL.update('UPDATE player_horses SET stored_weapon = ?, stored_weapon_name = ?, stored_weapon_data = ? WHERE citizenid = ? AND active = 1', {
        weaponHash,
        weaponName,
        weaponDataJson,
        citizenid
    })

    SendDiscordLog('economy', 'Weapon Stored on Horse', weaponName .. ' stored on active horse.', WebhookColors.success, {
        { name = 'Weapon', value = weaponName, inline = true },
        { name = 'Slot', value = tostring(weaponData.slot), inline = true },
    }, src)
end)


RegisterServerEvent('rsg-horses:server:retrieveHorseWeapon')
AddEventHandler('rsg-horses:server:retrieveHorseWeapon', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid

    local result = MySQL.query.await('SELECT stored_weapon, stored_weapon_name, stored_weapon_data FROM player_horses WHERE citizenid = ? AND active = 1', { citizenid })

    if result and result[1] and result[1].stored_weapon_name then
        local weaponName = result[1].stored_weapon_name
        local weaponDataJson = result[1].stored_weapon_data
        local weaponData = {}

        if weaponDataJson then
            weaponData = json.decode(weaponDataJson) or {}
        end

        
        local info = weaponData.info or {}
        if weaponData.serial then
            info.serial = weaponData.serial
        end

        
        Player.Functions.AddItem(weaponName, 1, nil, info)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[weaponName], 'add', 1)

        
        MySQL.update('UPDATE player_horses SET stored_weapon = NULL, stored_weapon_name = NULL, stored_weapon_data = NULL WHERE citizenid = ? AND active = 1', { citizenid })

        
        TriggerClientEvent('rsg-horses:client:equipRetrievedWeapon', src, result[1].stored_weapon)

        SendDiscordLog('economy', 'Weapon Retrieved from Horse', weaponName .. ' retrieved from active horse.', WebhookColors.success, {
            { name = 'Weapon', value = weaponName, inline = true },
        }, src)
    end
end)


RSGCore.Functions.CreateCallback('rsg-horses:server:getHorseWeapon', function(source, cb)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then cb(nil) return end

    local citizenid = Player.PlayerData.citizenid
    local result = MySQL.query.await('SELECT stored_weapon, stored_weapon_name, stored_weapon_data FROM player_horses WHERE citizenid = ? AND active = 1', { citizenid })

    if result and result[1] and result[1].stored_weapon then
        local weaponData = {}
        if result[1].stored_weapon_data then
            weaponData = json.decode(result[1].stored_weapon_data) or {}
        end

        cb({
            weaponHash = result[1].stored_weapon,
            weaponName = result[1].stored_weapon_name,
            weaponData = weaponData
        })
    else
        cb(nil)
    end
end)

RSGCore.Functions.CreateCallback('rsg-horses:server:getWeaponData', function(source, cb, weaponName)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then cb(nil) return end

    local items = Player.PlayerData.items

    for slot, item in pairs(items) do
        if item and item.name == weaponName then
            cb({
                name = item.name,
                info = item.info or {},
                slot = slot,
                serial = item.info and item.info.serial or nil
            })
            return
        end
    end

    cb(nil)
end)

RegisterServerEvent('rsg-horses:server:clearHorseWeapon')
AddEventHandler('rsg-horses:server:clearHorseWeapon', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid

    local result = MySQL.query.await('SELECT stored_weapon, stored_weapon_name, stored_weapon_data FROM player_horses WHERE citizenid = ? AND active = 1', { citizenid })

    if result and result[1] and result[1].stored_weapon_name then
        local weaponName = result[1].stored_weapon_name
        local weaponDataJson = result[1].stored_weapon_data
        local weaponData = {}

        if weaponDataJson then
            weaponData = json.decode(weaponDataJson) or {}
        end

        local info = weaponData.info or {}
        if weaponData.serial then
            info.serial = weaponData.serial
        end

        Player.Functions.AddItem(weaponName, 1, nil, info)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[weaponName], 'add', 1)

        
        TriggerClientEvent('rsg-horses:client:equipRetrievedWeapon', src, result[1].stored_weapon)
    end

    MySQL.update('UPDATE player_horses SET stored_weapon = NULL, stored_weapon_name = NULL, stored_weapon_data = NULL WHERE citizenid = ? AND active = 1', { citizenid })
end)
-----------------------------------
-- set horse active
-----------------------------------
RegisterServerEvent('rsg-horses:server:SetHoresActive', function(id)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    
    local owned = MySQL.scalar.await('SELECT COUNT(*) FROM player_horses WHERE id = ? AND citizenid = ?', {id, Player.PlayerData.citizenid})
    if not owned or owned == 0 then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_not_own_horse'), type = 'error', duration = 5000 })
        return
    end
    
    local activehorse = MySQL.scalar.await('SELECT id FROM player_horses WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, true})
    MySQL.update('UPDATE player_horses SET active = ? WHERE id = ? AND citizenid = ?', { false, activehorse, Player.PlayerData.citizenid })
    MySQL.update('UPDATE player_horses SET active = ? WHERE id = ? AND citizenid = ?', { true, id, Player.PlayerData.citizenid })
end)

-----------------------------------
-- set horse unactive
-----------------------------------
RegisterServerEvent('rsg-horses:server:SetHoresUnActive', function(id, stableid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- SECURITY: Verify ownership
    local owned = MySQL.scalar.await('SELECT COUNT(*) FROM player_horses WHERE id = ? AND citizenid = ?', {id, Player.PlayerData.citizenid})
    if not owned or owned == 0 then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_not_own_horse'), type = 'error', duration = 5000 })
        return
    end
    
    MySQL.update('UPDATE player_horses SET active = ? WHERE citizenid = ? AND active = ?', { false, Player.PlayerData.citizenid, true })
    MySQL.update('UPDATE player_horses SET active = ? WHERE id = ? AND citizenid = ?', { false, id, Player.PlayerData.citizenid })
    MySQL.update('UPDATE player_horses SET stable = ? WHERE id = ? AND citizenid = ?', { stableid, id, Player.PlayerData.citizenid })
end)

-----------------------------------
-- store horse when flee is used
-----------------------------------
RegisterServerEvent('rsg-horses:server:fleeStoreHorse', function(stableid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local activehorse = MySQL.scalar.await('SELECT id FROM player_horses WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, 1})
    MySQL.update('UPDATE player_horses SET active = ? WHERE id = ? AND citizenid = ?', { 0, activehorse, Player.PlayerData.citizenid })
    MySQL.update('UPDATE player_horses SET stable = ? WHERE id = ? AND citizenid = ?', { stableid, activehorse, Player.PlayerData.citizenid })
end)

-----------------------------------
-- rename horse
-----------------------------------
RegisterServerEvent('rsg-horses:renameHorse', function(name)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- SECURITY: Validate input
    if not name or type(name) ~= "string" then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_invalid_horse_name'), type = 'error', duration = 5000 })
        return
    end
    
    -- Remove special characters
    name = string.gsub(name, "[^%w%s%-_]", "")
    
    if #name < 1 or #name > 50 then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_horse_name_length'), type = 'error', duration = 5000 })
        return
    end
    
    local newName = MySQL.query.await('UPDATE player_horses SET name = ? WHERE citizenid = ? AND active = ?' , {name, Player.PlayerData.citizenid, 1})

    if newName == nil then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_name_change_failed'), type = 'error', duration = 5000 })
        return
    end

    TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_success_name_change').. ' \''..name..'\' '..locale('sv_success_successfully'), type = 'success', duration = 5000 })
end)

----------------------------------
-- horse death handler
----------------------------------
RegisterServerEvent('rsg-horses:server:HorseDied', function(horseid, horsename)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local cid = Player.PlayerData.citizenid
    
    -- Get horse data (must be active/spawned to die)
    local horse = MySQL.query.await('SELECT * FROM player_horses WHERE citizenid = @citizenid AND horseid = @horseid AND active = @active', {
        ['@citizenid'] = cid,
        ['@horseid'] = horseid,
        ['@active'] = 1
    })
    
    if horse[1] then
        local horsestash = horse[1].name .. ' ' .. horseid
        
        
        MySQL.update('DELETE FROM inventories WHERE identifier = ?', {horsestash})
        
        
        MySQL.update('DELETE FROM player_horses WHERE citizenid = ? AND horseid = ?', {cid, horseid})
        
        
        TriggerEvent('rsg-log:server:CreateLog', 'horsetrainer', locale('sv_log_horse_trainer'), 'red', horsename .. ' ' .. locale('sv_log_horse_belong') .. ' ' .. cid .. ' ' .. locale('sv_log_horse_dead'))
        
        lib.notify(src, {title = locale('sv_error_horse_died'), type = 'error', duration = 7000})

        SendDiscordLog('horses', 'Horse Died', horsename .. ' has died.', WebhookColors.danger, {
            { name = 'Horse Name', value = horsename, inline = true },
            { name = 'Horse ID', value = tostring(horseid), inline = true },
        }, src)
    end
end)

----------------------------------
-- sell horse
----------------------------------
RegisterServerEvent('rsg-horses:server:deletehorse', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local horseid = data.horseid
    
   
    local player_horses = MySQL.query.await('SELECT * FROM player_horses WHERE id = @id AND `citizenid` = @citizenid', {
        ['@id'] = horseid,
        ['@citizenid'] = Player.PlayerData.citizenid
    })
    
    if not player_horses or #player_horses == 0 then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_not_own_horse'), type = 'error', duration = 5000 })
        return
    end
    
    local modelHorse = nil
    for i = 1, #player_horses do
        if tonumber(player_horses[i].id) == tonumber(horseid) then
            modelHorse = player_horses[i].horse
            
            
            local horsestash = player_horses[i].name .. ' ' .. player_horses[i].horseid
            MySQL.update('DELETE FROM inventories WHERE identifier = ?', {horsestash})
            
            
            MySQL.update('DELETE FROM player_horses WHERE id = ? AND citizenid = ?', { data.horseid, Player.PlayerData.citizenid })
        end
    end
    
    for k, v in pairs(HorseSettings) do
        if v.horsemodel == modelHorse then
            local sellprice = v.horseprice * 0.5
            Player.Functions.AddMoney('cash', sellprice)
            TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_success_horse_sold_for')..sellprice, type = 'success', duration = 5000 })

            SendDiscordLog('economy', 'Horse Sold', 'Horse (model ' .. tostring(modelHorse) .. ') sold back to the stable.', WebhookColors.success, {
                { name = 'Model', value = tostring(modelHorse), inline = true },
                { name = 'Sell Price', value = '$' .. tostring(sellprice), inline = true },
            }, src)
            break
        end
    end
end)

-----------------------------------
-- get horses
-----------------------------------
lib.callback.register('rsg-horses:server:GetHorse', function(source, stable)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local horses = {}
    local Result = MySQL.query.await('SELECT * FROM player_horses WHERE citizenid=@citizenid AND stable=@stable', { ['@citizenid'] = Player.PlayerData.citizenid, ['@stable'] = stable })
    for i = 1, #Result do
        horses[#horses + 1] = Result[i]
    end
    return horses
end)

-----------------------------------
-- get active horse
-----------------------------------
RSGCore.Functions.CreateCallback('rsg-horses:server:GetActiveHorse', function(source, cb)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    local result = MySQL.query.await('SELECT * FROM player_horses WHERE citizenid=@citizenid AND active=@active', { ['@citizenid'] = cid, ['@active'] = 1 })
    if (result[1] ~= nil) then
        cb(result[1])
    else
        return
    end
end)

-----------------------------------
-- horse customization
----------------------------------
-- get active horse components callback
RSGCore.Functions.CreateCallback('rsg-horses:server:CheckComponents', function(source, cb)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local Playercid = Player.PlayerData.citizenid
    local result = MySQL.query.await('SELECT * FROM player_horses WHERE citizenid=@citizenid AND active=@active', {
        ['@citizenid'] = Playercid,
        ['@active'] = 1
    })
    if (result[1] ~= nil) then
        cb(result[1])
    else
        return
    end
end)

-----------------------------------
-- save saddle
-----------------------------------
RegisterNetEvent('rsg-horses:server:SaveComponents', function(newComponents, horseid, newCoat)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

   
    local valid, error = ValidateComponents(newComponents)
    if not valid then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_invalid_components') .. error, type = 'error', duration = 5000 })
        return
    end

    local coatValid, coatError = ValidateCoat(newCoat)
    if not coatValid then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_invalid_components') .. coatError, type = 'error', duration = 5000 })
        return
    end

    local citizenid = Player.PlayerData.citizenid
    
   
    local result = MySQL.query.await('SELECT * FROM player_horses WHERE citizenid=@citizenid AND horseid=@horseid', { ['@citizenid'] = citizenid, ['@horseid'] = horseid })
    local horseData = result[1]
    
    if not horseData then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_not_own_horse'), type = 'error', duration = 5000 })
        return
    end
    
    local newComponents = newComponents or {}
    local currentComponents = json.decode(horseData.components) or {}
    local price = CalculatePrice(newComponents, currentComponents)

    -- coat price (merged from horse_markings flat fee)
    local currentCoat = nil
    if horseData.coat ~= nil and horseData.coat ~= '' then
        local ok, decoded = pcall(json.decode, horseData.coat)
        if ok and type(decoded) == 'table' then currentCoat = decoded end
    end
    price = price + CalculateCoatPrice(newCoat, currentCoat)

    if Player.Functions.RemoveMoney('cash', price) then
        MySQL.update('UPDATE player_horses SET components = @components WHERE id = @id', {['@components'] = json.encode(newComponents), ['@id'] = horseData.id})
        if newCoat ~= nil then
            local baseTint0 = math.floor(tonumber(newCoat.tint0) or 0)
            local saveCoat = {
                tint0 = baseTint0,
                tint1 = math.floor(tonumber(newCoat.tint1) == nil and 255 or tonumber(newCoat.tint1)),
                tint2 = math.floor(tonumber(newCoat.tint2) == nil and 255 or tonumber(newCoat.tint2)),
                mane = math.floor(tonumber(newCoat.mane) == nil and baseTint0 or tonumber(newCoat.mane)),
                tail = math.floor(tonumber(newCoat.tail) == nil and baseTint0 or tonumber(newCoat.tail)),
                palette = newCoat.palette or 'metaped_tint_horse',
                rainbow = newCoat.rainbow or false,
            }
            MySQL.update('UPDATE player_horses SET coat = @coat WHERE id = @id', {['@coat'] = json.encode(saveCoat), ['@id'] = horseData.id})
        end
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_success_component_saved') .. price, type = 'success', duration = 5000 })

        SendDiscordLog('horses', 'Horse Customization Saved', 'Saddle/coat customization updated on horse ' .. tostring(horseData.name) .. '.', WebhookColors.info, {
            { name = 'Horse', value = tostring(horseData.name), inline = true },
            { name = 'Price Paid', value = '$' .. tostring(price), inline = true },
        }, src)
    else
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_no_cash'), type = 'error', duration = 5000 })
    end
end)

-----------------------------------
-- trade horse (request)
-----------------------------------
RegisterNetEvent('rsg-horses:server:TradeHorse', function(playerId, horseId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local Target = RSGCore.Functions.GetPlayer(playerId)
    
    if not Player or not Target then return end
    
    
    local horse = MySQL.query.await('SELECT * FROM player_horses WHERE horseid = ? AND citizenid = ? AND active = ?', 
        {horseId, Player.PlayerData.citizenid, 1})
    
    if not horse or not horse[1] then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_not_own_or_active'), type = 'error', duration = 5000 })
        return
    end
    
   
    local playerPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(playerId)
    if not playerPed or not targetPed then return end
    
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = GetEntityCoords(targetPed)
    if #(playerCoords - targetCoords) > 5.0 then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_player_too_far'), type = 'error', duration = 5000 })
        return
    end
    
   
    tradeRequests[playerId] = {
        from = src,
        horseId = horseId,
        horseName = horse[1].name,
        horseModel = horse[1].horse,
        expires = os.time() + 30
    }
    
    TriggerClientEvent('ox_lib:notify', playerId, {
        title = locale('sv_trade_request_title'), 
        description = string.format(locale('sv_trade_request_desc'), GetPlayerName(src), horse[1].name),
        type = 'info', 
        duration = 30000 
    })
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = string.format(locale('sv_trade_request_sent'), GetPlayerName(playerId)), 
        type = 'success', 
        duration = 5000 
    })
end)

-----------------------------------
-- trade horse (accept)
-----------------------------------
RegisterNetEvent('rsg-horses:server:AcceptTrade', function(fromId)
    local src = source
    local trade = tradeRequests[src]
    
    if not trade then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_no_trade_request'), type = 'error', duration = 5000 })
        return
    end
    
    if trade.from ~= fromId then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_invalid_trade_request'), type = 'error', duration = 5000 })
        return
    end
    
    if os.time() > trade.expires then
        tradeRequests[src] = nil
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_trade_expired'), type = 'error', duration = 5000 })
        return
    end
    
    local Target = RSGCore.Functions.GetPlayer(src)
    local Sender = RSGCore.Functions.GetPlayer(fromId)
    
    if not Target or not Sender then
        tradeRequests[src] = nil
        return
    end
    
    
    local horse = MySQL.query.await('SELECT * FROM player_horses WHERE horseid = ? AND citizenid = ?', 
        {trade.horseId, Sender.PlayerData.citizenid})
    
    if not horse or not horse[1] then
        tradeRequests[src] = nil
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_horse_unavailable'), type = 'error', duration = 5000 })
        TriggerClientEvent('ox_lib:notify', fromId, {title = locale('sv_error_trade_failed'), type = 'error', duration = 5000 })
        return
    end
    
    
    MySQL.update('UPDATE player_horses SET citizenid = ?, active = ? WHERE horseid = ?', {Target.PlayerData.citizenid, 0, trade.horseId})
    
    
    MySQL.update('UPDATE player_horses SET active = ? WHERE citizenid = ? AND active = ?', {0, Target.PlayerData.citizenid, 1})
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = string.format(locale('sv_trade_received'), trade.horseName), 
        type = 'success', 
        duration = 7000 
    })
    
    TriggerClientEvent('ox_lib:notify', fromId, {
        title = string.format(locale('sv_trade_success'), GetPlayerName(src)), 
        type = 'success', 
        duration = 7000 
    })
    
    tradeRequests[src] = nil
end)

-----------------------------------
-- move horse between stables
-----------------------------------
RegisterServerEvent('rsg-horses:server:MoveHorse', function(horseId, newStableId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid

    
    local horse = MySQL.query.await('SELECT * FROM player_horses WHERE id = ? AND citizenid = ?', {horseId, citizenid})
    
    if not horse or not horse[1] then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_not_own_horse'), type = 'error', duration = 5000 })
        return
    end

    
    local currentStable = nil
    local newStable = nil
    
    for _, stableConfig in pairs(Config.StableSettings) do
        if stableConfig.stableid == horse[1].stable then
            currentStable = stableConfig
        end
        if stableConfig.stableid == newStableId then
            newStable = stableConfig
        end
    end

    if not newStable then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_invalid_stable'), type = 'error', duration = 5000 })
        return
    end

   
    if horse[1].stable == newStableId then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_horse_already_there'), type = 'error', duration = 5000 })
        return
    end

  
    if not currentStable then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_invalid_stable'), type = 'error', duration = 5000 })
        return
    end

    
    local baseFee = Config.MoveHorseBasePrice
    local feePerMeter = Config.MoveFeePerMeter
    local distance = #(currentStable.coords - newStable.coords)
    local moveFee = math.ceil(baseFee + (distance * feePerMeter))

    
    if not Player.Functions.RemoveMoney('cash', moveFee) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('sv_error_insufficient_funds'),
            description = string.format('Cost: $%d', moveFee),
            type = 'error',
            duration = 5000
        })
        return
    end

    
    MySQL.update('UPDATE player_horses SET stable = ? WHERE id = ? AND citizenid = ?', {newStableId, horseId, citizenid})

    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('sv_success_horse_moved'),
        description = string.format(locale('sv_success_horse_moved_desc'), horse[1].name, newStableId, moveFee),
        type = 'success',
        duration = 5000
    })

    SendDiscordLog('horses', 'Horse Moved Between Stables', horse[1].name .. ' moved to stable ' .. tostring(newStableId) .. '.', WebhookColors.info, {
        { name = 'Horse', value = horse[1].name, inline = true },
        { name = 'From Stable', value = tostring(horse[1].stable), inline = true },
        { name = 'To Stable', value = tostring(newStableId), inline = true },
        { name = 'Fee Paid', value = '$' .. tostring(moveFee), inline = true },
    }, src)
end)

-----------------------------------
-- generate horseid
-----------------------------------
function GenerateHorseid()
    local UniqueFound = false
    local horseid = nil
    while not UniqueFound do
        horseid = tostring(RSGCore.Shared.RandomStr(3) .. RSGCore.Shared.RandomInt(3)):upper()
        local result = MySQL.prepare.await('SELECT COUNT(*) as count FROM player_horses WHERE horseid = ?', { horseid })
        if result == 0 then
            UniqueFound = true
        end
    end
    return horseid
end

----------------------------------
-- others
----------------------------------
-- Check if Player has horsebrush before brush the horse
RegisterServerEvent('rsg-horses:server:brushhorse', function(item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    if Player.Functions.GetItemByName(item) then
        TriggerClientEvent('rsg-horses:client:playerbrushhorse', source, item)
    else
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_brush')..' '..item, type = 'error', duration = 5000 })
    end
end)

-----------------------------------
-- horse xp for feeding / brushing (server-authoritative)
-- client sends only the action ('brush' or feed item name),
-- amount is looked up from Config.HorseXp so it can't be spoofed
-----------------------------------
local horseXpCooldowns = {}

RegisterServerEvent('rsg-horses:server:AddHorseXp', function(action)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    if type(action) ~= 'string' then return end

    local xpConfig = Config.HorseXp
    if not xpConfig then return end

    local amount = nil
    local isBrush = (action == 'brush')
    if isBrush then
        amount = tonumber(xpConfig.Brush) or 0
    elseif type(xpConfig.Feed) == 'table' then
        amount = tonumber(xpConfig.Feed[action]) or 0
    end

    if not amount or amount <= 0 then
        SendDiscordLog('security', 'Rejected Horse XP - Unknown Action', 'Player sent an unknown feed/brush action for XP.', WebhookColors.warning, {
            { name = 'Action Sent', value = tostring(action), inline = true },
        }, src)
        return
    end

    local horse = MySQL.query.await('SELECT id, horseid, name, horsexp FROM player_horses WHERE citizenid = ? AND active = ?', { Player.PlayerData.citizenid, 1 })
    if not horse or not horse[1] then
        TriggerClientEvent('ox_lib:notify', src, { title = locale('sv_error_no_active_horse'), type = 'error', duration = 5000 })
        return
    end

    local horseRow = horse[1]
    local maxXp = tonumber(xpConfig.MaxXp) or 2000
    local currentXp = tonumber(horseRow.horsexp) or 0

    if currentXp >= maxXp then
        TriggerClientEvent('ox_lib:notify', src, { title = locale('sv_horse_xp_maxed'), type = 'info', duration = 5000 })
        return
    end

    local cooldown = tonumber(xpConfig.CooldownSeconds) or 0
    if cooldown > 0 then
        local last = horseXpCooldowns[horseRow.horseid] or 0
        local remaining = cooldown - (os.time() - last)
        if remaining > 0 then
            TriggerClientEvent('ox_lib:notify', src, { title = locale('sv_horse_xp_cooldown'):format(remaining), type = 'error', duration = 5000 })
            SendDiscordLog('security', 'Horse XP Cooldown Hit', 'Player tried to gain horse XP during cooldown.', WebhookColors.warning, {
                { name = 'Horse', value = tostring(horseRow.name), inline = true },
                { name = 'Remaining', value = tostring(remaining) .. 's', inline = true },
            }, src)
            return
        end
    end

    local newXp = math.min(currentXp + amount, maxXp)
    MySQL.update('UPDATE player_horses SET horsexp = ? WHERE id = ? AND citizenid = ?', { newXp, horseRow.id, Player.PlayerData.citizenid })

    if cooldown > 0 then
        horseXpCooldowns[horseRow.horseid] = os.time()
    end

    TriggerClientEvent('rsg-horses:client:horseXpUpdated', src, newXp, amount)
    TriggerClientEvent('ox_lib:notify', src, { title = locale('sv_horse_xp_gain'):format(amount, horseRow.name), type = 'success', duration = 5000 })

    SendDiscordLog('horses', 'Horse Gained XP', tostring(horseRow.name) .. ' gained +' .. tostring(amount) .. ' XP (' .. (isBrush and 'brush' or tostring(action)) .. ').', WebhookColors.success, {
        { name = 'Horse', value = tostring(horseRow.name), inline = true },
        { name = 'Action', value = isBrush and 'brush' or tostring(action), inline = true },
        { name = 'XP', value = tostring(currentXp) .. ' -> ' .. tostring(newXp), inline = true },
    }, src)
end)

-----------------------------------
-- horse attributes to database
-----------------------------------
RegisterServerEvent('rsg-horses:server:sethorseAttributes', function(dirt)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    dirt = tonumber(dirt)
    if not dirt or dirt < 0 or dirt > 100 then return end

    local activehorse = MySQL.scalar.await('SELECT id FROM player_horses WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, true})
    if not activehorse then return end
    MySQL.update('UPDATE player_horses SET dirt = ? WHERE id = ? AND citizenid = ?', { dirt, activehorse, Player.PlayerData.citizenid })
end)

RegisterServerEvent('rsg-horses:server:SetPlayerBucket', function(random, ped)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    if random then
        local BucketID = RSGCore.Shared.RandomInt(1000, 9999)
        SetRoutingBucketPopulationEnabled(BucketID, false)
        SetPlayerRoutingBucket(source, BucketID)
        SetPlayerRoutingBucket(ped, BucketID)
    else
        SetPlayerRoutingBucket(source, 0)
        SetPlayerRoutingBucket(ped, 0)
    end
end)

---------------------------------
-- horse inventory
---------------------------------
RegisterNetEvent('rsg-horses:server:openhorseinventory', function(horseid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    -- verify ownership
    local horse = MySQL.query.await('SELECT * FROM player_horses WHERE horseid = ? AND citizenid = ?', {horseid, Player.PlayerData.citizenid})
    if not horse[1] then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_not_own_horse'), type = 'error', duration = 5000 })
        return
    end

    local horsestash = horse[1].name .. ' ' .. horse[1].horseid
    local horsexp = horse[1].horsexp

    -- calculate inventory capacity based on xp (server-authoritative)
    local invWeight, invSlots
    if horsexp <= 99 then
        invWeight = Config.Level1InvWeight
        invSlots = Config.Level1InvSlots
    elseif horsexp <= 199 then
        invWeight = Config.Level2InvWeight
        invSlots = Config.Level2InvSlots
    elseif horsexp <= 299 then
        invWeight = Config.Level3InvWeight
        invSlots = Config.Level3InvSlots
    elseif horsexp <= 399 then
        invWeight = Config.Level4InvWeight
        invSlots = Config.Level4InvSlots
    elseif horsexp <= 499 then
        invWeight = Config.Level5InvWeight
        invSlots = Config.Level5InvSlots
    elseif horsexp <= 999 then
        invWeight = Config.Level6InvWeight
        invSlots = Config.Level6InvSlots
    elseif horsexp <= 1399 then
        invWeight = Config.Level7InvWeight
        invSlots = Config.Level7InvSlots
    elseif horsexp <= 1699 then
        invWeight = Config.Level8InvWeight
        invSlots = Config.Level8InvSlots
    elseif horsexp <= 1899 then
        invWeight = Config.Level9InvWeight
        invSlots = Config.Level9InvSlots
    else
        invWeight = Config.Level10InvWeight
        invSlots = Config.Level10InvSlots
    end

    local data = { label = locale('sv_horse_inventory'), maxweight = invWeight, slots = invSlots }
    exports['rsg-inventory']:OpenInventory(src, horsestash, data)
end)

--------------------------------------
-- register shop
--------------------------------------
CreateThread(function()
    exports['rsg-inventory']:CreateShop({
        name = 'horse',
        label = locale('cl_horse_shop'),
        slots = #Config.horsesShopItems,
        items = Config.horsesShopItems,
        persistentStock = Config.PersistStock,
    })
end)

--------------------------------------
-- open shop
--------------------------------------
--------------------------------------
-- NUI shop purchase items
--------------------------------------
RegisterNetEvent('rsg-horses:server:buyShopItems', function(items, total)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    if not items or #items == 0 then return end

    -- SECURITY: item.quantity is client-supplied. Without validating it is a
    -- positive integer, a negative quantity makes calcTotal negative; if the
    -- client also sends a matching negative `total`, RemoveMoney is called
    -- with a negative amount which effectively hands the player free money
    -- (and AddItem with a negative quantity is undefined behaviour too).
    for _, item in ipairs(items) do
        if type(item.quantity) ~= 'number' or item.quantity <= 0 or item.quantity ~= math.floor(item.quantity) then
            TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_invalid_quantity'), type = 'error', duration = 5000})
            SendDiscordLog('security', 'Rejected Shop Purchase - Invalid Quantity', 'Player attempted to buy a shop item with an invalid quantity.', WebhookColors.warning, {
                { name = 'Item', value = tostring(item.name), inline = true },
                { name = 'Quantity Sent', value = tostring(item.quantity), inline = true },
            }, src)
            return
        end
    end

    -- Verify total
    local calcTotal = 0
    for _, item in ipairs(items) do
        for _, shopItem in ipairs(Config.horsesShopItems) do
            if shopItem.name == item.name then
                calcTotal = calcTotal + (shopItem.price * item.quantity)
                break
            end
        end
    end

    if calcTotal <= 0 or calcTotal ~= total then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_price_mismatch'), type = 'error', duration = 5000})
        SendDiscordLog('security', 'Rejected Shop Purchase - Price Mismatch', 'Client-sent total did not match the server-calculated price.', WebhookColors.warning, {
            { name = 'Server Calculated Total', value = '$' .. tostring(calcTotal), inline = true },
            { name = 'Client Sent Total', value = '$' .. tostring(total), inline = true },
        }, src)
        return
    end

    if not Player.Functions.RemoveMoney('cash', total) then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_no_cash'), type = 'error', duration = 5000})
        return
    end

    for _, item in ipairs(items) do
        Player.Functions.AddItem(item.name, item.quantity)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item.name], 'add', item.quantity)
    end
    TriggerClientEvent('rsg-horses:client:shopPurchaseSuccess', src)

    local itemSummary = {}
    for _, item in ipairs(items) do
        itemSummary[#itemSummary + 1] = tostring(item.quantity) .. 'x ' .. tostring(item.name)
    end
    SendDiscordLog('economy', 'Horse Shop Purchase', table.concat(itemSummary, ', '), WebhookColors.success, {
        { name = 'Total Paid', value = '$' .. tostring(total), inline = true },
    }, src)
end)

RegisterNetEvent('rsg-horses:server:openShop', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    -- verify player is near a stable
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local nearStable = false
    for _, stable in pairs(Config.StableSettings) do
        if #(coords - stable.coords) < 10.0 then
            nearStable = true
            break
        end
    end

    if not nearStable then return end

    exports['rsg-inventory']:OpenShop(src, 'horse')
end)

----------------------------------
-- horse check system
----------------------------------
UpkeepInterval = function()

    local result = MySQL.query.await('SELECT * FROM player_horses')

    if not result then goto continue end

    for i = 1, #result do
        local id = result[i].id
        local horsetype = result[i].horse
        local horsename = result[i].name
        local ownercid = result[i].citizenid
        local currentTime = os.time()
        local timeDifference = currentTime - result[i].born
        local daysPassed = math.floor(timeDifference / (24 * 60 * 60))

        --print(id, horsetype, horsename, ownercid, daysPassed)

        if horsetype == 'a_c_horse_mp_mangy_backup' and daysPassed >= Config.StarterHorseDieAge then

            -- horseid already available from the initial SELECT * above; no need to re-query
            local horsestash = horsename .. ' ' .. result[i].horseid

            -- Clear horse inventory stash from database
            MySQL.update('DELETE FROM inventories WHERE identifier = ?', {horsestash})

            -- delete horse
            MySQL.update('DELETE FROM player_horses WHERE id = ?', {id})
            TriggerEvent('rsg-log:server:CreateLog', 'horsetrainer', locale('sv_log_horse_trainer'), 'red', horsename..' '..locale('sv_log_horse_belong')..' '..ownercid..' '..locale('sv_log_horse_dead'))

            SendDiscordLog('horses', 'Starter Horse Expired (Upkeep)', horsename .. ' aged out and was removed from stables.', WebhookColors.warning, {
                { name = 'Horse', value = horsename, inline = true },
                { name = 'Owner CitizenID', value = tostring(ownercid), inline = true },
                { name = 'Days Passed', value = tostring(daysPassed), inline = true },
            })

            -- telegram message to the horse owner
            MySQL.insert('INSERT INTO telegrams (citizenid, recipient, sender, sendername, subject, sentDate, message) VALUES (?, ?, ?, ?, ?, ?, ?)',
            {   ownercid,
                locale('sv_telegram_owner'),
                '22222222',
                locale('sv_telegram_stables'),
                horsename..' '..locale('sv_telegram_away'),
                os.date('%x'),
                locale('sv_telegram_inform')..' '..horsename..' '..locale('sv_telegram_has_passed'),
            })

            goto continue
        end

        if daysPassed >= Config.HorseDieAge then

            -- horseid already available from the initial SELECT * above; no need to re-query
            local horsestash = horsename .. ' ' .. result[i].horseid

            -- Clear horse inventory
            local success = pcall(function()
                exports['rsg-inventory']:ClearInventory(horsestash)
            end)

            if not success then
                MySQL.update('DELETE FROM inventories WHERE identifier = ?', {horsestash})
            end

            -- delete horse
            MySQL.update('DELETE FROM player_horses WHERE id = ?', {id})
            TriggerEvent('rsg-log:server:CreateLog', 'horsetrainer', locale('sv_log_horse_trainer'), 'red', horsename..' '..locale('sv_log_horse_belong')..' '..ownercid..' '..locale('sv_log_horse_dead'))

            SendDiscordLog('horses', 'Horse Expired (Upkeep)', horsename .. ' aged out and was removed from stables.', WebhookColors.warning, {
                { name = 'Horse', value = horsename, inline = true },
                { name = 'Owner CitizenID', value = tostring(ownercid), inline = true },
                { name = 'Days Passed', value = tostring(daysPassed), inline = true },
            })

            -- telegram message to the horse owner
            MySQL.insert('INSERT INTO telegrams (citizenid, recipient, sender, sendername, subject, sentDate, message) VALUES (?, ?, ?, ?, ?, ?, ?)',
            {   ownercid,
                locale('sv_telegram_owner'),
                '22222222',
                locale('sv_telegram_stables'),
                horsename..' '..locale('sv_telegram_away'),
                os.date('%x'),
                locale('sv_telegram_inform')..' '..horsename..' '..locale('sv_telegram_has_passed'),
            })

            goto continue
        end

    end

    ::continue::
    
    if Config.EnableServerNotify then
        print(locale('sv_print'))
    end

SetTimeout(Config.CheckCycle * (60 * 1000), UpkeepInterval)
end

-----------------------------------
-- BREEDING SYSTEM
-----------------------------------

-- Ensure breeding columns exist on resource start
CreateThread(function()
    Wait(2000)
    local columns = MySQL.query.await('SHOW COLUMNS FROM player_horses')
    local existing = {}
    for _, col in ipairs(columns) do
        existing[col.Field] = true
    end
    if not existing['age_seconds'] then
        MySQL.query.await('ALTER TABLE player_horses ADD COLUMN `age_seconds` INT(11) NOT NULL DEFAULT 0')
    end
    if not existing['pregnant_until'] then
        MySQL.query.await('ALTER TABLE player_horses ADD COLUMN `pregnant_until` INT(11) DEFAULT NULL')
    end
    if not existing['last_bred'] then
        MySQL.query.await('ALTER TABLE player_horses ADD COLUMN `last_bred` INT(11) DEFAULT NULL')
    end
    print('[rsg-horses] Breeding system columns ensured')
end)

local function GetRandomHorseModel()
    local models = Config.HorseModels
    if not models or #models == 0 then return 'a_c_horse_morgan_bay' end
    return models[math.random(#models)]
end

local function GetRandomFoalName()
    local prefixes = { 'Little', 'Tiny', 'Baby', 'Sweet', 'Lucky', 'Happy', 'Sunny', 'Storm', 'Shadow', 'Star', 'Dusty', 'Buddy' }
    local suffixes = { 'Star', 'Storm', 'Wind', 'Heart', 'Spirit', 'Dream', 'Bolt', 'Flash', 'Cloud', 'Moon', 'Fire', 'Rose' }
    return prefixes[math.random(#prefixes)] .. ' ' .. suffixes[math.random(#suffixes)]
end

-- Get all horses for a player (for stallion selection)
lib.callback.register('rsg-horses:server:GetPlayerHorses', function(source)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return {} end
    local cid = Player.PlayerData.citizenid
    local result = MySQL.query.await('SELECT id, name, horse, gender, age_seconds, pregnant_until FROM player_horses WHERE citizenid = ?', { cid })
    return result or {}
end)

-- Breed horse event
RegisterServerEvent('rsg-horses:server:breedHorse', function(mareId, stallionId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    if not Config.Breeding or not Config.Breeding.enabled then
        TriggerClientEvent('ox_lib:notify', src, { title = locale('sv_error_breeding_disabled'), type = 'error', duration = 5000 })
        return
    end

    if Config.Breeding.requiredJob and Player.PlayerData.job.name ~= Config.Breeding.requiredJob then
        TriggerClientEvent('ox_lib:notify', src, { title = locale('err_breeder_required'), type = 'error', duration = 5000 })
        return
    end

    local cid = Player.PlayerData.citizenid

    -- Fetch mare
    local mare = MySQL.query.await('SELECT * FROM player_horses WHERE id = ? AND citizenid = ?', { mareId, cid })
    if not mare or not mare[1] then
        TriggerClientEvent('ox_lib:notify', src, { title = locale('sv_error_not_own_horse'), type = 'error', duration = 5000 })
        return
    end
    mare = mare[1]

    -- Validate mare gender
    if Config.Breeding.requireOppositeSex and mare.gender ~= 'female' then
        TriggerClientEvent('ox_lib:notify', src, { title = locale('sv_error_breed_select_mare'), type = 'error', duration = 5000 })
        return
    end

    -- Check mare maturity
    local maturitySecs = (Config.Breeding.maturityMinutes or 60) * 60
    local mareAge = mare.age_seconds or 0
    if mareAge < maturitySecs then
        local minsLeft = math.ceil((maturitySecs - mareAge) / 60)
        TriggerClientEvent('ox_lib:notify', src, { title = locale('sv_error_mare_not_mature'):format(minsLeft), type = 'error', duration = 5000 })
        return
    end

    -- Check mare not already pregnant
    if mare.pregnant_until and mare.pregnant_until > os.time() then
        local remaining = math.ceil((mare.pregnant_until - os.time()) / 60)
        TriggerClientEvent('ox_lib:notify', src, { title = locale('sv_error_already_pregnant'):format(remaining), type = 'error', duration = 5000 })
        return
    end

    -- Check cooldown
    local cooldownSecs = (Config.Breeding.breedCooldownMinutes or 60) * 60
    if mare.last_bred and (os.time() - mare.last_bred) < cooldownSecs then
        local remaining = math.ceil((cooldownSecs - (os.time() - mare.last_bred)) / 60)
        TriggerClientEvent('ox_lib:notify', src, { title = locale('sv_error_breeding_cooldown'):format(remaining), type = 'error', duration = 5000 })
        return
    end

    -- Fetch stallion
    local stallion = MySQL.query.await('SELECT * FROM player_horses WHERE id = ? AND citizenid = ?', { stallionId, cid })
    if not stallion or not stallion[1] then
        TriggerClientEvent('ox_lib:notify', src, { title = locale('sv_error_not_own_stallion'), type = 'error', duration = 5000 })
        return
    end
    stallion = stallion[1]

    -- Validate stallion gender
    if Config.Breeding.requireOppositeSex and stallion.gender ~= 'male' then
        TriggerClientEvent('ox_lib:notify', src, { title = locale('sv_error_breed_must_be_male'), type = 'error', duration = 5000 })
        return
    end

    -- Check stallion maturity
    local stallionAge = stallion.age_seconds or 0
    if stallionAge < maturitySecs then
        TriggerClientEvent('ox_lib:notify', src, { title = locale('sv_error_stallion_not_mature'), type = 'error', duration = 5000 })
        return
    end

    -- Remove hay cost
    local hayCost = Config.Breeding.hayCost or 0
    if hayCost > 0 then
        local hasItem = Player.Functions.GetItemByName('hay')
        if not hasItem or hasItem.amount < hayCost then
            TriggerClientEvent('ox_lib:notify', src, { title = locale('sv_error_need_hay'):format(hayCost), type = 'error', duration = 5000 })
            return
        end
        Player.Functions.RemoveItem('hay', hayCost)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items['hay'], 'remove', hayCost)
    end

    -- Set pregnancy
    local gestationSecs = (Config.Breeding.gestationMinutes or 30) * 60
    local now = os.time()
    local pregnantUntil = now + gestationSecs

    MySQL.update.await('UPDATE player_horses SET pregnant_until = ?, last_bred = ? WHERE id = ?', { pregnantUntil, now, mareId })

    local gestMins = Config.Breeding.gestationMinutes or 30
    TriggerClientEvent('ox_lib:notify', src, { title = locale('sv_success_breeding_started'):format(gestMins), type = 'success', duration = 7000 })
end)

-- Birth processing loop
CreateThread(function()
    while true do
        Wait(30000)
        local now = os.time()

        local readyMothers = MySQL.query.await('SELECT * FROM player_horses WHERE pregnant_until IS NOT NULL AND pregnant_until <= ?', { now })

        if readyMothers and #readyMothers > 0 then
            for _, mother in ipairs(readyMothers) do
                local cid = mother.citizenid
                local foalModel = GetRandomHorseModel()
                local foalGender = math.random(0, 1) == 0 and 'male' or 'female'
                local foalName = GetRandomFoalName()
                local horseid = tostring(RSGCore.Shared.RandomStr(3) .. RSGCore.Shared.RandomInt(3)):upper()
                local foalStable = mother.stable or 'valentine'

                -- Ensure unique horseid
                local attempts = 0
                while attempts < 10 do
                    local exists = MySQL.scalar.await('SELECT COUNT(*) FROM player_horses WHERE horseid = ?', { horseid })
                    if exists == 0 then break end
                    horseid = tostring(RSGCore.Shared.RandomStr(3) .. RSGCore.Shared.RandomInt(3)):upper()
                    attempts = attempts + 1
                end

                MySQL.insert.await('INSERT INTO player_horses(stable, citizenid, horseid, name, horse, gender, active, born, age_seconds) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)', {
                    foalStable, cid, horseid, foalName, foalModel, foalGender, false, now, 0
                })

                -- Clear mother pregnancy
                MySQL.update.await('UPDATE player_horses SET pregnant_until = NULL WHERE id = ?', { mother.id })

                -- Find the owner online and notify
                for _, playerId in ipairs(GetPlayers()) do
                    local pid = tonumber(playerId)
                    if pid then
                        local p = RSGCore.Functions.GetPlayer(pid)
                        if p and p.PlayerData.citizenid == cid then
                            TriggerClientEvent('ox_lib:notify', pid, {
                                title = locale('sv_success_foal_born_title'),
                                description = locale('sv_success_foal_born_desc'):format(foalGender, foalModel, foalName, foalStable),
                                type = 'success',
                                duration = 10000
                            })
                            break
                        end
                    end
                end

                print(('[rsg-horses] Foal born: %s (%s) for player %s at %s'):format(foalName, foalModel, cid, foalStable))
            end
        end
    end
end)

-- Age tick loop (increments age_seconds for all horses)
CreateThread(function()
    while true do
        Wait(30000)
        MySQL.update('UPDATE player_horses SET age_seconds = age_seconds + 30 WHERE age_seconds IS NOT NULL')
    end
end)

-----------------------------------
-- end of breeding system
-----------------------------------

SetTimeout(Config.CheckCycle * (60 * 1000), UpkeepInterval)
