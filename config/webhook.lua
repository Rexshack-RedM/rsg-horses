WebhookConfig = {}

-- Discord Webhook URLs
-- Replace these with your actual webhook URLs
WebhookConfig.Webhooks = {
    HorsePurchase = '',  -- Webhook for horse purchases
    HorseActions = '',   -- Webhook for horse interactions (feed, brush, etc)
    HorseRevive = '',    -- Webhook for horse revivals
    HorseDeath = '',     -- Webhook for horse deaths
    HorseTransfer = '',  -- Webhook for horse transfers/trades
    General = '',        -- General horse activities
}

-- Enable/Disable specific webhook logs
WebhookConfig.EnableLogs = {
    HorsePurchase = true,
    HorseActivation = true,
    HorseDeactivation = true,
    HorseFeed = true,
    HorseBrush = true,
    HorseRevive = true,
    HorseDeath = true,
    HorseEquipment = true,
    HorseRename = true,
    HorseTransfer = true,
}

-- Webhook appearance settings
WebhookConfig.BotName = 'RSG Horses Logger'
WebhookConfig.BotAvatar = 'https://i.imgur.com/your-horse-icon.png'

-- Color codes (in decimal format)
WebhookConfig.Colors = {
    Purchase = 3066993,  -- Green
    Action = 3447003,    -- Blue
    Revive = 15844367,   -- Gold
    Death = 15158332,    -- Red
    Transfer = 10181046, -- Purple
    Equipment = 3447003, -- Blue
    Default = 7506394,   -- Grey
}

-- Include server name in embeds
WebhookConfig.IncludeServerName = true
WebhookConfig.ServerName = 'Your Server Name'

-- Include player identifiers
WebhookConfig.IncludeIdentifiers = {
    Steam = true,
    Discord = true,
    License = true,
}

return WebhookConfig
