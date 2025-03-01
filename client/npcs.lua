local RSGCore = exports['rsg-core']:GetCoreObject()
local spawnedPeds = {}
lib.locale()

CreateThread(function()
    for k,v in pairs(Config.StableSettings) do
        exports['rsg-core']:createPrompt(v.stableid, v.coords, RSGCore.Shared.Keybinds[Config.KeyBind], locale('cl_menu'), {
            type = 'client',
            event = 'rsg-horses:client:stablemenu',
            args = {v.stableid}
        })
        if v.showblip == true then
            local StablesBlip = BlipAddForCoords(1664425300, v.coords)
            SetBlipSprite(StablesBlip, joaat(Config.Blip.blipSprite), true)
            SetBlipScale(StablesBlip, Config.Blip.blipScale)
            SetBlipName(StablesBlip, Config.Blip.blipName)
        end
    end
end)

local function NearNPC(npcmodel, npccoords, heading)
    local spawnedPed = CreatePed(npcmodel, npccoords.x, npccoords.y, npccoords.z - 1.0, heading, false, false, 0, 0)
    SetEntityAlpha(spawnedPed, 0, false)
    SetRandomOutfitVariation(spawnedPed, true)
    SetEntityCanBeDamaged(spawnedPed, false)
    SetEntityInvincible(spawnedPed, true)
    FreezeEntityPosition(spawnedPed, true)
    SetBlockingOfNonTemporaryEvents(spawnedPed, true)
    SetPedCanBeTargetted(spawnedPed, false)
    if Config.FadeIn then
        for i = 0, 255, 51 do
            Wait(50)
            SetEntityAlpha(spawnedPed, i, false)
        end
    end
    return spawnedPed
end

CreateThread(function()
    for k,v in pairs(Config.StableSettings) do
        local coords = v.npccoords
        local newpoint = lib.points.new({
            coords = coords,
            heading = coords.w,
            distance = Config.DistanceSpawn,
            model = v.npcmodel,
            ped = nil,
            stableid = v.stableid
        })
        
        newpoint.onEnter = function(self)
            if not self.ped then
                lib.requestModel(self.model, 10000)
                self.ped = NearNPC(self.model, self.coords, self.heading)

                pcall(function ()
                    exports.ox_target:addLocalEntity(self.ped, {
                        {
                            name = 'npc_stablehand',
                            icon = 'far fa-eye',
                            label = locale('cl_menu'),
                            onSelect = function()
                                TriggerEvent('rsg-horses:client:stablemenu', self.stableid)
                            end,
                            distance = 2.0
                        }
                    })
                end)
            end
        end

        newpoint.onExit = function(self)
            exports.ox_target:removeEntity(self.ped, 'npc_stablehand')
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

        spawnedPeds[k] = newpoint
    end
end)

-- cleanup
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for k, v in pairs(spawnedPeds) do
        exports.ox_target:removeEntity(spawnedPed, 'npc_stablehand')
        if v.ped and DoesEntityExist(v.ped) then
            DeleteEntity(v.ped)
        end
        spawnedPeds[k] = nil
    end
end)
