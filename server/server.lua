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
    end
end)

-- feed horse carrot
RSGCore.Functions.CreateUseableItem('horse_carrot', function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('rsg-horses:client:playerfeedhorse', source, item.name)
    end
end)

 -- feed apple
 RSGCore.Functions.CreateUseableItem('horse_apple', function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('rsg-horses:client:playerfeedhorse', source, item.name)
    end
end)

-- feed horse sugarcube
RSGCore.Functions.CreateUseableItem('sugarcube', function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('rsg-horses:client:playerfeedhorse', source, item.name)
    end
end)

-- feed horse haysnack
RSGCore.Functions.CreateUseableItem('haysnack', function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('rsg-horses:client:playerfeedhorse', source, item.name)
    end
end)

-- feed horse horsemeal
RSGCore.Functions.CreateUseableItem('horsemeal', function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('rsg-horses:client:playerfeedhorse', source, item.name)
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

    TriggerClientEvent('rsg-horses:client:revivehorse', src, item, result[1])
end)

----------------------------------
-- revive horse
----------------------------------
RegisterServerEvent('rsg-horses:server:revivehorse', function(item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(source)

    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item.name], 'remove', 1)
    end
end)

----------------------------------
-- buy & active
----------------------------------
RegisterServerEvent('rsg-horses:server:BuyHorse', function(model, stable, horsename, gender)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    -- SECURITY: Validate horse name
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
    
    -- SECURITY: Atomic transaction - remove money first
    if not Player.Functions.RemoveMoney('cash', price) then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_no_cash'), type = 'error', duration = 5000 })
        return
    end
    
    -- Money removed successfully, now safe to create horse
    local horseid = GenerateHorseid()
    MySQL.insert('INSERT INTO player_horses(stable, citizenid, horseid, name, horse, gender, active, born) VALUES(@stable, @citizenid, @horseid, @name, @horse, @gender, @active, @born)', {
        ['@stable'] = stable,
        ['@citizenid'] = Player.PlayerData.citizenid,
        ['@horseid'] = horseid,
        ['@name'] = horsename,
        ['@horse'] = model,
        ['@gender'] = gender,
        ['@active'] = false,
        ['@born'] = os.time()
    })
    
    TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_success_horse_owned'), type = 'success', duration = 5000 })
end)

-----------------------------------
-- set horse active
-----------------------------------
RegisterServerEvent('rsg-horses:server:SetHoresActive', function(id)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- SECURITY: Verify ownership
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
    
    local activehorse = MySQL.scalar.await('SELECT id FROM player_horses WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, false})
    MySQL.update('UPDATE player_horses SET active = ? WHERE id = ? AND citizenid = ?', { false, activehorse, Player.PlayerData.citizenid })
    MySQL.update('UPDATE player_horses SET active = ? WHERE id = ? AND citizenid = ?', { false, id, Player.PlayerData.citizenid })
    MySQL.update('UPDATE player_horses SET stable = ? WHERE id = ? AND citizenid = ?', { stableid, id, Player.PlayerData.citizenid })
end)

-----------------------------------
-- store horse when flee is used
-----------------------------------
RegisterServerEvent('rsg-horses:server:fleeStoreHorse', function(stableid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
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
    
    -- Get horse data
    local horse = MySQL.query.await('SELECT * FROM player_horses WHERE citizenid = @citizenid AND horseid = @horseid', {
        ['@citizenid'] = cid,
        ['@horseid'] = horseid
    })
    
    if horse[1] then
        local horsestash = horse[1].name .. ' ' .. horseid
        
        -- Clear horse inventory stash from database
        -- Horse stashes are stored as identifiers in the inventories table
        MySQL.update('DELETE FROM inventories WHERE identifier = ?', {horsestash})
        
        -- Remove horse from database
        MySQL.update('DELETE FROM player_horses WHERE citizenid = ? AND horseid = ?', {cid, horseid})
        
        -- Log the death
        TriggerEvent('rsg-log:server:CreateLog', 'horsetrainer', locale('sv_log_horse_trainer'), 'red', horsename .. ' ' .. locale('sv_log_horse_belong') .. ' ' .. cid .. ' ' .. locale('sv_log_horse_dead'))
        
        lib.notify(src, {title = locale('sv_error_horse_died'), type = 'error', duration = 7000})
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
    
    -- SECURITY: Verify ownership before selling
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
            
            -- Delete horse inventory
            local horsestash = player_horses[i].name .. ' ' .. player_horses[i].horseid
            MySQL.update('DELETE FROM inventories WHERE identifier = ?', {horsestash})
            
            -- Delete horse
            MySQL.update('DELETE FROM player_horses WHERE id = ? AND citizenid = ?', { data.horseid, Player.PlayerData.citizenid })
        end
    end
    
    for k, v in pairs(HorseSettings) do
        if v.horsemodel == modelHorse then
            local sellprice = v.horseprice * 0.5
            Player.Functions.AddMoney('cash', sellprice)
            TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_success_horse_sold_for')..sellprice, type = 'success', duration = 5000 })
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
RegisterNetEvent('rsg-horses:server:SaveComponents', function(newComponents, horseid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    -- SECURITY: Validate components
    local valid, error = ValidateComponents(newComponents)
    if not valid then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_invalid_components') .. error, type = 'error', duration = 5000 })
        return
    end

    local citizenid = Player.PlayerData.citizenid
    
    -- SECURITY: Verify ownership
    local result = MySQL.query.await('SELECT * FROM player_horses WHERE citizenid=@citizenid AND horseid=@horseid', { ['@citizenid'] = citizenid, ['@horseid'] = horseid })
    local horseData = result[1]
    
    if not horseData then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_not_own_horse'), type = 'error', duration = 5000 })
        return
    end
    
    local newComponents = newComponents or {}
    local currentComponents = json.decode(horseData.components) or {}
    local price = CalculatePrice(newComponents, currentComponents)

    if Player.Functions.RemoveMoney('cash', price) then
        MySQL.update('UPDATE player_horses SET components = @components WHERE id = @id', {['@components'] = json.encode(newComponents), ['@id'] = horseData.id})
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_success_component_saved') .. price, type = 'success', duration = 5000 })
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
    
    -- SECURITY: Verify ownership
    local horse = MySQL.query.await('SELECT * FROM player_horses WHERE horseid = ? AND citizenid = ? AND active = ?', 
        {horseId, Player.PlayerData.citizenid, 1})
    
    if not horse or not horse[1] then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_not_own_or_active'), type = 'error', duration = 5000 })
        return
    end
    
    -- SECURITY: Distance check
    local playerPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(playerId)
    if not playerPed or not targetPed then return end
    
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = GetEntityCoords(targetPed)
    if #(playerCoords - targetCoords) > 5.0 then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_player_too_far'), type = 'error', duration = 5000 })
        return
    end
    
    -- Send trade request to target
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
    
    -- Verify horse still exists and is owned by sender
    local horse = MySQL.query.await('SELECT * FROM player_horses WHERE horseid = ? AND citizenid = ?', 
        {trade.horseId, Sender.PlayerData.citizenid})
    
    if not horse or not horse[1] then
        tradeRequests[src] = nil
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_horse_unavailable'), type = 'error', duration = 5000 })
        TriggerClientEvent('ox_lib:notify', fromId, {title = locale('sv_error_trade_failed'), type = 'error', duration = 5000 })
        return
    end
    
    -- Proceed with trade
    MySQL.update('UPDATE player_horses SET citizenid = ?, active = ? WHERE horseid = ?', {Target.PlayerData.citizenid, 0, trade.horseId})
    
    -- Deactivate target's current active horse if they have one
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

    -- verify ownership
    local horse = MySQL.query.await('SELECT * FROM player_horses WHERE id = ? AND citizenid = ?', {horseId, citizenid})
    
    if not horse or not horse[1] then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_not_own_horse'), type = 'error', duration = 5000 })
        return
    end

    -- verify stable exists and get coordinates
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

    -- check if horse is already at that stable
    if horse[1].stable == newStableId then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_horse_already_there'), type = 'error', duration = 5000 })
        return
    end

    -- calculate distance-based fee
    local baseFee = Config.MoveHorseBasePrice
    local feePerMeter = Config.MoveFeePerMeter
    local distance = 0
    
    if currentStable then
        distance = #(currentStable.coords - newStable.coords)
    end
    
    local moveFee = math.ceil(baseFee + (distance * feePerMeter))

    -- Attempt to deduct fee
    if not Player.Functions.RemoveMoney('cash', moveFee) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('sv_error_insufficient_funds'),
            description = string.format('Cost: $%d', moveFee),
            type = 'error',
            duration = 5000
        })
        return
    end

    -- Move horse to new stable
    MySQL.update('UPDATE player_horses SET stable = ? WHERE id = ? AND citizenid = ?', {newStableId, horseId, citizenid})

    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('sv_success_horse_moved'),
        description = string.format(locale('sv_success_horse_moved_desc'), horse[1].name, newStableId, moveFee),
        type = 'success',
        duration = 5000
    })
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
    if Player.Functions.GetItemByName(item) then
        TriggerClientEvent('rsg-horses:client:playerbrushhorse', source, item)
    else
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_brush')..' '..item, type = 'error', duration = 5000 })
    end
end)

-----------------------------------
-- horse attributes to database
-----------------------------------
RegisterServerEvent('rsg-horses:server:sethorseAttributes', function(dirt)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local activehorse = MySQL.scalar.await('SELECT id FROM player_horses WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, true})
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
RegisterNetEvent('rsg-horses:server:openhorseinventory', function(horsestash, invWeight, invSlots)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
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
RegisterNetEvent('rsg-horses:server:openShop', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
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
            
            -- Get horseid for inventory cleanup
            local horsedata = MySQL.query.await('SELECT horseid FROM player_horses WHERE id = ?', {id})
            if horsedata[1] then
                local horsestash = horsename .. ' ' .. horsedata[1].horseid
                
                -- Clear horse inventory stash from database
                MySQL.update('DELETE FROM inventories WHERE identifier = ?', {horsestash})
            end

            -- delete horse
            MySQL.update('DELETE FROM player_horses WHERE id = ?', {id})
            TriggerEvent('rsg-log:server:CreateLog', 'horsetrainer', locale('sv_log_horse_trainer'), 'red', horsename..' '..locale('sv_log_horse_belong')..' '..ownercid..' '..locale('sv_log_horse_dead'))

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
            
            -- Get horseid for inventory cleanup
            local horsedata = MySQL.query.await('SELECT horseid FROM player_horses WHERE id = ?', {id})
            if horsedata[1] then
                local horsestash = horsename .. ' ' .. horsedata[1].horseid
                
                -- Clear horse inventory
                local success = pcall(function()
                    exports['rsg-inventory']:ClearInventory(horsestash)
                end)
                
                if not success then
                    MySQL.update('DELETE FROM inventories WHERE identifier = ?', {horsestash})
                end
            end

            -- delete horse
            MySQL.update('DELETE FROM player_horses WHERE id = ?', {id})
            TriggerEvent('rsg-log:server:CreateLog', 'horsetrainer', locale('sv_log_horse_trainer'), 'red', horsename..' '..locale('sv_log_horse_belong')..' '..ownercid..' '..locale('sv_log_horse_dead'))

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

SetTimeout(Config.CheckCycle * (60 * 1000), UpkeepInterval)
