# rsg-horses

A full horse system for RSG-Core RedM servers — stables, ownership, customization, care, breeding, and wild horse taming — built on `ox_lib` and `oxmysql`.

**Version:** 2.3.0

---

## Features

- **Stables** at Colter, Van Horn, Saint Denis, Rhodes, Valentine and Strawberry, each with a stablehand NPC, a menu prompt/target option, and a map blip.
- **Buy, sell, store and move horses.** Preview a horse before buying (with a rotating camera), name it, choose its gender, and sell it back for half the buy price. Move a horse between stables for a base fee plus a per-metre distance fee.
- **Trading** an active horse to another nearby player, accepted with `/accepttrade` (requests expire after 30 seconds).
- **Leveling and bonding.** Horses gain XP from feeding, up to level 10, increasing health, stamina, speed and inventory capacity. Bonding unlocks tricks (Lay Down at 1000 XP, Play at 2000 XP).
- **Per-horse inventory** (saddlebag required), with weight and slot capacity that scales with horse level.
- **Customization** (Valentine only): swap tack components (blankets, saddles, horns, saddlebags, stirrups, bedrolls, tails, manes, masks, mustaches) with per-part fees, plus coat colour, markings, nose shade, and mane/tail colour with live total pricing and full-turn preview.
- **Horse care items:** brush (cleans dirt), feed (carrot, apple, hay, stimulant), lantern, holster (store a long-arm on the horse), and a reviver for downed horses with a configurable grace period.
- **Environmental interactions:** horses can drink at water troughs and graze at hay piles automatically.
- **Horse Shop** at every stable selling care items, with optional stock persistence across restarts.
- **Breeding system** (requires the `horsebreeder` job): pick a mare and stallion, pay a hay cost, wait out a gestation period, and get a foal with a random breed, name and gender. Foals grow from a small scale to full size over a configurable duration. Mares have a breeding cooldown.
- **Wild horses:** tame a wild horse in the field, then sell it to a frontier buyer (Van Horn, Valentine, Blackwater) via an appraisal minigame for cash and an item reward, or register/save it into your own stable as an owned horse. Includes a sale cooldown and anti-abuse checks so you can't sell/save a horse you don't own or didn't tame. Admins can force a mount to be "wild" for events.
- **Ageing and death:** horses age over real time and can die of old age (with a telegram notification); starter horses die sooner than normal horses. Dead horses and their inventory are lost permanently.
- **Webhooks and version checking** for server-side logging/update notices.
- **Full localization** — English, German, Spanish, French, Italian, Polish, Portuguese, Portuguese (BR), Czech and Greek locales included.
- **Exports:** `CheckHorseLevel`, `CheckHorseBondingLevel`, `CheckActiveHorse`.

For a player-facing walkthrough of all of the above, see [`installation/guides/rsg-horses-player-guide.md`](installation/guides/rsg-horses-player-guide.md).

---

## Requirements

- [RSG-Core](https://github.com/Rexshack-RedM/rsg-core)
- [ox_lib](https://github.com/Rexshack-RedM/ox_lib)
- [oxmysql](https://github.com/Rexshack-RedM/oxmysql)

---

## Installation

1. **Download** the resource and place the `rsg-horses` folder in your server's `resources` directory (a subfolder of `[standalone]` or similar is fine).

2. **Add items** — merge the item definitions from `installation/shared_items.lua` into your RSG-Core shared items (`hay`, `horse_brush`, `horse_holster`, `horse_lantern`, `horse_reviver`, `horse_stimulant`, `horseapple`, `horsecarrot`).

3. **Create the database table** — run `installation/setup.sql` against your database to create the `player_horses` table.

   > Upgrading from an older version of this resource? Run `installation/migration.sql` instead (or after reviewing it, if your schema already partially matches) to bring an existing `player_horses` table up to date — it drops the obsolete `wild` column, adjusts existing column types/defaults, adds the new coat/ageing/breeding/weapon-storage columns, and adds performance indexes. Back up your database before running it.

4. **Add the `horsebreeder` job** (or rename `Config.Breeding.requiredJob` in `shared/config.lua` to an existing job) if you want players to be able to breed horses.

5. **Add the resource to your `server.cfg`**, after `rsg-core`, `ox_lib` and `oxmysql`:

   ```cfg
   ensure ox_lib
   ensure oxmysql
   ensure rsg-core
   ensure rsg-horses
   ```

6. **Restart your server** (or start the resource) and confirm no errors appear in the console.

---

## Configuration

All settings live in `shared/config.lua`. Key options:

### General

| Setting | Description |
|---|---|
| `Config.Debug` | Enable debug output. |
| `Config.EnableTarget` | Use a targeting system (e.g. ox_target) instead of prompts. |
| `Config.TargetHelp` | Show target help text (`[L-ALT]`). |
| `Config.Automount` | Automatically mount a horse when interacting. |
| `Config.SpawnOnRoadOnly` | Force horses to always spawn on a road. |
| `Config.KeyBind` | Key used to whistle/call your active horse (default `J`). |
| `Config.AllowTwoPlayersRide` | Allow a second player to ride along. |
| `Config.StoreFleedHorse` | Store a horse automatically if it flees. |
| `Config.EnableServerNotify` | Enable server-side notifications. |
| `Config.DeathGracePeriod` | Milliseconds a player has to revive a critically injured horse. |
| `Config.CheckCycle` | Minutes between the background horse-ageing/health check cycle. |

### Ageing

| Setting | Description |
|---|---|
| `Config.StarterHorseDieAge` | Days until a starter horse dies of old age. |
| `Config.HorseDieAge` | Days until a regular horse dies of old age. |

### Inventory & Leveling

| Setting | Description |
|---|---|
| `Config.HorseInvWeight` / `Config.HorseInvSlots` | Base horse inventory weight/slots. |
| `Config.LevelXInvWeight` / `Config.LevelXInvSlots` (X = 1–10) | Inventory capacity per horse level. |
| `Config.LevelX` (X = 1–10) | Health/stamina/ability/speed/acceleration value per level. |
| `Config.MaxBondingLevel` | Max bonding XP. |
| `Config.TrickXp.Lay` / `Config.TrickXp.Play` | XP thresholds required to unlock each trick. |

### Feeding

`Config.HorseFeed` maps item names to the health/stamina they restore, and whether they count as medicine (with an optional custom `medicineHash`).

### Shop

`Config.horsesShopItems` lists the items, stock amounts and prices sold at stable shops. `Config.PersistStock` toggles whether remaining stock is saved to the database and restored after a restart.

### Customization

- `Config.ComponentHash` / `Config.PriceComponent` — the tack component categories and their per-change fee.
- `Config.Coat` — flat price for changing coat/mane/tail colour, the tint palette used, and default tint values.
- `Config.CoatPresets` — named coat colour presets with their tint ID and price.

### Breeding & Growth

| Setting | Description |
|---|---|
| `Config.Breeding.enabled` | Turn breeding on/off. |
| `Config.Breeding.requiredJob` | Job required to breed (default `horsebreeder`). |
| `Config.Breeding.requireOppositeSex` | Require one mare and one stallion. |
| `Config.Breeding.gestationMinutes` | Minutes from breeding to foal birth. |
| `Config.Breeding.breedCooldownMinutes` | Cooldown before a mare can be bred again. |
| `Config.Breeding.hayCost` | Hay required per breeding attempt. |
| `Config.Growth.enabled` | Turn foal growth on/off. |
| `Config.Growth.minScale` / `Config.Growth.growthMinutesToAdult` | Starting scale of a foal and minutes to reach full size. |
| `Config.HorseModels` | Pool of horse models a random foal can be born as. |

### Stables

`Config.StableSettings` defines each stable: `stableid`, NPC location/model, horse-customization spot, preview camera coordinates (Valentine only), and whether to show a map blip. Add, remove or reposition entries here to change stable locations.

### Wild Horses

See `shared/wildhorse_config.lua` for frontier seller locations, appraisal/sale settings, and taming behaviour.

### Locales

Set the active language via `ox_lib`'s locale system (`lib.locale()`); translation files are in `locales/*.json`. Add a new language by copying `locales/en.json` and translating its values.

---

## Usage

### For players

- Visit a stable and interact with the stablehand (via prompt or target, per `Config.EnableTarget`) to open **Buy Horse**, **View Horses**, **Sell Horse**, **Move Horse**, **Trade Horse**, **Breed Horse** (job required), **Horse Shop**, **Store Horse**, and **Customize** (Valentine only).
- Press the configured key bind (default `J`) to whistle for your active horse.
- Interact with a nearby horse for context options: brush, feed, lantern, holster, inventory, and tricks (once bonded).
- Useful chat commands:

  | Command | Description |
  |---|---|
  | `/sethorsename` | Rename your active horse. |
  | `/findhorse` | Show which stables your horses are kept at. |
  | `/accepttrade` | Accept an incoming horse trade offer. |

- To tame and use a wild horse: calm and mount it in the field, then ride it to a frontier seller blip (Van Horn, Valentine or Blackwater) to either **Sell Horse** (appraisal minigame for cash + item) or **Save Horse** (register it into your own stable).

Full player instructions are in [`installation/guides/rsg-horses-player-guide.md`](installation/guides/rsg-horses-player-guide.md).

### For admins/developers

- `/sethorsewild` — flag your current mount as a wild horse (for events/testing).
- Exports available to other resources:

  ```lua
  exports['rsg-horses']:CheckHorseLevel(...)
  exports['rsg-horses']:CheckHorseBondingLevel(...)
  exports['rsg-horses']:CheckActiveHorse(...)
  ```

- Server-side logic lives in `server/server.lua` (core), `server/wildhorse.lua` (wild horse handling), `server/webhooks.lua`, and `server/versionchecker.lua`.
- Client-side logic lives in `client/client.lua` (core), `client/coat.lua`, `client/npcs.lua`, `client/horses.lua`, `client/showroom.lua`, `client/action.lua`, `client/horseinfo.lua`, `client/dataview.lua`, and `client/wildhorse.lua`.
- The NUI (stable/customization/shop menus) is in `html/` (`index.html`, `script.js`, `style.css`, `icons/`).

---

## Support

For issues, review the console for errors on startup first (missing dependency, missing database table, or missing items are the most common causes). Check that `rsg-core`, `ox_lib` and `oxmysql` all start before `rsg-horses` in your `server.cfg`.
