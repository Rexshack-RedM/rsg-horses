function CalculatePrice(comp, initial)
    local price = 0

    for category, value in pairs(comp) do
        if Config.PriceComponent[category] and value > 0 and (not initial or initial[category] ~= value) then
            price = price + Config.PriceComponent[category]
        end
    end

    return price
end

--- coat fee: a single charge when anything coat-related differs, priced by
--- the selected main colour (tint0). Preset colours use their configured
--- price, anything else falls back to Config.Coat.Price.
function CoatPresetPrice(tint0)
    tint0 = math.floor(tonumber(tint0) or 0)
    if Config.CoatPresets then
        for _, preset in ipairs(Config.CoatPresets) do
            if preset.tint0 == tint0 then
                return preset.price or ((Config.Coat and Config.Coat.Price) or 100)
            end
        end
    end
    return (Config.Coat and Config.Coat.Price) or 100
end

--- coat fee when the saved coat tint differs (merged from horse_markings)
--- covers coat (tint0), markings (tint1), nose (tint2), mane + tail colours
function CalculateCoatPrice(newCoat, initialCoat)
    if not newCoat then return 0 end
    if not initialCoat then
        return CoatPresetPrice(newCoat.tint0)
    end
    if (newCoat.tint0 or 0) ~= (initialCoat.tint0 or 0)
        or (newCoat.tint1 or 255) ~= (initialCoat.tint1 or 255)
        or (newCoat.tint2 or 255) ~= (initialCoat.tint2 or 255)
        or (newCoat.mane or newCoat.tint0 or 0) ~= (initialCoat.mane or initialCoat.tint0 or 0)
        or (newCoat.tail or newCoat.tint0 or 0) ~= (initialCoat.tail or initialCoat.tint0 or 0)
        or (newCoat.rainbow or false) ~= (initialCoat.rainbow or false) then
        return CoatPresetPrice(newCoat.tint0)
    end
    return 0
end

function CalculateHorseMovePrice(fromCoords, toCoords)
    local baseFee = Config.MoveHorseBasePrice 
    local distanceMultiplier = Config.MoveFeePerMeter
    local distance = #(fromCoords - toCoords)
    local cost = math.floor(baseFee + (distance * distanceMultiplier))
    return cost
end