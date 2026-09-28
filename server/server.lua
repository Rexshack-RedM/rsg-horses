local RSGCore = exports['rsg-core']:GetCoreObject()
local HorseSettings = lib.load('shared.horse_settings')
local HorseComp = lib.load('shared.horse_comp')
lib.locale()

----------------------------------
-- lookups (built once)
----------------------------------
local HorsePrices = {}
for _, v in pairs(HorseSettings) do
    HorsePrices[v.horsemodel] = v.horseprice
end

local STARTER_MODEL = 'a_c_horse_mp_mangy_backup'
local STABLE_RADIUS = 20.0
local tradeRequests = {} -- [targetSrc] = { from, horseid, horseName, expires }
local xpCooldowns   = {} -- [horseid]   = os.time()
local playerBuckets = {} -- [src]       = bucket id while customizing

----------------------------------
-- helpers
----------------------------------
local function Notify(src, description, nType, title, duration)
    TriggerClientEvent('ox_lib:notify', src, {
        title = title,
        description = description,
        type = nType or 'inform',
        duration = duration or 5000,
    })
end

local function GetActiveHorse(citizenid)
    return MySQL.single.await('SELECT * FROM player_horses WHERE citizenid = ? AND active = 1 LIMIT 1', { citizenid })
end

local function GetOwnedHorse(citizenid, id)
    return MySQL.single.await('SELECT * FROM player_horses WHERE id = ? AND citizenid = ? LIMIT 1', { id, citizenid })
end

local function HorseStash(row)
    return row.name .. ' ' .. row.horseid
end

local function ClearHorseStash(stash)
    pcall(function() exports['rsg-inventory']:ClearInventory(stash) end)
    MySQL.update('DELETE FROM inventories WHERE identifier = ?', { stash })
end

local function IsNearCoords(src, coords, radius)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    return #(GetEntityCoords(ped) - vector3(coords.x, coords.y, coords.z)) <= radius
end

local function IsNearStable(src, stableid, radius)
    local stable = GetStableConfig(stableid)
    return stable ~= nil and IsNearCoords(src, stable.coords, radius or STABLE_RADIUS)
end

local function GetNearestStable(src, radius)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    local pos = GetEntityCoords(ped)
    local best, bestDist
    for _, v in pairs(Config.StableSettings) do
        local d = #(pos - v.coords)
        if not bestDist or d < bestDist then best, bestDist = v, d end
    end
    if best and (not radius or bestDist <= radius) then return best end
    return nil
end

local function SanitizeName(name, maxLen)
    if type(name) ~= 'string' then return nil end
    name = name:gsub('[^%w%s%-_]', ''):gsub('^%s+', ''):gsub('%s+$', '')
    if #name < 1 or #name > (maxLen or 50) then return nil end
    return name
end

local function IsInteger(v, min, max)
    return type(v) == 'number' and v == math.floor(v) and v >= min and v <= max
end

function GenerateHorseid()
    local horseid
    repeat
        horseid = (RSGCore.Shared.RandomStr(3) .. RSGCore.Shared.RandomInt(3)):upper()
    until MySQL.scalar.await('SELECT COUNT(*) FROM player_horses WHERE horseid = ?', { horseid }) == 0
    return horseid
end

--- asks the client whether it is beside its (alive / dead) horse before anything is consumed
local function CanInteractWithHorse(src, mode)
    local ok, result = pcall(lib.callback.await, 'rsg-horses:client:canInteract', src, mode)
    return ok and result == true
end

----------------------------------
-- validation
----------------------------------
local function ValidateComponents(components)
    if type(components) ~= 'table' then return false end
    for category, value in pairs(components) do
        if not HorseComp[category] or not IsInteger(value, 0, #HorseComp[category]) then
            return false
        end
    end
    return true
end

-- tint0 / mane / tail 0-254, tint1 / tint2 0-255
local function ValidateCoat(coat)
    if coat == nil then return true end
    if type(coat) ~= 'table' then return false end
    local t0 = tonumber(coat.tint0) or 0
    local checks = {
        { t0, 254 },
        { tonumber(coat.tint1) or 255, 255 },
        { tonumber(coat.tint2) or 255, 255 },
        { tonumber(coat.mane) or t0, 254 },
        { tonumber(coat.tail) or t0, 254 },
    }
    for _, c in ipairs(checks) do
        if c[1] < 0 or c[1] > c[2] then return false end
    end
    return true
end

----------------------------------
-- xp (server authoritative - only ever called from server code)
----------------------------------
local function AwardHorseXp(src, Player, action)
    local xpConfig = Config.HorseXp
    if not xpConfig then return end

    local amount = action == 'brush' and tonumber(xpConfig.Brush) or tonumber(xpConfig.Feed and xpConfig.Feed[action])
    if not amount or amount <= 0 then return end

    local horse = GetActiveHorse(Player.PlayerData.citizenid)
    if not horse then return end

    local maxXp = tonumber(xpConfig.MaxXp) or 2000
    local currentXp = tonumber(horse.horsexp) or 0
    if currentXp >= maxXp then
        return Notify(src, locale('sv_horse_xp_maxed'), 'inform')
    end

    local cooldown = tonumber(xpConfig.CooldownSeconds) or 0
    if cooldown > 0 then
        local remaining = cooldown - (os.time() - (xpCooldowns[horse.horseid] or 0))
        if remaining > 0 then
            return Notify(src, locale('sv_horse_xp_cooldown', remaining), 'warning')
        end
        xpCooldowns[horse.horseid] = os.time()
    end

    local newXp = math.min(currentXp + amount, maxXp)
    MySQL.update('UPDATE player_horses SET horsexp = ? WHERE id = ?', { newXp, horse.id })

    TriggerClientEvent('rsg-horses:client:horseXpUpdated', src, newXp)
    Notify(src, locale('sv_horse_xp_gain', amount, horse.name), 'success')
end

----------------------------------
-- trade accept (shared by command + event)
----------------------------------
local function AcceptTrade(src)
    local trade = tradeRequests[src]
    tradeRequests[src] = nil

    if not trade then
        return Notify(src, locale('sv_error_no_trade_request'), 'error')
    end
    if os.time() > trade.expires then
        return Notify(src, locale('sv_error_trade_expired'), 'error')
    end

    local Target = RSGCore.Functions.GetPlayer(src)
    local Sender = RSGCore.Functions.GetPlayer(trade.from)
    if not Target or not Sender then
        return Notify(src, locale('sv_error_horse_unavailable'), 'error')
    end

    -- atomic ownership transfer: only succeeds if the sender still owns the horse
    local affected = MySQL.update.await('UPDATE player_horses SET citizenid = ?, active = 0 WHERE horseid = ? AND citizenid = ?', {
        Target.PlayerData.citizenid, trade.horseid, Sender.PlayerData.citizenid
    })
    if affected ~= 1 then
        Notify(src, locale('sv_error_horse_unavailable'), 'error')
        Notify(trade.from, locale('sv_error_trade_failed'), 'error')
        return
    end

    TriggerClientEvent('rsg-horses:client:FleeHorse', trade.from)
    Notify(src, locale('sv_trade_received', trade.horseName), 'success', nil, 7000)
    Notify(trade.from, locale('sv_trade_success', GetPlayerName(src)), 'success', nil, 7000)

    SendDiscordLog('horses', 'Horse Traded', trade.horseName .. ' traded.', WebhookColors.info, {
        { name = 'From', value = Sender.PlayerData.citizenid, inline = true },
        { name = 'To', value = Target.PlayerData.citizenid, inline = true },
    }, src)
end

----------------------------------
-- commands
----------------------------------
RSGCore.Commands.Add('findhorse', locale('sv_command_find'), {}, false, function(source)
    TriggerClientEvent('rsg-horses:client:gethorselocation', source)
end)

RSGCore.Commands.Add('accepttrade', locale('sv_command_accept_trade'), {}, false, function(source)
    AcceptTrade(source)
end)

----------------------------------
-- useable items
----------------------------------
RSGCore.Functions.CreateUseableItem('horse_brush', function(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player or not CanInteractWithHorse(source, 'alive') then return end
    TriggerClientEvent('rsg-horses:client:playerbrushhorse', source)
    AwardHorseXp(source, Player, 'brush')
end)

RSGCore.Functions.CreateUseableItem('horse_lantern', function(source)
    TriggerClientEvent('rsg-horses:client:equipHorseLantern', source)
end)

RSGCore.Functions.CreateUseableItem('horse_holster', function(source)
    TriggerClientEvent('rsg-horses:client:equipHorseHolster', source)
end)

-- every key in Config.HorseFeed is a feed item. The item is only consumed once
-- the client confirms the horse is out, alive and within reach.
for itemName in pairs(Config.HorseFeed) do
    RSGCore.Functions.CreateUseableItem(itemName, function(source, item)
        local Player = RSGCore.Functions.GetPlayer(source)
        if not Player or not CanInteractWithHorse(source, 'alive') then return end
        if not Player.Functions.RemoveItem(item.name, 1, item.slot) then return end
        TriggerClientEvent('rsg-inventory:client:ItemBox', source, RSGCore.Shared.Items[item.name], 'remove', 1)
        TriggerClientEvent('rsg-horses:client:playerfeedhorse', source, item.name)
        AwardHorseXp(source, Player, item.name)
    end)
end

RSGCore.Functions.CreateUseableItem('horse_reviver', function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end

    local horse = GetActiveHorse(Player.PlayerData.citizenid)
    if not horse then
        return Notify(source, locale('sv_error_no_active_horse'), 'error')
    end
    -- only consume the reviver when the horse is actually down and the player is beside it
    if not CanInteractWithHorse(source, 'dead') then return end
    if not Player.Functions.RemoveItem(item.name, 1, item.slot) then return end

    TriggerClientEvent('rsg-inventory:client:ItemBox', source, RSGCore.Shared.Items[item.name], 'remove', 1)
    TriggerClientEvent('rsg-horses:client:revivehorse', source)
    SendDiscordLog('horses', 'Horse Revived', 'Player revived ' .. horse.name .. '.', WebhookColors.info, nil, source)
end)

----------------------------------
-- buy horse
----------------------------------
RegisterNetEvent('rsg-horses:server:BuyHorse', function(model, stableid, horsename, gender)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local price = HorsePrices[model]
    if not price then return end

    if not IsNearStable(src, stableid) then
        return Notify(src, locale('sv_error_invalid_stable'), 'error')
    end
    if gender ~= 'male' and gender ~= 'female' then gender = 'male' end

    horsename = SanitizeName(horsename, 50)
    if not horsename then
        return Notify(src, locale('sv_error_horse_name_length'), 'error')
    end

    if not Player.Functions.RemoveMoney('cash', price, 'horse-purchase') then
        return Notify(src, locale('sv_error_no_cash'), 'error')
    end

    MySQL.insert.await('INSERT INTO player_horses (stable, citizenid, horseid, name, horse, gender, active, born, age_seconds) VALUES (?, ?, ?, ?, ?, ?, 0, ?, ?)', {
        stableid, Player.PlayerData.citizenid, GenerateHorseid(), horsename, model, gender, os.time(),
        (Config.Growth.growthMinutesToAdult or 120) * 60
    })

    Notify(src, locale('sv_success_horse_owned'), 'success')
    SendDiscordLog('economy', 'Horse Purchased', horsename .. ' (' .. model .. ')', WebhookColors.success, {
        { name = 'Price', value = '$' .. price, inline = true },
        { name = 'Stable', value = stableid, inline = true },
    }, src)
end)

----------------------------------
-- horse holster (weapon storage)
----------------------------------
RegisterNetEvent('rsg-horses:server:storeHorseWeapon', function(weaponHash)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    -- the item name comes from the server-side map, never from the client
    local weaponName = Config.HolsterWeapons[weaponHash]
    if not weaponName then return end

    local horse = GetActiveHorse(Player.PlayerData.citizenid)
    if not horse then
        return Notify(src, locale('sv_error_no_active_horse'), 'error')
    end
    if horse.stored_weapon_name then
        return Notify(src, locale('sv_error_weapon_already_stored'), 'error')
    end

    local item = Player.Functions.GetItemByName(weaponName)
    if not item then
        return Notify(src, locale('cl_holster_error_no_weapon_data'), 'error')
    end
    if not Player.Functions.RemoveItem(item.name, 1, item.slot, 'horse-holster-store') then return end

    -- serial / info are copied from the real inventory item, not from the client
    local affected = MySQL.update.await('UPDATE player_horses SET stored_weapon = ?, stored_weapon_name = ?, stored_weapon_data = ? WHERE id = ? AND stored_weapon_name IS NULL', {
        weaponHash, item.name, json.encode({ info = item.info or {} }), horse.id
    })
    if affected ~= 1 then
        Player.Functions.AddItem(item.name, 1, nil, item.info, 'horse-holster-refund')
        return
    end

    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item.name], 'remove', 1)
    TriggerClientEvent('rsg-horses:client:weaponStored', src, weaponHash)
    SendDiscordLog('economy', 'Weapon Stored on Horse', item.name, WebhookColors.success, nil, src)
end)

RegisterNetEvent('rsg-horses:server:retrieveHorseWeapon', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local horse = GetActiveHorse(Player.PlayerData.citizenid)
    if not horse or not horse.stored_weapon_name then
        return Notify(src, locale('cl_holster_error_no_weapon_stored'), 'error')
    end

    if not exports['rsg-inventory']:CanAddItem(src, horse.stored_weapon_name, 1) then
        return Notify(src, locale('sv_error_inventory_full'), 'error')
    end

    -- claim the weapon atomically so parallel requests can't duplicate it
    local affected = MySQL.update.await('UPDATE player_horses SET stored_weapon = NULL, stored_weapon_name = NULL, stored_weapon_data = NULL WHERE id = ? AND stored_weapon_name = ?', {
        horse.id, horse.stored_weapon_name
    })
    if affected ~= 1 then return end

    local ok, data = pcall(json.decode, horse.stored_weapon_data or '{}')
    local info = (ok and type(data) == 'table' and data.info) or {}

    Player.Functions.AddItem(horse.stored_weapon_name, 1, nil, info, 'horse-holster-retrieve')
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[horse.stored_weapon_name], 'add', 1)
    TriggerClientEvent('rsg-horses:client:weaponRetrieved', src)
    SendDiscordLog('economy', 'Weapon Retrieved from Horse', horse.stored_weapon_name, WebhookColors.success, nil, src)
end)

lib.callback.register('rsg-horses:server:getHorseWeapon', function(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return nil end
    return MySQL.scalar.await('SELECT stored_weapon FROM player_horses WHERE citizenid = ? AND active = 1 LIMIT 1', { Player.PlayerData.citizenid })
end)

----------------------------------
-- active / store / flee
----------------------------------
RegisterNetEvent('rsg-horses:server:SetHoresActive', function(id)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid

    if not GetOwnedHorse(cid, id) then
        return Notify(src, locale('sv_error_not_own_horse'), 'error')
    end
    MySQL.update.await('UPDATE player_horses SET active = (id = ?) WHERE citizenid = ?', { id, cid })
    TriggerClientEvent('rsg-horses:client:horseActivated', src, id)
    Notify(src, locale('cl_success_horse_active'), 'success', nil, 7000)
end)

RegisterNetEvent('rsg-horses:server:SetHoresUnActive', function(stableid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    if not IsNearStable(src, stableid) then
        return Notify(src, locale('sv_error_invalid_stable'), 'error')
    end
    MySQL.update('UPDATE player_horses SET active = 0, stable = ? WHERE citizenid = ? AND active = 1', { stableid, Player.PlayerData.citizenid })
end)

-- flee-store sends the horse to the stable nearest the player (the server decides which)
RegisterNetEvent('rsg-horses:server:fleeStoreHorse', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or not Config.StoreFleedHorse then return end
    local stable = GetNearestStable(src)
    if not stable then return end
    MySQL.update('UPDATE player_horses SET active = 0, stable = ? WHERE citizenid = ? AND active = 1', { stable.stableid, Player.PlayerData.citizenid })
end)

----------------------------------
-- rename
----------------------------------
RegisterNetEvent('rsg-horses:renameHorse', function(name)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    name = SanitizeName(name, 50)
    if not name then
        return Notify(src, locale('sv_error_horse_name_length'), 'error')
    end

    local horse = GetActiveHorse(Player.PlayerData.citizenid)
    if not horse then
        return Notify(src, locale('sv_error_no_active_horse'), 'error')
    end

    MySQL.update.await('UPDATE player_horses SET name = ? WHERE id = ?', { name, horse.id })
    -- the saddlebag stash is keyed on name + horseid: move the contents to the new key
    MySQL.update('UPDATE inventories SET identifier = ? WHERE identifier = ?', { name .. ' ' .. horse.horseid, HorseStash(horse) })

    Notify(src, locale('sv_success_name_changed', name), 'success')
end)

----------------------------------
-- death
----------------------------------
RegisterNetEvent('rsg-horses:server:HorseDied', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local horse = GetActiveHorse(Player.PlayerData.citizenid)
    if not horse then return end

    ClearHorseStash(HorseStash(horse))
    MySQL.update('DELETE FROM player_horses WHERE id = ?', { horse.id })
    TriggerEvent('rsg-log:server:CreateLog', 'horsetrainer', locale('sv_log_horse_trainer'), 'red', horse.name .. ' ' .. locale('sv_log_horse_belong') .. ' ' .. horse.citizenid)

    Notify(src, locale('sv_error_horse_died'), 'error', nil, 7000)
    SendDiscordLog('horses', 'Horse Died', horse.name .. ' has died.', WebhookColors.danger, {
        { name = 'Horse ID', value = horse.horseid, inline = true },
    }, src)
end)

----------------------------------
-- sell
----------------------------------
RegisterNetEvent('rsg-horses:server:deletehorse', function(id)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid

    local horse = GetOwnedHorse(cid, id)
    if not horse then
        return Notify(src, locale('sv_error_not_own_horse'), 'error')
    end
    if not IsNearStable(src, horse.stable) then
        return Notify(src, locale('sv_error_invalid_stable'), 'error')
    end
    if horse.stored_weapon_name then
        return Notify(src, locale('sv_error_weapon_stored_sell'), 'error')
    end

    -- delete first and only pay if THIS request removed the row (blocks double-sell races)
    local affected = MySQL.update.await('DELETE FROM player_horses WHERE id = ? AND citizenid = ?', { horse.id, cid })
    if affected ~= 1 then return end

    ClearHorseStash(HorseStash(horse))
    if horse.active == 1 then
        TriggerClientEvent('rsg-horses:client:FleeHorse', src)
    end

    local sellprice = math.floor((HorsePrices[horse.horse] or 0) * (Config.SellPriceMultiplier or 0.5))
    if sellprice > 0 then
        Player.Functions.AddMoney('cash', sellprice, 'horse-sold')
    end
    Notify(src, locale('sv_success_horse_sold', sellprice), 'success')

    SendDiscordLog('economy', 'Horse Sold', horse.name .. ' (' .. horse.horse .. ')', WebhookColors.success, {
        { name = 'Sell Price', value = '$' .. sellprice, inline = true },
    }, src)
end)

----------------------------------
-- data callbacks
----------------------------------
lib.callback.register('rsg-horses:server:GetHorse', function(source, stableid)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player or type(stableid) ~= 'string' then return {} end
    return MySQL.query.await('SELECT * FROM player_horses WHERE citizenid = ? AND stable = ?', { Player.PlayerData.citizenid, stableid }) or {}
end)

lib.callback.register('rsg-horses:server:GetActiveHorse', function(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return nil end
    return GetActiveHorse(Player.PlayerData.citizenid)
end)

lib.callback.register('rsg-horses:server:GetAllHorses', function(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return {} end
    return MySQL.query.await('SELECT name, stable, active FROM player_horses WHERE citizenid = ?', { Player.PlayerData.citizenid }) or {}
end)

lib.callback.register('rsg-horses:server:GetPlayerHorses', function(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return {} end
    return MySQL.query.await('SELECT id, name, horse, gender, age_seconds, pregnant_until FROM player_horses WHERE citizenid = ?', { Player.PlayerData.citizenid }) or {}
end)

----------------------------------
-- customization
----------------------------------
RegisterNetEvent('rsg-horses:server:SaveComponents', function(newComponents, horseid, newCoat)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    newComponents = newComponents or {}
    if not ValidateComponents(newComponents) or not ValidateCoat(newCoat) then
        return Notify(src, locale('sv_error_invalid_components'), 'error')
    end
    if not GetNearestStable(src, 40.0) then return end

    local horse = MySQL.single.await('SELECT * FROM player_horses WHERE citizenid = ? AND horseid = ? LIMIT 1', { Player.PlayerData.citizenid, horseid })
    if not horse then
        return Notify(src, locale('sv_error_not_own_horse'), 'error')
    end

    local okC, currentComponents = pcall(json.decode, horse.components or '{}')
    local okCoat, currentCoat = pcall(json.decode, horse.coat or 'null')
    local price = CalculatePrice(newComponents, okC and type(currentComponents) == 'table' and currentComponents or {})
        + CalculateCoatPrice(newCoat, okCoat and type(currentCoat) == 'table' and currentCoat or nil)

    if price > 0 and not Player.Functions.RemoveMoney('cash', price, 'horse-customization') then
        return Notify(src, locale('sv_error_no_cash'), 'error')
    end

    local coatJson = horse.coat
    if newCoat then
        local t0 = math.floor(tonumber(newCoat.tint0) or 0)
        coatJson = json.encode({
            tint0 = t0,
            tint1 = math.floor(tonumber(newCoat.tint1) or 255),
            tint2 = math.floor(tonumber(newCoat.tint2) or 255),
            mane = math.floor(tonumber(newCoat.mane) or t0),
            tail = math.floor(tonumber(newCoat.tail) or t0),
            palette = Config.Coat.Palette, -- never persist a client-supplied palette string
            rainbow = newCoat.rainbow == true,
        })
    end
    MySQL.update('UPDATE player_horses SET components = ?, coat = ? WHERE id = ?', { json.encode(newComponents), coatJson, horse.id })

    Notify(src, locale('sv_success_customization_saved', price), 'success')
    SendDiscordLog('horses', 'Horse Customization Saved', horse.name, WebhookColors.info, {
        { name = 'Price Paid', value = '$' .. price, inline = true },
    }, src)
end)

----------------------------------
-- trade
----------------------------------
RegisterNetEvent('rsg-horses:server:TradeHorse', function(targetId)
    local src = source
    targetId = tonumber(targetId)
    if not targetId or targetId == src then return end

    local Player = RSGCore.Functions.GetPlayer(src)
    local Target = RSGCore.Functions.GetPlayer(targetId)
    if not Player then return end
    if not Target then
        return Notify(src, locale('cl_error_no_nearby_player'), 'error')
    end

    local horse = GetActiveHorse(Player.PlayerData.citizenid)
    if not horse then
        return Notify(src, locale('sv_error_not_own_or_active'), 'error')
    end

    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(targetId))) > 5.0 then
        return Notify(src, locale('sv_error_player_too_far'), 'error')
    end

    tradeRequests[targetId] = {
        from = src,
        horseid = horse.horseid,
        horseName = horse.name,
        expires = os.time() + 30,
    }

    Notify(targetId, locale('sv_trade_request_desc', GetPlayerName(src), horse.name), 'inform', locale('sv_trade_request_title'), 30000)
    Notify(src, locale('sv_trade_request_sent', GetPlayerName(targetId)), 'success')
end)

RegisterNetEvent('rsg-horses:server:AcceptTrade', function()
    AcceptTrade(source)
end)

----------------------------------
-- move between stables
----------------------------------
RegisterNetEvent('rsg-horses:server:MoveHorse', function(id, newStableId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local horse = GetOwnedHorse(Player.PlayerData.citizenid, id)
    if not horse then
        return Notify(src, locale('sv_error_not_own_horse'), 'error')
    end

    local currentStable = GetStableConfig(horse.stable)
    local newStable = GetStableConfig(newStableId)
    if not currentStable or not newStable then
        return Notify(src, locale('sv_error_invalid_stable'), 'error')
    end
    if horse.stable == newStableId then
        return Notify(src, locale('sv_error_horse_already_there'), 'error')
    end
    if not IsNearCoords(src, currentStable.coords, STABLE_RADIUS) then
        return Notify(src, locale('sv_error_invalid_stable'), 'error')
    end

    local moveFee = CalculateHorseMovePrice(currentStable.coords, newStable.coords)
    if not Player.Functions.RemoveMoney('cash', moveFee, 'horse-move') then
        return Notify(src, locale('sv_error_move_cost', moveFee), 'error', locale('sv_error_insufficient_funds'))
    end

    MySQL.update('UPDATE player_horses SET stable = ? WHERE id = ?', { newStableId, horse.id })
    Notify(src, locale('sv_success_horse_moved_desc', horse.name, newStableId, moveFee), 'success', locale('sv_success_horse_moved'))

    SendDiscordLog('horses', 'Horse Moved Between Stables', horse.name, WebhookColors.info, {
        { name = 'From', value = horse.stable, inline = true },
        { name = 'To', value = newStableId, inline = true },
        { name = 'Fee', value = '$' .. moveFee, inline = true },
    }, src)
end)

----------------------------------
-- horse attributes (dirt)
----------------------------------
RegisterNetEvent('rsg-horses:server:sethorseAttributes', function(dirt)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    dirt = tonumber(dirt)
    if not dirt or dirt < 0 or dirt > 100 then return end
    MySQL.update('UPDATE player_horses SET dirt = ? WHERE citizenid = ? AND active = 1', { math.floor(dirt), Player.PlayerData.citizenid })
end)

----------------------------------
-- routing bucket while customizing (own player only, only at a stable)
----------------------------------
RegisterNetEvent('rsg-horses:server:SetPlayerBucket', function(enable)
    local src = source
    if not RSGCore.Functions.GetPlayer(src) then return end

    if enable then
        if playerBuckets[src] or not GetNearestStable(src, 40.0) then return end
        local bucket = 10000 + src
        SetRoutingBucketPopulationEnabled(bucket, false)
        SetPlayerRoutingBucket(src, bucket)
        playerBuckets[src] = bucket
    elseif playerBuckets[src] then
        SetPlayerRoutingBucket(src, 0)
        playerBuckets[src] = nil
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    playerBuckets[src] = nil
    tradeRequests[src] = nil
    for target, trade in pairs(tradeRequests) do
        if trade.from == src then tradeRequests[target] = nil end
    end
end)

----------------------------------
-- saddlebag inventory
----------------------------------
RegisterNetEvent('rsg-horses:server:openhorseinventory', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local horse = GetActiveHorse(Player.PlayerData.citizenid)
    if not horse then
        return Notify(src, locale('sv_error_no_active_horse'), 'error')
    end

    local weight, slots = GetHorseInventorySize(horse.horsexp)
    exports['rsg-inventory']:OpenInventory(src, HorseStash(horse), { label = locale('sv_horse_inventory'), maxweight = weight, slots = slots })
end)

----------------------------------
-- shop
----------------------------------
CreateThread(function()
    exports['rsg-inventory']:CreateShop({
        name = 'horse',
        label = locale('cl_horse_shop'),
        slots = #Config.horsesShopItems,
        items = Config.horsesShopItems,
        persistentStock = Config.PersistStock,
    })
end)

RegisterNetEvent('rsg-horses:server:openShop', function()
    local src = source
    if not RSGCore.Functions.GetPlayer(src) or not GetNearestStable(src, 10.0) then return end
    exports['rsg-inventory']:OpenShop(src, 'horse')
end)

----------------------------------
-- upkeep (old age)
----------------------------------
local function ExpireHorse(row, daysPassed)
    ClearHorseStash(HorseStash(row))
    MySQL.update('DELETE FROM player_horses WHERE id = ?', { row.id })

    TriggerEvent('rsg-log:server:CreateLog', 'horsetrainer', locale('sv_log_horse_trainer'), 'red', row.name .. ' ' .. locale('sv_log_horse_belong') .. ' ' .. row.citizenid .. ' ' .. locale('sv_log_horse_dead'))
    SendDiscordLog('horses', 'Horse Expired (Upkeep)', row.name .. ' aged out.', WebhookColors.warning, {
        { name = 'Owner', value = row.citizenid, inline = true },
        { name = 'Days', value = tostring(daysPassed), inline = true },
    })

    MySQL.insert('INSERT INTO telegrams (citizenid, recipient, sender, sendername, subject, sentDate, message) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        row.citizenid,
        locale('sv_telegram_owner'),
        '22222222',
        locale('sv_telegram_stables'),
        row.name .. ' ' .. locale('sv_telegram_away'),
        os.date('%x'),
        locale('sv_telegram_inform') .. ' ' .. row.name .. ' ' .. locale('sv_telegram_has_passed'),
    })
end

local function UpkeepInterval()
    local now = os.time()
    local day = 24 * 60 * 60
    -- only fetch horses that are actually due instead of the whole table
    local due = MySQL.query.await('SELECT id, horseid, name, citizenid, born FROM player_horses WHERE born <= ? OR (horse = ? AND born <= ?)', {
        now - Config.HorseDieAge * day, STARTER_MODEL, now - Config.StarterHorseDieAge * day
    }) or {}

    for i = 1, #due do
        ExpireHorse(due[i], math.floor((now - due[i].born) / day))
    end

    if Config.EnableServerNotify then print(locale('sv_print')) end
    SetTimeout(Config.CheckCycle * 60000, UpkeepInterval)
end

SetTimeout(Config.CheckCycle * 60000, UpkeepInterval)

----------------------------------
-- breeding
----------------------------------
CreateThread(function()
    -- make sure breeding columns exist for servers that skipped migration.sql
    local existing = {}
    for _, col in ipairs(MySQL.query.await('SHOW COLUMNS FROM player_horses') or {}) do
        existing[col.Field] = true
    end
    if not existing.age_seconds then MySQL.query.await('ALTER TABLE player_horses ADD COLUMN `age_seconds` INT(11) NOT NULL DEFAULT 0') end
    if not existing.pregnant_until then MySQL.query.await('ALTER TABLE player_horses ADD COLUMN `pregnant_until` INT(11) DEFAULT NULL') end
    if not existing.last_bred then MySQL.query.await('ALTER TABLE player_horses ADD COLUMN `last_bred` INT(11) DEFAULT NULL') end
end)

local FOAL_PREFIX = { 'Little', 'Tiny', 'Baby', 'Sweet', 'Lucky', 'Happy', 'Sunny', 'Storm', 'Shadow', 'Star', 'Dusty', 'Buddy' }
local FOAL_SUFFIX = { 'Star', 'Storm', 'Wind', 'Heart', 'Spirit', 'Dream', 'Bolt', 'Flash', 'Cloud', 'Moon', 'Fire', 'Rose' }

RegisterNetEvent('rsg-horses:server:breedHorse', function(mareId, stallionId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local cfg = Config.Breeding

    if not cfg or not cfg.enabled then
        return Notify(src, locale('sv_error_breeding_disabled'), 'error')
    end
    if cfg.requiredJob and Player.PlayerData.job.name ~= cfg.requiredJob then
        return Notify(src, locale('err_breeder_required'), 'error')
    end
    if mareId == stallionId then
        return Notify(src, locale('sv_error_breed_select_mare'), 'error')
    end

    local cid = Player.PlayerData.citizenid
    local mare = GetOwnedHorse(cid, mareId)
    local stallion = GetOwnedHorse(cid, stallionId)
    if not mare then return Notify(src, locale('sv_error_not_own_horse'), 'error') end
    if not stallion then return Notify(src, locale('sv_error_not_own_stallion'), 'error') end

    if cfg.requireOppositeSex then
        if mare.gender ~= 'female' then return Notify(src, locale('sv_error_breed_select_mare'), 'error') end
        if stallion.gender ~= 'male' then return Notify(src, locale('sv_error_breed_must_be_male'), 'error') end
    end

    local now = os.time()
    local maturitySecs = (cfg.maturityMinutes or 60) * 60
    if (mare.age_seconds or 0) < maturitySecs then
        return Notify(src, locale('sv_error_mare_not_mature', math.ceil((maturitySecs - (mare.age_seconds or 0)) / 60)), 'error')
    end
    if (stallion.age_seconds or 0) < maturitySecs then
        return Notify(src, locale('sv_error_stallion_not_mature'), 'error')
    end
    if mare.pregnant_until and mare.pregnant_until > now then
        return Notify(src, locale('sv_error_already_pregnant', math.ceil((mare.pregnant_until - now) / 60)), 'error')
    end
    local cooldownSecs = (cfg.breedCooldownMinutes or 60) * 60
    if mare.last_bred and (now - mare.last_bred) < cooldownSecs then
        return Notify(src, locale('sv_error_breeding_cooldown', math.ceil((cooldownSecs - (now - mare.last_bred)) / 60)), 'error')
    end

    local hayCost = cfg.hayCost or 0
    if hayCost > 0 then
        if not Player.Functions.RemoveItem('hay', hayCost, nil, 'horse-breeding') then
            return Notify(src, locale('sv_error_need_hay', hayCost), 'error')
        end
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items['hay'], 'remove', hayCost)
    end

    local gestation = cfg.gestationMinutes or 30
    MySQL.update.await('UPDATE player_horses SET pregnant_until = ?, last_bred = ? WHERE id = ?', { now + gestation * 60, now, mare.id })
    Notify(src, locale('sv_success_breeding_started', gestation), 'success', nil, 7000)
end)

-- ageing + births
CreateThread(function()
    local adultSecs = math.max(Config.Growth.growthMinutesToAdult or 120, Config.Breeding.maturityMinutes or 60) * 60
    while true do
        Wait(30000)
        local now = os.time()

        -- only horses that are still growing need the update
        MySQL.update('UPDATE player_horses SET age_seconds = age_seconds + 30 WHERE age_seconds < ?', { adultSecs })

        local mothers = MySQL.query.await('SELECT id, citizenid, stable FROM player_horses WHERE pregnant_until IS NOT NULL AND pregnant_until <= ?', { now }) or {}
        for _, mother in ipairs(mothers) do
            local models = Config.HorseModels
            local foalModel = models[math.random(#models)]
            local foalGender = math.random(2) == 1 and 'male' or 'female'
            local foalName = FOAL_PREFIX[math.random(#FOAL_PREFIX)] .. ' ' .. FOAL_SUFFIX[math.random(#FOAL_SUFFIX)]
            local foalStable = mother.stable or 'valentine'

            MySQL.update.await('UPDATE player_horses SET pregnant_until = NULL WHERE id = ?', { mother.id })
            MySQL.insert.await('INSERT INTO player_horses (stable, citizenid, horseid, name, horse, gender, active, born, age_seconds) VALUES (?, ?, ?, ?, ?, ?, 0, ?, 0)', {
                foalStable, mother.citizenid, GenerateHorseid(), foalName, foalModel, foalGender, now
            })

            local owner = RSGCore.Functions.GetPlayerByCitizenId(mother.citizenid)
            if owner then
                Notify(owner.PlayerData.source, locale('sv_success_foal_born_desc', foalGender, foalModel, foalName, foalStable), 'success', locale('sv_success_foal_born_title'), 10000)
            end
        end
    end
end)
