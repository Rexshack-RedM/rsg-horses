local spawnedHorses = {}
local HorseSettings = lib.load('shared.horse_settings')
lib.locale()

function SpawnHorses(horsemodel, horsecoords, heading)

    local spawnedHorse = CreatePed(horsemodel, horsecoords.x, horsecoords.y, horsecoords.z - 1.0, heading, false, false, 0, 0)
    SetEntityAlpha(spawnedHorse, 0, false)
    SetRandomOutfitVariation(spawnedHorse, true)
    SetEntityCanBeDamaged(spawnedHorse, false)
    SetEntityInvincible(spawnedHorse, true)
    FreezeEntityPosition(spawnedHorse, true)
    SetBlockingOfNonTemporaryEvents(spawnedHorse, true)
    SetPedCanBeTargetted(spawnedHorse, false)

    if Config.FadeIn then
        for i = 0, 255, 51 do
            Wait(50)
            SetEntityAlpha(spawnedHorse, i, false)
        end
    end

    return spawnedHorse
end

CreateThread(function()
    for k, v in pairs(HorseSettings) do
        local coords = v.horsecoords
        local newpoint = lib.points.new({
            coords = coords,
            distance = Config.DistanceSpawn,
            model = v.horsemodel,
            ped = nil,
            price = v.horseprice,
            heading = coords.w,
            horsename = v.horsename
        })

        newpoint.onEnter = function(self)
            if not self.ped then
                lib.requestModel(self.model, 10000)
                self.ped = SpawnHorses(self.model, self.coords, self.heading) -- spawn horse
                pcall(function ()
                    exports.ox_target:addLocalEntity(self.ped, {
                        {
                            name = 'npc_stablehorses',
                            icon = "fas fa-horse-head",
                            label = self.horsename..' $'..self.price,
                            onSelect = function()
                                local dialog = lib.inputDialog(locale('cl_setup'), {
                                    { type = 'input', label = locale('cl_setup_name'), required = true },
                                    {
                                        type = 'select',
                                        label = locale('cl_setup_gender'),
                                        options = {
                                            { value = 'male',   label = locale('cl_setup_gender_a') },
                                            { value = 'female', label = locale('cl_setup_gender_b') }
                                        }
                                    }
                                })

                                if not dialog then return end

                                local setHorseName = dialog[1]
                                local setHorseGender = dialog[2]

                                if setHorseName and setHorseGender then
                                    TriggerServerEvent('rsg-horses:server:BuyHorse', self.model, v.stableid, setHorseName, setHorseGender)
                                else
                                    return
                                end
                            end,
                            distance = 2.5,
                        }
                    })
                end)
            end
        end

        newpoint.onExit = function(self)
            exports.ox_target:removeEntity(self.ped, 'npc_stablehorses')
            if self.ped and DoesEntityExist(self.ped) then
                if Config.FadeIn then
                    for i = 255, 0, -51 do
                        Wait(50)
                        SetEntityAlpha(self.ped, i, false)
                    end
                end
                DeleteEntity(self.ped)
                self.ped = nil
            end
        end

        spawnedHorses[k] = newpoint
    end
end)

-- cleanup
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for k, v in pairs(spawnedHorses) do
        exports.ox_target:removeEntity(v.ped, 'npc_stablehorses')
        if v.ped and DoesEntityExist(v.ped) then
            DeleteEntity(v.ped)
        end

        spawnedHorses[k] = nil
    end
end)