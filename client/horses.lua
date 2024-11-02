local spawnedHorses = {}

local function SpawnHorses(horsemodel, horsecoords, heading, deleteHorseForChange, oldhorsemodel)

    if deleteHorseForChange then
        DeleteEntity(oldhorsemodel)
    end
    
    local spawnedHorse = CreatePed(horsemodel, horsecoords.x, horsecoords.y, horsecoords.z - 1.0, heading, false, false, 0, 0)
    SetEntityAlpha(spawnedHorse, 0, false)
    SetRandomOutfitVariation(spawnedHorse, true)
    SetEntityCanBeDamaged(spawnedHorse, false)
    SetEntityInvincible(spawnedHorse, true)
    FreezeEntityPosition(spawnedHorse, true)
    SetBlockingOfNonTemporaryEvents(spawnedHorse, true)
    -- set relationship group between horse and player
    SetPedRelationshipGroupHash(spawnedHorse, GetPedRelationshipGroupHash(spawnedHorse))
    SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(spawnedHorse), `PLAYER`)

    if Config.FadeIn then
        for i = 0, 255, 51 do
            Wait(50)
            SetEntityAlpha(spawnedHorse, i, false)
        end
    end

    return spawnedHorse
end


-- Horse Handler
-- horsecoords , horsemodel , horseprice , horsename, oldkey, oldmodel

local function OpenHorseMenu(data)
    local menus = {}
    --print(data.horsesmenu)
    if not data.horsesmenu then
        for k, v in pairs (Config.HorsesCFG) do
            menus[#menus+1] = {
                title = k,
                onSelect = function()
                    local dbs = {}
                    dbs.horsesmenu = true
                    dbs.horsemenuid = k
                    dbs.horsecoords = data.horsecoords
                    dbs.oldmodel = data.oldmodel
                    dbs.oldkey = data.oldkey
                    dbs.pedd = data.pedd
                    dbs.stableid = data.stableid
                    dbs.head = data.head
                    print(json.encode(dbs))
                    OpenHorseMenu(dbs)
                end
            }
        end
    else
        for k, v in pairs (Config.HorsesCFG[data.horsemenuid]) do
            menus[#menus+1] = {
                title = v.horsename,
                description = '$'..tonumber(v.horseprice),
                onSelect = function()
                    print(data.oldmodel)
                    local dbss = {
                        horsecoords = data.horsecoords,
                        oldmodel =  data.oldmodel,
                        oldkey = data.oldkey,
                        horsemodel = v.horsemodel,
                        horsename = v.horsename,
                        stableid = data.stableid,
                        head = data.head,
                        horseprice = tonumber(v.horseprice),
                    }
                    --print(json.encode(dbss))
                    TriggerServerEvent('rsg-horses:server:changehorse', dbss)

                end
            }
        end

    end

    lib.registerContext({
        id = 'stable_menu_horses_menu',
        title = Lang:t('menu.stable_menu_horses'),
        options = menus,
    })
    lib.showContext("stable_menu_horses_menu")

end

local function HorsesHandler(data)
    local coords = data.horsecoords
    print(json.encode(data))
    local newpointCreated = lib.points.new({
        coords = coords,
        distance = Config.DistanceSpawn,
        model = data.horsemodel,
        ped = nil,
        price = data.horseprice,
        heading = data.head,
        oldmodel = data.oldmodel,
        horsename = data.horsename,
        stableid = data.stableid
    })
    
    newpointCreated.onEnter = function(self)
        if not self.ped then
            lib.requestModel(self.model, 10000)
            self.ped = SpawnHorses(self.model, self.coords, self.heading, true, self.oldmodel) -- spawn horse
            print(self.ped)
            pcall(function ()
                exports['rsg-target']:AddTargetEntity(self.ped, {
                    options = {
                        {
                            icon = "fas fa-horse-head",
                            label = self.horsename..' $'..self.price,
                            targeticon = "fas fa-eye",
                            action = function()
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
                                    TriggerServerEvent('rsg-horses:server:BuyHorse', self.price, self.model, self.stableid, setHorseName, setHorseGender)
                                else
                                    return
                                end
                            end
                        },
                        {
                            icon = "fas fa-horse-head",
                            label = "Change Horse",
                            targeticon = "fas fa-eye",
                            action = function()
                                local db = {}
                                db.horsesmenu = false
                                db.horsecoords = self.coords
                                db.head = self.heading
                                db.oldmodel = self.ped
                                --db.oldkey = key
                                db.pedd = self.ped
                                db.stableid =  self.stableid
                                OpenHorseMenu(db)
                            end
                        }
                    },
                    distance = 2.5,
                })
            end)
        end
    end

    newpointCreated.onExit = function(self)
        exports['rsg-target']:RemoveTargetEntity(self.ped, self.horsename..' $'..self.price)
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
    
    
    spawnedHorses[#spawnedHorses + 1] = newpointCreated

end


CreateThread(function()
    for key, value in pairs(Config.HorseSettings) do
        local coords = value.horsecoords
        local newpoint = lib.points.new({
            coords = coords,
            distance = Config.DistanceSpawn,
            model = value.horsemodel,
            ped = nil,
            price = value.horseprice,
            heading = coords.w,
            horsename = value.horsename,
            stableid = value.stableid
        })
        
        newpoint.onEnter = function(self)
            if not self.ped then
                lib.requestModel(self.model, 10000)
                self.ped = SpawnHorses(self.model, self.coords, self.heading) -- spawn horse
                pcall(function ()
                    exports['rsg-target']:AddTargetEntity(self.ped, {
                        options = {
                            {
                                icon = "fas fa-horse-head",
                                label = self.horsename..' $'..self.price,
                                targeticon = "fas fa-eye",
                                action = function()
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
                                        TriggerServerEvent('rsg-horses:server:BuyHorse', self.price, self.model, self.stableid, setHorseName, setHorseGender)
                                    else
                                        return
                                    end
                                end
                            },
                            {
                                icon = "fas fa-horse-head",
                                label = "Change Horse",
                                targeticon = "fas fa-eye",
                                action = function()

                                    local db = {}
                                    db.horsesmenu = false
                                    db.horsecoords = self.coords
                                    db.head = self.heading
                                    db.oldmodel = self.ped
                                    db.oldkey = key
                                    db.pedd = self.ped
                                    db.stableid =  self.stableid
                                    OpenHorseMenu(db)
                                end
                            }
                        },
                        distance = 2.5,
                    })
                end)
            end
        end

        newpoint.onExit = function(self)
            exports['rsg-target']:RemoveTargetEntity(self.ped, self.horsename..' $'..self.price)
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
        
        spawnedHorses[key] = newpoint
    end
end)



---------------------------------------------------
----- Horse Change Event
---------------------------------------------------
RegisterNetEvent('rsg-horses:client:changeHorses', function(data)
    HorsesHandler(data)
end)


-- cleanup
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for key, value in pairs(spawnedHorses) do
        exports['rsg-target']:RemoveTargetEntity(value.ped, value.horsename..' $'..value.price)
        if value.ped and DoesEntityExist(value.ped) then
            DeleteEntity(value.ped)
        end

        spawnedHorses[key] = nil
    end
end)


