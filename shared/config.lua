Config = {}
lib.locale()

-- debug
Config.Debug = false

Config = {
    horsesShopItems ={
        { name = 'horse_brush',     amount = 10, price = 5 },
        { name = 'horse_lantern',   amount = 10, price = 10 },
        { name = 'horsecarrot',    amount = 50, price = 1 },
        { name = 'horseapple',     amount = 50, price = 1 },
		{ name = 'hay',     amount = 50, price = 1 },
        { name = 'horse_stimulant', amount = 25, price = 2 },
        { name = 'horse_reviver',   amount = 25, price = 10 },
		{ name = 'horse_holster',   amount = 25, price = 20 }
    },
    PersistStock = false, --should stock save in database and load it after restart, to 'remember' stock value before restart
}

Config.HorseHolster = {
    hash         = 0xF772CED6, -- holster shop item hash (already used in the original SpawnHorse)
    categoryHash = 0x80451C25, -- saddlebags category hash to clear it if needed
}
Config.Prompt = {
    HorseDrink = 0xD8CF0C95,
    HorseGraze = 0xD8CF0C95,
    HorseLay = 0xD8CF0C95,
    HorsePlay = 0x620A6C5E,
    HorseSaddleBag = 0xC7B5340A,
    HorseBrush = 0x63A38F2C,
    HorseLantern = 0x63A38F2C,
    Rotate = { 0x7065027D, 0xB4E465B4 },
}

Config.TrickXp = {
    Lay = 1000,
    Play = 2000
}

Config.ComponentHash = {
    Blankets = 0x17CEB41A,
    Saddles = 0xBAA7E618,
    Horns = 0x05447332,
    Saddlebags = 0x80451C25,
    Stirrups = 0xDA6DADCA,
    Bedrolls = 0xEFB31921,
    Tails = 0xA63CAE10,
    Manes = 0xAA0217AB,
    Masks = 0xD3500E5D,
    Mustaches = 0x30DEFDDF,
}

Config.PriceComponent = {
    Blankets = 5,
    Saddles = 2,
    Horns = 10,
    Saddlebags = 3,
    Stirrups = 4,
    Bedrolls = 5,
    Tails = 4,
    Manes = 3,
    Masks = 3,
    Mustaches = 2,
}

---------------------------------
-- horse coat color / markings (merged from horse_markings test resource)
-- tint0 = main coat colour (0-254), tint1 = horse marking (0-255), tint2 = nose (0-255)
-- mane/tail = mane & tail colours (0-254), applied to mane/tail components
-- applied via SetMetaPedTag on horse_bodies + horse_heads with palette metaped_tint_horse
---------------------------------
Config.Coat = {
    Price = 100, -- flat price charged when coat/mane/tail differs from saved coat
    Palette = 'metaped_tint_horse',
    Default = { tint0 = 0, tint1 = 255, tint2 = 255, mane = 0, tail = 0 },
}

-- preset tint0 ids found in test folder (horse_markings/shared/config.lua)
Config.CoatPresets = {
    { name = 'White',        tint0 = 0,   price = 100 },
    { name = 'Black',        tint0 = 9,   price = 100 },
    { name = 'Brown',        tint0 = 40,  price = 100 },
    { name = 'Bay',          tint0 = 100, price = 100 },
    { name = 'Purple',       tint0 = 105, price = 100 },
    { name = 'Pink',         tint0 = 107, price = 100 },
    { name = 'Lilac',        tint0 = 108, price = 100 },
    { name = 'Dark Green',   tint0 = 109, price = 100 },
    { name = 'Blue',         tint0 = 110, price = 100 },
    { name = 'Green',        tint0 = 112, price = 100 },
    { name = 'Lime',         tint0 = 115, price = 100 },
    { name = 'Yellow',       tint0 = 119, price = 100 },
    { name = 'Orange',       tint0 = 120, price = 100 },
    { name = 'Bronze',       tint0 = 121, price = 100 },
    { name = 'Blood Red',    tint0 = 125, price = 100 },
    { name = 'Chestnut Red', tint0 = 127, price = 100 },
    { name = 'Silver',       tint0 = 128, price = 100 },
    { name = 'Grey',         tint0 = 130, price = 100 },
}

---------------------------------
-- general settings
---------------------------------
Config.EnableTarget        = true -- toggle between target and prompt
Config.TargetHelp          = false -- target help to use [L-ALT]
Config.Automount           = false -- horse automount
Config.SpawnOnRoadOnly     = false -- always spawn on road
Config.HorseInvWeight      = 16000 -- horse inventory weight
Config.HorseInvSlots       = 30 -- horse inventory slots
Config.CheckCycle          = 30 -- horse check system (mins) -- default 60
Config.StarterHorseDieAge  = 7 -- starter horse age in days till it dies (days)
Config.HorseDieAge         = 665 -- horse age in days till it dies (days)
Config.StoreFleedHorse     = false -- store horse if flee is used
Config.EnableServerNotify  = false
Config.KeyBind             = 'J'
Config.AllowTwoPlayersRide = true -- if true two players can ride but may have some impact on other features
Config.DeathGracePeriod    = 60000 -- grace period to let player attempt to revive the horse
Config.MoveHorseBasePrice  = 10
Config.MoveFeePerMeter     = 0.01

---------------------------------
-- horse inventory weight by level
---------------------------------
Config.Level1InvWeight = 4000
Config.Level1InvSlots = 14
Config.Level2InvWeight = 6000
Config.Level2InvSlots = 16
Config.Level3InvWeight = 8000
Config.Level3InvSlots = 18
Config.Level4InvWeight = 9000
Config.Level4InvSlots = 20
Config.Level5InvWeight = 10000
Config.Level5InvSlots = 25
Config.Level6InvWeight = 12000
Config.Level6InvSlots = 26
Config.Level7InvWeight = 13000
Config.Level7InvSlots = 27
Config.Level8InvWeight = 14000
Config.Level8InvSlots = 28
Config.Level9InvWeight = 15000
Config.Level9InvSlots = 29
Config.Level10InvWeight = 16000
Config.Level10InvSlots = 30

---------------------------------
-- horse health/stamina/ability/speed/acceleration levels
---------------------------------
Config.Level1 = 100
Config.Level2 = 200
Config.Level3 = 300
Config.Level4 = 400
Config.Level5 = 500
Config.Level6 = 900
Config.Level7 = 1000
Config.Level8 = 1500
Config.Level9 = 1750
Config.Level10 = 2000

---------------------------------
-- player feed horse settings
---------------------------------
Config.HorseFeed = {
    -- medicineHash is optional. If u do not set, the default value wil be: consumable_horse_stimulant
    ['horsecarrot']    = { health = 10,  stamina = 10,  ismedicine = false },
	['hay']    = { health = 10,  stamina = 10,  ismedicine = false },
    ['horseapple']     = { health = 15,  stamina = 15,  ismedicine = false },
    ['horse_stimulant'] = { health = 100, stamina = 100, ismedicine = true, medicineHash = 'consumable_horse_stimulant' },
}

---------------------------------
--horse action
---------------------------------
Config.ObjectAction = true

Config.BoostAction = {
    Health = math.random(3, 9),
    Stamina = math.random(3, 9)
}

Config.ObjectActionList = {
    [1] = {`p_watertrough02x`, 'drink'},
    [2] = {`p_watertrough01x`, 'drink'},
    [3] = {`p_haypile01x`, 'feed'},
}

Config.Anim = {
    Drink  = { dict = 'amb_creature_mammal@world_horse_drink_ground@base', anim = 'base',   duration = 20 }, --duration in seconds
    Drink2 = { dict = 'amb_creature_mammal@prop_horse_drink_trough@idle0', anim = 'idle_a', duration = 20 },
    Graze  = { dict = 'amb_creature_mammal@world_horse_grazing@idle',      anim = 'idle_a', duration = 20 }
}

---------------------------------
-- horse bonding settings
---------------------------------
Config.MaxBondingLevel = 5000

---------------------------------
-- config blips
---------------------------------
Config.Blip = {
    blipName = locale('cf_menu_horse_blip_name'), -- Config.Blip.blipName
    blipSprite = 'blip_shop_horse', -- Config.Blip.blipSprite
    blipScale = 0.1 -- Config.Blip.blipScale
}

---------------------------------
-- stable npc settings
---------------------------------
Config.DistanceSpawn = 20.0
Config.FadeIn = true

---------------------------------
-- stable npcs
---------------------------------
---------------------------------
-- breeding settings
---------------------------------
Config.Breeding = {
    enabled = true,
    requiredJob = 'horsebreeder',
    requireOppositeSex = true,
    gestationMinutes = 120,
    breedCooldownMinutes = 120, -- 2 hours
    hayCost = 1,
    maturityMinutes = 60,
}

---------------------------------
-- growth / foal settings
---------------------------------
Config.Growth = {
    enabled = true,
    minScale = 0.4,
    growthMinutesToAdult = 720, --- 12 hours
}

---------------------------------
-- all horse models for random foal breed
---------------------------------
Config.HorseModels = {
    'a_c_horse_americanpaint_greyovero',
    'a_c_horse_americanpaint_overo',
    'a_c_horse_americanpaint_splashedwhite',
    'a_c_horse_americanpaint_tobiano',
    'a_c_horse_americanstandardbred_black',
    'a_c_horse_americanstandardbred_buckskin',
    'a_c_horse_americanstandardbred_lightbuckskin',
    'a_c_horse_americanstandardbred_palominodapple',
    'a_c_horse_americanstandardbred_silvertailbuckskin',
    'a_c_horse_andalusian_darkbay',
    'a_c_horse_andalusian_perlino',
    'a_c_horse_andalusian_rosegray',
    'a_c_horse_appaloosa_blanket',
    'a_c_horse_appaloosa_blacksnowflake',
    'a_c_horse_appaloosa_brownleopard',
    'a_c_horse_appaloosa_fewspotted_pc',
    'a_c_horse_appaloosa_leopard',
    'a_c_horse_appaloosa_leopardblanket',
    'a_c_horse_arabian_black',
    'a_c_horse_arabian_grey',
    'a_c_horse_arabian_redchestnut',
    'a_c_horse_arabian_rosegreybay',
    'a_c_horse_arabian_warpedbrindle_pc',
    'a_c_horse_arabian_white',
    'a_c_horse_ardennes_bayroan',
    'a_c_horse_ardennes_irongreyroan',
    'a_c_horse_ardennes_strawberryroan',
    'a_c_horse_belgian_blondchestnut',
    'a_c_horse_belgian_mealychestnut',
    'a_c_horse_breton_grullodun',
    'a_c_horse_breton_mealydapplebay',
    'a_c_horse_breton_redroan',
    'a_c_horse_breton_sealbrown',
    'a_c_horse_breton_sorrel',
    'a_c_horse_breton_steelgrey',
    'a_c_horse_criollo_baybrindle',
    'a_c_horse_criollo_bayframeovero',
    'a_c_horse_criollo_blueroanovero',
    'a_c_horse_criollo_dun',
    'a_c_horse_criollo_marblesabino',
    'a_c_horse_criollo_sorrelovero',
    'a_c_horse_dutchwarmblood_chocolateroan',
    'a_c_horse_dutchwarmblood_sealbrown',
    'a_c_horse_dutchwarmblood_sootybuckskin',
    'a_c_horse_gypsycob_skewbald',
    'a_c_horse_gypsycob_splashedpiebald',
    'a_c_horse_gypsycob_whiteblagdon',
    'a_c_horse_hungarianhalfbred_darkdapplegrey',
    'a_c_horse_hungarianhalfbred_flaxenchestnut',
    'a_c_horse_hungarianhalfbred_liverchestnut',
    'a_c_horse_hungarianhalfbred_piebaldtobiano',
    'a_c_horse_kentuckysaddle_black',
    'a_c_horse_kentuckysaddle_buttermilkbuckskin_pc',
    'a_c_horse_kentuckysaddle_chestnutpinto',
    'a_c_horse_kentuckysaddle_grey',
    'a_c_horse_kentuckysaddle_silverbay',
    'a_c_horse_kladruber_black',
    'a_c_horse_kladruber_cremello',
    'a_c_horse_kladruber_dapplerosegrey',
    'a_c_horse_kladruber_grey',
    'a_c_horse_kladruber_silver',
    'a_c_horse_kladruber_white',
    'a_c_horse_missourifoxtrotter_amberchampagne',
    'a_c_horse_missourifoxtrotter_buckskinbrindle',
    'a_c_horse_missourifoxtrotter_dapplegrey',
    'a_c_horse_missourifoxtrotter_sablechampagne',
    'a_c_horse_missourifoxtrotter_silverdapplepinto',
    'a_c_horse_morgan_bay',
    'a_c_horse_morgan_bayroan',
    'a_c_horse_morgan_flaxenchestnut',
    'a_c_horse_morgan_liverchestnut_pc',
    'a_c_horse_morgan_palomino',
    'a_c_horse_mustang_goldendun',
    'a_c_horse_mustang_grullodun',
    'a_c_horse_mustang_reddunovero',
    'a_c_horse_mustang_tigerstripedbay',
    'a_c_horse_mustang_wildbay',
    'a_c_horse_nokota_blueroan',
    'a_c_horse_nokota_reversedappleroan',
    'a_c_horse_nokota_whiteroan',
    'a_c_horse_norfolkroadster_piebaldroan',
    'a_c_horse_norfolkroadster_speckledgrey',
    'a_c_horse_norfolkroadster_spottedtricolor',
    'a_c_horse_shire_darkbay',
    'a_c_horse_shire_lightgrey',
    'a_c_horse_shire_ravenblack',
    'a_c_horse_suffolkpunch_redchestnut',
    'a_c_horse_suffolkpunch_sorrel',
    'a_c_horse_tennesseewalker_blackrabicano',
    'a_c_horse_tennesseewalker_chestnut',
    'a_c_horse_tennesseewalker_dapplebay',
    'a_c_horse_tennesseewalker_flaxenroan',
    'a_c_horse_tennesseewalker_goldpalomino_pc',
    'a_c_horse_tennesseewalker_mahoganybay',
    'a_c_horse_tennesseewalker_redroan',
    'a_c_horse_thoroughbred_blackchestnut',
    'a_c_horse_thoroughbred_bloodbay',
    'a_c_horse_thoroughbred_brindle',
    'a_c_horse_thoroughbred_dapplegrey',
    'a_c_horse_thoroughbred_reversedappleblack',
    'a_c_horse_turkoman_darkbay',
    'a_c_horse_turkoman_gold',
    'a_c_horse_turkoman_silver',
}

Config.StableSettings = {

    {   -- colter
        stableid = 'colter',
        coords = vector3(-1334.2, 2397.41, 307.21),
        npcmodel = `u_m_m_bwmstablehand_01`,
        npccoords = vector4(-1334.2, 2397.41, 307.21, 67.43),
        horsecustom = vec4(-1344.8345, 2392.2900, 306.7908, 153.3136),
        showblip = true
    },

    {   -- vanhorn
        stableid = 'vanhorn',
        coords = vector3(2968.86, 792.97, 51.4),
        npcmodel = `u_m_m_bwmstablehand_01`,
        npccoords = vector4(2968.86, 792.97, 51.4, 357.89),
        horsecustom = vec4(2970.4155, 785.6143, 51.3995, 137.7870),
        showblip = true
    },

    {   -- saintdenis
        stableid = 'saintdenis',
        coords = vector3(2512.28, -1457.33, 46.31),
        npcmodel = `u_m_m_bwmstablehand_01`,
        npccoords = vector4(2512.28, -1457.33, 46.31, 86.43),
        horsecustom = vec4(2502.7288, -1439.7654, 46.3141, 176.4436),
        showblip = true
    },

    {   -- rhodes
        stableid = 'rhodes',
        coords = vector3(1211.55, -190.84, 101.39),
        npcmodel = `u_m_m_bwmstablehand_01`,
        npccoords = vector4(1211.55, -190.84, 101.39, 100.22),
        horsecustom = vec4(1215.1134, -207.5254, 101.0958, 267.8741),
        showblip = true
    },

    {   -- valentine
        stableid = 'valentine',
        coords = vector3(-365.2, 791.94, 116.18),
        npcmodel = `u_m_m_bwmstablehand_01`,
        npccoords = vector4(-365.2, 791.94, 116.18, 180.9),
        horsecustom = vec4(-388.5212, 784.0562, 115.8154, 150.4135),
        horsePreview = vec4(-357.77, 771.73, 116.52, 5.00),
        horseCameraPreview = vec4(-357.77, 764.73, 118.52, 5.00),
        showblip = true
    },

    {   -- strawberry
        stableid = 'strawberry',
        coords = vector3(-1817.1, -568.64, 155.98),
        npcmodel = `u_m_m_bwmstablehand_01`,
        npccoords = vector4(-1817.1, -568.64, 155.98, 254.85),
        horsecustom = vec4(-1827.2969, -577.0493, 155.9565, 215.5404),
        showblip = true
    },

    {   -- blackwater
        stableid = 'blackwater',
        coords = vector3(-876.85, -1365.55, 43.53),
        npcmodel = `u_m_m_bwmstablehand_01`,
        npccoords = vector4(-876.85, -1365.55, 43.53, 275.38),
        horsecustom = vec4(-865.1928, -1366.3270, 43.5440, 86.8795),
        showblip = true
    },

    {   -- tumbleweed
        stableid = 'tumbleweed',
        coords = vector3(-5514.81, -3040.25, -2.39),
        npcmodel = `u_m_m_bwmstablehand_01`,
        npccoords = vector4(-5514.81, -3040.25, -2.39, 175.22),
        horsecustom = vec4(-5526.3452, -3030.7842, -2.0329, 105.3392),
        showblip = true
    },

    {   -- emerald ranch
        stableid = 'emeraldranch',
        coords = vector3(1393.46, 353.09, 87.63),
        npcmodel = `mp_de_u_f_m_doverhill_01`,
        npccoords = vector4(1393.90, 354.29, 87.66, 151.53),
        horsecustom = vec4(1396.73, 345.73, 87.58, 58.91),
        showblip = true
    },

}
----------------------------------
-- discord webhook logging
----------------------------------
Config.Webhooks = {
    Enabled = true, -- master on/off switch
    BotName = 'RSG Horses',
    BotAvatar = '', -- optional image URL, leave blank string if none
    URLs = {
        economy  = '', -- horse purchases, sales, stabling, shop purchases, weapon store/retrieve, wild horse rewards
        horses   = '', -- feeding, brushing, reviving, customization/coat/component changes, horse death, horse move
        security = '', -- rejected/invalid/exploit-attempt events (clamped rewards, invalid quantities, failed validations, cooldown hits)
        general  = '', -- fallback / resource start-stop / anything uncategorized
    },
}
