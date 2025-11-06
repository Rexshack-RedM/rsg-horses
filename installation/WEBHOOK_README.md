# Discord Webhook System for RSG Horses

A comprehensive Discord webhook logging system for tracking all horse-related activities in your RSG RedM server.

## 📋 Features

The webhook system logs the following activities:

- 🐴 **Horse Purchases** - Track when players buy new horses
- 🏇 **Horse Activation** - Log when players take their horse out
- 🛑 **Horse Storage** - Monitor when horses are stored in stables
- 🥕 **Horse Feeding** - Track feeding activities with different items
- 🧹 **Horse Brushing** - Log grooming activities
- ⚙️ **Horse Equipment** - Track lantern and holster usage
- 💊 **Horse Revivals** - Monitor horse revival events
- 💀 **Horse Deaths** - Log when horses die with details

## 🚀 Installation

### 1. Create Discord Webhooks

1. Go to your Discord server settings
2. Navigate to **Integrations** → **Webhooks**
3. Click **New Webhook**
4. Create separate webhooks for different categories (recommended):
   - Horse Purchases
   - Horse Actions
   - Horse Revivals
   - Horse Deaths
   - General (fallback)
5. Copy each webhook URL

### 2. Configure Webhooks

Open `config/webhook.lua` and paste your webhook URLs:

```lua
WebhookConfig.Webhooks = {
    HorsePurchase = 'https://discord.com/api/webhooks/YOUR_WEBHOOK_URL',
    HorseActions = 'https://discord.com/api/webhooks/YOUR_WEBHOOK_URL',
    HorseRevive = 'https://discord.com/api/webhooks/YOUR_WEBHOOK_URL',
    HorseDeath = 'https://discord.com/api/webhooks/YOUR_WEBHOOK_URL',
    General = 'https://discord.com/api/webhooks/YOUR_WEBHOOK_URL',
}
```

**Note:** You can use the same webhook URL for multiple categories or leave some blank to disable them.

### 3. Customize Settings

In `config/webhook.lua`, you can customize:

```lua
-- Enable/Disable specific logs
WebhookConfig.EnableLogs = {
    HorsePurchase = true,
    HorseActivation = true,
    HorseDeactivation = true,
    HorseFeed = true,      -- May generate many logs
    HorseBrush = true,     -- May generate many logs
    HorseRevive = true,
    HorseDeath = true,
    HorseEquipment = true,
}

-- Bot appearance
WebhookConfig.BotName = 'RSG Horses Logger'
WebhookConfig.BotAvatar = 'https://i.imgur.com/your-horse-icon.png'

-- Server information
WebhookConfig.IncludeServerName = true
WebhookConfig.ServerName = 'Your Server Name'

-- Player identifiers
WebhookConfig.IncludeIdentifiers = {
    Steam = true,
    Discord = true,
    License = true,
}
```

### 4. Restart Resource

```bash
ensure rsg-horses
# or
restart rsg-horses
```

## 🎨 Customization

### Colors

You can change embed colors in `config/webhook.lua` (decimal format):

```lua
WebhookConfig.Colors = {
    Purchase = 3066993,  -- Green
    Action = 3447003,    -- Blue
    Revive = 15844367,   -- Gold
    Death = 15158332,    -- Red
    Transfer = 10181046, -- Purple
    Equipment = 3447003, -- Blue
    Default = 7506394,   -- Grey
}
```

**Color Converter:** Use [this tool](https://www.spycolor.com/) to convert hex colors to decimal.

### Adding Custom Events

To add webhook logging to custom events, use the exported functions:

```lua
-- In your server-side code
exports['rsg-horses']:LogHorsePurchase(source, {
    name = horsename,
    model = model,
    gender = gender,
    price = price,
    stable = stable
})

exports['rsg-horses']:LogHorseActivation(source, {
    name = horsename,
    model = horsemodel
})

exports['rsg-horses']:LogHorseFeed(source, itemName)

exports['rsg-horses']:LogHorseDeath(source, {
    name = horsename,
    age = age_in_days
}, 'Reason for death')
```

## 📊 Example Webhook Messages

### Horse Purchase
```
🐴 Horse Purchased
PlayerName purchased a new horse

Player Name: John Doe
Horse Name: Thunder
Horse Model: A_C_Horse_Arabian_White
Gender: Male
Price: $1000
Stable Location: valentine
```

### Horse Death
```
💀 Horse Died
PlayerName's horse has died

Player Name: John Doe
Horse Name: Thunder
Reason: Natural causes
Age: 365 days
```

## ⚙️ Performance Considerations

### High-Traffic Servers

If you have a busy server, consider:

1. **Disable frequent events:**
   ```lua
   WebhookConfig.EnableLogs = {
       HorseFeed = false,  -- Can spam if many players feed horses
       HorseBrush = false, -- Can spam if many players brush horses
   }
   ```

2. **Use separate webhooks** for different categories to avoid rate limits

3. **Discord Rate Limits:**
   - 5 requests per 2 seconds per webhook
   - 30 requests per minute per webhook

## 🔧 Troubleshooting

### Webhooks Not Sending

1. **Check webhook URLs** - Ensure they're valid and not expired
2. **Check console** - Look for HTTP errors in server console
3. **Test webhook** - Use a tool like Postman to test the webhook URL
4. **Verify permissions** - Ensure the webhook has proper permissions in Discord

### Missing Data

1. **Check EnableLogs** - Ensure the event type is enabled in config
2. **Check webhook URL** - Verify the correct webhook is configured for that event type
3. **Check server.lua** - Ensure the logging function is called in the right place

### Rate Limiting

If you see rate limit errors:
1. Reduce the number of enabled logs
2. Use separate webhooks for different categories
3. Consider batching logs (requires custom implementation)

## 📝 File Structure

```
rsg-horses/
├── config/
│   └── webhook.lua          # Webhook configuration
├── server/
│   ├── server.lua           # Main server file (modified with webhook calls)
│   └── webhook.lua          # Webhook utility functions
└── fxmanifest.lua          # Updated manifest
```

## 🤝 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review your configuration in `config/webhook.lua`
3. Check server console for errors
4. Ensure you're using the latest version

## 📜 License

This webhook system follows the same license as the RSG Horses script.

## 🔄 Updates

When updating the main rsg-horses script:
1. Backup your `config/webhook.lua` file
2. Update the resource
3. Restore your webhook configuration
4. Check for any new events to log

---

**Note:** This webhook system respects player privacy. Only enable the identifier logs you need and ensure compliance with your server's privacy policy.
