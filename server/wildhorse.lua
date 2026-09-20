-- Wild horse (tame / sell / save) server, merged from rsg-wildhorse v1.0.3.
-- Event names are kept identical so anything triggering them keeps working.
-- Model names and gender are normalised to lowercase on save for
-- compatibility with the stable database, breeding checks and model lookups.
local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

-- shared/wildhorse_config.lua (listed in fxmanifest shared_scripts) normally
-- provides this. If it is missing the running server is on a stale manifest:
-- fully Stop + Start the server (not Restart) so the new manifest loads.
if not Config.WildHorse then
    print('^1[rsg-horses] shared/wildhorse_config.lua did not load - fully Stop + Start the server so the new fxmanifest takes effect^7')
    Config.WildHorse = {
        Debug = false, SellTime = 20000, EnableCooldown = false, Cooldown = 900,
        Keybind = 'J', PaymentType = 'cash', SaleMultiplier = 1, Xp = 0,
        Blip = { blipName = 'Sell Wild Horse', blipSprite = 'blip_shop_horse_fencing', blipScale = 0.2 },
        SellWildHorseLocations = {}, Horse = {},
    }
end

-- SECURITY: rewardmoney/rewarditem are client-supplied and were fully
-- trusted here, letting a modified client call this event repeatedly with
-- an arbitrary amount/item for unlimited money+item duplication, with no
-- server-side cooldown. Every entry in Config.WildHorse.Horse currently
-- uses the same reward item and a 15-30 money range, so we derive a
-- server-authoritative cap/whitelist from that config and enforce a
-- per-player cooldown independent of the client.
local wildHorseRewardItems = {}
local wildHorseMaxReward = 0
for _, horseCfg in pairs(Config.WildHorse.Horse or {}) do
    if horseCfg.rewarditem then
        wildHorseRewardItems[horseCfg.rewarditem] = true
    end
    local rm = tonumber(horseCfg.rewardmoney) or 0
    if rm > wildHorseMaxReward then
        wildHorseMaxReward = rm
    end
end
if wildHorseMaxReward <= 0 then wildHorseMaxReward = 30 end

local wildHorseSellCooldowns = {} -- citizenid -> os.time() of last successful sale

RegisterServerEvent('rsg-sellwildhorse:server:reward')
AddEventHandler('rsg-sellwildhorse:server:reward', function(rewardmoney, rewarditem)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local firstname = Player.PlayerData.charinfo.firstname
    local lastname = Player.PlayerData.charinfo.lastname
    local citizenid = Player.PlayerData.citizenid

    if Config.WildHorse.Debug then
        print("Money    : "..tostring(rewardmoney))
        print("Item     : "..tostring(rewarditem))
    end

    -- SECURITY: enforce server-side cooldown so this event can't be spammed
    -- to farm money/items, regardless of what the client's own timer does.
    if Config.WildHorse.EnableCooldown then
        local cooldownSecs = tonumber(Config.WildHorse.Cooldown) or 0
        local lastSold = wildHorseSellCooldowns[citizenid]
        if lastSold and (os.time() - lastSold) < cooldownSecs then
            SendDiscordLog('security', 'Wild Horse Sell Cooldown Hit', 'Player attempted to sell a wild horse again before the cooldown expired.', WebhookColors.warning, {
                { name = 'Seconds Remaining', value = tostring(cooldownSecs - (os.time() - lastSold)), inline = true },
            }, src)
            return
        end
    end

    -- SECURITY: never trust the client's reward values directly. Validate
    -- the item against the configured reward items and clamp the money to
    -- the maximum configured for any wild horse.
    if type(rewarditem) ~= 'string' or not wildHorseRewardItems[rewarditem] then
        warn(('rsg-horses: rejected suspicious wild horse reward item "%s" from citizenid %s'):format(tostring(rewarditem), tostring(citizenid)))
        SendDiscordLog('security', 'Rejected Wild Horse Reward Item', 'Player attempted a wild horse sell reward with an unrecognised item.', WebhookColors.danger, {
            { name = 'Claimed Item', value = tostring(rewarditem), inline = true },
        }, src)
        return
    end

    local safeMoney = tonumber(rewardmoney) or 0
    local requestedMoney = safeMoney
    if safeMoney < 0 then safeMoney = 0 end
    if safeMoney > wildHorseMaxReward then safeMoney = wildHorseMaxReward end

    if requestedMoney ~= safeMoney then
        SendDiscordLog('security', 'Wild Horse Reward Clamped', 'Client-requested reward amount was outside the allowed range and was clamped.', WebhookColors.warning, {
            { name = 'Requested', value = tostring(requestedMoney), inline = true },
            { name = 'Clamped To', value = tostring(safeMoney), inline = true },
        }, src)
    end

    local reward = math.floor(safeMoney * (tonumber(Config.WildHorse.SaleMultiplier) or 1))

    wildHorseSellCooldowns[citizenid] = os.time()

    Player.Functions.AddMoney(Config.WildHorse.PaymentType, reward)
    Player.Functions.AddItem(rewarditem, 1)

    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[rewarditem], "add")

    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('wh_title'),
        description = locale('wh_success_sold_for')..reward,
        type = 'success',
        duration = 3000
    })

    TriggerEvent('rsg-log:server:CreateLog', 'testwebhook', 'WILD HORSE', 'yellow', firstname..' '..lastname..' Horse sold for '..reward)

    SendDiscordLog('economy', 'Wild Horse Sold', firstname .. ' ' .. lastname .. ' sold a tamed wild horse.', WebhookColors.success, {
        { name = 'Reward', value = '$' .. tostring(reward), inline = true },
        { name = 'Item', value = tostring(rewarditem), inline = true },
    }, src)
end)

-- Mapping of horse model hashes to their names
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
    horseModels[GetHashKey(name)] = name
end

RegisterServerEvent('rms-wildhorsestable:server:WildHorseStable')
AddEventHandler('rms-wildhorsestable:server:WildHorseStable', function(modelHash, horsename, gender)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid

    local modelName = horseModels[modelHash]
    if not modelName then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('wh_title'),
            description = locale('wh_error_invalid_model'),
            type = 'error',
            duration = 5000
        })
        SendDiscordLog('security', 'Wild Horse Stable Rejected - Invalid Model', 'Player attempted to stable a wild horse with an unrecognised model hash.', WebhookColors.warning, {
            { name = 'Model Hash', value = tostring(modelHash), inline = true },
        }, src)
        return
    end

    -- Normalise for stable compatibility: lowercase model (hash lookups and
    -- breed lists use lowercase) and lowercase gender (breeding checks expect
    -- 'male' / 'female'). The client dialog already sends lowercase gender;
    -- this is defence in depth.
    modelName = string.lower(modelName)
    gender = string.lower(gender or '')
    if gender ~= 'male' and gender ~= 'female' then
        gender = 'male'
    end
    if type(horsename) ~= 'string' then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('wh_title'),
            description = locale('wh_error_invalid_name'),
            type = 'error',
            duration = 5000
        })
        SendDiscordLog('security', 'Wild Horse Stable Rejected - Invalid Name Type', 'Player attempted to stable a wild horse with a non-string name.', WebhookColors.warning, nil, src)
        return
    end
    horsename = string.gsub(horsename, "[^%w%s%-_]", "")
    if #horsename < 1 or #horsename > 30 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('wh_title'),
            description = locale('wh_error_invalid_name'),
            type = 'error',
            duration = 5000
        })
        SendDiscordLog('security', 'Wild Horse Stable Rejected - Invalid Name Length', 'Player attempted to stable a wild horse with an invalid name length.', WebhookColors.warning, {
            { name = 'Sanitized Name', value = horsename, inline = true },
        }, src)
        return
    end

    -- Generate unique horse ID
    local horseid = tostring(RSGCore.Shared.RandomStr(3) .. RSGCore.Shared.RandomInt(3)):upper()

    -- Set born timestamp to 4 days ago so horse is NOT a foal (3+ days old)
    local fourDaysAgo = os.time() - (4 * 24 * 60 * 60)

    -- Default components (empty JSON object)
    local components = json.encode({})

    if Config.WildHorse.Debug then
        print('[rsg-horses] Saving wild horse to stables:')
        print('  CitizenID  : ' .. tostring(citizenid))
        print('  HorseID    : ' .. tostring(horseid))
        print('  Name       : ' .. tostring(horsename))
        print('  Model      : ' .. tostring(modelName))
        print('  Gender     : ' .. tostring(gender))
        print('  Born       : ' .. tostring(fourDaysAgo) .. ' (4 days ago)')
    end

    local query = [[
        INSERT INTO player_horses
        (stable, citizenid, horseid, name, horse, gender, active, born, components, horsexp, dirt, age_seconds)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]]

    local params = {
        'valentine',    -- stable
        citizenid,      -- citizenid
        horseid,        -- horseid
        horsename,      -- name
        modelName,      -- horse
        gender,         -- gender
        0,              -- active
        fourDaysAgo,    -- born (4 days ago so it's an adult)
        components,     -- components
        0,              -- horsexp
        0,              -- dirt
        4 * 24 * 60 * 60 -- age_seconds (4 days in seconds = 345600)
    }

    if Config.WildHorse.Debug then
        print('[rsg-horses] Query: ' .. query)
        print('[rsg-horses] Params: ' .. json.encode(params))
    end

    MySQL.Async.insert(query, params, function(insertId)
        if insertId and insertId > 0 then
            TriggerClientEvent('ox_lib:notify', src, {
                title = locale('wh_title'),
                description = locale('wh_save_success'):format(horsename),
                type = 'success',
                duration = 5000
            })

            TriggerClientEvent('rms-wildhorsestable:client:DeleteWildHorse', src)

            SendDiscordLog('horses', 'Wild Horse Tamed & Stabled', horsename .. ' (' .. modelName .. ') tamed and added to the valentine stable.', WebhookColors.info, {
                { name = 'Horse Name', value = horsename, inline = true },
                { name = 'Model', value = modelName, inline = true },
                { name = 'Gender', value = gender, inline = true },
            }, src)

            if Config.WildHorse.Debug then
                print('[rsg-horses] Wild horse successfully saved! InsertId: ' .. tostring(insertId))
            end
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = locale('wh_title'),
                description = locale('wh_error_save_failed'),
                type = 'error',
                duration = 5000
            })

            if Config.WildHorse.Debug then
                print('[rsg-horses] Failed to insert wild horse into database.')
            end
        end
    end)
end)

--debug
if Config.WildHorse.Debug then
    RSGCore.Commands.Add('sethorsewild', 'Make current Horse a Wild Horse to test/debug Horse Taming activity', {}, false, function(source)
        local src = source
        local Player = RSGCore.Functions.GetPlayer(src)
        if not Player then return end
        TriggerClientEvent('rsg-sellwildhorse:client:SetHorseAsWild', src)
    end, 'admin')
end
