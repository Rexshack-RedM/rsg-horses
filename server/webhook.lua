local WebhookConfig = require 'config.webhook'

-- Get player identifiers
local function GetPlayerIdentifiers(source)
    local identifiers = {
        steam = '',
        discord = '',
        license = '',
        name = GetPlayerName(source)
    }
    
    for k, v in pairs(GetPlayerIdentifiers(source)) do
        if string.find(v, 'steam:') then
            identifiers.steam = v
        elseif string.find(v, 'discord:') then
            identifiers.discord = '<@' .. string.gsub(v, 'discord:', '') .. '>'
        elseif string.find(v, 'license:') then
            identifiers.license = v
        end
    end
    
    return identifiers
end

-- Format identifier fields for embed
local function FormatIdentifierFields(identifiers)
    local fields = {}
    
    if WebhookConfig.IncludeIdentifiers.Steam and identifiers.steam ~= '' then
        table.insert(fields, {
            name = 'Steam ID',
            value = '`' .. identifiers.steam .. '`',
            inline = true
        })
    end
    
    if WebhookConfig.IncludeIdentifiers.Discord and identifiers.discord ~= '' then
        table.insert(fields, {
            name = 'Discord',
            value = identifiers.discord,
            inline = true
        })
    end
    
    if WebhookConfig.IncludeIdentifiers.License and identifiers.license ~= '' then
        table.insert(fields, {
            name = 'License',
            value = '`' .. identifiers.license .. '`',
            inline = true
        })
    end
    
    return fields
end

-- Send webhook message
local function SendWebhook(webhookUrl, embed)
    if not webhookUrl or webhookUrl == '' then
        return
    end
    
    local payload = json.encode({
        username = WebhookConfig.BotName,
        avatar_url = WebhookConfig.BotAvatar,
        embeds = { embed }
    })
    
    PerformHttpRequest(webhookUrl, function(err, text, headers) end, 'POST', payload, {
        ['Content-Type'] = 'application/json'
    })
end

-- Log horse purchase
function LogHorsePurchase(source, horseData)
    if not WebhookConfig.EnableLogs.HorsePurchase then return end
    
    local identifiers = GetPlayerIdentifiers(source)
    local fields = FormatIdentifierFields(identifiers)
    
    table.insert(fields, {
        name = 'Player Name',
        value = identifiers.name,
        inline = true
    })
    
    table.insert(fields, {
        name = 'Horse Name',
        value = horseData.name or 'Unknown',
        inline = true
    })
    
    table.insert(fields, {
        name = 'Horse Model',
        value = '`' .. horseData.model .. '`',
        inline = true
    })
    
    table.insert(fields, {
        name = 'Gender',
        value = horseData.gender or 'Unknown',
        inline = true
    })
    
    table.insert(fields, {
        name = 'Price',
        value = '$' .. horseData.price,
        inline = true
    })
    
    table.insert(fields, {
        name = 'Stable Location',
        value = horseData.stable or 'Unknown',
        inline = true
    })
    
    if WebhookConfig.IncludeServerName then
        table.insert(fields, {
            name = 'Server',
            value = WebhookConfig.ServerName,
            inline = false
        })
    end
    
    local embed = {
        title = '🐴 Horse Purchased',
        description = '**' .. identifiers.name .. '** purchased a new horse',
        color = WebhookConfig.Colors.Purchase,
        fields = fields,
        footer = {
            text = os.date('%Y-%m-%d %H:%M:%S')
        },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%S')
    }
    
    SendWebhook(WebhookConfig.Webhooks.HorsePurchase or WebhookConfig.Webhooks.General, embed)
end

-- Log horse activation
function LogHorseActivation(source, horseData)
    if not WebhookConfig.EnableLogs.HorseActivation then return end
    
    local identifiers = GetPlayerIdentifiers(source)
    local fields = FormatIdentifierFields(identifiers)
    
    table.insert(fields, {
        name = 'Player Name',
        value = identifiers.name,
        inline = true
    })
    
    table.insert(fields, {
        name = 'Horse Name',
        value = horseData.name or 'Unknown',
        inline = true
    })
    
    if horseData.model then
        table.insert(fields, {
            name = 'Horse Model',
            value = '`' .. horseData.model .. '`',
            inline = true
        })
    end
    
    if WebhookConfig.IncludeServerName then
        table.insert(fields, {
            name = 'Server',
            value = WebhookConfig.ServerName,
            inline = false
        })
    end
    
    local embed = {
        title = '🏇 Horse Activated',
        description = '**' .. identifiers.name .. '** activated their horse',
        color = WebhookConfig.Colors.Action,
        fields = fields,
        footer = {
            text = os.date('%Y-%m-%d %H:%M:%S')
        },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%S')
    }
    
    SendWebhook(WebhookConfig.Webhooks.HorseActions or WebhookConfig.Webhooks.General, embed)
end

-- Log horse deactivation
function LogHorseDeactivation(source, horseData)
    if not WebhookConfig.EnableLogs.HorseDeactivation then return end
    
    local identifiers = GetPlayerIdentifiers(source)
    local fields = FormatIdentifierFields(identifiers)
    
    table.insert(fields, {
        name = 'Player Name',
        value = identifiers.name,
        inline = true
    })
    
    table.insert(fields, {
        name = 'Horse Name',
        value = horseData.name or 'Unknown',
        inline = true
    })
    
    table.insert(fields, {
        name = 'Stable Location',
        value = horseData.stable or 'Unknown',
        inline = true
    })
    
    if WebhookConfig.IncludeServerName then
        table.insert(fields, {
            name = 'Server',
            value = WebhookConfig.ServerName,
            inline = false
        })
    end
    
    local embed = {
        title = '🛑 Horse Stored',
        description = '**' .. identifiers.name .. '** stored their horse',
        color = WebhookConfig.Colors.Action,
        fields = fields,
        footer = {
            text = os.date('%Y-%m-%d %H:%M:%S')
        },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%S')
    }
    
    SendWebhook(WebhookConfig.Webhooks.HorseActions or WebhookConfig.Webhooks.General, embed)
end

-- Log horse feed
function LogHorseFeed(source, itemName)
    if not WebhookConfig.EnableLogs.HorseFeed then return end
    
    local identifiers = GetPlayerIdentifiers(source)
    local fields = FormatIdentifierFields(identifiers)
    
    table.insert(fields, {
        name = 'Player Name',
        value = identifiers.name,
        inline = true
    })
    
    table.insert(fields, {
        name = 'Item Used',
        value = itemName,
        inline = true
    })
    
    if WebhookConfig.IncludeServerName then
        table.insert(fields, {
            name = 'Server',
            value = WebhookConfig.ServerName,
            inline = false
        })
    end
    
    local embed = {
        title = '🥕 Horse Fed',
        description = '**' .. identifiers.name .. '** fed their horse',
        color = WebhookConfig.Colors.Action,
        fields = fields,
        footer = {
            text = os.date('%Y-%m-%d %H:%M:%S')
        },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%S')
    }
    
    SendWebhook(WebhookConfig.Webhooks.HorseActions or WebhookConfig.Webhooks.General, embed)
end

-- Log horse brush
function LogHorseBrush(source)
    if not WebhookConfig.EnableLogs.HorseBrush then return end
    
    local identifiers = GetPlayerIdentifiers(source)
    local fields = FormatIdentifierFields(identifiers)
    
    table.insert(fields, {
        name = 'Player Name',
        value = identifiers.name,
        inline = true
    })
    
    if WebhookConfig.IncludeServerName then
        table.insert(fields, {
            name = 'Server',
            value = WebhookConfig.ServerName,
            inline = false
        })
    end
    
    local embed = {
        title = '🧹 Horse Brushed',
        description = '**' .. identifiers.name .. '** brushed their horse',
        color = WebhookConfig.Colors.Action,
        fields = fields,
        footer = {
            text = os.date('%Y-%m-%d %H:%M:%S')
        },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%S')
    }
    
    SendWebhook(WebhookConfig.Webhooks.HorseActions or WebhookConfig.Webhooks.General, embed)
end

-- Log horse equipment
function LogHorseEquipment(source, itemName)
    if not WebhookConfig.EnableLogs.HorseEquipment then return end
    
    local identifiers = GetPlayerIdentifiers(source)
    local fields = FormatIdentifierFields(identifiers)
    
    table.insert(fields, {
        name = 'Player Name',
        value = identifiers.name,
        inline = true
    })
    
    table.insert(fields, {
        name = 'Equipment',
        value = itemName,
        inline = true
    })
    
    if WebhookConfig.IncludeServerName then
        table.insert(fields, {
            name = 'Server',
            value = WebhookConfig.ServerName,
            inline = false
        })
    end
    
    local embed = {
        title = '⚙️ Horse Equipment',
        description = '**' .. identifiers.name .. '** equipped their horse',
        color = WebhookConfig.Colors.Equipment,
        fields = fields,
        footer = {
            text = os.date('%Y-%m-%d %H:%M:%S')
        },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%S')
    }
    
    SendWebhook(WebhookConfig.Webhooks.HorseActions or WebhookConfig.Webhooks.General, embed)
end

-- Log horse revive
function LogHorseRevive(source, horseData)
    if not WebhookConfig.EnableLogs.HorseRevive then return end
    
    local identifiers = GetPlayerIdentifiers(source)
    local fields = FormatIdentifierFields(identifiers)
    
    table.insert(fields, {
        name = 'Player Name',
        value = identifiers.name,
        inline = true
    })
    
    table.insert(fields, {
        name = 'Horse Name',
        value = horseData.name or 'Unknown',
        inline = true
    })
    
    if WebhookConfig.IncludeServerName then
        table.insert(fields, {
            name = 'Server',
            value = WebhookConfig.ServerName,
            inline = false
        })
    end
    
    local embed = {
        title = '💊 Horse Revived',
        description = '**' .. identifiers.name .. '** revived their horse',
        color = WebhookConfig.Colors.Revive,
        fields = fields,
        footer = {
            text = os.date('%Y-%m-%d %H:%M:%S')
        },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%S')
    }
    
    SendWebhook(WebhookConfig.Webhooks.HorseRevive or WebhookConfig.Webhooks.General, embed)
end

-- Log horse death
function LogHorseDeath(source, horseData, reason)
    if not WebhookConfig.EnableLogs.HorseDeath then return end
    
    local identifiers = GetPlayerIdentifiers(source)
    local fields = FormatIdentifierFields(identifiers)
    
    table.insert(fields, {
        name = 'Player Name',
        value = identifiers.name,
        inline = true
    })
    
    table.insert(fields, {
        name = 'Horse Name',
        value = horseData.name or 'Unknown',
        inline = true
    })
    
    if reason then
        table.insert(fields, {
            name = 'Reason',
            value = reason,
            inline = true
        })
    end
    
    if horseData.age then
        table.insert(fields, {
            name = 'Age',
            value = horseData.age .. ' days',
            inline = true
        })
    end
    
    if WebhookConfig.IncludeServerName then
        table.insert(fields, {
            name = 'Server',
            value = WebhookConfig.ServerName,
            inline = false
        })
    end
    
    local embed = {
        title = '💀 Horse Died',
        description = '**' .. identifiers.name .. '**\'s horse has died',
        color = WebhookConfig.Colors.Death,
        fields = fields,
        footer = {
            text = os.date('%Y-%m-%d %H:%M:%S')
        },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%S')
    }
    
    SendWebhook(WebhookConfig.Webhooks.HorseDeath or WebhookConfig.Webhooks.General, embed)
end

-- Export functions
exports('LogHorsePurchase', LogHorsePurchase)
exports('LogHorseActivation', LogHorseActivation)
exports('LogHorseDeactivation', LogHorseDeactivation)
exports('LogHorseFeed', LogHorseFeed)
exports('LogHorseBrush', LogHorseBrush)
exports('LogHorseEquipment', LogHorseEquipment)
exports('LogHorseRevive', LogHorseRevive)
exports('LogHorseDeath', LogHorseDeath)
