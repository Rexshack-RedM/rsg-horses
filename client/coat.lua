-- Horse coat color / markings (merged from horse_markings test resource into rsg-horses)
-- tint0 = main coat colour (0-254), tint1 = horse marking (0-255), tint2 = nose (0-255)
-- mane = mane colour (0-254), tail = tail colour (0-254)
-- Uses SetMetaPedTag on horse_bodies + horse_heads with palette metaped_tint_horse,
-- plus mane/tail categories (0xAA0217AB / 0xA63CAE10) tinted via the same native.
-- Persisted per-horse in player_horses.coat (JSON), not in separate JSON files.

horseCoats = horseCoats or {}
initialHorseCoat = initialHorseCoat or nil



local COAT_COMPONENTS = {
    GetHashKey('horse_bodies'),
    GetHashKey('horse_heads'),
}

local ORIGINAL_COAT_ASSETS = {}
local ORIGINAL_MANETAIL_ASSETS = {}
local coatRainbowThread = nil

-- Category hashes for mane / tail (mirror Config.ComponentHash so coat.lua works standalone)
-- NOTE: shop-item category hashes (used by RemoveShopItem) are NOT necessarily the
-- same as the metaped enumeration hashes, so we try several candidates.
local MANE_CATEGORY_HASH = 0xAA0217AB
local TAIL_CATEGORY_HASH = 0xA63CAE10

local function CoatIsHorse(model)
    return Citizen.InvokeNative(0x772A1969F649E902, model) == 1
end

local function CoatGetNumComponents(ped)
    return Citizen.InvokeNative(0x90403E8107B60E81, ped)
end

local function CoatGetCategory(ped, index)
    local pedType = CoatIsHorse(GetEntityModel(ped)) and 6 or 0
    return Citizen.InvokeNative(0x9B90842304C938A7, ped, index, pedType, Citizen.ResultAsInteger())
end

local function CoatGetGuids(ped, index)
    return Citizen.InvokeNative(0xA9C28516A6DC9D56, ped, index,
        Citizen.PointerValueInt(), Citizen.PointerValueInt(), Citizen.PointerValueInt(), Citizen.PointerValueInt())
end

local function CoatGetTint(ped, index)
    return Citizen.InvokeNative(0xE7998FEC53A33BBE, ped, index,
        Citizen.PointerValueInt(), Citizen.PointerValueInt(), Citizen.PointerValueInt(), Citizen.PointerValueInt())
end

local function CoatGetIndex(ped, targetHash)
    local num = CoatGetNumComponents(ped)
    if num then
        for i = 0, num - 1 do
            if CoatGetCategory(ped, i) == targetHash then
                return i
            end
        end
    end
    return nil
end

local function CoatSetTag(ped, tag, albedo, normal, material, palette, tint0, tint1, tint2)
    Citizen.InvokeNative(0xBC6DF00D7A4A6819, ped, tag, albedo, normal, material, palette, tint0, tint1, tint2)
end

local function ManeTailCandidates()
    local cands = { mane = {}, tail = {} }
    -- shop-item category hashes (from Config / horse_comp.lua)
    local cfgMane = (Config and Config.ComponentHash and Config.ComponentHash.Manes) or MANE_CATEGORY_HASH
    local cfgTail = (Config and Config.ComponentHash and Config.ComponentHash.Tails) or TAIL_CATEGORY_HASH
    cands.mane[#cands.mane + 1] = cfgMane
    cands.tail[#cands.tail + 1] = cfgTail
    -- metaped name hashes (joaat) – one of these usually matches GetCategory()
    for _, n in ipairs({ 'horse_manes', 'horse_mane', 'manes', 'mane', 'horse_hair', 'hair' }) do
        cands.mane[#cands.mane + 1] = GetHashKey(n)
    end
    for _, n in ipairs({ 'horse_tails', 'horse_tail', 'tails', 'tail' }) do
        cands.tail[#cands.tail + 1] = GetHashKey(n)
    end
    return cands
end

function CoatStopRainbow()
    coatRainbowThread = nil
end

local function CoatStartRainbow(horsePed, horseid)
    CoatStopRainbow()
    local idx = 0
    local ped = horsePed
    coatRainbowThread = Citizen.CreateThread(function()
        while horseCoats[horseid] and horseCoats[horseid].rainbow do
            if not ped or not DoesEntityExist(ped) then
                return
            end
            if next(ORIGINAL_COAT_ASSETS) ~= nil
                and Citizen.InvokeNative(0xA0BC8FAED8CFEB3C, ped) then
                for _, assets in pairs(ORIGINAL_COAT_ASSETS) do
                    CoatSetTag(ped, assets.drawable, assets.albedo, assets.normal, assets.material,
                        assets.palette, idx, 255, 255)
                end
                for _, assets in pairs(ORIGINAL_MANETAIL_ASSETS) do
                    CoatSetTag(ped, assets.drawable, assets.albedo, assets.normal, assets.material,
                        assets.palette, idx, idx, idx)
                end
                Citizen.InvokeNative(0xAAB86462966168CE, ped, true)
                Citizen.InvokeNative(0xCC8CA3E88256E58F, ped, false, true, true, true, false)
            end
            idx = (idx + 1) % 256
            Wait(200)
        end
        coatRainbowThread = nil
    end)
end

function CoatSaveOriginalAssets(horsePed)
    ORIGINAL_COAT_ASSETS = {}
    local found = false
    for _, catHash in ipairs(COAT_COMPONENTS) do
        local index = CoatGetIndex(horsePed, catHash)
        if index then
            local drawable, albedo, normal, material = CoatGetGuids(horsePed, index)
            if drawable and drawable ~= 0 then
                local palette, ctint0, ctint1, ctint2 = CoatGetTint(horsePed, index)
                ORIGINAL_COAT_ASSETS[catHash] = {
                    drawable = drawable,
                    albedo = albedo,
                    normal = normal,
                    material = material,
                    palette = palette or GetHashKey('metaped_tint_horse'),
                    original_tint0 = ctint0 or 0,
                    original_tint1 = ctint1 or 0,
                    original_tint2 = ctint2 or 0,
                }
                found = true
            end
        end
    end
    -- Also capture mane/tail originals so colours can be restored / re-tinted
    ManeTailSaveOriginalAssets(horsePed)
    return found
end

--- Capture original mane/tail drawable assets for colour tinting.
--- Returns true if at least one mane/tail component was found.
--- Tries shop hashes + metaped name hashes, then falls back to a full scan.
function ManeTailSaveOriginalAssets(horsePed)
    ORIGINAL_MANETAIL_ASSETS = {}
    if not horsePed or horsePed == 0 or not DoesEntityExist(horsePed) then return false end
    local cands = ManeTailCandidates()
    local found = false
    for key, list in pairs(cands) do
        for _, catHash in ipairs(list) do
            local index = CoatGetIndex(horsePed, catHash)
            if index then
                local drawable, albedo, normal, material = CoatGetGuids(horsePed, index)
                if drawable and drawable ~= 0 and ORIGINAL_MANETAIL_ASSETS[key] == nil then
                    local palette, ctint0, ctint1, ctint2 = CoatGetTint(horsePed, index)
                    if palette == nil or palette == 0 then
                        palette = GetHashKey('metaped_tint_horse')
                    end
                    ORIGINAL_MANETAIL_ASSETS[key] = {
                        category = catHash,
                        compIndex = index,
                        drawable = drawable,
                        albedo = albedo,
                        normal = normal,
                        material = material,
                        palette = palette,
                        original_tint0 = ctint0 or 0,
                        original_tint1 = ctint1 == nil and 255 or ctint1,
                        original_tint2 = ctint2 == nil and 255 or ctint2,
                    }
                    found = true
                end
            end
        end
    end
    -- Fallback: full scan limited to assets using the horse tint palette, so we
    -- don't accidentally re-tint saddles/blankets (different palettes).
    if not found then
        local bodyHead = {}
        for _, h in ipairs(COAT_COMPONENTS) do bodyHead[h] = true end
        local horsePalette = GetHashKey('metaped_tint_horse')
        local num = CoatGetNumComponents(horsePed) or 0
        for i = 0, num - 1 do
            local cat = CoatGetCategory(horsePed, i)
            if cat and not bodyHead[cat] then
                local drawable, albedo, normal, material = CoatGetGuids(horsePed, i)
                if drawable and drawable ~= 0 then
                    local palette, ctint0, ctint1, ctint2 = CoatGetTint(horsePed, i)
                    if palette == horsePalette then
                        local key = ('slot_%d_%08X'):format(i, cat or 0)
                        ORIGINAL_MANETAIL_ASSETS[key] = {
                            category = cat,
                            compIndex = i,
                            drawable = drawable,
                            albedo = albedo,
                            normal = normal,
                            material = material,
                            palette = palette,
                            original_tint0 = ctint0 or 0,
                            original_tint1 = ctint1 == nil and 255 or ctint1,
                            original_tint2 = ctint2 == nil and 255 or ctint2,
                        }
                        found = true
                    end
                end
            end
        end
    end
    return found
end

--- Refresh mane/tail capture after a style (shop item) change.
--- Apply itself is fresh-lookup now, so this only refreshes the restore
--- snapshot and then re-applies the requested colour on the new drawable.
function ManeTailRefreshAfterStyleChange(horsePed, coatData)
    ManeTailSaveOriginalAssets(horsePed)
    if coatData then
        ManeTailApply(horsePed, coatData)
    end
end

--- Does this ped expose tintable mane/tail components?
function ManeTailHasSupport(horsePed)
    if next(ORIGINAL_MANETAIL_ASSETS) ~= nil then return true end
    if not horsePed or horsePed == 0 or not DoesEntityExist(horsePed) then return false end
    local cands = ManeTailCandidates()
    for _, list in pairs(cands) do
        for _, h in ipairs(list) do
            if CoatGetIndex(horsePed, h) ~= nil then return true end
        end
    end
    -- If enumeration has more than body/head slots, assume tintable extras exist
    local num = CoatGetNumComponents(horsePed) or 0
    return num > #COAT_COMPONENTS
end

--- Fresh lookup of a mane/tail slot: returns index + guids + palette.
--- Never uses the stale ORIGINAL_* cache, so slot reorder after
--- UpdatePedVariation can't silently retint the wrong drawable.
local function ManeTailFindSlot(horsePed, which)
    local cands = ManeTailCandidates()[which]
    if not cands then return nil end
    for _, catHash in ipairs(cands) do
        local index = CoatGetIndex(horsePed, catHash)
        if index then
            local drawable, albedo, normal, material = CoatGetGuids(horsePed, index)
            if drawable and drawable ~= 0 then
                local palette = CoatGetTint(horsePed, index)
                if palette == nil or palette == 0 then
                    palette = GetHashKey('metaped_tint_horse')
                end
                return { index = index, drawable = drawable, albedo = albedo,
                    normal = normal, material = material, palette = palette }
            end
        end
    end
    return nil
end

--- Apply mane/tail colours. coatData.mane / coatData.tail are 0-254 tint ids.
--- Missing values leave that part untouched.
--- Looks up FRESH slots every call (dump proved cached compIndex goes stale
--- and retints the wrong drawable, so caching is restore-only now).
function ManeTailApply(horsePed, coatData)
    if not coatData then return true end
    if coatData.mane == nil and coatData.tail == nil then return true end
    if not horsePed or horsePed == 0 or not DoesEntityExist(horsePed) then return false end
    -- NOTE: never return early on the ready flag here; the preview ped may
    -- report not-ready for a frame while streaming, and returning would
    -- silently skip the tint. Just proceed.
    Citizen.InvokeNative(0xA0BC8FAED8CFEB3C, horsePed)
    local jobs = {}
    if coatData.mane ~= nil then
        jobs[#jobs + 1] = { which = 'mane', wanted = math.max(0, math.min(254, math.floor(coatData.mane))) }
    end
    if coatData.tail ~= nil then
        jobs[#jobs + 1] = { which = 'tail', wanted = math.max(0, math.min(254, math.floor(coatData.tail))) }
    end
    -- NOTE: keep the full variation rebuild (both natives + UpdatePedVariation).
    -- Mane/tail tints only render with this exact sequence; dropping the
    -- natives breaks them.
    local function pushUpdate()
        Citizen.InvokeNative(0xAAB86462966168CE, horsePed, true)
        Citizen.InvokeNative(0xCC8CA3E88256E58F, horsePed, false, true, true, true, false)
        if UpdatePedVariation then
            pcall(UpdatePedVariation, horsePed)
        end
    end
    local function readT0(which)
        local s = ManeTailFindSlot(horsePed, which)
        if not s then return nil end
        local _, t0, t1, t2 = CoatGetTint(horsePed, s.index)
        return t0, t1, t2
    end
    -- Try tint combos in order until one reads back: all-three, then tint0
    -- only, then forced horse palette. Different mane/tail albedos accept
    -- different combos.
    local appliedAny = false
    local horsePalette = GetHashKey('metaped_tint_horse')
    for _, job in ipairs(jobs) do
        local slot = ManeTailFindSlot(horsePed, job.which)
        if slot then
            CoatSetTag(horsePed, slot.drawable, slot.albedo, slot.normal, slot.material,
                slot.palette, job.wanted, job.wanted, job.wanted)
            pushUpdate()
            if readT0(job.which) == job.wanted then
                appliedAny = true
            else
                CoatSetTag(horsePed, slot.drawable, slot.albedo, slot.normal, slot.material,
                    slot.palette, job.wanted, 255, 255)
                pushUpdate()
                if readT0(job.which) == job.wanted then
                    appliedAny = true
                else
                    CoatSetTag(horsePed, slot.drawable, slot.albedo, slot.normal, slot.material,
                        horsePalette, job.wanted, 255, 255)
                    pushUpdate()
                    if readT0(job.which) == job.wanted then
                        appliedAny = true
                    end
                end
            end
        end
    end
    return appliedAny
end

function ManeTailClear(horsePed)
    if next(ORIGINAL_MANETAIL_ASSETS) == nil then return end
    if not horsePed or horsePed == 0 or not DoesEntityExist(horsePed) then return end
    if not Citizen.InvokeNative(0xA0BC8FAED8CFEB3C, horsePed) then
        return
    end
    for _, assets in pairs(ORIGINAL_MANETAIL_ASSETS) do
        CoatSetTag(horsePed,
            assets.drawable,
            assets.albedo,
            assets.normal,
            assets.material,
            assets.palette,
            assets.original_tint0,
            assets.original_tint1,
            assets.original_tint2)
    end
    Citizen.InvokeNative(0xAAB86462966168CE, horsePed, true)
    Citizen.InvokeNative(0xCC8CA3E88256E58F, horsePed, false, true, true, true, false)
end

--- Returns original marking tint (tint1) for conditional UI, or nil if unknown.
function CoatGetOriginalMarking()
    for _, assets in pairs(ORIGINAL_COAT_ASSETS) do
        return assets.original_tint1
    end
    return nil
end

--- Apply a saved coat table {tint0,tint1,tint2,mane,tail,palette,rainbow} to a ped
function CoatApply(horsePed, coatData)
    if not coatData then return true end
    if not horsePed or horsePed == 0 or not DoesEntityExist(horsePed) then return false end
    if next(ORIGINAL_COAT_ASSETS) == nil then
        if not CoatSaveOriginalAssets(horsePed) then return false end
    end
    local horseid = nil
    for id, c in pairs(horseCoats) do
        if c == coatData then horseid = id break end
    end
    if coatData.rainbow and horseid then
        CoatStartRainbow(horsePed, horseid)
        return true
    end
    CoatStopRainbow()
    if not Citizen.InvokeNative(0xA0BC8FAED8CFEB3C, horsePed) then
        return false
    end
    for _, assets in pairs(ORIGINAL_COAT_ASSETS) do
        CoatSetTag(horsePed,
            assets.drawable,
            assets.albedo,
            assets.normal,
            assets.material,
            assets.palette,
            math.floor(coatData.tint0 or 0),
            math.floor(coatData.tint1 == nil and 255 or coatData.tint1),
            math.floor(coatData.tint2 == nil and 255 or coatData.tint2))
    end
    Citizen.InvokeNative(0xAAB86462966168CE, horsePed, true)
    Citizen.InvokeNative(0xCC8CA3E88256E58F, horsePed, false, true, true, true, false)
    -- Mane / tail colours ride along with the coat so they preview + persist together
    ManeTailApply(horsePed, coatData)
    return true
end

function CoatClear(horsePed)
    CoatStopRainbow()
    if next(ORIGINAL_COAT_ASSETS) == nil then
        if not CoatSaveOriginalAssets(horsePed) then return end
    end
    if not Citizen.InvokeNative(0xA0BC8FAED8CFEB3C, horsePed) then
        return
    end
    for _, assets in pairs(ORIGINAL_COAT_ASSETS) do
        CoatSetTag(horsePed,
            assets.drawable,
            assets.albedo,
            assets.normal,
            assets.material,
            assets.palette,
            assets.original_tint0,
            assets.original_tint1,
            assets.original_tint2)
    end
    Citizen.InvokeNative(0xAAB86462966168CE, horsePed, true)
    Citizen.InvokeNative(0xCC8CA3E88256E58F, horsePed, false, true, true, true, false)
    ManeTailClear(horsePed)
end

--- Normalise coat from DB (JSON string) or NUI/server table into {tint0,tint1,tint2,mane,tail,palette,rainbow}
function CoatNormalize(raw)
    local defaults = (Config.Coat and Config.Coat.Default) or { tint0 = 0, tint1 = 255, tint2 = 255 }
    local function defaultManeTail(tint0)
        -- Backwards compat: old saves have no mane/tail, default them to the
        -- main coat colour so the UI has something sensible to show.
        return tint0 or defaults.tint0
    end
    if raw == nil or raw == '' then
        local t0 = defaults.tint0
        return { tint0 = t0, tint1 = defaults.tint1, tint2 = defaults.tint2, mane = defaultManeTail(t0), tail = defaultManeTail(t0), palette = (Config.Coat and Config.Coat.Palette) or 'metaped_tint_horse' }
    end
    if type(raw) == 'string' then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == 'table' then
            raw = decoded
        else
            local t0 = defaults.tint0
            return { tint0 = t0, tint1 = defaults.tint1, tint2 = defaults.tint2, mane = defaultManeTail(t0), tail = defaultManeTail(t0), palette = (Config.Coat and Config.Coat.Palette) or 'metaped_tint_horse' }
        end
    end
    if type(raw) ~= 'table' then
        local t0 = defaults.tint0
        return { tint0 = t0, tint1 = defaults.tint1, tint2 = defaults.tint2, mane = defaultManeTail(t0), tail = defaultManeTail(t0), palette = (Config.Coat and Config.Coat.Palette) or 'metaped_tint_horse' }
    end
    local t0 = tonumber(raw.tint0) or defaults.tint0
    return {
        tint0 = t0,
        tint1 = tonumber(raw.tint1) == nil and defaults.tint1 or tonumber(raw.tint1),
        tint2 = tonumber(raw.tint2) == nil and defaults.tint2 or tonumber(raw.tint2),
        mane = tonumber(raw.mane) == nil and defaultManeTail(t0) or tonumber(raw.mane),
        tail = tonumber(raw.tail) == nil and defaultManeTail(t0) or tonumber(raw.tail),
        palette = raw.palette or ((Config.Coat and Config.Coat.Palette) or 'metaped_tint_horse'),
        rainbow = raw.rainbow or false,
    }
end


