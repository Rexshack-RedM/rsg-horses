local RSGCore = exports['rsg-core']:GetCoreObject()

-----------------------------------------------------------------------

-- find horse command
RSGCore.Commands.Add("findhorse", "find where your horses are stored", {}, false, function(source)
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

-----------------------------------------------------------------------

-- player horselantern
RSGCore.Functions.CreateUseableItem("horselantern", function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    TriggerClientEvent("rsg-horses:client:equipHorseLantern", source, item.name)
end)

-- player horseholster
RSGCore.Functions.CreateUseableItem("horseholster", function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    TriggerClientEvent("rsg-horses:client:equipHorseHolster", source, item.name)
end)

-- feed horse carrot
RSGCore.Functions.CreateUseableItem("carrot", function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent("rsg-horses:client:playerfeedhorse", source, item.name)
    end
end)

 -- feed Stimulant cheval 
 RSGCore.Functions.CreateUseableItem("stimulantcheval", function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent("rsg-horses:client:playerfeedhorse", source, item.name)
    end
end)

 -- feed apple
 RSGCore.Functions.CreateUseableItem("apple", function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent("rsg-horses:client:playerfeedhorse", source, item.name)
    end
end)

-- feed horse sugarcube
RSGCore.Functions.CreateUseableItem("sugarcube", function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent("rsg-horses:client:playerfeedhorse", source, item.name)
    end
end)

-- brush horse
RSGCore.Functions.CreateUseableItem("horsebrush", function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    TriggerClientEvent("rsg-horses:client:playerbrushhorse", source, item.name)
end)

-- horse reviver
RSGCore.Functions.CreateUseableItem("horsereviver", function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    if not Player then return end

    local cid = Player.PlayerData.citizenid
    local result = MySQL.query.await('SELECT * FROM player_horses WHERE citizenid=@citizenid AND active=@active',
    {
        ['@citizenid'] = cid,
        ['@active'] = 1
    })

    if not result[1] then
        RSGCore.Functions.Notify(src, Lang:t('error.no_active_horse'), 'error', 3000)

        return
    end

    TriggerClientEvent("rsg-horses:client:revivehorse", src, item, result[1])
end)

RegisterServerEvent('rsg-horses:server:revivehorse', function(item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(source)

    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent("inventory:client:ItemBox", src, RSGCore.Shared.Items[item.name], "remove")
    end
end)

-------------------------------------------------------------------------------

RegisterServerEvent('rsg-horses:server:BuyHorse', function(price, model, stable, horsename, gender)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if (Player.PlayerData.money.cash < price) then
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.no_cash'), 'error')
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
    TriggerClientEvent('RSGCore:Notify', src, Lang:t('success.horse_owned'), 'success')
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
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.name_change_failed'), 'error')
        return
    end

    TriggerClientEvent('RSGCore:Notify', src, 'Horse name changed to \''..name..'\' successfully!', 'success')
end)

-- sell horse
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
            TriggerClientEvent('RSGCore:Notify', src, Lang:t('success.horse_sold_for')..sellprice, 'success')
        end
    end
end)

RSGCore.Functions.CreateCallback('rsg-horses:server:GetHorse', function(source, cb, stableid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local GetHorse = {}
    local horses = MySQL.query.await('SELECT * FROM player_horses WHERE citizenid=@citizenid AND stable=@stableid', { ['@citizenid'] = Player.PlayerData.citizenid, ['@stableid'] = stableid })    
    if horses[1] ~= nil then
        cb(horses)
    else
        cb(nil)
    end
end)

RSGCore.Functions.CreateCallback('rsg-horses:server:GetActiveHorse', function(source, cb)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local cid = Player.PlayerData.citizenid
    local result = MySQL.query.await('SELECT * FROM player_horses WHERE citizenid=@citizenid AND active=@active', { ['@citizenid'] = cid, ['@active'] = 1 })
    if (result[1] ~= nil) then
        cb(result[1])
    else
        return
    end
end)
------------------------------------- Horse Customization  -------------------------------------

-- get active horse components callback
RSGCore.Functions.CreateCallback('rsg-horses:server:CheckComponents', function(source, cb)
    local src = source
    local encodedSaddle = json.encode(SaddleDataEncoded)
    local Player = RSGCore.Functions.GetPlayer(src)
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
RegisterNetEvent("rsg-horses:server:SaveSaddles", function(SaddleDataEncoded)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local Playercid = Player.PlayerData.citizenid
    if SaddleDataEncoded ~= nil then
        MySQL.update('UPDATE player_horses SET saddle = ?  WHERE citizenid = ? AND active = ?', {SaddleDataEncoded ,  Player.PlayerData.citizenid, 1 })
    end
end)

RegisterNetEvent("rsg-horses:server:SaveBlankets", function(BlanketDataEncoded)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local Playercid = Player.PlayerData.citizenid
    if BlanketDataEncoded ~= nil then
        MySQL.update('UPDATE player_horses SET blanket = ?  WHERE citizenid = ? AND active = ? ' , {BlanketDataEncoded ,  Player.PlayerData.citizenid, 1 })
    end
end)

RegisterNetEvent("rsg-horses:server:SaveHorns", function(HornDataEncoded)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local Playercid = Player.PlayerData.citizenid
    if HornDataEncoded ~= nil then
        MySQL.update('UPDATE player_horses SET horn = ?  WHERE citizenid = ? AND active = ?', {HornDataEncoded ,  Player.PlayerData.citizenid, 1 })
    end
end)

RegisterNetEvent("rsg-horses:server:SaveSaddlebags", function(SaddlebagsDataEncoded)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local Playercid = Player.PlayerData.citizenid
    if SaddlebagsDataEncoded ~= nil then
        MySQL.update('UPDATE player_horses SET saddlebag = ?  WHERE citizenid = ? AND active = ?', {SaddlebagsDataEncoded ,  Player.PlayerData.citizenid, 1 })
    end
end)

RegisterNetEvent("rsg-horses:server:SaveBedrolls", function(BedrollDataEncoded)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local Playercid = Player.PlayerData.citizenid
    if BedrollDataEncoded ~= nil then
        MySQL.update('UPDATE player_horses SET bedroll = ?  WHERE citizenid = ? AND active = ?', {BedrollDataEncoded ,  Player.PlayerData.citizenid, 1 })
    end
end)

RegisterNetEvent("rsg-horses:server:SaveStirrups", function(StirrupDataEncoded)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local Playercid = Player.PlayerData.citizenid
    if StirrupDataEncoded ~= nil then
        MySQL.update('UPDATE player_horses SET stirrup = ?  WHERE citizenid = ? AND active = ? ' , {StirrupDataEncoded ,  Player.PlayerData.citizenid, 1 })
    end
end)

RegisterNetEvent("rsg-horses:server:SaveManes", function(ManeDataEncoded)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local Playercid = Player.PlayerData.citizenid
    if ManeDataEncoded ~= nil then
        MySQL.update('UPDATE player_horses SET mane = ?  WHERE citizenid = ? AND active = ?', {ManeDataEncoded ,  Player.PlayerData.citizenid, 1 })
    end
end)

RegisterNetEvent("rsg-horses:server:SaveTails", function(TailDataEncoded)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local Playercid = Player.PlayerData.citizenid
    if TailDataEncoded ~= nil then
        MySQL.update('UPDATE player_horses SET tail = ?  WHERE citizenid = ? AND active = ?', {TailDataEncoded ,  Player.PlayerData.citizenid, 1 })
    end
end)

RegisterNetEvent("rsg-horses:server:SaveMasks", function(MaskDataEncoded)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local Playercid = Player.PlayerData.citizenid
    if MaskDataEncoded ~= nil then
        MySQL.update('UPDATE player_horses SET mask = ?  WHERE citizenid = ? AND active = ?', {MaskDataEncoded ,  Player.PlayerData.citizenid, 1 })
    end
end)

RegisterNetEvent("rsg-horses:server:SaveMustaches", function(MaskDataEncoded)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local Playercid = Player.PlayerData.citizenid
    if MaskDataEncoded ~= nil then
        MySQL.update('UPDATE player_horses SET mustache = ?  WHERE citizenid = ? AND active = ?', {MaskDataEncoded ,  Player.PlayerData.citizenid, 1 })
    end
end)

RegisterNetEvent("rsg-horses:server:TradeHorse", function(playerId, horseId, source)
    local src = source
    local Player2 = RSGCore.Functions.GetPlayer(playerId)
    local Playercid2 = Player2.PlayerData.citizenid
    MySQL.update('UPDATE player_horses SET citizenid = ? WHERE horseid = ? AND active = ?', {Playercid2, horseId, 1})
    MySQL.update('UPDATE player_horses SET active = ? WHERE citizenid = ? AND active = ?', {0, Playercid2, 1})
    TriggerClientEvent('RSGCore:Notify', playerId, Lang:t('success.horse_owned'), 'success')
end)

-- generate horseid
function GenerateHorseid()
    local UniqueFound = false
    local horseid = nil
    while not UniqueFound do
        horseid = tostring(RSGCore.Shared.RandomStr(3) .. RSGCore.Shared.RandomInt(3)):upper()
        local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM player_horses WHERE horseid = ?", { horseid })
        if result == 0 then
            UniqueFound = true
        end
    end
    return horseid
end

-- Check if Player has horsebrush before brush the horse
RegisterServerEvent('rsg-horses:server:brushhorse', function(item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.Functions.GetItemByName(item) then
        TriggerClientEvent("rsg-horses:client:playerbrushhorse", source, item)
    else
        TriggerClientEvent('RSGCore:Notify', src, "You don't have "..item, 'error')
    end
end)
-- end

-- horse attributes to database
RegisterServerEvent('rsg-horses:server:sethorseAttributes', function(dirt)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local activehorse = MySQL.scalar.await('SELECT id FROM player_horses WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, true})
    MySQL.update('UPDATE player_horses SET dirt = ? WHERE id = ? AND citizenid = ?', { dirt, activehorse, Player.PlayerData.citizenid })
end)

--------------------------------------------------------------------------------------------------
-- horse check system
--------------------------------------------------------------------------------------------------
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
            TriggerEvent('rsg-log:server:CreateLog', 'horsetrainer', 'Horse Died', 'red', horsename..' belonging to '..ownercid..' died of old age!')

            -- telegram message to the horse owner
            MySQL.insert('INSERT INTO telegrams (citizenid, recipient, sender, sendername, subject, sentDate, message) VALUES (?, ?, ?, ?, ?, ?, ?)',
            {   ownercid,
                'Horse Owner',
                '22222222',
                'Horse Stables',
                horsename..' passed away',
                os.date("%x"),
                'I am sorry to inform you that your horse '..horsename..' has passed away, please visit your friendly horse trainer to discuss a replacement!',
            })

            goto continue
        end

    end

    ::continue::
    
    if Config.EnableServerNotify then
        print('horse check cycle complete')
    end

    SetTimeout(Config.CheckCycle * (60 * 1000), UpkeepInterval)
end

SetTimeout(Config.CheckCycle * (60 * 1000), UpkeepInterval)
