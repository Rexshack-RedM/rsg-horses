local spawnedHorses = {}

CreateThread(function()
    while true do
        Wait(500)
        for key, value in pairs(Config.HorseSettings) do
            local playerCoords = GetEntityCoords(cache.ped)
            local distance = #(playerCoords - value.horsecoords.xyz)

            if distance < Config.DistanceSpawn and not spawnedHorses[key] then
                local spawnedHorse = NearHorse(value.horsemodel, value.horsecoords, value.horseprice, value.horsename, value.stableid )
                spawnedHorses[key] = { spawnedHorse = spawnedHorse }
            end
            
            if distance >= Config.DistanceSpawn and spawnedHorses[key] then
                if Config.FadeIn then
                    for i = 255, 0, -51 do
                        Wait(50)
                        SetEntityAlpha(spawnedHorses[key].spawnedHorse, i, false)
                    end
                end
                DeletePed(spawnedHorses[key].spawnedHorse)
                spawnedHorses[key] = nil
            end
        end
    end
end)

function NearHorse(horsemodel, horsecoords, horseprice, horsename, stableid)

    RequestModel(horsemodel)
    
    while not HasModelLoaded(horsemodel) do
        Wait(500)
    end
    
    spawnedHorse = CreatePed(horsemodel, horsecoords.x, horsecoords.y, horsecoords.z - 1.0, horsecoords.w, false, false, 0, 0)
    SetEntityAlpha(spawnedHorse, 0, false)
    SetRandomOutfitVariation(spawnedHorse, true)
    SetEntityCanBeDamaged(spawnedHorse, false)
    SetEntityInvincible(spawnedHorse, true)
    FreezeEntityPosition(spawnedHorse, true)
    SetBlockingOfNonTemporaryEvents(spawnedHorse, true)
    -- set relationship group between horse and player
    SetPedRelationshipGroupHash(spawnedHorse, GetPedRelationshipGroupHash(spawnedHorse))
    SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(spawnedHorse), `PLAYER`)
    -- end of relationship group

    if Config.FadeIn then
        for i = 0, 255, 51 do
            Citizen.Wait(50)
            SetEntityAlpha(spawnedHorse, i, false)
        end
    end

    -- target start
    exports['rsg-target']:AddTargetEntity(spawnedHorse, {
        options = {
            {
                icon = "fas fa-horse-head",
                label = horsename..' $'..horseprice,
                targeticon = "fas fa-eye",
                action = function(newnames)
                    local dialog = lib.inputDialog('Horse Setup', {
                        { type = 'input', label = 'Horse Name', required = true },
                        {
                            type = 'select',
                            label = 'Horse Gender',
                            options = {
                                { value = 'male',   label = 'Gelding' },
                                { value = 'female', label = 'Mare' }
                            }
                        }
                    })

                    if not dialog then return end

                    local setHorseName = dialog[1]
                    local setHorseGender = dialog[2]
                    
                    if setHorseName and setHorseGender then
                        TriggerServerEvent('rsg-horses:server:BuyHorse', horseprice, horsemodel, stableid, setHorseName, setHorseGender)
                    else
                        return
                    end
                end
            }
        },
        distance = 2.5,
    })
    -- target end
    return spawnedHorse
end

-- cleanup
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for key,value in pairs(spawnedHorses) do
        DeletePed(spawnedHorses[key].spawnedHorse)
        spawnedHorses[key] = nil
    end
end)
