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
        horsecoords = vector4(-357.77, 771.73, 116.52, 5.00),
        horsemodel = 'a_c_horse_dutchwarmblood_chocolateroan',
        horseprice = 250,
        horsename = 'Chocolate Dutch Warmblood',
        stableid = 'valentine'
    },
    {
        horsecoords = vector4(-362.45, 771.06, 116.53, 5.00),
        horsemodel = 'a_c_horse_dutchwarmblood_sootybuckskin',
        horseprice = 250,
        horsename = 'Sooty Dutch Warmblood',
        stableid = 'valentine'
    },
    {
        horsecoords = vector4(-368.03, 770.17, 116.53, 5.00),
        horsemodel = 'a_c_horse_kentuckysaddle_silverbay',
        horseprice = 50,
        horsename = 'Silver Bay Kentucky Saddler',
        stableid = 'valentine'
    },
    {
        horsecoords = vector4(-372.58, 769.81, 116.43, 5.00),
        horsemodel = 'a_c_horse_kentuckysaddle_buttermilkbuckskin_pc',
        horseprice = 120,
        horsename = 'Buttermilk Buckskin Kentucky Saddler',
        stableid = 'valentine'
    },
    {
        horsecoords = vector4(-377.73, 769.48, 116.3, 5.00),
        horsemodel = 'a_c_horse_morgan_bay',
        horseprice = 55,
        horsename = 'Morgan Bay',
        stableid = 'valentine'
    },
    {
        horsecoords = vector4(-363.47, 782.77, 116.17, 5.00),
        horsemodel = 'a_c_horse_morgan_bayroan',
        horseprice = 55,
        horsename = 'Morgan Bay Roan',
        stableid = 'valentine'
    },
    {
        horsecoords = vector4(-366.36, 782.3, 116.15, 5.00),
        horsemodel = 'a_c_horse_mustang_reddunovero',
        horseprice = 500,
        horsename = 'Mustang Red Dun Overo',
        stableid = 'valentine'
    },
    {
        horsecoords = vector4(-369.15, 782.53, 116.16, 5.00),
        horsemodel = 'a_c_horse_suffolkpunch_sorrel',
        horseprice = 120,
        horsename = 'Suffolk Punch Sorrel',
        stableid = 'valentine'
    },
    {
        horsecoords = vector4(-372.02, 781.94, 116.17, 5.00),
        horsemodel = 'a_c_horse_turkoman_darkbay',
        horseprice = 925,
        horsename = 'Turkoman Dark Bay',
        stableid = 'valentine'
    },
    {
        horsecoords = vector4(-374.94, 782.11, 116.19, 5.00),
        horsemodel = 'a_c_horse_turkoman_gold',
        horseprice = 950,
        horsename = 'Turkoman Gold',
        stableid = 'valentine'
    },
    {
        horsecoords = vector4(-375.38, 790.93, 116.14, 179.00),
        horsemodel = 'a_c_horse_andalusian_rosegray',
        horseprice = 440,
        horsename = 'Andalusian Rose Gray',
        stableid = 'valentine'
    },
    {
        horsecoords = vector4(-372.33, 791.02, 116.14, 179.00),
        horsemodel = 'a_c_horse_breton_redroan',
        horseprice = 150,
        horsename = 'Breton Red Roan',
        stableid = 'valentine'
    },
    {
        horsecoords = vector4(-369.49, 791.53, 116.35, 179.00),
        horsemodel = 'a_c_horse_americanpaint_tobiano',
        horseprice = 130,
        horsename = 'American Paint Tobiano',
        stableid = 'valentine'
    },
    -- colter
    {
        horsecoords = vector4(-1342.05, 2399.79, 307.08, 245.73),
        horsemodel = 'a_c_horse_gypsycob_splashedpiebald',
        horseprice = 950,
        horsename = 'Gypsy Cob Splashed Piebald',
        stableid = 'colter'
    },
    {
        horsecoords = vector4(-1341.15, 2401.66, 307.08, 245.73),
        horsemodel = 'a_c_horse_missourifoxtrotter_dapplegrey',
        horseprice = 1125,
        horsename = 'Missouri Fox Trotter Dapple Gray',
        stableid = 'colter'
    },
    {
        horsecoords = vector4(-1339.84, 2404.34, 307.08, 245.73),
        horsemodel = 'a_c_horse_missourifoxtrotter_buckskinbrindle',
        horseprice = 1125,
        horsename = 'Missouri Fox Trotter Buckskin Brindle',
        stableid = 'colter'
    },
    {
        horsecoords = vector4(-1340.76, 2402.88, 307.08, 245.73),
        horsemodel = 'a_c_horse_norfolkroadster_speckledgrey',
        horseprice = 150,
        horsename = 'Norfolk Roadster Speckled Gray',
        stableid = 'colter'
    },
    {
        horsecoords = vector4(-1343.29, 2397.1, 307.08, 245.73),
        horsemodel = 'a_c_horse_norfolkroadster_spottedtricolor',
        horseprice = 950,
        horsename = 'Norfolk Roadster Spotted Tricolor',
        stableid = 'colter'
    },
    {
        horsecoords = vector4(-1342.87, 2398.36, 307.08, 245.73),
        horsemodel = 'a_c_horse_breton_steelgrey',
        horseprice = 950,
        horsename = 'Breton Steel Grey',
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
        horsecoords = vector4(2964.53, 801.19, 51.49, 177.97),
        horsemodel = 'a_c_horse_hungarianhalfbred_liverchestnut',
        horseprice = 300,
        horsename = 'Hungarian Half-bred Liver Chestnut',
        stableid = 'vanhorn'
    },
    {
        horsecoords = vector4(2967.34, 801.36, 51.42, 177.97),
        horsemodel = 'a_c_horse_kentuckysaddle_black',
        horseprice = 50,
        horsename = 'Kentucky Saddler Black',
        stableid = 'vanhorn'
    },
    {
        horsecoords = vector4(2970.28, 801.52, 51.52, 177.97),
        horsemodel = 'a_c_horse_morgan_liverchestnut_pc',
        horseprice = 27.50,
        horsename = 'Morgan Liver Chestnut',
        stableid = 'vanhorn',
    },
    {
        horsecoords = vector4(2973.12, 801.27, 51.52, 177.97),
        horsemodel = 'a_c_horse_thoroughbred_blackchestnut',
        horseprice = 450,
        horsename = 'Thoroughbred Black Chestnut',
        stableid = 'vanhorn'
    },
    {
        horsecoords = vector4(2972.74, 792.47, 51.5, 3.97),
        horsemodel = 'a_c_horse_turkoman_silver',
        horseprice = 950,
        horsename = 'Thoroughbred Silver',
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
    {
        horsecoords = vector4(2508.98, -1449.32, 46.4, 90.00),
        horsemodel = 'a_c_horse_tennesseewalker_goldpalomino_pc',
        horseprice = 60,
        horsename = 'Tennessee Walker Gold Palomino',
        stableid = 'saintdenis'
    },
    {
        horsecoords = vector4(2508.71, -1446.48, 46.42, 90.00),
        horsemodel = 'a_c_horse_americanstandardbred_lightbuckskin',
        horseprice = 350,
        horsename = 'American Standardbred Light Buckskin',
        stableid = 'saintdenis'
    },
    {
        horsecoords = vector4(2508.92, -1444.31, 46.43, 90.00),
        horsemodel = 'a_c_horse_tennesseewalker_flaxenroan',
        horseprice = 150,
        horsename = 'Tennessee Walker Flaxen Roan',
        stableid = 'saintdenis'
    },
    {
        horsecoords = vector4(2508.99, -1438.3, 46.44, 90.00),
        horsemodel = 'a_c_horse_tennesseewalker_redroan',
        horseprice = 60,
        horsename = 'Tennessee Walker Red Roan',
        stableid = 'saintdenis'
    },
    {
        horsecoords = vector4(2508.62, -1441.26, 46.51, 90.00),
        horsemodel = 'a_c_horse_kladruber_white',
        horseprice = 150,
        horsename = 'Kladruber White',
        stableid = 'saintdenis'
    },
    -- rhodes
    {
        horsecoords = vector4(1204.03, -189.56, 101.48, 281.00),
        horsemodel = 'a_c_horse_morgan_flaxenchestnut',
        horseprice = 55,
        horsename = 'Morgan Flaxen Chestnut',
        stableid = 'rhodes'
    },
    {
        horsecoords = vector4(1204.99, -192.58, 101.49, 281.00),
        horsemodel = 'a_c_horse_kladruber_dapplerosegrey',
        horseprice = 950,
        horsename = 'Kladruber Dapple Rose Grey',
        stableid = 'rhodes'
    },
    {
        horsecoords = vector4(1205.33, -195.26, 101.39, 281.00),
        horsemodel = 'a_c_horse_kladruber_cremello',
        horseprice = 550,
        horsename = 'Kladruber Cremello',
        stableid = 'rhodes'
    },
    {
        horsecoords = vector4(1206.23, -198.26, 101.49, 281.00),
        horsemodel = 'a_c_horse_breton_sorrel',
        horseprice = 150,
        horsename = 'Breton Sorrel',
        stableid = 'rhodes'
    },
    {
        horsecoords = vector4(1214.58, -195.64, 101.38, 110.00),
        horsemodel = 'a_c_horse_ardennes_irongreyroan',
        horseprice = 450,
        horsename = 'Ardennes Iron Grey',
        stableid = 'rhodes'
    },
    {
        horsecoords = vector4(1213.95, -192.89, 101.45, 110.00),
        horsemodel = 'a_c_horse_shire_lightgrey',
        horseprice = 120,
        horsename = 'Shire Light Grey',
        stableid = 'rhodes'
    },
    -- strawberry
    {
        horsecoords = vector4(-1814.43, -558.66, 156.17, 160.00),
        horsemodel = 'a_c_horse_arabian_white',
        horseprice = 1200,
        horsename = 'Arabian White',
        stableid = 'strawberry'
    },
    {
        horsecoords = vector4(-1817.16, -558.1, 156.18, 160.00),
        horsemodel = 'a_c_horse_belgian_blondchestnut',
        horseprice = 120,
        horsename = 'Belgian Draft Horse Blond Chestnut',
        stableid = 'strawberry'
    },
    {
        horsecoords = vector4(-1820.25, -557.28, 156.13, 160.00),
        horsemodel = 'a_c_horse_gypsycob_whiteblagdon',
        horseprice = 150,
        horsename = 'Gypsy Cob White Blagdon',
        stableid = 'strawberry'
    },
    {
        horsecoords = vector4(-1822.8, -556.54, 156.18, 160.00),
        horsemodel = 'a_c_horse_gypsycob_skewbald',
        horseprice = 550,
        horsename = 'Gypsy Cob Skewbald',
        stableid = 'strawberry'
    },
    {
        horsecoords = vector4(-1825.12, -564.83, 156.06, 344.00),
        horsemodel = 'a_c_horse_americanpaint_splashedwhite',
        horseprice = 140,
        horsename = 'American Paint Splashed White',
        stableid = 'strawberry'
    },
    {
        horsecoords = vector4(-1822.42, -565.68, 156.12, 344.00),
        horsemodel = 'a_c_horse_norfolkroadster_piebaldroan',
        horseprice = 400,
        horsename = 'Norfolk Roadster Piebald Roan',
        stableid = 'strawberry'
    },
    -- blackwater
    {
        horsecoords = vector4(-866.46, -1370.88, 43.68, 90.00),
        horsemodel = 'a_c_horse_thoroughbred_dapplegrey',
        horseprice = 130,
        horsename = 'Thoroughbred Dapple Grey',
        stableid = 'blackwater'
    },
    {
        horsecoords = vector4(-863.67, -1370.8, 43.71, 90.00),
        horsemodel = 'a_c_horse_mustang_grullodun',
        horseprice = 130,
        horsename = 'Mustang Grullo Dun',
        stableid = 'blackwater'
    },
    {
        horsecoords = vector4(-860.54, -1371.12, 43.71, 90.00),
        horsemodel = 'a_c_horse_nokota_whiteroan',
        horseprice = 130,
        horsename = 'Nokota White Roan',
        stableid = 'blackwater'
    },
    {
        horsecoords = vector4(-859.52, -1361.72, 43.66, 90.00),
        horsemodel = 'a_c_horse_nokota_blueroan',
        horseprice = 130,
        horsename = 'Nokota Blue Roan',
        stableid = 'blackwater'
    },
    {
        horsecoords = vector4(-863.33, -1361.55, 43.65, 90.00),
        horsemodel = 'a_c_horse_kentuckysaddle_grey',
        horseprice = 50,
        horsename = 'Kentucky Saddler Grey',
        stableid = 'blackwater'
    },
    {
        horsecoords = vector4(-867.02, -1361.5, 43.66, 90.00),
        horsemodel = 'a_c_horse_kentuckysaddle_chestnutpinto',
        horseprice = 50,
        horsename = 'Kentucky Saddler Chestnut Pinto',
        stableid = 'blackwater'
    },
    -- tumbleweed
    {
        horsecoords = vector4(-5513.65, -3049.7, -2.39, 5.00),
        horsemodel = 'a_c_horse_mustang_wildbay',
        horseprice = 130,
        horsename = 'Mustang Wild Bay',
        stableid = 'tumbleweed'
    },
    {
        horsecoords = vector4(-5516.52, -3049.36, -2.39, 5.00),
        horsemodel = 'a_c_horse_mustang_goldendun',
        horseprice = 500,
        horsename = 'Mustang Golden Dun',
        stableid = 'tumbleweed'
    },
    {
        horsecoords = vector4(-5519.14, -3049.17, -2.39, 5.00),
        horsemodel = 'a_c_horse_missourifoxtrotter_silverdapplepinto',
        horseprice = 950,
        horsename = 'Missouri Fox Trotter Silver Dapple Pinto',
        stableid = 'tumbleweed'
    },
    {
        horsecoords = vector4(-5522.1, -3049.14, -2.36, 5.00),
        horsemodel = 'a_c_horse_appaloosa_blanket',
        horseprice = 130,
        horsename = 'Appaloosa Blanket',
        stableid = 'tumbleweed'
    },
    {
        horsecoords = vector4(-5525.21, -3049.12, -2.39, 5.00),
        horsemodel = 'a_c_horse_appaloosa_brownleopard',
        horseprice = 450,
        horsename = 'Appaloosa Brown Leopard',
        stableid = 'tumbleweed'
    },
    {
        horsecoords = vector4(-5525.09, -3039.77, -2.32, 180.00),
        horsemodel = 'a_c_horse_americanstandardbred_palominodapple',
        horseprice = 150,
        horsename = 'American Standardbred Palomino Dapple',
        stableid = 'tumbleweed'
    },
    {
        horsecoords = vector4(-5522.55, -3039.45, -2.18, 180.00),
        horsemodel = 'a_c_horse_americanstandardbred_silvertailbuckskin',
        horseprice = 400,
        horsename = 'American Standardbred Silver Tail Buckskin',
        stableid = 'tumbleweed'
    },
    {
        horsecoords = vector4(-5519.27, -3039.19, -2.21, 180.00),
        horsemodel = 'a_c_horse_belgian_mealychestnut',
        horseprice = 120,
        horsename = 'Belgian Draft Horse Mealy Chestnut',
        stableid = 'tumbleweed'
    },
    {
        horsecoords = vector4(-5534.55, -3051.61, -1.42, 5.00),
        horsemodel = 'a_c_horse_breton_grullodun',
        horseprice = 550,
        horsename = 'Breton Grullo Dun',
        stableid = 'tumbleweed'
    },
    {
        horsecoords = vector4(-5538.84, -3052.61, -1.11, 5.00),
        horsemodel = 'a_c_horse_criollo_sorrelovero',
        horseprice = 550,
        horsename = 'Criollo Sorrel Overo',
        stableid = 'tumbleweed'
    },
    {
        horsecoords = vector4(-5543.72, -3053.49, -0.89, 5.00),
        horsemodel = 'a_c_horse_criollo_dun',
        horseprice = 150,
        horsename = 'Criollo Dun',
        stableid = 'tumbleweed'
    },
}
