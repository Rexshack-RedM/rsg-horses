Config = {}

-- debug
Config.Debug = false

-- horse inventory hotkey, please refer to '[framework]/rsg-core/shared/keybinds.lua' for complete list of hotkeys
Config.HorseInvKey = 0x760A9C6F -- G

Config.Prompt = {
    HorseDrink = 0xD8CF0C95,
    HorseGraze = 0xD8CF0C95,
    HorseLay = 0xD8CF0C95,
    HorsePlay = 0x620A6C5E,
    HorseSaddleBag = 0xC7B5340A,
    HorseBrush = 0x63A38F2C,
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
-- general settings
---------------------------------
Config.TargetHelp         = false -- target help to use [L-ALT]
Config.Automount          = false -- horse automount
Config.SpawnOnRoadOnly    = false -- always spawn on road
Config.HorseInvWeight     = 15000 -- horse inventory weight
Config.HorseInvSlots      = 20 -- horse inventory slots
Config.CheckCycle         = 60 -- horse check system (mins)
Config.HorseDieAge        = 90 -- horse age in days till it dies (days)
Config.StoreFleedHorse    = true -- store horse if flee is used
Config.EnableServerNotify = false

---------------------------------
-- horse inventory weight by level
---------------------------------
Config.Level1InvWeight = 2000
Config.Level1InvSlots = 2
Config.Level2InvWeight = 4000
Config.Level2InvSlots = 4
Config.Level3InvWeight = 6000
Config.Level3InvSlots = 6
Config.Level4InvWeight = 8000
Config.Level4InvSlots = 8
Config.Level5InvWeight = 9000
Config.Level5InvSlots = 10
Config.Level6InvWeight = 10000
Config.Level6InvSlots = 12
Config.Level7InvWeight = 12000
Config.Level7InvSlots = 14
Config.Level8InvWeight = 13000
Config.Level8InvSlots = 16
Config.Level9InvWeight = 14000
Config.Level9InvSlots = 18
Config.Level10InvWeight = 15000
Config.Level10InvSlots = 20

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
    ['carrot']          = { health = 10,  stamina = 10,  ismedicine = false },
    ['apple']           = { health = 15,  stamina = 15,  ismedicine = false },
    ['sugarcube']       = { health = 25,  stamina = 25,  ismedicine = false },
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
    blipName = Lang:t('menu.horse_blip_name'), -- Config.Blip.blipName
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
Config.StableSettings = {

    {   -- colter
        stableid = 'colter',
        coords = vector3(-1334.2, 2397.41, 307.21),
        npcmodel = `u_m_m_bwmstablehand_01`,
        npccoords = vector4(-1334.2, 2397.41, 307.21, 67.43),
        horsecustom = vec4(-1344.8345, 2392.2900, 306.7908, 153.3136)
    },

    {   -- vanhorn
        stableid = 'vanhorn',
        coords = vector3(2968.86, 792.97, 51.4),
        npcmodel = `u_m_m_bwmstablehand_01`,
        npccoords = vector4(2968.86, 792.97, 51.4, 357.89),
        horsecustom = vec4(2970.4155, 785.6143, 51.3995, 137.7870)
    },

    {   -- saintdenis
        stableid = 'saintdenis',
        coords = vector3(2512.28, -1457.33, 46.31),
        npcmodel = `u_m_m_bwmstablehand_01`,
        npccoords = vector4(2512.28, -1457.33, 46.31, 86.43),
        horsecustom = vec4(2502.7288, -1439.7654, 46.3141, 176.4436)
    },

    {   -- rhodes
        stableid = 'rhodes',
        coords = vector3(1211.55, -190.84, 101.39),
        npcmodel = `u_m_m_bwmstablehand_01`,
        npccoords = vector4(1211.55, -190.84, 101.39, 100.22),
        horsecustom = vec4(1215.1134, -207.5254, 101.0958, 267.8741)
    },

    {   -- valentine
        stableid = 'valentine',
        coords = vector3(-365.2, 791.94, 116.18),
        npcmodel = `u_m_m_bwmstablehand_01`,
        npccoords = vector4(-365.2, 791.94, 116.18, 180.9),
        horsecustom = vec4(-388.5212, 784.0562, 115.8154, 150.4135)
    },

    {   -- strawberry
        stableid = 'strawberry',
        coords = vector3(-1817.1, -568.64, 155.98),
        npcmodel = `u_m_m_bwmstablehand_01`,
        npccoords = vector4(-1817.1, -568.64, 155.98, 254.85),
        horsecustom = vec4(-1827.2969, -577.0493, 155.9565, 215.5404)
    },

    {   -- blackwater
        stableid = 'blackwater',
        coords = vector3(-876.85, -1365.55, 43.53),
        npcmodel = `u_m_m_bwmstablehand_01`,
        npccoords = vector4(-876.85, -1365.55, 43.53, 275.38),
        horsecustom = vec4(-865.1928, -1366.3270, 43.5440, 86.8795)
    },

    {   -- tumbleweed
        stableid = 'tumbleweed',
        coords = vector3(-5514.81, -3040.25, -2.39),
        npcmodel = `u_m_m_bwmstablehand_01`,
        npccoords = vector4(-5514.81, -3040.25, -2.39, 175.22),
        horsecustom = vec4(-5526.3452, -3030.7842, -2.0329, 105.3392)
    },

}

---------------------------------
-- horse settings
---------------------------------
Config.HorseSettings = {

    -- valentine
    {
        horsecoords = vector4(-370.2911, 786.8988, 116.1610, 276.1605),
        horsemodel = 'a_c_horse_dutchwarmblood_chocolateroan',
        horseprice = 250,
        horsename = 'Chocolate Dutch Warmblood',
        stableid = 'valentine'
    },

    -- colter
    {
        horsecoords = vector4(-1341.4624, 2400.6799, 306.9836, 243.5384),
        horsemodel = 'a_c_horse_gypsycob_splashedpiebald',
        horseprice = 950,
        horsename = 'Gypsy Cob Splashed Piebald',
        stableid = 'colter'
    },
    -- vanhorn
    {
        horsecoords = vector4(2961.36, 801.11, 51.5, 177.97),
        horsemodel = 'a_c_horse_kladruber_black',
        horseprice = 150,
        horsename = 'Kladruber Black',
        stableid = 'vanhorn'
    },
    {
        horsecoords = vector4(2968.1147, 796.6931, 51.4026, 264.8413),
        horsemodel = 'a_c_horse_hungarianhalfbred_liverchestnut',
        horseprice = 300,
        horsename = 'Hungarian Half-bred Liver Chestnut',
        stableid = 'vanhorn'
    },
    -- saintdenis
    {
        horsecoords = vector4(2508.99, -1452.45, 46.42, 90.00),
        horsemodel = 'a_c_horse_tennesseewalker_chestnut',
        horseprice = 60,
        horsename = 'Tennessee Walker Chestnut',
        stableid = 'saintdenis'
    },
    -- rhodes
    {
        horsecoords = vector4(1209.2368, -192.9376, 101.3839, 192.3010),
        horsemodel = 'a_c_horse_morgan_flaxenchestnut',
        horseprice = 55,
        horsename = 'Morgan Flaxen Chestnut',
        stableid = 'rhodes'
    },
    -- strawberry
    {
        horsecoords = vector4(-1821.0715, -561.6779, 156.0577, 75.8207),
        horsemodel = 'a_c_horse_arabian_white',
        horseprice = 1200,
        horsename = 'Arabian White',
        stableid = 'strawberry'
    },
    -- blackwater
    {
        horsecoords = vector4(-873.5551, -1366.1289, 43.5308, 265.0755),
        horsemodel = 'a_c_horse_thoroughbred_dapplegrey',
        horseprice = 130,
        horsename = 'Thoroughbred Dapple Grey',
        stableid = 'blackwater'
    },
    -- tumbleweed
    {
        horsecoords = vector4(-5519.5239, -3044.8074, -2.3877, 85.0038),
        horsemodel = 'a_c_horse_mustang_wildbay',
        horseprice = 130,
        horsename = 'Mustang Wild Bay',
        stableid = 'tumbleweed'
    },
}


Config.HorsesCFG = {
    ["American Paint horse"] = {
        {
            horsemodel = 'A_C_Horse_AmericanPaint_Greyovero',
            horseprice = 150,
            horsename = 'Greyovero',
        },
        {
            horsemodel = 'A_C_Horse_AmericanPaint_Tobiano1',
            horseprice = 150,
            horsename = 'Tobiano White',
        },
        {
            horsemodel = 'A_C_Horse_AmericanPaint_Tobiano',
            horseprice = 150,
            horsename = 'Tobiano',
        },
        {
            horsemodel = 'A_C_Horse_AmericanPaint_Overo',
            horseprice = 150,
            horsename = 'Overo',
        },
        {
            horsemodel = 'A_C_Horse_AmericanPaint_SplashedWhite',
            horseprice = 150,
            horsename = 'Splash White',
        },
    },
    ["Gypsy cob"] = {
        {
            horsemodel = 'a_c_horse_gypsycob_palominoblagdon',
            horseprice = 200,
            horsename = 'Palomino Blagdon',
        },
        {
            horsemodel = 'a_c_horse_gypsycob_piebald',
            horseprice = 200,
            horsename = 'Piebald',
        },
        {
            horsemodel = 'a_c_horse_gypsycob_splashedbay',
            horseprice = 200,
            horsename = 'Splashed Bay',
        },
        {
            horsemodel = 'a_c_horse_gypsycob_splashedpiebald',
            horseprice = 200,
            horsename = 'Splashed Piebald',
        },
        {
            horsemodel = 'a_c_horse_gypsycob_skewbald',
            horseprice = 200,
            horsename = 'Skewbald',
        },
        {
            horsemodel = 'a_c_horse_gypsycob_whiteblagdon',
            horseprice = 200,
            horsename = 'White Blagdon',
        },
    },
    ["American standard"] = {
        {
            horsemodel = 'A_C_Horse_AmericanStandardbred_Black',
            horseprice = 200,
            horsename = 'Black',
        },
        {
            horsemodel = 'A_C_Horse_AmericanStandardbred_Buckskin',
            horseprice = 200,
            horsename = 'Buck Skin',
        },
        {
            horsemodel = 'A_C_Horse_AmericanStandardbred_PalominoDapple',
            horseprice = 200,
            horsename = 'Palomino Dapple',
        },
        {
            horsemodel = 'A_C_Horse_AmericanStandardbred_SilverTailBuckskin',
            horseprice = 200,
            horsename = 'Silver Tail Buck Skin',
        },
        {
            horsemodel = 'a_c_horse_americanstandardbred_lightbuckskin',
            horseprice = 200,
            horsename = 'Light buck skin',
        },
    },
    ["Andalusian"] = {
        {
            horsemodel = 'A_C_Horse_Andalusian_DarkBay',
            horseprice = 200,
            horsename = 'Dark Bay',
        },
        {
            horsemodel = 'A_C_Horse_Andalusian_Perlino',
            horseprice = 200,
            horsename = 'Perlino',
        },
        {
            horsemodel = 'A_C_Horse_Andalusian_RoseGray',
            horseprice = 200,
            horsename = 'Rose Gray',
        },

    },
    ["Appaloosa"] = {
        {
            horsemodel = 'A_C_Horse_Appaloosa_BlackSnowflake',
            horseprice = 200,
            horsename = 'Black Snow flake',
        },
        {
            horsemodel = 'A_C_Horse_Appaloosa_Blanket',
            horseprice = 200,
            horsename = 'Blanket',
        },
        {
            horsemodel = 'A_C_Horse_Appaloosa_BrownLeopard',
            horseprice = 200,
            horsename = 'Brown Leopard',
        },
        {
            horsemodel = 'A_C_Horse_Appaloosa_FewSpotted_PC',
            horseprice = 200,
            horsename = 'FewSpotted',
        },
        {
            horsemodel = 'A_C_Horse_Appaloosa_Leopard',
            horseprice = 200,
            horsename = 'Leopard',
        },
        {
            horsemodel = 'A_C_Horse_Appaloosa_LeopardBlanket',
            horseprice = 200,
            horsename = 'Leopard Blanket',
        },

    },
    ["Arabian"] = {
        {
            horsemodel = 'A_C_Horse_Arabian_Black',
            horseprice = 200,
            horsename = 'Black',
        },
        {
            horsemodel = 'A_C_Horse_Arabian_White2',
            horseprice = 200,
            horsename = 'Bay Arab',
        },
        {
            horsemodel = 'A_C_Horse_Arabian_Grey',
            horseprice = 200,
            horsename = 'Grey',
        },
        {
            horsemodel = 'A_C_Horse_Arabian_RedChestnut',
            horseprice = 200,
            horsename = 'Red White Chestnut',
        },
        {
            horsemodel = 'A_C_Horse_Arabian_RedChestnut_PC',
            horseprice = 200,
            horsename = 'Red Chestnut',
        },
        {
            horsemodel = 'A_C_Horse_Arabian_RoseGreyBay',
            horseprice = 200,
            horsename = 'Rose Grey Bay',
        },
        {
            horsemodel = 'A_C_Horse_Arabian_WarpedBrindle_PC',
            horseprice = 200,
            horsename = 'Warped Brindle',
        },
        {
            horsemodel = 'A_C_Horse_Arabian_White',
            horseprice = 200,
            horsename = 'White',
        },
    },
}
