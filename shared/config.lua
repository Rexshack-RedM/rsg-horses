Config = {}

-- debug
Config.Debug = false

-- horse inventory hotkey, please refer to '[framework]/rsg-core/shared/keybinds.lua' for complete list of hotkeys
Config.HorseInvKey = 0x760A9C6F -- G

-- horse inventory
Config.HorseInvWeight = 15000
Config.HorseInvSlots = 20

-- horse inventory weight by level (horse trainer)
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

-- horse health/stamina/ability/speed/acceleration levels (horse trainer)
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

-- player feed horse settings
Config.FeedCarrotHealth = 10 -- amount of health increase when you feed your horse a carrot
Config.FeedCarrotStamina = 10 -- amount of stamina increase when you feed your horse a carrot
Config.FeedSugarCubeHealth = 25 -- amount of health increase when you feed your horse a sugarcube
Config.FeedSugarCubeStamina = 25 -- amount of stamina increase when you feed your horse a sugarcube

-- horse bonding settings
Config.MaxBondingLevel = 5000

-- config blips
Config.Blip = {
    blipName = 'Horse Stable', -- Config.Blip.blipName
    blipSprite = 'blip_shop_horse', -- Config.Blip.blipSprite
    blipScale = 0.1 -- Config.Blip.blipScale
}

-- stable zone settings
Config.StableZones = { 
    [1] = {
        zones = { -- valentine
            vector2(-351.95422363281, 765.86352539063),
            vector2(-357.52621459961, 802.44140625),
            vector2(-381.51461791992, 801.77264404297),
            vector2(-381.98571777344, 762.39996337891)
        },
        name = "valentine",
        minZ = 115.68551635742,
        maxZ = 116.26064300537
    },
    [2] = {
        zones = { -- rhodes
            vector2(1219.2058105469, -178.54296875),
            vector2(1187.3292236328, -191.03520202637),
            vector2(1165.1896972656, -212.90550231934),
            vector2(1175.7316894531, -242.43215942383),
            vector2(1235.4838867188, -223.5404510498)
        },
        name = "rhodes",
        minZ = 98.466262817383,
        maxZ = 101.29354858398
    },
    [3] = {
        zones = { -- strawberry
            vector2(-1815.6284179688, -592.89923095703),
            vector2(-1800.5074462891, -544.78729248047),
            vector2(-1818.9364013672, -540.58422851563),
            vector2(-1831.2164306641, -548.20263671875),
            vector2(-1843.1755371094, -583.43347167969)
        },
        name = "strawberry",
        minZ = 155.25595092773,
        maxZ = 157.08734130859
    },
    [4] = {
        zones = { -- blackwater
            vector2(-853.02996826172, -1355.8588867188),
            vector2(-883.69805908203, -1356.0323486328),
            vector2(-883.3671875, -1377.3862304688),
            vector2(-869.95574951172, -1381.4445800781),
            vector2(-852.90069580078, -1381.1949462891)
        },
        name = "blackwater",
        minZ = 43.35774230957,
        maxZ = 43.785705566406
    },
    [5] = {
        zones = { -- tumbleweed
            vector2(-5508.4213867188, -3056.8959960938),
            vector2(-5509.5458984375, -3034.9086914063),
            vector2(-5519.4760742188, -3012.0825195313),
            vector2(-5552.8447265625, -3028.0861816406),
            vector2(-5550.27734375, -3058.8181152344)
        },
        name = "tumbleweed",
        minZ = -2.8395669460297,
        maxZ = -1.0039472579956
    },
    [6] = {
        zones = { -- saintdenis
            vector2(2492.3596191406, -1469.1479492188),
            vector2(2520.1884765625, -1469.4697265625),
            vector2(2520.1906738281, -1432.2353515625),
            vector2(2492.8266601563, -1431.7962646484)
        },
        name = "saintdenis",
        minZ = 46.160320281982,
        maxZ = 46.294803619385
    },
    [7] = {
        zones = { -- vanhorn
            vector2(2956.6457519531, 811.98394775391),
            vector2(2953.2971191406, 752.78448486328),
            vector2(2974.1459960938, 749.93920898438),
            vector2(3000.6635742188, 768.41748046875),
            vector2(3001.1127929688, 792.94287109375),
            vector2(2986.8193359375, 809.01385498047)
        },
        name = "vanhorn",
        minZ = 49.876262664795,
        maxZ = 51.792041778564
    },
    [8] = {
        zones = { -- colter
            vector2(-1356.1180419922, 2396.6086425781),
            vector2(-1336.0328369141, 2383.5346679688),
            vector2(-1326.0085449219, 2401.4853515625),
            vector2(-1348.6867675781, 2412.9951171875)
        },
        name = "colter",
        minZ = 49.876262664795,
        maxZ = 51.792041778564
    },
}

-- tack shop npcs
Config.TackShops = {
    ["colter"] = {
        ["coords"] = vector3(-1334.2, 2397.41, 307.21),
        ["heading"] = 67.43,
        ["model"] = `U_M_M_BwmStablehand_01`,
    },
    ["vanhorn"] = {
        ["coords"] = vector3(2968.86, 792.97, 51.4),
        ["heading"] = 128.9,
        ["model"] = `U_M_M_BwmStablehand_01`,
    },
    ["saintdenis"] = {
        ["coords"] = vector3(2512.28, -1457.33, 46.31),
        ["heading"] = 86.43,
        ["model"] = `U_M_M_BwmStablehand_01`,
    }, 
    ["rhodes"] = {
        ["coords"] = vector3(1211.55, -190.84, 101.39),
        ["heading"] = 100.22,
        ["model"] = `U_M_M_BwmStablehand_01`,
    },
    ["valentine"] = {
        ["coords"] = vector3(-363.14, 802.97, 116.22),
        ["heading"] = 287.9,
        ["model"] = `U_M_M_BwmStablehand_01`,
    },
     ["strawberry"] = {
        ["coords"] = vector3(-1817.1, -568.64, 155.98),
        ["heading"] = 254.85,
        ["model"] = `U_M_M_BwmStablehand_01`,
    },
    ["blackwater"] = {
        ["coords"] = vector3(-876.85, -1365.55, 43.53),
        ["heading"] = 275.38,
        ["model"] = `U_M_M_BwmStablehand_01`,
    },
    ["tumbleweed"] = {
        ["coords"] = vector3(-5514.81, -3040.25, -2.39),
        ["heading"] = 175.22,
        ["model"] = `U_M_M_BwmStablehand_01`,
    },
    
}

Config.ModelSpawns = {
    ["colter"] = {
        ["coords"] = vector3(-1334.2, 2397.41, 307.21),
        ["heading"] = 67.43,
        ["model"] = `U_M_M_BwmStablehand_01`,
    },
    ["vanhorn"] = {
        ["coords"] = vector3(2968.86, 792.97, 51.4),
        ["heading"] = 357.89,
        ["model"] = `U_M_M_BwmStablehand_01`,
    },
    ["saintdenis"] = {
        ["coords"] = vector3(2512.28, -1457.33, 46.31),
        ["heading"] = 86.43,
        ["model"] = `U_M_M_BwmStablehand_01`,
    },
    ["rhodes"] = {
        ["coords"] = vector3(1211.55, -190.84, 101.39),
        ["heading"] = 100.22,
        ["model"] = `U_M_M_BwmStablehand_01`,
    }, 
    ["valentine"] = {
        ["coords"] = vector3(-365.2, 791.94, 116.18),
        ["heading"] = 180.9,
        ["model"] = `U_M_M_BwmStablehand_01`,
    },
    ["strawberry"] = {
        ["coords"] = vector3(-1817.1, -568.64, 155.98),
        ["heading"] = 254.85,
        ["model"] = `U_M_M_BwmStablehand_01`,
    },
    ["blackwater"] = {
        ["coords"] = vector3(-876.85, -1365.55, 43.53),
        ["heading"] = 275.38,
        ["model"] = `U_M_M_BwmStablehand_01`,
    },
    ["tumbleweed"] = {
        ["coords"] = vector3(-5514.81, -3040.25, -2.39),
        ["heading"] = 175.22,
        ["model"] = `U_M_M_BwmStablehand_01`,
    }, 
    
}

Config.BoxZones = {
    ["colter"] = {
        [1] = {
            ["coords"] = vector3(-1342.05, 2399.79, 307.08),
            ["heading"] = 245.73,
            ["model"] = "a_c_horse_gypsycob_splashedpiebald",
            ["price"] = 650,
            ["names"] = "Splashed Pie Bald Irish Vanner",
        },
        [2] = {
            ["coords"] = vector3(-1341.15, 2401.66, 307.08),
            ["heading"] = 245.73,
            ["model"] = "a_c_horse_missourifoxtrotter_dapplegrey",
            ["price"] = 450,
            ["names"] = "Dapple Grey Fox Trotter",
        },
        [3] = {
            ["coords"] = vector3(-1339.84, 2404.34, 307.08),
            ["heading"] = 245.73,
            ["model"] = "a_c_horse_missourifoxtrotter_buckskinbrindle",
            ["price"] = 600,
            ["names"] = "Buckskin Brindle Fox Trotter",
        },
        [4] = {
            ["coords"] = vector3(-1340.76, 2402.88, 307.08),
            ["heading"] = 245.73,
            ["model"] = "a_c_horse_norfolkroadster_speckledgrey",
            ["price"] = 300,
            ["names"] = "Speckled Grey Roadster",
        },
        [5] = {
            ["coords"] = vector3(-1343.29, 2397.1, 307.08),
            ["heading"] = 245.73,
            ["model"] = "a_c_horse_norfolkroadster_spottedtricolor",
            ["price"] = 500,
            ["names"] = "Tri Color Roadster",
        },
        [6] = {
            ["coords"] = vector3(-1342.87, 2398.36, 307.08),
            ["heading"] = 245.73,
            ["model"] = "a_c_horse_breton_steelgrey",
            ["price"] = 450,
            ["names"] = "Steel Grey Breton",
        },
    },
    ["vanhorn"] = {
        [1] = {
            ["coords"] = vector3(2961.36, 801.11, 51.5),
            ["heading"] = 177.97,
            ["model"] = "a_c_horse_kladruber_black",
            ["price"] = 300,
            ["names"] = "Black Kladruber",
        },
        [2] = {
            ["coords"] = vector3(2964.53, 801.19, 51.49),
            ["heading"] = 177.97,
            ["model"] = "a_c_horse_hungarianhalfbred_liverchestnut",
            ["price"] = 400,
            ["names"] = "Liver Chestnut Hungarian Halfbred",
        },
        [3] = {
            ["coords"] = vector3(2967.34, 801.36, 51.42),
            ["heading"] = 177.97,
            ["model"] = "a_c_horse_kentuckysaddle_black",
            ["price"] = 70,
            ["names"] = "Black Kentucky Saddler",
        },
        [4] = {
            ["coords"] = vector3(2970.28, 801.52, 51.52),
            ["heading"] = 177.97,
            ["model"] = "a_c_horse_morgan_liverchestnut_pc",
            ["price"] = 70,
            ["names"] = "Liver Chestnut Morgan",
        },
        [5] = {
            ["coords"] = vector3(2973.12, 801.27, 51.52),
            ["heading"] = 177.97,
            ["model"] = "a_c_horse_thoroughbred_blackchestnut",
            ["price"] = 300,
            ["names"] = "Black Chestnut Thoroughbred",
        },
        [6] = {
            ["coords"] = vector3(2972.74, 792.47, 51.5),
            ["heading"] = 3.97,
            ["model"] = "a_c_horse_turkoman_silver",
            ["price"] = 450,
            ["names"] = "Silver Turkoman",
        },
    },
    ["saintdenis"] = {
        [1] = {
            ["coords"] = vector3(2508.99, -1452.45, 46.42),
            ["heading"] = 90.00,
            ["model"] = "a_c_horse_tennesseewalker_chestnut",
            ["price"] = 55,
            ["names"] = "Chestnut Tennessee Walker",
        },
        [2] = {
            ["coords"] = vector3(2508.98, -1449.32, 46.4),
            ["heading"] = 90.00,
            ["model"] = "a_c_horse_tennesseewalker_goldpalomino_pc",
            ["price"] = 75,
            ["names"] = "Gold Palomino Tennessee Walker",
        },
        [3] = {
            ["coords"] = vector3(2508.71, -1446.48, 46.42),
            ["heading"] = 90.00,
            ["model"] = "a_c_horse_americanstandardbred_lightbuckskin",
            ["price"] = 150,
            ["names"] = "Light Buckskin American Standardbred",
        },
        [4] = {
            ["coords"] = vector3(2508.92, -1444.31, 46.43),
            ["heading"] = 90.00,
            ["model"] = "a_c_horse_tennesseewalker_flaxenroan",
            ["price"] = 80,
            ["names"] = "Flaxen Roan Tennessee Walker",
        },
        [5] = {
            ["coords"] = vector3(2508.99, -1438.3, 46.44),
            ["heading"] = 90.00,
            ["model"] = "a_c_horse_tennesseewalker_redroan",
            ["price"] = 60,
            ["names"] = "Red Roan Tennessee Walker",
        },
        [6] = {
            ["coords"] = vector3(2508.62, -1441.26, 46.51),
            ["heading"] = 90.00,
            ["model"] = "a_c_horse_kladruber_white",
            ["price"] = 300,
            ["names"] = "White Kladruber",
        },
    },
    ["rhodes"] = {
        [1] = {
            ["coords"] = vector3(1204.03, -189.56, 101.48),
            ["heading"] = 281.00,
            ["model"] = "a_c_horse_morgan_flaxenchestnut",
            ["price"] = 60,
            ["names"] = "Flaxen Chestnut Morgan",
        },
        [2] = {
            ["coords"] = vector3(1204.99, -192.58, 101.49),
            ["heading"] = 281.00,
            ["model"] = "a_c_horse_kladruber_dapplerosegrey",
            ["price"] = 600,
            ["names"] = "Dapple Rose Grey Kladruber",
        },
        [3] = {
            ["coords"] = vector3(1205.33, -195.26, 101.39),
            ["heading"] = 281.00,
            ["model"] = "a_c_horse_kladruber_cremello",
            ["price"] = 550,
            ["names"] = "Cremello Kladruber",
        },
        [4] = {
            ["coords"] = vector3(1206.23, -198.26, 101.49),
            ["heading"] = 281.00,
            ["model"] = "a_c_horse_breton_sorrel",
            ["price"] = 250,
            ["names"] = "Sorrel Breton",
        },
        [5] = {
            ["coords"] = vector3(1214.58, -195.64, 101.38),
            ["heading"] = 110.00,
            ["model"] = "a_c_horse_ardennes_irongreyroan",
            ["price"] = 450,
            ["names"] = "Iron Grey Roan Ardennes",
        },
        [6] = {
            ["coords"] = vector3(1213.95, -192.89, 101.45),
            ["heading"] = 110.00,
            ["model"] = "a_c_horse_shire_lightgrey",
            ["price"] = 60,
            ["names"] = "Light Grey Shire",
        },
    },
    ["valentine"] = {

        [1] = {
            ["coords"] = vector3(-357.77, 771.73, 116.52),
            ["heading"] = 5.00,
            ["model"] = "a_c_horse_dutchwarmblood_chocolateroan",
            ["price"] = 250,
            ["names"] = "Chocolate Roan Warmblood",
        },
        [2] = {
            ["coords"] = vector3(-362.45, 771.06, 116.53),
            ["heading"] = 5.00,
            ["model"] = "a_c_horse_dutchwarmblood_sootybuckskin",
            ["price"] = 150,
            ["names"] = "Sooty Buckskin Warmblood",
        },
        [3] = {
            ["coords"] = vector3(-368.03, 770.17, 116.53),
            ["heading"] = 5.00,
            ["model"] = "a_c_horse_kentuckysaddle_silverbay",
            ["price"] = 55,
            ["names"] = "Silver Bay Kentucky Saddle",
        },
        [4] = {
            ["coords"] = vector3(-372.58, 769.81, 116.43),
            ["heading"] = 5.00,
            ["model"] = "a_c_horse_kentuckysaddle_buttermilkbuckskin_pc",
            ["price"] = 70,
            ["names"] = "Buttermilk Buckskin Kentucky Saddler",
        },
        [5] = {
            ["coords"] = vector3(-377.73, 769.48, 116.3),
            ["heading"] = 5.00,
            ["model"] = "a_c_horse_morgan_bay",
            ["price"] = 50,
            ["names"] = "Bay Morgan",
        },
        [6] = {
            ["coords"] = vector3(-363.47, 782.77, 116.17),
            ["heading"] = 5.00,
            ["model"] = "a_c_horse_morgan_bayroan",
            ["price"] = 55,
            ["names"] = "Bay Roan Morgan",
        },
        [7] = {
            ["coords"] = vector3(-366.36, 782.3, 116.15),
            ["heading"] = 5.00,
            ["model"] = "a_c_horse_mustang_reddunovero",
            ["price"] = 500,
            ["names"] = "Red Overo Mustang",
        },
        [8] = {
            ["coords"] = vector3(-369.15, 782.53, 116.16),
            ["heading"] = 5.00,
            ["model"] = "a_c_horse_suffolkpunch_sorrel",
            ["price"] = 60,
            ["names"] = "Sorrel Suffolk Punch",
        },
        [9] = {
            ["coords"] = vector3(-372.02, 781.94, 116.17),
            ["heading"] = 5.00,
            ["model"] = "a_c_horse_turkoman_darkbay",
            ["price"] = 350,
            ["names"] = "Dark Bay Turkoman",
        },
        [10] = {
            ["coords"] = vector3(-374.94, 782.11, 116.19),
            ["heading"] = 5.00,
            ["model"] = "a_c_horse_turkoman_gold",
            ["price"] = 500,
            ["names"] = "Gold Turkoman",
        },
        [11] = {
            ["coords"] = vector3(-375.38, 790.93, 116.14),
            ["heading"] = 179.00,
            ["model"] = "a_c_horse_andalusian_rosegray",
            ["price"] = 250,
            ["names"] = "Rose Gray Andalusian",
        },
        [12] = {
            ["coords"] = vector3(-372.33, 791.02, 116.14),
            ["heading"] = 179.00,
            ["model"] = "a_c_horse_breton_redroan",
            ["price"] = 250,
            ["names"] = "Red Roan Breton",
        },
        [13] = {
            ["coords"] = vector3(-369.49, 791.53, 116.35),
            ["heading"] = 179.00,
            ["model"] = "a_c_horse_americanpaint_tobiano",
            ["price"] = 60,
            ["names"] = "American Paint Tobiano",
        },
    },
    ["strawberry"] = {
        [1] = {
            ["coords"] = vector3(-1814.43, -558.66, 156.17),
            ["heading"] = 160.00,
            ["model"] = "a_c_horse_arabian_white",
            ["price"] = 750,
            ["names"] = "White Arabian",
        },
        [2] = {
            ["coords"] = vector3(-1817.16, -558.1, 156.18),
            ["heading"] = 160.00,
            ["model"] = "a_c_horse_belgian_blondchestnut",
            ["price"] = 60,
            ["names"] = "Blonde Chestnut Belgian",
        },
        [3] = {
            ["coords"] = vector3(-1820.25, -557.28, 156.13),
            ["heading"] = 160.00,
            ["model"] = "a_c_horse_gypsycob_whiteblagdon",
            ["price"] = 300,
            ["names"] = "White Blagdon Irish Vanner",
        },
        [4] = {
            ["coords"] = vector3(-1822.8, -556.54, 156.18),
            ["heading"] = 160.00,
            ["model"] = "a_c_horse_gypsycob_skewbald",
            ["price"] = 500,
            ["names"] = "Skewbald Irish Vanner",
        },
        [5] = {
            ["coords"] = vector3(-1825.12, -564.83, 156.06),
            ["heading"] = 344.00,
            ["model"] = "a_c_horse_americanpaint_splashedwhite",
            ["price"] = 100,
            ["names"] = "Splashed White American Paint",
        },
        [6] = {
            ["coords"] = vector3(-1822.42, -565.68, 156.12),
            ["heading"] = 344.00,
            ["model"] = "a_c_horse_norfolkroadster_piebaldroan",
            ["price"] = 400,
            ["names"] = "Piebald Roan Roadster",
        },
    },
    ["blackwater"] = {
        [1] = {
            ["coords"] = vector3(-866.46, -1370.88, 43.68),
            ["heading"] = 90.00,
            ["model"] = "a_c_horse_thoroughbred_dapplegrey",
            ["price"] = 130,
            ["names"] = "Dapple Grey Thoroughbred",
        },
        [2] = {
            ["coords"] = vector3(-863.67, -1370.8, 43.71),
            ["heading"] = 90.00,
            ["model"] = "a_c_horse_mustang_grullodun",
            ["price"] = 200,
            ["names"] = "Grullo Dun Mustang",
        },
        [3] = {
            ["coords"] = vector3(-860.54, -1371.12, 43.71),
            ["heading"] = 90.00,
            ["model"] = "a_c_horse_nokota_whiteroan",
            ["price"] = 200,
            ["names"] = "White Roan Nokota",
        },
        [4] = {
            ["coords"] = vector3(-859.52, -1361.72, 43.66),
            ["heading"] = 90.00,
            ["model"] = "a_c_horse_nokota_blueroan",
            ["price"] = 250,
            ["names"] = "Blue Roan Nokota",
        },
        [5] = {
            ["coords"] = vector3(-863.33, -1361.55, 43.65),
            ["heading"] = 90.00,
            ["model"] = "a_c_horse_kentuckysaddle_grey",
            ["price"] = 55,
            ["names"] = "Grey Kentucky Saddler",
        },
        [6] = {
            ["coords"] = vector3(-867.02, -1361.5, 43.66),
            ["heading"] = 90.00,
            ["model"] = "a_c_horse_kentuckysaddle_chestnutpinto",
            ["price"] = 65,
            ["names"] = "Chestnut Pinto Kentucky Saddler",
        },
    },
    ["tumbleweed"] = {
        [1] = {
            ["coords"] = vector3(-5513.65, -3049.7, -2.39),
            ["heading"] = 5.00,
            ["model"] = "a_c_horse_mustang_wildbay",
            ["price"] = 200,
            ["names"] = "Wild Bay Mustang",
        },
        [2] = {
            ["coords"] = vector3(-5516.52, -3049.36, -2.39),
            ["heading"] = 5.00,
            ["model"] = "a_c_horse_mustang_goldendun",
            ["price"] = 350,
            ["names"] = "Golden Dun Mustang",
        },
        [3] = {
            ["coords"] = vector3(-5519.14, -3049.17, -2.39),
            ["heading"] = 5.00,
            ["model"] = "a_c_horse_missourifoxtrotter_silverdapplepinto",
            ["price"] = 700,
            ["names"] = "Silver Dapple Pinto Missouri Fox Trotter",
        },
        [4] = {
            ["coords"] = vector3(-5522.1, -3049.14, -2.36),
            ["heading"] = 5.00,
            ["model"] = "a_c_horse_appaloosa_blanket",
            ["price"] = 100,
            ["names"] = "Blanket Appaloosa",
        },
        [5] = {
            ["coords"] = vector3(-5525.21, -3049.12, -2.39),
            ["heading"] = 5.00,
            ["model"] = "a_c_horse_appaloosa_brownleopard",
            ["price"] = 250,
            ["names"] = "Brown Leopard Appaloosa",
        },
        [6] = {
            ["coords"] = vector3(-5525.09, -3039.77, -2.32),
            ["heading"] = 180.00,
            ["model"] = "a_c_horse_americanstandardbred_palominodapple",
            ["price"] = 130,
            ["names"] = "Palomino Dapple American Standardbred",
        },
        [7] = {
            ["coords"] = vector3(-5522.55, -3039.45, -2.18),
            ["heading"] = 180.00,
            ["model"] = "a_c_horse_americanstandardbred_silvertailbuckskin",
            ["price"] = 250,
            ["names"] = "Silver Tail Buckstin American Standardbred",
        },
        [8] = {
            ["coords"] = vector3(-5519.27, -3039.19, -2.21),
            ["heading"] = 180.00,
            ["model"] = "a_c_horse_belgian_mealychestnut",
            ["price"] = 60,
            ["names"] = "Mealy Chestnut Belgian",
        },
        [9] = {
            ["coords"] = vector3(-5534.55, -3051.61, -1.42),
            ["heading"] = 5.00,
            ["model"] = "a_c_horse_breton_grullodun",
            ["price"] = 500,
            ["names"] = "Grullo Dun Breton",
        },
        [10] = {
            ["coords"] = vector3(-5538.84, -3052.61, -1.11),
            ["heading"] = 5.00,
            ["model"] = "a_c_horse_criollo_sorrelovero",
            ["price"] = 450,
            ["names"] = "Sorrel Overo Criollo",
        },
        [11] = {
            ["coords"] = vector3(-5543.72, -3053.49, -0.89),
            ["heading"] = 5.00,
            ["model"] = "a_c_horse_criollo_dun",
            ["price"] = 300,
            ["names"] = "Dun Criollo",
        },
    },
}
