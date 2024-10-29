local objectInteract = false
lib.locale()

local ActionHorseDrink
local DrinkPrompt = GetRandomIntInRange(0, 0xffffff)

local ActionHorseGraze
local GrazePrompt = GetRandomIntInRange(0, 0xffffff)

local function TaskStopLeadingHorse(ped)
    return Citizen.InvokeNative(0xED27560703F37258, ped)
end

local function GetLedHorseFromPed(ped)
    return Citizen.InvokeNative(0xED1F514AF4732258, ped)
end

local function IsPedLeadingHorse(ped)
    return Citizen.InvokeNative(0xEFC4303DDC6E60D3, ped)
end

local function SetupActionPrompt()
    local str1 = locale('cl_action_drink')
    ActionHorseDrink = PromptRegisterBegin()
    PromptSetControlAction(ActionHorseDrink,Config.Prompt.HorseDrink)
    str1 = CreateVarString(10, 'LITERAL_STRING', str1)
    PromptSetText(ActionHorseDrink, str1)
    PromptSetEnabled(ActionHorseDrink, 1)
    PromptSetVisible(ActionHorseDrink, 1)
    PromptSetStandardMode(ActionHorseDrink,1)
    PromptSetGroup(ActionHorseDrink, DrinkPrompt)
    Citizen.InvokeNative(0xC5F428EE08FA7F2C,ActionHorseDrink,true)
    PromptRegisterEnd(ActionHorseDrink)

    local str2 = locale('cl_action_graze')
    ActionHorseGraze = PromptRegisterBegin()
    PromptSetControlAction(ActionHorseGraze,Config.Prompt.HorseGraze)
    str2 = CreateVarString(10, 'LITERAL_STRING', str2)
    PromptSetText(ActionHorseGraze, str2)
    PromptSetEnabled(ActionHorseGraze, 1)
    PromptSetVisible(ActionHorseGraze, 1)
    PromptSetStandardMode(ActionHorseGraze,1)
    PromptSetGroup(ActionHorseGraze, GrazePrompt)
    Citizen.InvokeNative(0xC5F428EE08FA7F2C,ActionHorseGraze,true)
    PromptRegisterEnd(ActionHorseGraze)
end

CreateThread(function()
    SetupActionPrompt()
    repeat Wait(1000) until LocalPlayer.state.isLoggedIn
    while true do
        ::continue::
        Wait(1)
        local thorse = GetLedHorseFromPed(cache.ped)
        if cache.ped == nil or thorse == nil then goto continue end

        if not IsPedLeadingHorse(cache.ped) or objectInteract then
            Wait(1000)
            goto continue
        end

        if IsEntityInWater(thorse) then
            HandleWaterInteraction(thorse)
        elseif Config.ObjectAction then
            HandleObjectInteraction(thorse)
        end
    end
end)

function HandleWaterInteraction(thorse)
    if not IsPedStill(thorse) or IsPedSwimming(thorse) then return end
    
    DisableControlAction(0, 0x7914A3DD, true)
    local label = CreateVarString(10, 'LITERAL_STRING', locale('cl_action_horses'))
    PromptSetActiveGroupThisFrame(DrinkPrompt, label) 
    
    if Citizen.InvokeNative(0xC92AC953F0A982AE, ActionHorseDrink) then
        PerformHorseAction(thorse, Config.Anim.Drink)
    end
end

function HandleObjectInteraction(thorse)
    local forward = GetOffsetFromEntityInWorldCoords(thorse, 0.0, 0.8, -0.5)
    local obj, type = GetNearestInteractableObject(forward)
    
    if obj == nil then return end

    local promptGroup, action, anim
    if type == "drink" then
        promptGroup, action = DrinkPrompt, ActionHorseDrink
        anim = Config.Anim.Drink2
    elseif type == "feed" then
        promptGroup, action = GrazePrompt, ActionHorseGraze
        anim = Config.Anim.Graze
    else
        return
    end

    local label = CreateVarString(10, 'LITERAL_STRING', locale('cl_action_horses'))
    PromptSetActiveGroupThisFrame(promptGroup, label) 
    
    if Citizen.InvokeNative(0xC92AC953F0A982AE, action) then
        PerformHorseAction(thorse, anim, obj, forward)
    end
end

function PerformHorseAction(thorse, anim, obj, forward)
    objectInteract = true
    TaskStopLeadingHorse(cache.ped)
    Wait(500)

    if obj then
        TaskGoStraightToCoord(thorse, forward.x, forward.y, forward.z, 1.0, -1, -1, 0)
        Wait(1000)
        TaskTurnPedToFaceEntity(thorse, obj, 1000)
        Wait(1000)
    end

    RequestAnimDict(anim.dict)
    while not HasAnimDictLoaded(anim.dict) do Wait(1) end

    local timer = anim.duration * 1000
    TaskPlayAnim(thorse, anim.dict, anim.anim, 1.0, 1.0, timer, 1, 0, 1, 0, 0, 0, 0)
    Wait(timer)

    if obj then ClearPedTasks(thorse) end

    local horseHealth = Citizen.InvokeNative(0x36731AC041289BB1, thorse, 0)
    local horseStamina = Citizen.InvokeNative(0x36731AC041289BB1, thorse, 1)

    Citizen.InvokeNative(0xC6258F41D86676E0, thorse, 0, horseHealth + Config.BoostAction.Health)
    Citizen.InvokeNative(0xC6258F41D86676E0, thorse, 1, horseStamina + Config.BoostAction.Stamina)

    objectInteract = false
end

function GetNearestInteractableObject(forward)
    for _, v in pairs(Config.ObjectActionList) do
        local obj = GetClosestObjectOfType(forward.x, forward.y, forward.z, 0.9, v[1], 0, 1, 1)
        if obj ~= 0 then
            return obj, v[2]
        end
    end
    return nil, nil
end