local RSGCore = exports['rsg-core']:GetCoreObject()

-----------------------------------------------------------------------
-- version checker
-----------------------------------------------------------------------
local function versionCheckPrint(_type, log)
    local color = _type == 'success' and '^2' or '^1'

    print(('^5['..GetCurrentResourceName()..']%s %s^7'):format(color, log))
end

local function CheckVersion()
    PerformHttpRequest('https://raw.githubusercontent.com/Rexshack-RedM/rsg-horses/main/version.txt', function(err, text, headers)
        local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version')

        if not text then 
            versionCheckPrint('error', 'Currently unable to run a version check.')
            return 
        end

        --versionCheckPrint('success', ('Current Version: %s'):format(currentVersion))
        --versionCheckPrint('success', ('Latest Version: %s'):format(text))
        
        if text == currentVersion then
            versionCheckPrint('success', 'You are running the latest version.')
        else
            versionCheckPrint('error', ('You are currently running an outdated version, please update to version %s'):format(text))
        end
    end)
end

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
    for k,v in pairs(Config.BoxZones) do
        for j,n in pairs(v) do
            if n.model == modelHorse then
                local sellprice = n.price * 0.5
                Player.Functions.AddMoney('cash', sellprice)
                TriggerClientEvent('RSGCore:Notify', src, Lang:t('success.horse_sold_for')..sellprice, 'success')
            end
        end
    end
end)

RSGCore.Functions.CreateCallback('rsg-horses:server:GetHorse', function(source, cb)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local GetHorse = {}
    local horses = MySQL.query.await('SELECT * FROM player_horses WHERE citizenid=@citizenid', { ['@citizenid'] = Player.PlayerData.citizenid })    
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

--------------------------------------------------------------------------------------------------
-- start version check
--------------------------------------------------------------------------------------------------
CheckVersion()