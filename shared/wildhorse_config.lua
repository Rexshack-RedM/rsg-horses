

Config.WildHorse = Config.WildHorse or {}


-- settings
Config.WildHorse.Debug = false -- kept off for clean consoles
Config.WildHorse.SellTime = 20000
Config.WildHorse.EnableCooldown = true
Config.WildHorse.Cooldown = 900 -- 15 mins cooldown by default
Config.WildHorse.Keybind = 'J'



Config.WildHorse.Blip =
{
    blipName = 'Sell Wild Horse',
    blipSprite = 'blip_shop_horse_fencing',
    blipScale = 0.2
}

Config.WildHorse.SellWildHorseLocations =
{
    {name = 'Van Horn Horse Seller', location = 'vanhorn-sellwildhorse', coords = vector3(2936.08, 575.43, 44.63), showblip = true },
	{name = 'Valentine Horse Seller', location = 'valentine-sellwildhorse', coords = vector3(-369.88, 787.02, 116.16), showblip = true },
	{name = 'Blackwater Horse Seller', location = 'Blackwater-sellwildhorse', coords = vector3(-863.92, -1366.71, 43.55), showblip = true },
}

Config.WildHorse.PaymentType = 'cash'
Config.WildHorse.SaleMultiplier = 1
Config.WildHorse.Xp = 0.05

Config.WildHorse.Horse =
{
    {
        name        = 'Donkey',
        model       = `A_C_Donkey_01`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Greyovero',
        model       = `A_C_Horse_AmericanPaint_Greyovero`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Overo',
        model       = `A_C_Horse_AmericanPaint_Overo`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'SplashedWhite',
        model       = `A_C_Horse_AmericanPaint_SplashedWhite`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Tobiano',
        model       = `A_C_Horse_AmericanPaint_Tobiano`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'TobianoPC',
        model       = `A_C_Horse_Americanpaint_Tobiano_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'StandardbredBlack',
        model       = `A_C_Horse_AmericanStandardbred_Black`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'StandardbredBuckskin',
        model       = `A_C_Horse_AmericanStandardbred_Buckskin`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'StandardbredPalominoDapple',
        model       = `A_C_Horse_AmericanStandardbred_PalominoDapple`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'StandardbredSilverTailBuckskin',
        model       = `A_C_Horse_AmericanStandardbred_SilverTailBuckskin`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'StandardbredLightBuckskin',
        model       = `A_C_Horse_AmericanStandardbred_LightBuckskin`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'AndalusianDarkBay',
        model       = `A_C_Horse_Andalusian_DarkBay`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'AndalusianDarkBayPC',
        model       = `A_C_Horse_Andalusian_DarkBay_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Perlino',
        model       = `A_C_Horse_Andalusian_Perlino`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'PerlinoPC',
        model       = `A_C_Horse_Andalusian_Perlino_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'RoseGray',
        model       = `A_C_Horse_Andalusian_RoseGray`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'RoseGrayPC',
        model       = `A_C_Horse_Andalusian_RoseGray_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'BlackSnowflake',
        model       = `A_C_Horse_Appaloosa_BlackSnowflake`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'BlackSnowflakePC',
        model       = `A_C_Horse_Appaloosa_BlackSnowflake_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Blanket',
        model       = `A_C_Horse_Appaloosa_Blanket`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'BlanketPC',
        model       = `A_C_Horse_Appaloosa_Blanket_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'BrownLeopard',
        model       = `A_C_Horse_Appaloosa_BrownLeopard`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'BrownLeopardPC',
        model       = `A_C_Horse_Appaloosa_BrownLeopard_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'FewSpottedPC',
        model       = `A_C_Horse_Appaloosa_FewSpotted_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Leopard',
        model       = `A_C_Horse_Appaloosa_Leopard`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'LeopardPC',
        model       = `A_C_Horse_Appaloosa_Leopard_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'LeopardBlanket',
        model       = `A_C_Horse_Appaloosa_LeopardBlanket`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'LeopardBlanketPC',
        model       = `A_C_Horse_Appaloosa_LeopardBlanket_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'ArabianBlack',
        model       = `A_C_Horse_Arabian_Black`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'ArabianBlackPC',
        model       = `A_C_Horse_Arabian_Black_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'ArabianGrey',
        model       = `A_C_Horse_Arabian_Grey`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'ArabianGreyPC',
        model       = `A_C_Horse_Arabian_Grey_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'ArabianRedChestnut',
        model       = `A_C_Horse_Arabian_RedChestnut`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'RedChestnutPC',
        model       = `A_C_Horse_Arabian_RedChestnut_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'RoseGreyBay',
        model       = `A_C_Horse_Arabian_RoseGreyBay`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'RoseGreyBayPC',
        model       = `A_C_Horse_Arabian_RoseGreyBay_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'WarpedBrindlePC',
        model       = `A_C_Horse_Arabian_WarpedBrindle_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'ArabianWhite',
        model       = `A_C_Horse_Arabian_White`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'ArabianWhitePC',
        model       = `A_C_Horse_Arabian_White_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'ArdennesBayRoan',
        model       = `A_C_Horse_Ardennes_BayRoan`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'ArdennesBayRoanPC',
        model       = `A_C_Horse_Ardennes_BayRoan_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'IronGreyRoan',
        model       = `A_C_Horse_Ardennes_IronGreyRoan`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'IronGreyRoanPC',
        model       = `A_C_Horse_Ardennes_IronGreyRoan_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'StrawberryRoan',
        model       = `A_C_Horse_Ardennes_StrawberryRoan`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'StrawberryRoanPC',
        model       = `A_C_Horse_Ardennes_StrawberryRoan_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'BlondChestnut',
        model       = `A_C_Horse_Belgian_BlondChestnut`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'BlondChestnutPC',
        model       = `A_C_Horse_Belgian_BlondChestnut_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'MealyChestnut',
        model       = `A_C_Horse_Belgian_MealyChestnut`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'BretonGrulloDun',
        model       = `A_C_Horse_Breton_GrulloDun`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'BretonMealyDappleBay',
        model       = `A_C_Horse_Breton_MealyDappleBay`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'BretonRedRoan',
        model       = `A_C_Horse_Breton_RedRoan`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'BretonSealBrown',
        model       = `A_C_Horse_Breton_SealBrown`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'BretonSorrel',
        model       = `A_C_Horse_Breton_Sorrel`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'BretonSteelGrey',
        model       = `A_C_Horse_Breton_SteelGrey`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'BretonBayblonde',
        model       = `A_C_Horse_Breton_Bayblonde`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'BretonBlackChestnut',
        model       = `A_C_Horse_Breton_BlackChestnut`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'BretonLiverchestnut',
        model       = `A_C_Horse_Breton_Liverchestnut`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'WarVets',
        model       = `A_C_Horse_Buell_WarVets`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'CriolloBayBrindle',
        model       = `A_C_Horse_Criollo_BayBrindle`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'CriolloBayFrameOvero',
        model       = `A_C_Horse_Criollo_BayFrameOvero`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'CriolloBlueRoanOvero',
        model       = `A_C_Horse_Criollo_BlueRoanOvero`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'CriolloDun',
        model       = `A_C_Horse_Criollo_Dun`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'CriolloMarbleSabino',
        model       = `A_C_Horse_Criollo_MarbleSabino`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'CriolloSorrelOvero',
        model       = `A_C_Horse_Criollo_SorrelOvero`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'CriolloBayRoan',
        model       = `A_C_Horse_Criollo_BayRoan`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'CriolloBuckskin',
        model       = `A_C_Horse_Criollo_Buckskin`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'CriolloGrullaDun',
        model       = `A_C_Horse_Criollo_GrullaDun`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'ChocolateRoan',
        model       = `A_C_Horse_DutchWarmblood_ChocolateRoan`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'ChocolateRoanPC',
        model       = `A_C_Horse_DutchWarmblood_ChocolateRoan_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'DutchSealBrown',
        model       = `A_C_Horse_DutchWarmblood_SealBrown`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'DutchSealBrownPC',
        model       = `A_C_Horse_DutchWarmblood_SealBrown_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'SootyBuckskin',
        model       = `A_C_Horse_DutchWarmblood_SootyBuckskin`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'SootyBuckskinPC',
        model       = `A_C_Horse_DutchWarmblood_SootyBuckskin_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'EagleFlies',
        model       = `A_C_Horse_EagleFlies`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Bill',
        model       = `A_C_Horse_Gang_Bill`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Charles',
        model       = `A_C_Horse_Gang_Charles`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'CharlesEndlessSummer',
        model       = `A_C_Horse_Gang_Charles_EndlessSummer`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Dutch',
        model       = `A_C_Horse_Gang_Dutch`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Hosea',
        model       = `A_C_Horse_Gang_Hosea`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Javier',
        model       = `A_C_Horse_Gang_Javier`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'John',
        model       = `A_C_Horse_Gang_John`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Karen',
        model       = `A_C_Horse_Gang_Karen`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Kieran',
        model       = `A_C_Horse_Gang_Kieran`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Lenny',
        model       = `A_C_Horse_Gang_Lenny`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Micah',
        model       = `A_C_Horse_Gang_Micah`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Sadie',
        model       = `A_C_Horse_Gang_Sadie`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'SadieEndlessSummer',
        model       = `A_C_Horse_Gang_Sadie_EndlessSummer`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Sean',
        model       = `A_C_Horse_Gang_Sean`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Trelawney',
        model       = `A_C_Horse_Gang_Trelawney`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Uncle',
        model       = `A_C_Horse_Gang_Uncle`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'UncleEndlessSummer',
        model       = `A_C_Horse_Gang_Uncle_EndlessSummer`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'GypsyCobSkewbald',
        model       = `A_C_Horse_GypsyCob_Skewbald`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'GypsyCobSplashedPiebald',
        model       = `A_C_Horse_GypsyCob_SplashedPiebald`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'GypsyCobWhiteBlagdon',
        model       = `A_C_Horse_GypsyCob_WhiteBlagdon`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'GypsyCobPiebaldRosamillo',
        model       = `A_C_Horse_GypsyCob_PiebaldRosamillo`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'GypsyCobPalominoBlagdon',
        model       = `A_C_Horse_GypsyCob_PalominoBlagdon`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'GypsyCobDarkBay',
        model       = `A_C_Horse_GypsyCob_DarkBay`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'DarkDappleGrey',
        model       = `A_C_Horse_HungarianHalfbred_DarkDappleGrey`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'DarkDappleGreyPC',
        model       = `A_C_Horse_HungarianHalfbred_DarkDappleGrey_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'HungarianLiverChestnut',
        model       = `A_C_Horse_HungarianHalfbred_LiverChestnut`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'HungarianHalfbredFlaxenChestnut',
        model       = `A_C_Horse_HungarianHalfbred_FlaxenChestnut`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'HungarianFlaxenChestnutPC',
        model       = `A_C_Horse_HungarianHalfbred_FlaxenChestnut_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'PiebaldTobiano',
        model       = `A_C_Horse_HungarianHalfbred_PiebaldTobiano`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'JohnEndlessSummer',
        model       = `A_C_Horse_John_EndlessSummer`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'KentuckySaddleBlack',
        model       = `A_C_Horse_KentuckySaddle_Black`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'ButterMilkBuckskinPC',
        model       = `A_C_Horse_KentuckySaddle_ButterMilkBuckskin_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'ChestnutPinto',
        model       = `A_C_Horse_KentuckySaddle_ChestnutPinto`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'ChestnutPintoPC',
        model       = `A_C_Horse_KentuckySaddle_ChestnutPinto_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'SaddleGrey',
        model       = `A_C_Horse_KentuckySaddle_Grey`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'SaddleGreyPC',
        model       = `A_C_Horse_KentuckySaddle_Grey_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'SilverBay',
        model       = `A_C_Horse_KentuckySaddle_SilverBay`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'SilverBayPC',
        model       = `A_C_Horse_KentuckySaddle_SilverBay_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'KladruberBlack',
        model       = `A_C_Horse_Kladruber_Black`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'KladruberCremello',
        model       = `A_C_Horse_Kladruber_Cremello`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'KladruberDappleRoseGrey',
        model       = `A_C_Horse_Kladruber_DappleRoseGrey`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'KladruberGrey',
        model       = `A_C_Horse_Kladruber_Grey`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'KladruberSilver',
        model       = `A_C_Horse_Kladruber_Silver`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'KladruberWhite',
        model       = `A_C_Horse_Kladruber_White`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'KladruberBayRoan',
        model       = `A_C_Horse_Kladruber_BayRoan`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'KladruberLightbuckskin',
        model       = `A_C_Horse_Kladruber_Lightbuckskin`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'KladruberSilverDapple',
        model       = `A_C_Horse_Kladruber_SilverDapple`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'AmberChampagne',
        model       = `A_C_Horse_MissouriFoxTrotter_AmberChampagne`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'AmberChampagnePC',
        model       = `A_C_Horse_MissouriFoxTrotter_AmberChampagne_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'FoxTrotterBuckskinBrindle',
        model       = `A_C_Horse_MissouriFoxTrotter_BuckskinBrindle`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'FoxTrotterDappleGrey',
        model       = `A_C_Horse_MissouriFoxTrotter_DappleGrey`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'FoxTrotterDappleGreyPC',
        model       = `A_C_Horse_MissouriFoxTrotter_DappleGrey_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'SableChampagne',
        model       = `A_C_Horse_MissouriFoxTrotter_SableChampagne`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'SableChampagnePC',
        model       = `A_C_Horse_MissouriFoxTrotter_SableChampagne_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'SilverDapplePinto',
        model       = `A_C_Horse_MissouriFoxTrotter_SilverDapplePinto`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'SilverDapplePintoPC',
        model       = `A_C_Horse_MissouriFoxTrotter_SilverDapplePinto_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Bay',
        model       = `A_C_Horse_Morgan_Bay`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'MorganBayPC',
        model       = `A_C_Horse_Morgan_Bay_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'MorganBayRoan',
        model       = `A_C_Horse_Morgan_BayRoan`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'MorganBayRoanPC',
        model       = `A_C_Horse_Morgan_BayRoan_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'MorganFlaxenChestnut',
        model       = `A_C_Horse_Morgan_FlaxenChestnut`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'MorganFlaxenChestnutPC',
        model       = `A_C_Horse_Morgan_FlaxenChestnut_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'LiverChestnutPC',
        model       = `A_C_Horse_Morgan_LiverChestnut_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Palomino',
        model       = `A_C_Horse_Morgan_Palomino`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'MorganPalominoPC',
        model       = `A_C_Horse_Morgan_Palomino_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Mangy',
        model       = `A_C_Horse_MP_Mangy_Backup`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Mange',
        model       = `A_C_Horse_MurfreeBrood_Mange_01`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Mange2',
        model       = `A_C_Horse_MurfreeBrood_Mange_02`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Mange3',
        model       = `A_C_Horse_MurfreeBrood_Mange_03`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'GoldenDun',
        model       = `A_C_Horse_Mustang_GoldenDun`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'GoldenDunPC',
        model       = `A_C_Horse_Mustang_GoldenDun_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'GrulloDun',
        model       = `A_C_Horse_Mustang_GrulloDun`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'GrulloDunPC',
        model       = `A_C_Horse_Mustang_GrulloDun_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'MustangRedDunOvero',
        model       = `A_C_Horse_Mustang_RedDunOvero`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'TigerStripedBay',
        model       = `A_C_Horse_Mustang_TigerStripedBay`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'TigerStripedBayPC',
        model       = `A_C_Horse_Mustang_TigerStripedBay_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'WildBay',
        model       = `A_C_Horse_Mustang_WildBay`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'WildBayPC',
        model       = `A_C_Horse_Mustang_WildBay_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'MustangBuckskinBrindle',
        model       = `A_C_Horse_Mustang_BuckskinBrindle`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'MustangChestnutDunOvero',
        model       = `A_C_Horse_Mustang_ChestnutDunOvero`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'MustangRedDun',
        model       = `A_C_Horse_Mustang_RedDun`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'BlueRoan',
        model       = `A_C_Horse_Nokota_BlueRoan`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'BlueRoanPC',
        model       = `A_C_Horse_Nokota_BlueRoan_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'ReverseDappleRoan',
        model       = `A_C_Horse_Nokota_ReverseDappleRoan`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'ReverseDappleRoanPC',
        model       = `A_C_Horse_Nokota_ReverseDappleRoan_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'WhiteRoan',
        model       = `A_C_Horse_Nokota_WhiteRoan`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'WhiteRoanPC',
        model       = `A_C_Horse_Nokota_WhiteRoan_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'NorfolkRoadsterPiebaldRoan',
        model       = `A_C_Horse_NorfolkRoadster_PiebaldRoan`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'NorfolkRoadsterSpeckledGrey',
        model       = `A_C_Horse_NorfolkRoadster_SpeckledGrey`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'NorfolkRoadsterSpottedTricolor',
        model       = `A_C_Horse_NorfolkRoadster_SpottedTricolor`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'NorfolkRoadsterBlack',
        model       = `A_C_Horse_NorfolkRoadster_Black`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'NorfolkRoadsterDappleBuckskin',
        model       = `A_C_Horse_NorfolkRoadster_DappleBuckskin`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'NorfolkRoadsterRoseGrey',
        model       = `A_C_Horse_NorfolkRoadster_RoseGrey`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'ShireDarkBay',
        model       = `A_C_Horse_Shire_DarkBay`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'ShireDarkBayPC',
        model       = `A_C_Horse_Shire_DarkBay_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'LightGrey',
        model       = `A_C_Horse_Shire_LightGrey`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'LightGreyPC',
        model       = `A_C_Horse_Shire_LightGrey_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'RavenBlack',
        model       = `A_C_Horse_Shire_RavenBlack`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'RavenBlackPC',
        model       = `A_C_Horse_Shire_RavenBlack_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'SuffolkPunchRedChestnut',
        model       = `A_C_Horse_SuffolkPunch_RedChestnut`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'SuffolkPunchRedChestnutPC',
        model       = `A_C_Horse_SuffolkPunch_RedChestnut_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'PunchSorrel',
        model       = `A_C_Horse_SuffolkPunch_Sorrel`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'PunchSorrelPC',
        model       = `A_C_Horse_SuffolkPunch_Sorrel_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'BlackRabicano',
        model       = `A_C_Horse_TennesseeWalker_BlackRabicano`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'BlackRabicanoPC',
        model       = `A_C_Horse_TennesseeWalker_BlackRabicano_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Chestnut',
        model       = `A_C_Horse_TennesseeWalker_Chestnut`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'ChestnutPC',
        model       = `A_C_Horse_TennesseeWalker_Chestnut_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'DappleBay',
        model       = `A_C_Horse_TennesseeWalker_DappleBay`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'DappleBayPC',
        model       = `A_C_Horse_TennesseeWalker_DappleBay_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'FlaxenRoan',
        model       = `A_C_Horse_TennesseeWalker_FlaxenRoan`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'FlaxenRoanPC',
        model       = `A_C_Horse_TennesseeWalker_FlaxenRoan_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'GoldPalominoPC',
        model       = `A_C_Horse_TennesseeWalker_GoldPalomino_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'MahoganyBay',
        model       = `A_C_Horse_TennesseeWalker_MahoganyBay`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'MahoganyBayPC',
        model       = `A_C_Horse_TennesseeWalker_MahoganyBay_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'RedRoan',
        model       = `A_C_Horse_TennesseeWalker_RedRoan`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'RedRoanPC',
        model       = `A_C_Horse_TennesseeWalker_RedRoan_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'BlackChestnut',
        model       = `A_C_Horse_Thoroughbred_BlackChestnut`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'BlackChestnutPC',
        model       = `A_C_Horse_Thoroughbred_BlackChestnut_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'BloodBay',
        model       = `A_C_Horse_Thoroughbred_BloodBay`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'BloodBayPC',
        model       = `A_C_Horse_Thoroughbred_BloodBay_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Brindle',
        model       = `A_C_Horse_Thoroughbred_Brindle`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'BrindlePC',
        model       = `A_C_Horse_Thoroughbred_Brindle_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'DappleGrey',
        model       = `A_C_Horse_Thoroughbred_DappleGrey`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'DappleGreyPC',
        model       = `A_C_Horse_Thoroughbred_DappleGrey_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'ReverseDappleBlack',
        model       = `A_C_Horse_Thoroughbred_ReverseDappleBlack`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'ReverseDappleBlackPC',
        model       = `A_C_Horse_Thoroughbred_ReverseDappleBlack_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'TurkomanDarkBay',
        model       = `A_C_Horse_Turkoman_DarkBay`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'TurkomanDarkBayPC',
        model       = `A_C_Horse_Turkoman_DarkBay_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Gold',
        model       = `A_C_Horse_Turkoman_Gold`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'GoldPC',
        model       = `A_C_Horse_Turkoman_Gold_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'TurkomanSilver',
        model       = `A_C_Horse_Turkoman_Silver`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'TurkomanSilverPC',
        model       = `A_C_Horse_Turkoman_Silver_PC`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'TurkomanChestnut',
        model       = `A_C_Horse_Turkoman_Chestnut`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'TurkomanGrey',
        model       = `A_C_Horse_Turkoman_Grey`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'TurkomanPerlino',
        model       = `A_C_Horse_Turkoman_Perlino`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Winter2',
        model       = `A_C_Horse_Winter02_01`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Mule',
        model       = `A_C_HorseMule_01`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'MulePainted',
        model       = `A_C_HorseMulePainted_01`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
    {
        name        = 'Horse',
        model       = `P_C_Horse_01`,
        rewardmoney = math.random(15, 30),
        rewarditem  = 'water'
    },
}
