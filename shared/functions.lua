-----------------------------------
-- shared helpers (client + server)
-----------------------------------

-- xp thresholds: level N starts at LEVEL_XP[N]
local LEVEL_XP = { 0, 100, 200, 300, 400, 500, 1000, 1400, 1700, 1900 }

--- returns horse level (1-10) for an xp value
function GetHorseLevel(xp)
    xp = tonumber(xp) or 0
    for lvl = #LEVEL_XP, 1, -1 do
        if xp >= LEVEL_XP[lvl] then return lvl end
    end
    return 1
end

--- saddlebag weight/slots for an xp value (reads Config.Level<N>InvWeight / InvSlots)
function GetHorseInventorySize(xp)
    local lvl = GetHorseLevel(xp)
    return Config['Level' .. lvl .. 'InvWeight'], Config['Level' .. lvl .. 'InvSlots']
end

--- attribute points for an xp value (reads Config.Level<N>)
function GetHorseAttributeValue(xp)
    return Config['Level' .. GetHorseLevel(xp)]
end

function GetStableConfig(stableid)
    if type(stableid) ~= 'string' then return nil end
    for _, v in pairs(Config.StableSettings) do
        if v.stableid == stableid then return v end
    end
    return nil
end

function CalculatePrice(comp, initial)
    local price = 0
    for category, value in pairs(comp or {}) do
        if Config.PriceComponent[category] and value > 0 and (not initial or initial[category] ~= value) then
            price = price + Config.PriceComponent[category]
        end
    end
    return price
end

--- flat fee when the coat / markings / mane / tail differ from the saved coat
function CalculateCoatPrice(newCoat, initialCoat)
    if not newCoat then return 0 end
    local price = (Config.Coat and Config.Coat.Price) or 100
    if not initialCoat then return price end
    if (newCoat.tint0 or 0) ~= (initialCoat.tint0 or 0)
        or (newCoat.tint1 or 255) ~= (initialCoat.tint1 or 255)
        or (newCoat.tint2 or 255) ~= (initialCoat.tint2 or 255)
        or (newCoat.mane or newCoat.tint0 or 0) ~= (initialCoat.mane or initialCoat.tint0 or 0)
        or (newCoat.tail or newCoat.tint0 or 0) ~= (initialCoat.tail or initialCoat.tint0 or 0)
        or (newCoat.rainbow or false) ~= (initialCoat.rainbow or false) then
        return price
    end
    return 0
end

--- stable-to-stable transfer fee (single source of truth for client display + server charge)
function CalculateHorseMovePrice(fromCoords, toCoords)
    return math.ceil(Config.MoveHorseBasePrice + (#(fromCoords - toCoords) * Config.MoveFeePerMeter))
end

function table.copy(t)
    if type(t) ~= 'table' then return t end
    local u = {}
    for k, v in pairs(t) do
        u[k] = type(v) == 'table' and table.copy(v) or v
    end
    return setmetatable(u, getmetatable(t))
end
