function CalculatePrice(comp, initial)
    local price = 0

    for category, value in pairs(comp) do
        if Config.PriceComponent[category] and value > 0 and (not initial or initial[category] ~= value) then
            price = price + Config.PriceComponent[category]
        end
    end

    return price
end

--- flat fee when the saved coat tint differs (merged from horse_markings)
--- covers coat (tint0), markings (tint1), nose (tint2), mane + tail colours
function CalculateCoatPrice(newCoat, initialCoat)
    if not newCoat then return 0 end
    local price = (Config.Coat and Config.Coat.Price) or 100
    if not initialCoat then
        return price
    end
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

function CalculateHorseMovePrice(fromCoords, toCoords)
    local baseFee = Config.MoveHorseBasePrice 
    local distanceMultiplier = Config.MoveFeePerMeter
    local distance = #(fromCoords - toCoords)
    local cost = math.floor(baseFee + (distance * distanceMultiplier))
    return cost
end