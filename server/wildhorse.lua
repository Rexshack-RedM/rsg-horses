-- Wild horse selling / stabling (merged from rsg-wildhorse).
-- The client only sends the network id of the horse it is riding. Everything
-- else (model, reward, validity, deletion) is decided and done by the server.
local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

local WH = Config.WildHorse
local SELL_RADIUS  = 10.0 -- player must be this close to a wild horse seller
local HORSE_RADIUS = 6.0  -- and the horse this close to the player
-- a sale/stable can never happen faster than the appraisal takes, even with EnableCooldown off
local MIN_COOLDOWN = math.ceil((tonumber(WH.SellTime) or 5000) / 1000)

local rewardsByModel = {}
for _, cfg in pairs(WH.Horse or {}) do
    rewardsByModel[cfg.model] = cfg
end

local lastAction = {} -- [citizenid] = os.time()

local function Notify(src, key, nType, ...)
    TriggerClientEvent('ox_lib:notify', src, { title = locale('wh_title'), description = locale(key, ...), type = nType, duration = 5000 })
end

local function IsNearSeller(coords)
    for _, loc in pairs(WH.SellWildHorseLocations or {}) do
        if #(coords - loc.coords) <= SELL_RADIUS then return true end
    end
    return false
end

local function CooldownRemaining(citizenid)
    local cd = WH.EnableCooldown and math.max(tonumber(WH.Cooldown) or 0, MIN_COOLDOWN) or MIN_COOLDOWN
    return cd - (os.time() - (lastAction[citizenid] or 0))
end

--- resolves + validates the horse entity the client claims to be on
local function ResolveWildHorse(src, netId)
    if type(netId) ~= 'number' then return nil end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 or not DoesEntityExist(entity) or GetEntityType(entity) ~= 1 then return nil end
    -- never allow a player-owned stable horse to be sold/stabled
    if Entity(entity).state.rsgHorseOwner then return nil end

    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    if not IsNearSeller(playerCoords) then return nil end
    if #(playerCoords - GetEntityCoords(entity)) > HORSE_RADIUS then return nil end
    return entity
end

local function Security(src, title, reason)
    SendDiscordLog('security', title, reason, WebhookColors.warning, nil, src)
end

-----------------------------------
-- sell
-----------------------------------
RegisterNetEvent('rsg-sellwildhorse:server:reward', function(netId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid

    local remaining = CooldownRemaining(citizenid)
    if remaining > 0 then
        return Security(src, 'Wild Horse Sell Cooldown Hit', remaining .. 's remaining')
    end

    local entity = ResolveWildHorse(src, netId)
    if not entity then
        Notify(src, 'wh_error_no_horse_sell', 'error')
        return Security(src, 'Wild Horse Sell Rejected', 'invalid entity / location / distance')
    end

    local cfg = rewardsByModel[GetEntityModel(entity)]
    if not cfg then
        return Notify(src, 'wh_error_invalid_model', 'error')
    end

    lastAction[citizenid] = os.time()
    DeleteEntity(entity)

    local reward = math.floor((tonumber(cfg.rewardmoney) or 0) * (tonumber(WH.SaleMultiplier) or 1))
    if reward > 0 then
        Player.Functions.AddMoney(WH.PaymentType, reward, 'wild-horse-sold')
    end
    if cfg.rewarditem and RSGCore.Shared.Items[cfg.rewarditem] and exports['rsg-inventory']:CanAddItem(src, cfg.rewarditem, 1) then
        Player.Functions.AddItem(cfg.rewarditem, 1, nil, nil, 'wild-horse-sold')
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[cfg.rewarditem], 'add', 1)
    end

    Notify(src, 'wh_success_sold', 'success', reward)
    SendDiscordLog('economy', 'Wild Horse Sold', cfg.name or 'wild horse', WebhookColors.success, {
        { name = 'Reward', value = '$' .. reward, inline = true },
    }, src)
end)

-----------------------------------
-- stable (tamed wild horse -> player_horses)
-----------------------------------
-- every model that may be stabled from the wild
local horseNames = {
    "a_c_horse_nokota_whiteroan",
    "a_c_donkey_01",
    "A_C_Horse_AmericanPaint_Greyovero",
    "A_C_Horse_AmericanPaint_Overo",
    "A_C_Horse_AmericanPaint_SplashedWhite",
    "A_C_Horse_AmericanPaint_Tobiano",
    "A_C_Horse_AmericanStandardbred_Black",
    "A_C_Horse_AmericanStandardbred_Buckskin",
    "A_C_Horse_AmericanStandardbred_PalominoDapple",
    "A_C_Horse_AmericanStandardbred_SilverTailBuckskin",
    "A_C_Horse_AmericanStandardbred_LightBuckskin",
    "A_C_Horse_Andalusian_DarkBay",
    "A_C_Horse_Andalusian_Perlino",
    "A_C_Horse_Andalusian_RoseGray",
    "A_C_Horse_Appaloosa_BlackSnowflake",
    "A_C_Horse_Appaloosa_Blanket",
    "A_C_Horse_Appaloosa_BrownLeopard",
    "A_C_Horse_Appaloosa_FewSpotted_PC",
    "A_C_Horse_Appaloosa_Leopard",
    "A_C_Horse_Appaloosa_LeopardBlanket",
    "A_C_Horse_Arabian_Black",
    "A_C_Horse_Arabian_Grey",
    "A_C_Horse_Arabian_RedChestnut",
    "A_C_Horse_Arabian_RedChestnut_PC",
    "A_C_Horse_Arabian_RoseGreyBay",
    "A_C_Horse_Arabian_WarpedBrindle_PC",
    "A_C_Horse_Arabian_White",
    "A_C_Horse_Ardennes_BayRoan",
    "A_C_Horse_Ardennes_IronGreyRoan",
    "A_C_Horse_Ardennes_StrawberryRoan",
    "A_C_Horse_Belgian_BlondChestnut",
    "A_C_Horse_Belgian_MealyChestnut",
    "A_C_Horse_Breton_GrulloDun",
    "A_C_Horse_Breton_MealyDappleBay",
    "A_C_Horse_Breton_RedRoan",
    "A_C_Horse_Breton_SealBrown",
    "A_C_Horse_Breton_Sorrel",
    "A_C_Horse_Breton_SteelGrey",
    "A_C_Horse_Breton_Bayblonde",
    "A_C_Horse_Breton_BlackChestnut",
    "A_C_Horse_Breton_Liverchestnut",
    "A_C_Horse_Buell_WarVets",
    "A_C_Horse_Criollo_BayBrindle",
    "A_C_Horse_Criollo_BayFrameOvero",
    "A_C_Horse_Criollo_BlueRoanOvero",
    "A_C_Horse_Criollo_Dun",
    "A_C_Horse_Criollo_MarbleSabino",
    "A_C_Horse_Criollo_SorrelOvero",
    "A_C_Horse_Criollo_BayRoan",
    "A_C_Horse_Criollo_Buckskin",
    "A_C_Horse_Criollo_GrullaDun",
    "A_C_Horse_DutchWarmblood_ChocolateRoan",
    "A_C_Horse_DutchWarmblood_SealBrown",
    "A_C_Horse_DutchWarmblood_SootyBuckskin",
    "A_C_Horse_Gang_Bill",
    "A_C_Horse_Gang_Charles",
    "A_C_Horse_Gang_Charles_EndlessSummer",
    "A_C_Horse_Gang_Dutch",
    "A_C_Horse_Gang_Hosea",
    "A_C_Horse_Gang_Javier",
    "A_C_Horse_Gang_John",
    "A_C_Horse_Gang_Karen",
    "A_C_Horse_Gang_Kieran",
    "A_C_Horse_Gang_Lenny",
    "A_C_Horse_Gang_Micah",
    "A_C_Horse_Gang_Sadie",
    "A_C_Horse_Gang_Sadie_EndlessSummer",
    "A_C_Horse_Gang_Sean",
    "A_C_Horse_Gang_Trelawney",
    "A_C_Horse_Gang_Uncle",
    "A_C_Horse_Gang_Uncle_EndlessSummer",
    "A_C_Horse_GypsyCob_Skewbald",
    "A_C_Horse_GypsyCob_SplashedPiebald",
    "A_C_Horse_GypsyCob_WhiteBlagdon",
    "A_C_Horse_GypsyCob_PiebaldRosamillo",
    "A_C_Horse_GypsyCob_PalominoBlagdon",
    "A_C_Horse_GypsyCob_DarkBay",
    "A_C_Horse_HungarianHalfbred_DarkDappleGrey",
    "A_C_Horse_HungarianHalfbred_LiverChestnut",
    "A_C_Horse_HungarianHalfbred_FlaxenChestnut",
    "A_C_Horse_HungarianHalfbred_PiebaldTobiano",
    "A_C_Horse_John_EndlessSummer",
    "A_C_Horse_KentuckySaddle_Black",
    "A_C_Horse_KentuckySaddle_ButterMilkBuckskin_PC",
    "A_C_Horse_KentuckySaddle_ChestnutPinto",
    "A_C_Horse_KentuckySaddle_Grey",
    "A_C_Horse_KentuckySaddle_SilverBay",
    "A_C_Horse_Kladruber_Black",
    "A_C_Horse_Kladruber_Cremello",
    "A_C_Horse_Kladruber_DappleRoseGrey",
    "A_C_Horse_Kladruber_Grey",
    "A_C_Horse_Kladruber_Silver",
    "A_C_Horse_Kladruber_White",
    "A_C_Horse_Kladruber_BayRoan",
    "A_C_Horse_Kladruber_Lightbuckskin",
    "A_C_Horse_Kladruber_SilverDapple",
    "A_C_Horse_MissouriFoxTrotter_AmberChampagne",
    "A_C_Horse_MissouriFoxTrotter_BuckskinBrindle",
    "A_C_Horse_MissouriFoxTrotter_DappleGrey",
    "A_C_Horse_MissouriFoxTrotter_SableChampagne",
    "A_C_Horse_MissouriFoxTrotter_SilverDapplePinto",
    "A_C_Horse_Morgan_Bay",
    "A_C_Horse_Morgan_BayRoan",
    "A_C_Horse_Morgan_FlaxenChestnut",
    "A_C_Horse_Morgan_LiverChestnut_PC",
    "A_C_Horse_Morgan_Palomino",
    "A_C_Horse_MP_Mangy_Backup",
    "A_C_Horse_MurfreeBrood_Mange_01",
    "A_C_Horse_MurfreeBrood_Mange_02",
    "A_C_Horse_MurfreeBrood_Mange_03",
    "A_C_Horse_Mustang_GoldenDun",
    "A_C_Horse_Mustang_GrulloDun",
    "A_C_Horse_Mustang_RedDunOvero",
    "A_C_Horse_Mustang_TigerStripedBay",
    "A_C_Horse_Mustang_WildBay",
    "A_C_Horse_Mustang_BuckskinBrindle",
    "A_C_Horse_Mustang_ChestnutDunOvero",
    "A_C_Horse_Mustang_RedDun",
    "A_C_Horse_Nokota_BlueRoan",
    "A_C_Horse_Nokota_ReverseDappleRoan",
    "A_C_Horse_NorfolkRoadster_PiebaldRoan",
    "A_C_Horse_NorfolkRoadster_SpeckledGrey",
    "A_C_Horse_NorfolkRoadster_SpottedTricolor",
    "A_C_Horse_NorfolkRoadster_Black",
    "A_C_Horse_NorfolkRoadster_DappleBuckskin",
    "A_C_Horse_NorfolkRoadster_RoseGrey",
    "A_C_Horse_Shire_DarkBay",
    "A_C_Horse_Shire_LightGrey",
    "A_C_Horse_Shire_RavenBlack",
    "A_C_Horse_SuffolkPunch_RedChestnut",
    "A_C_Horse_SuffolkPunch_Sorrel",
    "A_C_Horse_TennesseeWalker_BlackRabicano",
    "A_C_Horse_TennesseeWalker_Chestnut",
    "A_C_Horse_TennesseeWalker_DappleBay",
    "A_C_Horse_TennesseeWalker_FlaxenRoan",
    "A_C_Horse_TennesseeWalker_GoldPalomino_PC",
    "A_C_Horse_TennesseeWalker_MahoganyBay",
    "A_C_Horse_TennesseeWalker_RedRoan",
    "A_C_Horse_Thoroughbred_BlackChestnut",
    "A_C_Horse_Thoroughbred_BloodBay",
    "A_C_Horse_Thoroughbred_Brindle",
    "A_C_Horse_Thoroughbred_DappleGrey",
    "A_C_Horse_Thoroughbred_ReverseDappleBlack",
    "A_C_Horse_Turkoman_DarkBay",
    "A_C_Horse_Turkoman_Gold",
    "A_C_Horse_Turkoman_Silver",
    "A_C_Horse_Turkoman_Chestnut",
    "A_C_Horse_Turkoman_Grey",
    "A_C_Horse_Turkoman_Perlino",
    "A_C_Horse_Winter02_01",
    "A_C_HorseMule_01",
    "A_C_HorseMulePainted_01",
    "P_C_Horse_01",
    "A_C_Horse_EagleFlies",
    -- PC Variants
    "A_C_Horse_Americanpaint_Tobiano_PC",
    "A_C_Horse_Andalusian_DarkBay_PC",
    "A_C_Horse_Andalusian_Perlino_PC",
    "A_C_Horse_Andalusian_RoseGray_PC",
    "A_C_Horse_Appaloosa_BlackSnowflake_PC",
    "A_C_Horse_Appaloosa_Blanket_PC",
    "A_C_Horse_Appaloosa_BrownLeopard_PC",
    "A_C_Horse_Appaloosa_Leopard_PC",
    "A_C_Horse_Appaloosa_LeopardBlanket_PC",
    "A_C_Horse_Arabian_Black_PC",
    "A_C_Horse_Arabian_Grey_PC",
    "A_C_Horse_Arabian_RoseGreyBay_PC",
    "A_C_Horse_Arabian_White_PC",
    "A_C_Horse_Ardennes_BayRoan_PC",
    "A_C_Horse_Ardennes_IronGreyRoan_PC",
    "A_C_Horse_Ardennes_StrawberryRoan_PC",
    "A_C_Horse_Belgian_BlondChestnut_PC",
    "A_C_Horse_DutchWarmblood_ChocolateRoan_PC",
    "A_C_Horse_DutchWarmblood_SealBrown_PC",
    "A_C_Horse_DutchWarmblood_SootyBuckskin_PC",
    "A_C_Horse_HungarianHalfbred_DarkDappleGrey_PC",
    "A_C_Horse_HungarianHalfbred_FlaxenChestnut_PC",
    "A_C_Horse_KentuckySaddle_ChestnutPinto_PC",
    "A_C_Horse_KentuckySaddle_Grey_PC",
    "A_C_Horse_KentuckySaddle_SilverBay_PC",
    "A_C_Horse_MissouriFoxTrotter_AmberChampagne_PC",
    "A_C_Horse_MissouriFoxTrotter_DappleGrey_PC",
    "A_C_Horse_MissouriFoxTrotter_SableChampagne_PC",
    "A_C_Horse_MissouriFoxTrotter_SilverDapplePinto_PC",
    "A_C_Horse_Morgan_Bay_PC",
    "A_C_Horse_Morgan_BayRoan_PC",
    "A_C_Horse_Morgan_FlaxenChestnut_PC",
    "A_C_Horse_Morgan_Palomino_PC",
    "A_C_Horse_Mustang_GoldenDun_PC",
    "A_C_Horse_Mustang_GrulloDun_PC",
    "A_C_Horse_Mustang_TigerStripedBay_PC",
    "A_C_Horse_Mustang_WildBay_PC",
    "A_C_Horse_Nokota_BlueRoan_PC",
    "A_C_Horse_Nokota_ReverseDappleRoan_PC",
    "A_C_Horse_Nokota_WhiteRoan_PC",
    "A_C_Horse_Shire_DarkBay_PC",
    "A_C_Horse_Shire_LightGrey_PC",
    "A_C_Horse_Shire_RavenBlack_PC",
    "A_C_Horse_SuffolkPunch_RedChestnut_PC",
    "A_C_Horse_SuffolkPunch_Sorrel_PC",
    "A_C_Horse_TennesseeWalker_BlackRabicano_PC",
    "A_C_Horse_TennesseeWalker_Chestnut_PC",
    "A_C_Horse_TennesseeWalker_DappleBay_PC",
    "A_C_Horse_TennesseeWalker_FlaxenRoan_PC",
    "A_C_Horse_TennesseeWalker_MahoganyBay_PC",
    "A_C_Horse_TennesseeWalker_RedRoan_PC",
    "A_C_Horse_Thoroughbred_BlackChestnut_PC",
    "A_C_Horse_Thoroughbred_BloodBay_PC",
    "A_C_Horse_Thoroughbred_Brindle_PC",
    "A_C_Horse_Thoroughbred_DappleGrey_PC",
    "A_C_Horse_Thoroughbred_ReverseDappleBlack_PC",
    "A_C_Horse_Turkoman_DarkBay_PC",
    "A_C_Horse_Turkoman_Gold_PC",
    "A_C_Horse_Turkoman_Silver_PC",
}

local horseModels = {}
for _, name in ipairs(horseNames) do
    horseModels[joaat(name)] = name:lower()
end

RegisterNetEvent('rms-wildhorsestable:server:WildHorseStable', function(netId, horsename, gender)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid

    if type(horsename) ~= 'string' then return Notify(src, 'wh_error_invalid_name', 'error') end
    horsename = horsename:gsub('[^%w%s%-_]', ''):gsub('^%s+', ''):gsub('%s+$', '')
    if #horsename < 1 or #horsename > 30 then
        return Notify(src, 'wh_error_invalid_name', 'error')
    end
    if gender ~= 'male' and gender ~= 'female' then gender = 'male' end

    local remaining = CooldownRemaining(citizenid)
    if remaining > 0 then
        return Security(src, 'Wild Horse Stable Cooldown Hit', remaining .. 's remaining')
    end

    local entity = ResolveWildHorse(src, netId)
    if not entity then
        Notify(src, 'wh_error_no_horse_save', 'error')
        return Security(src, 'Wild Horse Stable Rejected', 'invalid entity / location / distance')
    end

    local modelName = horseModels[GetEntityModel(entity)]
    if not modelName then
        return Notify(src, 'wh_error_invalid_model', 'error')
    end

    lastAction[citizenid] = os.time()
    DeleteEntity(entity)

    local adultAge = 4 * 24 * 60 * 60 -- wild horses are adults
    local insertId = MySQL.insert.await('INSERT INTO player_horses (stable, citizenid, horseid, name, horse, gender, active, born, components, horsexp, dirt, age_seconds) VALUES (?, ?, ?, ?, ?, ?, 0, ?, ?, 0, 0, ?)', {
        'valentine', citizenid, GenerateHorseid(), horsename, modelName, gender, os.time() - adultAge, '{}', adultAge
    })

    if not insertId then
        return Notify(src, 'wh_error_save_failed', 'error')
    end

    Notify(src, 'wh_save_success', 'success', horsename)
    SendDiscordLog('horses', 'Wild Horse Tamed & Stabled', horsename .. ' (' .. modelName .. ')', WebhookColors.info, nil, src)
end)

if WH.Debug then
    RSGCore.Commands.Add('sethorsewild', 'Make current horse wild (debug)', {}, false, function(source)
        TriggerClientEvent('rsg-sellwildhorse:client:SetHorseAsWild', source)
    end, 'admin')
end
