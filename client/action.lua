local objectInteract = false

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
    local str1 = Lang:t('action.drink')
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

    local str2 = Lang:t('action.graze')
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
    while true do
        Wait(1)
        if cache.ped == nil then return end
        if IsPedLeadingHorse(cache.ped) and not objectInteract then
            local thorse = GetLedHorseFromPed(cache.ped)
            if IsEntityInWater(thorse) then
                if IsPedStill(thorse) and not IsPedSwimming(thorse) then
                    DisableControlAction(0, 0x7914A3DD, true)
                    local label  = CreateVarString(10, 'LITERAL_STRING', Lang:t('action.horses'))
                    PromptSetActiveGroupThisFrame(DrinkPrompt, label) 
                    if Citizen.InvokeNative(0xC92AC953F0A982AE, ActionHorseDrink) then
                        objectInteract = true
                        TaskStopLeadingHorse(cache.ped)
                        Wait(500)
                        RequestAnimDict(Config.Anim.Drink.dict)
                        while not HasAnimDictLoaded(Config.Anim.Drink.dict) do
                            Wait(1)
                        end
                        local timer = Config.Anim.Drink.duration * 1000
                        TaskPlayAnim(thorse, Config.Anim.Drink.dict, Config.Anim.Drink.anim, 1.0, 1.0, timer, 1, 0, 1, 0, 0, 0, 0)
                        Wait(timer)
                        local horseHealth = Citizen.InvokeNative(0x36731AC041289BB1, thorse, 0) -- GetAttributeCoreValue (Health)
                        local newHealth = horseHealth + Config.BoostAction.Health
                        local horseStamina = Citizen.InvokeNative(0x36731AC041289BB1, thorse, 1) -- GetAttributeCoreValue (Stamina)
                        local newStamina = horseStamina + Config.BoostAction.Stamina
                
                        Citizen.InvokeNative(0xC6258F41D86676E0, thorse, 0, newHealth) -- SetAttributeCoreValue (Health)
                        Citizen.InvokeNative(0xC6258F41D86676E0, thorse, 1, newStamina) -- SetAttributeCoreValue (Stamina)
                        objectInteract = false
                    end
                end
            else
                if Config.ObjectAction then
                    local forward = GetOffsetFromEntityInWorldCoords(thorse, 0.0, 0.8, -0.5)
                    local obj = nil
                    local type = nil
                    for i,v in pairs(Config.ObjectActionList) do
                        local objt = GetClosestObjectOfType(forward.x, forward.y, forward.z, 0.9, v[1], 0, 1, 1)
                        if objt ~= 0 and obj == nil then
                            obj = objt
                            type = v[2]
                        end
                    end
                                   
                    if obj ~= nil then
                        if type == "drink" then
                            local label  = CreateVarString(10, 'LITERAL_STRING', Lang:t('action.horses'))
                            PromptSetActiveGroupThisFrame(DrinkPrompt, label) 
                            if Citizen.InvokeNative(0xC92AC953F0A982AE, ActionHorseDrink) then
                                objectInteract = true
                                TaskStopLeadingHorse(cache.ped)
                                Wait(500)
                                TaskGoStraightToCoord(thorse, forward.x, forward.y, forward.z, 1.0, -1, -1, 0)
                                Wait(1000)
                                TaskTurnPedToFaceEntity(thorse, obj, 1000)
                                Wait(1000)
                                RequestAnimDict(Config.Anim.Drink2.dict)
                                while not HasAnimDictLoaded(Config.Anim.Drink2.dict) do
                                    Wait(1)
                                end
                                local timer = Config.Anim.Drink2.duration * 1000
                                TaskPlayAnim(thorse, Config.Anim.Drink2.dict, Config.Anim.Drink2.anim, 1.0, 1.0, timer, 1, 0, 1, 0, 0, 0, 0)
                                Wait(timer)
                                ClearPedTasks(thorse)
                                local horseHealth = Citizen.InvokeNative(0x36731AC041289BB1, thorse, 0) -- GetAttributeCoreValue (Health)
                                local newHealth = horseHealth + Config.BoostAction.Health
                                local horseStamina = Citizen.InvokeNative(0x36731AC041289BB1, thorse, 1) -- GetAttributeCoreValue (Stamina)
                                local newStamina = horseStamina + Config.BoostAction.Stamina
                        
                                Citizen.InvokeNative(0xC6258F41D86676E0, thorse, 0, newHealth) -- SetAttributeCoreValue (Health)
                                Citizen.InvokeNative(0xC6258F41D86676E0, thorse, 1, newStamina) -- SetAttributeCoreValue (Stamina)
                                objectInteract = false
                            end
                        elseif type == "feed" then
                            local label  = CreateVarString(10, 'LITERAL_STRING', Lang:t('action.horses'))
                            PromptSetActiveGroupThisFrame(GrazePrompt, label) 
                            if Citizen.InvokeNative(0xC92AC953F0A982AE, ActionHorseGraze) then
                                objectInteract = true
                                TaskStopLeadingHorse(cache.ped)
                                Wait(500)
                                TaskGoStraightToCoord(thorse, forward.x, forward.y, forward.z, 1.0, -1, -1, 0)
                                Wait(1000)
                                TaskTurnPedToFaceEntity(thorse, obj, 1000)
                                Wait(1000)
                                RequestAnimDict(Config.Anim.Graze.dict)
                                while not HasAnimDictLoaded(Config.Anim.Graze.dict) do
                                    Wait(1)
                                end
                                local timer = Config.Anim.Graze.duration * 1000
                                TaskPlayAnim(thorse, Config.Anim.Graze.dict, Config.Anim.Graze.anim, 1.0, 1.0, timer, 1, 0, 1, 0, 0, 0, 0)
                                Wait(timer)
                                ClearPedTasks(thorse)
                                local horseHealth = Citizen.InvokeNative(0x36731AC041289BB1, thorse, 0) -- GetAttributeCoreValue (Health)
                                local newHealth = horseHealth + Config.BoostAction.Health
                                local horseStamina = Citizen.InvokeNative(0x36731AC041289BB1, thorse, 1) -- GetAttributeCoreValue (Stamina)
                                local newStamina = horseStamina + Config.BoostAction.Stamina
                        
                                Citizen.InvokeNative(0xC6258F41D86676E0, thorse, 0, newHealth) -- SetAttributeCoreValue (Health)
                                Citizen.InvokeNative(0xC6258F41D86676E0, thorse, 1, newStamina) -- SetAttributeCoreValue (Stamina)
                                objectInteract = false
                            end
                        end
                    end
                end
            end
        else
            Wait(1000)
        end
    end
end)