-- Discord webhook logging for rsg-horses.
-- Server-side only. Routes embeds to a category-specific URL from
-- Config.Webhooks.URLs, with a tiny per-category throttle so a burst of
-- events (e.g. the upkeep sweep) can't hammer Discord's rate limit.
--
-- Usage:
--   SendDiscordLog(category, title, description, color, fields, playerSource)
--     category      - 'economy' | 'horses' | 'security' | 'general'
--     title         - embed title (string)
--     description   - embed description (string)
--     color         - decimal embed color (number), see WebhookColors below
--     fields        - optional list of { name, value, inline } tables
--     playerSource  - optional player server id; when given, standard
--                     player fields (name, citizenid, server id) are
--                     appended automatically.

local RSGCore = exports['rsg-core']:GetCoreObject()

WebhookColors = {
    success  = 3066993,  -- green, successful economy actions
    info     = 3447003,  -- blue, general horse-care actions
    warning  = 15105570, -- orange, rejected/invalid attempts
    danger   = 15158332, -- red, exploit attempts / hard failures
    gold     = 15844367, -- gold, high value transactions
    general  = 9807270,  -- gray, fallback/misc
}

local WEBHOOK_MIN_INTERVAL = 500 -- ms between requests per category (< 2 req/s)
local lastSent = {}   -- category -> GetGameTimer() ms of last successful send

local function GetMs()
    return GetGameTimer()
end

local function ResolveWebhookUrl(category)
    if not Config.Webhooks or not Config.Webhooks.Enabled then
        return nil
    end

    local urls = Config.Webhooks.URLs or {}
    local url = urls[category]

    if not url or url == '' then
        -- fall back to general if the category has no url configured, unless
        -- general itself is empty (then there's nothing to send to)
        if category ~= 'general' then
            url = urls.general
        end
    end

    if not url or url == '' then
        return nil
    end

    return url
end

local function DoPost(url, payload)
    PerformHttpRequest(url, function(statusCode, response, headers) end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json'
    })
end

-- Simple per-category throttle: if we've sent recently, delay this send
-- with SetTimeout instead of dropping it, so bursts get spaced out rather
-- than spamming/erroring against Discord's rate limit.
local function ThrottledPost(category, url, payload)
    local now = GetMs()
    local last = lastSent[category] or 0
    local elapsed = now - last

    if elapsed >= WEBHOOK_MIN_INTERVAL then
        lastSent[category] = now
        DoPost(url, payload)
    else
        local delay = WEBHOOK_MIN_INTERVAL - elapsed
        SetTimeout(delay, function()
            lastSent[category] = GetMs()
            DoPost(url, payload)
        end)
    end
end

function SendDiscordLog(category, title, description, color, fields, playerSource)
    category = category or 'general'

    local url = ResolveWebhookUrl(category)
    if not url then
        return -- webhooks disabled or no url configured for this category (and no general fallback)
    end

    fields = fields or {}

    if playerSource then
        local Player = RSGCore.Functions.GetPlayer(playerSource)
        if Player then
            local charinfo = Player.PlayerData.charinfo or {}
            local fullname = (charinfo.firstname or 'Unknown') .. ' ' .. (charinfo.lastname or '')
            table.insert(fields, { name = 'Player', value = fullname, inline = true })
            table.insert(fields, { name = 'CitizenID', value = tostring(Player.PlayerData.citizenid), inline = true })
            table.insert(fields, { name = 'Server ID', value = tostring(playerSource), inline = true })
        else
            table.insert(fields, { name = 'Player', value = 'Unknown/Disconnected', inline = true })
            table.insert(fields, { name = 'Server ID', value = tostring(playerSource), inline = true })
        end
    end

    local embed = {
        title = title,
        description = description,
        color = color or WebhookColors.general,
        fields = fields,
        footer = { text = 'rsg-horses' },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
    }

    local payload = {
        username = (Config.Webhooks and Config.Webhooks.BotName) or 'RSG Horses',
        avatar_url = (Config.Webhooks and Config.Webhooks.BotAvatar ~= '' and Config.Webhooks.BotAvatar) or nil,
        embeds = { embed },
    }

    ThrottledPost(category, url, payload)
end
