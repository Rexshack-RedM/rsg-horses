local RSGCore = exports['rsg-core']:GetCoreObject()

-------------------------------------------------------------------------------

-- player horselantern
RSGCore.Functions.CreateUseableItem("horselantern", function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    TriggerClientEvent("rsg-horses:client:equipHorseLantern", source, item.name)
end)

-- feed horse carrot
RSGCore.Functions.CreateUseableItem("carrot", function(source, item)
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

-------------------------------------------------------------------------------

RegisterServerEvent('rsg-horses:server:BuyHorse', function(price, model, horsename, gender)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if (Player.PlayerData.money.cash < price) then
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.no_cash'), 'error')
        return
    end
    local horseid = GenerateHorseid()
    MySQL.insert('INSERT INTO player_horses(citizenid, horseid, name, horse, gender, active) VALUES(@citizenid, @horseid, @name, @horse, @gender, @active)', {
        ['@citizenid'] = Player.PlayerData.citizenid,
        ['@horseid'] = horseid,
        ['@name'] = horsename,
        ['@horse'] = model,
        ['@gender'] = gender,
        ['@active'] = false,
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

RegisterServerEvent('rsg-horses:server:SetHoresUnActive', function(id)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local activehorse = MySQL.scalar.await('SELECT id FROM player_horses WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, false})
    MySQL.update('UPDATE player_horses SET active = ? WHERE id = ? AND citizenid = ?', { false, activehorse, Player.PlayerData.citizenid })
    MySQL.update('UPDATE player_horses SET active = ? WHERE id = ? AND citizenid = ?', { false, id, Player.PlayerData.citizenid })
end)

RegisterServerEvent('rsg-horses:server:DelHores', function(id)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local modelHorse = nil
    local player_horses = MySQL.query.await('SELECT * FROM player_horses WHERE id = @id AND `citizenid` = @citizenid', {
        ['@id'] = id,
        ['@citizenid'] = Player.PlayerData.citizenid
    })
    for i = 1, #player_horses do
        if tonumber(player_horses[i].id) == tonumber(id) then
            modelHorse = player_horses[i].horse
            MySQL.update('DELETE FROM player_horses WHERE id = ? AND citizenid = ?', { id, Player.PlayerData.citizenid })
        end
    end
    for k,v in pairs(Config.BoxZones) do
        for j,n in pairs(v) do
            if n.model == modelHorse then
                Player.Functions.AddMoney('cash', n.price * 0.5)
            end
        end
    end
end)

RSGCore.Functions.CreateCallback('rsg-horses:server:GetHorse', function(source, cb,comps)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local GetHorse = {}
    local horses = MySQL.query.await('SELECT * FROM player_horses WHERE citizenid=@citizenid', {
        ['@citizenid'] = Player.PlayerData.citizenid,
    })    
    if horses[1] ~= nil then
        cb(horses)
    end
end)

RSGCore.Functions.CreateCallback('rsg-horses:server:GetActiveHorse', function(source, cb)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local cid = Player.PlayerData.citizenid
    local result = MySQL.query.await('SELECT * FROM player_horses WHERE citizenid=@citizenid AND active=@active', {
        ['@citizenid'] = cid,
        ['@active'] = 1
    })
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

RegisterNetEvent("rsg-horses:server:TradeHorse", function(playerId, horseId, source, cb)
    print("server")
    local src = source
    local Player2 = RSGCore.Functions.GetPlayer(playerId)
    local Playercid2 = Player2.PlayerData.citizenid
    local result = MySQL.update('UPDATE player_horses SET citizenid = ?  WHERE citizenid = ? AND active = ?', {Playercid2, horseId, 1})
    MySQL.update('UPDATE player_horses SET active = ?  WHERE citizenid = ? AND active = ?', {0, Playercid2, 1})
    if (result[1] ~= nil) then
        cb(result[1])
    else
        return
    end
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