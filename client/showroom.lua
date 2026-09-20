local showroomHorse, showroomCam
local renderThreadActive = false

-- Orbit state: the camera now circles the horse (rather than the horse
-- spinning on the spot in front of a static camera). orbitRadius/orbitHeight
-- are derived once from the configured horseCameraPreview offset, and
-- orbitAngle is what RotateShowroomHorse advances.
local orbitAngle, orbitRadius, orbitHeight = 0.0, 3.0, 0.0

-- Uses the optional "weathersync" resource's own client exports to force
-- noon/sunny while the buy-horse preview is open, since that resource
-- periodically re-syncs time/weather and would otherwise stomp raw natives.
-- weathersync is a soft dependency (not declared in fxmanifest.lua); if it
-- isn't running, we just skip the override silently.
local timeWeatherOverridden = false

local PREVIEW_HOUR, PREVIEW_MINUTE, PREVIEW_SECOND = 12, 0, 0
local PREVIEW_WEATHER = 'sunny'

local function ForcePreviewTimeWeather()
    if timeWeatherOverridden then return end
    if GetResourceState('weathersync') ~= 'started' then return end
    timeWeatherOverridden = true

    pcall(function()
        exports.weathersync:setMyTime(PREVIEW_HOUR, PREVIEW_MINUTE, PREVIEW_SECOND, true, false)
        exports.weathersync:setMyWeather(PREVIEW_WEATHER, 0.1, false)
    end)
end

local function RestorePreviewTimeWeather()
    if not timeWeatherOverridden then return end
    timeWeatherOverridden = false

    if GetResourceState('weathersync') ~= 'started' then return end
    pcall(function()
        exports.weathersync:setSyncEnabled(true)
    end)
end

-- Camera position offset, expressed the same way as the look-at bias below:
-- negative X = the target's local-left. Applied to the camera's own world
-- position (not just where it looks), this shifts the camera itself further
-- left so the horse renders further right/larger in the visible (non-panel)
-- part of the screen.
local CAMERA_POSITION_LATERAL_OFFSET = -0.0

local function SetUpShowroomCamera(cameraPosition, targetEntity)
    FreezeEntityPosition(cache.ped, true)
    SetEntityInvincible(cache.ped, true)

    local targetCoords = GetEntityCoords(targetEntity)
    local leftPoint = GetOffsetFromEntityInWorldCoords(targetEntity, CAMERA_POSITION_LATERAL_OFFSET, 0.0, 0.0)
    local lateralOffset = leftPoint - targetCoords

    local camX = cameraPosition.x + lateralOffset.x
    local camY = cameraPosition.y + lateralOffset.y
    local camZ = cameraPosition.z

    -- Derive the orbit circle (radius/height/starting angle) from the
    -- configured camera position, so the very first frame looks identical
    -- to before -- only rotating afterwards moves the camera, not the horse.
    local dx, dy = camX - targetCoords.x, camY - targetCoords.y
    orbitRadius = math.sqrt(dx * dx + dy * dy)
    if orbitRadius < 0.1 then orbitRadius = 3.0 end
    orbitHeight = camZ
    orbitAngle = math.atan(dy, dx)

    showroomCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(showroomCam, camX, camY, camZ)
    -- offsetX < 0 shifts the look-at point to the target's left, which pushes
    -- the target itself further right on screen -- clear of the left-side NUI panel.
    PointCamAtEntity(showroomCam, targetEntity, -1.5, 0, 0, true)

    SetCamActive(showroomCam, true)
    RenderScriptCams(true, false, 0, true, true)
    SetCamFov(showroomCam, 50.0)
end

local function ShowroomFadeIn(ped)
    if Config.FadeIn then
        for i = 0, 255, 51 do
            Wait(50)
            SetEntityAlpha(ped, i, false)
        end
    end
end

function SpawnShowroomHorse(model)
    if not closestStable then return end
    local store = nil
    for _, v in pairs(Config.StableSettings) do
        if v.stableid == closestStable then
            store = v
            break
        end
    end
    if not store or not store.horsePreview then return end

    local coords = store.horsePreview
    local camCoords = store.horseCameraPreview

    if not lib.requestModel(model, 10000) then return end

    -- delete old horse but keep camera alive
    if showroomHorse and DoesEntityExist(showroomHorse) then
        DeleteEntity(showroomHorse)
        showroomHorse = nil
    end

    local modelHash = GetHashKey(model)
    -- isNetwork = false: this ped is intentionally local-only to this client,
    -- never registered with NetworkRegisterEntityAsNetworked, so other players
    -- never receive it at all (strongest possible protection from interference).
    showroomHorse = CreatePed(modelHash, coords.x, coords.y, coords.z - 1.0, coords.w, false, false, 0, 0)

    if DoesEntityExist(showroomHorse) then
        -- Namespaced state bag so other resources (ox_target, admin tools, etc.)
        -- and our own client code can positively identify and ignore this preview
        -- ped. Replicated (3rd arg true) in case any code ever references its netId.
        Entity(showroomHorse).state:set('rsg_horses_preview', true, true)
    end

    SetEntityAlpha(showroomHorse, 0, false)
    SetRandomOutfitVariation(showroomHorse, true)
    SetEntityCanBeDamaged(showroomHorse, false)
    SetEntityInvincible(showroomHorse, true)
    SetEntityCollision(showroomHorse, true, true)
    FreezeEntityPosition(showroomHorse, true)
    SetBlockingOfNonTemporaryEvents(showroomHorse, true)
    SetPedCanBeTargetted(showroomHorse, false)
    SetEntityHeading(showroomHorse, 90.0)

    ShowroomFadeIn(showroomHorse)
    SetModelAsNoLongerNeeded(modelHash)

    if showroomCam then
        -- Keep the camera at its current orbit position/angle (so switching
        -- horses mid-browse doesn't snap the view back to the start) and
        -- just re-point it at the new horse.
        local targetCoords = GetEntityCoords(showroomHorse)
        local camX = targetCoords.x + orbitRadius * math.cos(orbitAngle)
        local camY = targetCoords.y + orbitRadius * math.sin(orbitAngle)
        SetCamCoord(showroomCam, camX, camY, orbitHeight)
        PointCamAtEntity(showroomCam, showroomHorse, -1.5, 0.0, 0.0, true)
    else
        SetUpShowroomCamera(camCoords, showroomHorse)
    end

    ForcePreviewTimeWeather()

    if not renderThreadActive then
        renderThreadActive = true
        CreateThread(function()
            while renderThreadActive and (showroomCam or showroomHorse) do
                Wait(0)
                if showroomCam then
                    SetCamActive(showroomCam, true)
                    RenderScriptCams(true, false, 0, true, true)
                end
                if showroomHorse and DoesEntityExist(showroomHorse) then
                    local crds = GetEntityCoords(showroomHorse)
                    DrawLightWithRange(crds.x - 5.0, crds.y - 5.0, crds.z + 1.0, 255, 255, 255, 15.0, 50.0)
                end
            end
            renderThreadActive = false
        end)
    end
end

function GetShowroomHorse()
    if showroomHorse and DoesEntityExist(showroomHorse) then
        return showroomHorse
    end
    return nil
end

function RotateShowroomHorse(direction)
    if not showroomHorse or not DoesEntityExist(showroomHorse) then return end
    if not showroomCam then return end

    local amountRad = math.rad(direction == 'left' and -5 or 5)
    orbitAngle = orbitAngle + amountRad

    local targetCoords = GetEntityCoords(showroomHorse)
    local camX = targetCoords.x + orbitRadius * math.cos(orbitAngle)
    local camY = targetCoords.y + orbitRadius * math.sin(orbitAngle)

    SetCamCoord(showroomCam, camX, camY, orbitHeight)
    PointCamAtEntity(showroomCam, showroomHorse, -1.5, 0.0, 0.0, true)
end

function CloseShowroom()
    renderThreadActive = false

    RestorePreviewTimeWeather()

    if showroomHorse and DoesEntityExist(showroomHorse) then
        DeleteEntity(showroomHorse)
        showroomHorse = nil
    end

    if showroomCam then
        DestroyCam(showroomCam, false)
        RenderScriptCams(false, false, 0, true, true)
        showroomCam = nil
    end

    FreezeEntityPosition(cache.ped, false)
    SetEntityInvincible(cache.ped, false)
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    CloseShowroom()
end)