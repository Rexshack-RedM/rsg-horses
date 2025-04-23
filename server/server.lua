local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

----------------------------------
-- find horse command
----------------------------------
RSGCore.Commands.Add('findhorse', locale('sv_command_find'), {}, false, function(source)
    local src = source
    TriggerClientEvent('rsg-horses:client:gethorselocation', src)
end)

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
-- Items
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

-- player horseholster
RSGCore.Functions.CreateUseableItem('horse_holster', function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    TriggerClientEvent('rsg-horses:client:equipHorseHolster', source, item.name)
end)

 -- horse stimulant
 RSGCore.Functions.CreateUseableItem('horse_stimulant', function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('rsg-horses:client:playerfeedhorse', source, item.name)
    end
end)

-- feed horse carrot
RSGCore.Functions.CreateUseableItem('carrot', function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('rsg-horses:client:playerfeedhorse', source, item.name)
    end
end)

 -- feed apple
 RSGCore.Functions.CreateUseableItem('apple', function(source, item)
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

-- horse reviver
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
-- Revive
----------------------------------
RegisterServerEvent('rsg-horses:server:revivehorse', function(item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(source)

    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item.name], 'remove', 1)
    end
end)

----------------------------------
-- Buy & active
----------------------------------
RegisterServerEvent('rsg-horses:server:BuyHorse', function(price, model, stable, horsename, gender)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    if (Player.PlayerData.money.cash < price) then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_no_cash'), type = 'error', duration = 5000 })
        return
    end
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
    Player.Functions.RemoveMoney('cash', price)
    
    TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_success_horse_owned'), type = 'success', duration = 5000 })
end)

RegisterServerEvent('rsg-horses:server:SetHoresActive', function(id)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local activehorse = MySQL.scalar.await('SELECT id FROM player_horses WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, true})
    MySQL.update('UPDATE player_horses SET active = ? WHERE id = ? AND citizenid = ?', { false, activehorse, Player.PlayerData.citizenid })
    MySQL.update('UPDATE player_horses SET active = ? WHERE id = ? AND citizenid = ?', { true, id, Player.PlayerData.citizenid })
end)

RegisterServerEvent('rsg-horses:server:SetHoresUnActive', function(id, stableid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local activehorse = MySQL.scalar.await('SELECT id FROM player_horses WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, false})
    MySQL.update('UPDATE player_horses SET active = ? WHERE id = ? AND citizenid = ?', { false, activehorse, Player.PlayerData.citizenid })
    MySQL.update('UPDATE player_horses SET active = ? WHERE id = ? AND citizenid = ?', { false, id, Player.PlayerData.citizenid })
    MySQL.update('UPDATE player_horses SET stable = ? WHERE id = ? AND citizenid = ?', { stableid, id, Player.PlayerData.citizenid })
end)

-- store horse when flee is used
RegisterServerEvent('rsg-horses:server:fleeStoreHorse', function(stableid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local activehorse = MySQL.scalar.await('SELECT id FROM player_horses WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, 1})
    MySQL.update('UPDATE player_horses SET active = ? WHERE id = ? AND citizenid = ?', { 0, activehorse, Player.PlayerData.citizenid })
    MySQL.update('UPDATE player_horses SET stable = ? WHERE id = ? AND citizenid = ?', { stableid, activehorse, Player.PlayerData.citizenid })
end)

RegisterServerEvent('rsg-horses:renameHorse', function(name)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local newName = MySQL.query.await('UPDATE player_horses SET name = ? WHERE citizenid = ? AND active = ?' , {name, Player.PlayerData.citizenid, 1})

    if newName == nil then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_name_change_failed'), type = 'error', duration = 5000 })
        return
    end

    TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_success_name_change').. ' \''..name..'\' '..locale('sv_success_successfully'), type = 'success', duration = 5000 })
end)

----------------------------------
-- sell horse
----------------------------------
RegisterServerEvent('rsg-horses:server:deletehorse', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local modelHorse = nil
    local horseid = data.horseid
    local player_horses = MySQL.query.await('SELECT * FROM player_horses WHERE id = @id AND `citizenid` = @citizenid', {
        ['@id'] = horseid,
        ['@citizenid'] = Player.PlayerData.citizenid
    })
    for i = 1, #player_horses do
        if tonumber(player_horses[i].id) == tonumber(horseid) then
            modelHorse = player_horses[i].horse
            MySQL.update('DELETE FROM player_horses WHERE id = ? AND citizenid = ?', { data.horseid, Player.PlayerData.citizenid })
        end
    end
    for k, v in pairs(Config.HorseSettings) do
        if v.horsemodel == modelHorse then
            local sellprice = v.horseprice * 0.5
            Player.Functions.AddMoney('cash', sellprice)
            TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_success_horse_sold_for')..sellprice, type = 'success', duration = 5000 })
        end
    end
end)

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
-- Horse Customization
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

-- save saddle
RegisterNetEvent('rsg-horses:server:SaveComponent', function(component, horsedata, price)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    local horseid = horsedata.horseid
    if (Player.PlayerData.money.cash < price) then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_error_no_cash'), type = 'error', duration = 5000 })
        return
    end

    if component then
        MySQL.update('UPDATE player_horses SET components = ? WHERE citizenid = ? AND horseid = ?', {json.encode(component), citizenid, horseid})

        Player.Functions.RemoveMoney('cash', price)
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_success_component_saved') .. price, type = 'success', duration = 5000 })
    end
end)

RegisterNetEvent('rsg-horses:server:TradeHorse', function(playerId, horseId, source)
    local src = source
    local Player2 = RSGCore.Functions.GetPlayer(playerId)
    local Playercid2 = Player2.PlayerData.citizenid
    MySQL.update('UPDATE player_horses SET citizenid = ? WHERE horseid = ? AND active = ?', {Playercid2, horseId, 1})
    MySQL.update('UPDATE player_horses SET active = ? WHERE citizenid = ? AND active = ?', {0, Playercid2, 1})
    TriggerClientEvent('ox_lib:notify', playerId, {title = locale('sv_success_horse_owned'), type = 'success', duration = 5000 })
end)

-- generate horseid
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
-- end

-- horse attributes to database
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
    local data = { label = 'Horse Inventory', maxweight = invWeight, slots = invSlots }
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
        local horsename = result[i].name
        local ownercid = result[i].citizenid
        local currentTime = os.time()
        local timeDifference = currentTime - result[i].born
        local daysPassed = math.floor(timeDifference / (24 * 60 * 60))

        --print(id, horsename, ownercid, daysPassed)

        if daysPassed == Config.HorseDieAge then

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
