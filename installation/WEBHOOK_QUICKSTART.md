# Discord Webhook Quick Start Guide

## ⚡ 3-Step Setup

### Step 1: Create Webhook in Discord
1. Right-click your Discord channel → **Edit Channel**
2. Go to **Integrations** → **Webhooks** → **New Webhook**
3. Name it (e.g., "Horse Logger")
4. Copy the webhook URL

### Step 2: Configure
Open `config/webhook.lua` and add your webhook URL:

```lua
WebhookConfig.Webhooks = {
    General = 'PASTE_YOUR_WEBHOOK_URL_HERE',
}
```

**Optional:** Customize server name:
```lua
WebhookConfig.ServerName = 'Your Server Name'
```

### Step 3: Restart
```
restart rsg-horses
```

## ✅ That's It!

Your webhook system is now active and will log:
- ✅ Horse purchases
- ✅ Horse activations/storage
- ✅ Feeding & grooming
- ✅ Equipment usage
- ✅ Revivals & deaths

## 🎛️ Quick Toggles

Disable noisy logs in `config/webhook.lua`:

```lua
WebhookConfig.EnableLogs = {
    HorseFeed = false,   -- Disable feed logging
    HorseBrush = false,  -- Disable brush logging
}
```

## 📚 Full Documentation

See `WEBHOOK_README.md` for:
- Advanced configuration
- Multiple webhook setup
- Custom colors
- Troubleshooting
- Performance tips

## 🧪 Test It

1. Buy a horse in-game
2. Check your Discord channel
3. You should see a webhook message! 🎉

---

**Need Help?** Check the full README or your server console for errors.
