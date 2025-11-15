Config = {}
lib.locale()

-- debug
Config.Debug = false

Config = {
    horsesShopItems ={
        { name = 'horse_brush',     amount = 10, price = 5 },
        { name = 'horse_lantern',   amount = 10, price = 10 },
        { name = 'sugarcube',       amount = 50, price = 0.05 },
        { name = 'horse_carrot',    amount = 50, price = 0.10 },
        { name = 'horse_apple',     amount = 50, price = 0.10 },
        { name = 'haysnack',        amount = 50, price = 0.25 },
        { name = 'horsemeal',       amount = 50, price = 0.50 },
        { name = 'horse_stimulant', amount = 25, price = 2 },
        { name = 'horse_reviver',   amount = 25, price = 10 }
    },
    PersistStock = false, --should stock save in database and load it after restart, to 'remember' stock value before restart
}

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
Config.EnableTarget        = true -- toggle between target and prompt
Config.TargetHelp          = false -- target help to use [L-ALT]
Config.Automount           = false -- horse automount
Config.SpawnOnRoadOnly     = false -- always spawn on road
Config.HorseInvWeight      = 16000 -- horse inventory weight
Config.HorseInvSlots       = 25 -- horse inventory slots
Config.CheckCycle          = 30 -- horse check system (mins) -- default 60
Config.StarterHorseDieAge  = 7 -- starter horse age in days till it dies (days)
Config.HorseDieAge         = 365 -- horse age in days till it dies (days)
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
Config.Level1InvSlots = 4
Config.Level2InvWeight = 6000
Config.Level2InvSlots = 6
Config.Level3InvWeight = 8000
Config.Level3InvSlots = 8
Config.Level4InvWeight = 9000
Config.Level4InvSlots = 10
Config.Level5InvWeight = 10000
Config.Level5InvSlots = 12
Config.Level6InvWeight = 12000
Config.Level6InvSlots = 14
Config.Level7InvWeight = 13000
Config.Level7InvSlots = 16
Config.Level8InvWeight = 14000
Config.Level8InvSlots = 18
Config.Level9InvWeight = 15000
Config.Level9InvSlots = 20
Config.Level10InvWeight = 16000
Config.Level10InvSlots = 25

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
    ['horse_carrot']    = { health = 10,  stamina = 10,  ismedicine = false },
    ['horse_apple']     = { health = 15,  stamina = 15,  ismedicine = false },
    ['sugarcube']       = { health = 25,  stamina = 25,  ismedicine = false },
    ['haysnack']        = { health = 50,  stamina = 25,  ismedicine = false },
    ['horsemeal']       = { health = 75,  stamina = 75,  ismedicine = false },
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