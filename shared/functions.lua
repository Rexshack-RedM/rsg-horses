function CalculatePrice(comp, initial)
    local price = 0

    for category, value in pairs(comp) do
        if Config.PriceComponent[category] and value > 0 and (not initial or initial[category] ~= value) then
            price = price + Config.PriceComponent[category]
        end
    end

    return price
end