# RSG-Horses Framework Documentation

<img width="2948" height="497" alt="rsg_framework" src="https://github.com/user-attachments/assets/638791d8-296d-4817-a596-785325c1b83a" />

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Installation](#installation)
4. [Configuration](#configuration)
5. [Database Schema](#database-schema)
6. [Core Systems](#core-systems)
7. [API & Exports](#api--exports)
8. [Items & Usables](#items--usables)
9. [Commands](#commands)
10. [Events](#events)
11. [Customization](#customization)
12. [Webhooks & Logging](#webhooks--logging)
13. [Troubleshooting](#troubleshooting)

---

## Overview

**rsg-horses** is an advanced horse management system for RedM servers using the RSG Core framework. It provides a complete, immersive horse ownership experience including:

- **Persistent horse ownership** with database storage
- **Multiple stable locations** across the map
- **XP/Bonding system** that affects horse performance
- **Component customization** (saddles, blankets, manes, tails, etc.)
- **Horse care mechanics** (feeding, grooming, reviving)
- **Inventory system** for horses
- **Interactive animations** and tricks
- **Multi-language support** (8 languages)

### Key Features
- **Version**: 2.1.7
- **Framework**: RSG Core (RedM)
- **Database**: MySQL (via oxmysql)
- **UI Library**: ox_lib
- **Locales**: English, French, Spanish, Portuguese (BR & PT), Greek, Italian, Polish

---

## Architecture

### File Structure

```
rsg-horses/
├── client/
│   ├── client.lua          # Main client logic, horse spawning, prompts
│   ├── npcs.lua            # Stable NPC management
│   ├── horses.lua          # Horse interaction handlers
│   ├── action.lua          # Horse actions (drink, graze, lay, play)
│   ├── horseinfo.lua       # Horse info display & stats
│   └── dataview.lua        # Data viewing utilities
├── server/
│   ├── server.lua          # Main server logic, database operations
│   ├── webhook.lua         # Discord webhook logging
│   └── versionchecker.lua  # Version checking system
├── shared/
│   ├── config.lua          # Main configuration file
│   ├── functions.lua       # Shared utility functions
│   ├── horse_settings.lua  # Horse catalog (breeds, prices, locations)
│   └── horse_comp.lua      # Component definitions (saddles, etc.)
├── config/
│   └── webhook.lua         # Webhook configuration
├── installation/
│   ├── rsg-horses.sql      # Database schema
│   ├── shared_items.lua    # Item definitions
│   └── WEBHOOK_*.md        # Webhook setup guides
└── locales/
    └── *.json              # Translation files
```

### Dependencies

**Required:**
- [rsg-core](https://github.com/Rexshack-RedM/rsg-core) - Core framework
- [rsg-inventory](https://github.com/Rexshack-RedM/rsg-inventory) - Inventory system
- [ox_lib](https://github.com/overextended/ox_lib) - Menus, prompts, localization
- [oxmysql](https://github.com/overextended/oxmysql) - Database operations

---

## Installation

### Step 1: File Setup
1. Extract `rsg-horses` to your `resources/[rsg]/` directory
2. Ensure all dependencies are installed

### Step 2: Database Setup
Import the SQL file:
```sql
-- Execute: installation/rsg-horses.sql
```

This creates the `player_horses` table with the following structure:
- `id` - Primary key
- `stable` - Home stable location
- `citizenid` - Player identifier
- `horseid` - Unique horse identifier
- `name` - Horse custom name
- `horse` - Horse model name
- `dirt` - Cleanliness level (0-100)
- `horsexp` - Experience points
- `components` - JSON for customization
- `gender` - Male/Female
- `wild` - Wild horse flag
- `active` - Currently active horse (1/0)
- `born` - Birth timestamp

### Step 3: Item Setup
Add items from `installation/shared_items.lua` to your `rsg-core/shared/items.lua`:

```lua
-- Core horse items
horse_brush         = { name = 'horse_brush',       label = 'Horse Brush',      weight = 100, ... },
horse_lantern       = { name = 'horse_lantern',     label = 'Horse Lantern',    weight = 100, ... },
horse_stimulant     = { name = 'horse_stimulant',   label = 'Horse Stimulant',  weight = 100, ... },
horse_reviver       = { name = 'horse_reviver',     label = 'Horse Reviver',    weight = 100, ... },
horse_carrot        = { name = 'horse_carrot',      label = 'Horse Carrot',     weight = 100, ... },
horse_apple         = { name = 'horse_apple',       label = 'Horse Apple',      weight = 100, ... },
sugarcube           = { name = 'sugarcube',         label = 'Sugar Cube',       weight = 100, ... },
haysnack            = { name = 'haysnack',          label = 'Hay Snack',        weight = 100, ... },
horsemeal           = { name = 'horsemeal',         label = 'Horse Meal',       weight = 100, ... },
```

### Step 4: Server Configuration
Add to `server.cfg`:
```cfg
ensure ox_lib
ensure oxmysql
ensure rsg-core
ensure rsg-inventory
ensure rsg-horses
```

### Step 5: Restart Server
Restart your server and verify no errors in console.

---

## Configuration

### Main Config (`shared/config.lua`)

#### General Settings

```lua
Config.Debug = false                    -- Enable debug mode
Config.EnableTarget = true              -- Use target system vs prompts
Config.TargetHelp = false               -- Show target help text
Config.Automount = false                -- Auto-mount when spawned
Config.SpawnOnRoadOnly = false          -- Force spawn on roads
Config.KeyBind = 'J'                    -- Default keybind for horse menu
Config.AllowTwoPlayersRide = true       -- Enable passenger riding
```

#### Horse Inventory Settings

```lua
Config.HorseInvKey = 0x760A9C6F         -- Hotkey for inventory (G)
Config.HorseInvWeight = 16000           -- Base inventory weight
Config.HorseInvSlots = 25               -- Base inventory slots
```

**Level-Based Inventory:**
Horse inventory capacity increases with XP level (1-10):
```lua
-- Level 1: 4000 weight, 4 slots
-- Level 5: 10000 weight, 12 slots  
-- Level 10: 16000 weight, 25 slots
```

#### Horse Lifecycle

```lua
Config.CheckCycle = 30                  -- Health check interval (minutes)
Config.StarterHorseDieAge = 7           -- Starter horse lifespan (days)
Config.HorseDieAge = 365                -- Regular horse lifespan (days)
Config.StoreFleedHorse = false          -- Auto-store when fled
Config.DeathGracePeriod = 60000         -- Revival window (milliseconds)
```

#### XP & Bonding

```lua
Config.MaxBondingLevel = 5000           -- Maximum bonding XP

-- XP requirements for levels 1-10
Config.Level1 = 100
Config.Level2 = 200
-- ... up to Config.Level10 = 2000
```

**Level Benefits:**
- **Health/Stamina/Speed** improvements per level
- **Ability** enhancements
- **Inventory capacity** increases
- **Acceleration** bonuses

#### Stable Shop Items

```lua
Config.horsesShopItems = {
    { name = 'horse_brush',     amount = 10, price = 5 },
    { name = 'horse_lantern',   amount = 10, price = 10 },
    { name = 'sugarcube',       amount = 50, price = 0.05 },
    { name = 'horse_carrot',    amount = 50, price = 0.10 },
    -- ...
}
Config.PersistStock = false             -- Persist stock in database
```

#### Horse Feeding Effects

```lua
Config.HorseFeed = {
    ['horse_carrot']    = { health = 10,  stamina = 10,  ismedicine = false },
    ['horse_apple']     = { health = 15,  stamina = 15,  ismedicine = false },
    ['sugarcube']       = { health = 25,  stamina = 25,  ismedicine = false },
    ['haysnack']        = { health = 50,  stamina = 25,  ismedicine = false },
    ['horsemeal']       = { health = 75,  stamina = 75,  ismedicine = false },
    ['horse_stimulant'] = { health = 100, stamina = 100, ismedicine = true, 
                            medicineHash = 'consumable_horse_stimulant' },
}
```

#### Component Customization Pricing

```lua
Config.PriceComponent = {
    Blankets    = 5,
    Saddles     = 2,
    Horns       = 10,
    Saddlebags  = 3,
    Stirrups    = 4,
    Bedrolls    = 5,
    Tails       = 4,
    Manes       = 3,
    Masks       = 3,
    Mustaches   = 2,
}
```

#### Prompt Controls

```lua
Config.Prompt = {
    HorseDrink      = 0xD8CF0C95,       -- E key
    HorseGraze      = 0xD8CF0C95,       -- E key
    HorseLay        = 0xD8CF0C95,       -- E key
    HorsePlay       = 0x620A6C5E,       -- Q key
    HorseSaddleBag  = 0xC7B5340A,       -- B key
    HorseBrush      = 0x63A38F2C,       -- Z key
    Rotate          = { 0x7065027D, 0xB4E465B4 }, -- A/D keys
}
```

### Stable Locations (`shared/config.lua`)

Each stable is defined in `Config.StableSettings`:

```lua
{
    stableid = 'valentine',                              -- Unique identifier
    coords = vector3(-365.2, 791.94, 116.18),           -- Interaction point
    npcmodel = `u_m_m_bwmstablehand_01`,                 -- NPC model hash
    npccoords = vector4(-365.2, 791.94, 116.18, 180.9), -- NPC spawn location
    horsecustom = vec4(-388.52, 784.06, 115.82, 150.41),-- Horse preview location
    showblip = true                                      -- Show on map
}
```

**Default Stables:**
- Colter
- Van Horn
- Saint Denis
- Rhodes
- Valentine
- Strawberry
- Blackwater
- Tumbleweed
- Emerald Ranch

### Horse Catalog (`shared/horse_settings.lua`)

Defines purchasable horses per stable:

```lua
{
    horsecoords = vector4(-357.77, 771.73, 116.52, 5.00),  -- Display position
    horsemodel = 'a_c_horse_dutchwarmblood_chocolateroan',  -- Model name
    horseprice = 250,                                       -- Price in dollars
    horsename = 'Chocolate Dutch Warmblood',                -- Display name
    stableid = 'valentine'                                  -- Assigned stable
}
```

### Component Definitions (`shared/horse_comp.lua`)

Large file containing component hashes for customization. Categories include:
- **Blankets** - Horse blankets
- **Saddles** - Various saddle types
- **Saddlebags** - Storage bags
- **Stirrups** - Saddle stirrups
- **Horns** - Saddle horns
- **Bedrolls** - Bedroll attachments
- **Tails** - Tail styles
- **Manes** - Mane styles
- **Masks** - Face masks
- **Mustaches** - Facial hair (decorative)

Each component entry contains:
```lua
{
    hashid = 1,                                 -- Local ID
    category = 'saddles',                       -- Component category
    category_hash = 0xBAA7E618,                 -- Native category hash
    hash = 0x15FB6791,                          -- Component hash
    hash_dec_signed = 369747857,                -- Decimal equivalent
    category_hash_dec_signed = -1163691496      -- Category decimal
}
```

---

## Database Schema

### `player_horses` Table

| Column | Type | Description |
|--------|------|-------------|
| `id` | INT(11) AUTO_INCREMENT | Primary key |
| `stable` | VARCHAR(50) | Home stable ID |
| `citizenid` | VARCHAR(50) | Player's citizen ID (RSG Core) |
| `horseid` | VARCHAR(11) | Unique horse identifier |
| `name` | VARCHAR(255) | Custom horse name |
| `horse` | VARCHAR(50) | Horse model name |
| `dirt` | INT(11) | Dirt level (0-100) |
| `horsexp` | INT(11) | Experience points |
| `components` | LONGTEXT | JSON string of applied components |
| `gender` | VARCHAR(11) | 'male' or 'female' |
| `wild` | VARCHAR(11) | Wild horse flag |
| `active` | TINYINT(4) | Currently active horse (1=yes, 0=no) |
| `born` | INT(11) | Unix timestamp of birth |

**Indexes:**
- Primary key on `id`

**Important Notes:**
- Only one horse per player can have `active = 1`
- `horseid` is generated server-side via `GenerateHorseid()`
- `components` stores JSON with applied customization hashes
- `born` is used to calculate horse age and death

---

## Core Systems

### 1. Horse Spawning System

**Client-side Process:**
1. Player requests horse spawn
2. System checks for active horse in database
3. Horse entity spawned at player location (or road if configured)
4. Components applied from database
5. Stats (health, stamina, bonding) set based on XP
6. Prompts/blips created
7. Horse registered to player

**Key Functions:**
- `SpawnHorse()` - Main spawn handler
- `SetupHorsePrompts()` - Creates interaction prompts
- `ApplyHorseComponents()` - Applies saved customization

### 2. Experience & Bonding System

**XP Sources:**
- Hiring trainers (primary method)
- Horse tricks (lay, play)
- Feeding and grooming
- Time spent with horse

**Bonding Levels (1-10):**
- **Level 1-2**: Basic riding, low stats
- **Level 3-5**: Improved control, medium stats
- **Level 6-8**: Advanced tricks, high stats
- **Level 9-10**: Maximum performance

**XP Benefits:**
```lua
-- At each level, horse gains:
- Increased health
- Increased stamina
- Better speed/acceleration
- More inventory slots/weight
- Unlock tricks (lay at 1000 XP, play at 2000 XP)
```

### 3. Horse Care System

**Grooming:**
- Use `horse_brush` item
- Reduces dirt level
- Slightly restores stamina
- Increases bonding

**Feeding:**
- Multiple food items with varying benefits
- Restores health and stamina
- Better food = better restoration
- Medicine items cure ailments

**Revival:**
- Use `horse_reviver` within grace period
- Grace period: 60 seconds (configurable)
- Fully restores health and stamina
- Horse must be dead but not despawned

### 4. Component Customization

**Access:**
- At any stable NPC
- "Customize Horse" menu option

**Categories:**
- Saddles, blankets, bags, horns
- Manes, tails, masks, mustaches
- Stirrups, bedrolls

**Process:**
1. Select category
2. Browse available components
3. Preview on horse (real-time)
4. Confirm purchase (if cost > $0)
5. Components saved to database
6. Applied on every spawn

### 5. Stable Shop System

**Features:**
- Buy horses (breed selection)
- Purchase horse care items
- Access owned horses
- Customize horses
- Set active horse

**Stock Management:**
```lua
Config.PersistStock = false  -- If true, stock persists across restarts
```

**Horse Purchase:**
1. Interact with stable NPC
2. Select "Buy Horse"
3. Browse available horses at that stable
4. Choose horse and set name/gender
5. Pay price (deducted from cash)
6. Horse added to database

### 6. Horse Actions & Tricks

**Basic Actions:**
- **Drink**: Near water troughs (`p_watertrough01x`, etc.)
- **Graze**: Near hay piles (`p_haypile01x`)
- Both restore small amounts of health/stamina

**Tricks (XP-Locked):**
- **Lay Down**: Requires 1000 XP
- **Play/Rear**: Requires 2000 XP

**Configuration:**
```lua
Config.ObjectAction = true  -- Enable automatic action near objects
Config.TrickXp = {
    Lay = 1000,
    Play = 2000
}
```

### 7. Horse Inventory System

**Access Methods:**
- Hotkey (default: G)
- Saddlebag prompt
- Target system

**Capacity:**
- Base: 16000 weight, 25 slots
- Level 1: 4000 weight, 4 slots
- Scales with XP level up to Level 10

**Integration:**
- Uses `rsg-inventory` system
- Separate stash per horse ID
- Persists across server restarts

### 8. Horse Lifecycle Management

**Birth:**
- Timestamp recorded on purchase/spawn
- Used to calculate age

**Aging:**
- Starter horses: Die after 7 days (default)
- Regular horses: Die after 365 days (default)
- Configurable in `Config.StarterHorseDieAge` and `Config.HorseDieAge`

**Death:**
- Health reaches 0
- Grace period begins (60 seconds default)
- Can be revived with `horse_reviver`
- After grace period, horse is removed from database

**Check System:**
- Runs every X minutes (`Config.CheckCycle`)
- Checks age and marks horses for death
- Server-side: `CheckHorses()` function

---

## API & Exports

### Client Exports

#### `CheckHorseLevel()`
Returns the current horse's XP level (1-10).

```lua
local level = exports['rsg-horses']:CheckHorseLevel()
print('Horse is level: ' .. level)
```

#### `CheckHorseBondingLevel()`
Returns the current bonding XP amount.

```lua
local bonding = exports['rsg-horses']:CheckHorseBondingLevel()
print('Bonding XP: ' .. bonding)
```

#### `CheckActiveHorse()`
Returns the entity ID of the active horse ped.

```lua
local horsePed = exports['rsg-horses']:CheckActiveHorse()
if horsePed ~= 0 then
    print('Horse entity: ' .. horsePed)
end
```

### Server Callbacks

#### `rsg-horses:server:GetAllHorses`
Retrieves all horses owned by a player.

```lua
-- Client-side usage
RSGCore.Functions.TriggerCallback('rsg-horses:server:GetAllHorses', function(horses)
    if horses then
        for k, v in pairs(horses) do
            print(v.name .. ' - ' .. v.horse)
        end
    end
end)
```

**Returns:** Array of horse data or `nil`

---

## Items & Usables

### Horse Care Items

| Item | Effect | Useable | Description |
|------|--------|---------|-------------|
| `horse_brush` | Cleans horse, reduces dirt | Yes | Grooming tool |
| `horse_lantern` | Equips lantern on horse | Yes | Provides light |
| `horse_stimulant` | +100 health, +100 stamina | Yes | Medicine |
| `horse_reviver` | Revives dead horse | Yes | Emergency revival |

### Feed Items

| Item | Health | Stamina | Price | Description |
|------|--------|---------|-------|-------------|
| `horse_carrot` | +10 | +10 | $0.10 | Basic snack |
| `horse_apple` | +15 | +15 | $0.10 | Healthy snack |
| `sugarcube` | +25 | +25 | $0.05 | Sweet treat |
| `haysnack` | +50 | +25 | $0.25 | Hay cube |
| `horsemeal` | +75 | +75 | $0.50 | Full meal |

### Equipment Items

| Item | Function | Description |
|------|----------|-------------|
| `horse_lantern` | Visibility | Equipped to saddle horn |
| `horse_holster` | Weapon storage | (Planned feature) |

---

## Commands

### Player Commands

#### `/sethorsename`
Rename your currently active horse.

**Usage:**
```
/sethorsename [new name]
```

**Example:**
```
/sethorsename Thunder
```

**Requirements:**
- Must have an active horse
- Horse must be spawned

#### `/findhorse`
Shows the location of your active horse on the map.

**Usage:**
```
/findhorse
```

**Effect:**
- Creates temporary blip at horse location
- Useful if horse is lost

---

## Events

### Server Events

#### `rsg-horses:server:BuyHorse`
Handles horse purchase from stable.

**Parameters:**
- `model` (string): Horse model name
- `stable` (string): Stable ID
- `horsename` (string): Custom name
- `gender` (string): 'male' or 'female'

```lua
TriggerServerEvent('rsg-horses:server:BuyHorse', 
    'a_c_horse_morgan_bay', 
    'valentine', 
    'My Horse', 
    'male'
)
```

#### `rsg-horses:server:SetHoresActive`
Sets a horse as the active horse.

**Parameters:**
- `id` (number): Database ID of horse

```lua
TriggerServerEvent('rsg-horses:server:SetHoresActive', horseId)
```

#### `rsg-horses:server:revivehorse`
Server-side horse revival handling.

**Parameters:**
- `item` (table): Item data
- `horseData` (table): Horse database entry

#### `rsg-horses:server:fleeStoreHorse`
Stores horse when it flees.

**Parameters:**
- `stableId` (string): Closest stable ID

### Client Events

#### `rsg-horses:client:gethorselocation`
Displays horse location blip.

```lua
TriggerEvent('rsg-horses:client:gethorselocation')
```

#### `rsg-horses:client:playerbrushhorse`
Handles horse grooming action.

**Parameters:**
- `itemName` (string): Item used ('horse_brush')

#### `rsg-horses:client:playerfeedhorse`
Handles horse feeding action.

**Parameters:**
- `itemName` (string): Food item name

#### `rsg-horses:client:equipHorseLantern`
Equips lantern to horse.

**Parameters:**
- `itemName` (string): 'horse_lantern'

#### `rsg-horses:client:revivehorse`
Client-side horse revival.

**Parameters:**
- `item` (table): Reviver item data
- `horseData` (table): Horse database entry

---

## Customization

### Adding New Horses

**Step 1:** Add to `shared/horse_settings.lua`
```lua
{
    horsecoords = vector4(x, y, z, heading),
    horsemodel = 'a_c_horse_BREED_VARIANT',
    horseprice = 500,
    horsename = 'Custom Horse Name',
    stableid = 'valentine'  -- Must match existing stable
}
```

**Step 2:** No restart needed for existing stables; new horses appear immediately.

### Adding New Stables

**Step 1:** Add to `Config.StableSettings` in `shared/config.lua`
```lua
{
    stableid = 'mystable',
    coords = vector3(x, y, z),
    npcmodel = `u_m_m_bwmstablehand_01`,
    npccoords = vector4(x, y, z, heading),
    horsecustom = vec4(x, y, z, heading),
    showblip = true
}
```

**Step 2:** Add horses to `shared/horse_settings.lua` with matching `stableid`.

### Adding New Components

Components are defined in `shared/horse_comp.lua`. To add new ones:

1. Find the component hash from game files
2. Add entry with proper structure:
```lua
{
    hashid = nextNumber,
    category = 'saddles',
    category_hash = 0xBAA7E618,
    hash = 0xYOURHASH,
    hash_dec_signed = decimalValue,
    category_hash_dec_signed = categoryDecimal
}
```

3. Price is controlled by `Config.PriceComponent[category]`

### Modifying XP Requirements

Edit `shared/config.lua`:
```lua
-- Adjust level thresholds
Config.Level1 = 100   -- Easy: Lower values
Config.Level10 = 2000 -- Hard: Higher values

-- Adjust trick requirements
Config.TrickXp = {
    Lay = 500,    -- Lower = unlock sooner
    Play = 1000
}
```

### Custom Feeding Effects

Modify `Config.HorseFeed` in `shared/config.lua`:
```lua
Config.HorseFeed = {
    ['mycustomfood'] = { 
        health = 50, 
        stamina = 50, 
        ismedicine = false 
    },
}
```

Then create the useable item in server code:
```lua
RSGCore.Functions.CreateUseableItem('mycustomfood', function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('rsg-horses:client:playerfeedhorse', source, item.name)
    end
end)
```

---

## Webhooks & Logging

### Setup

Configure webhooks in `config/webhook.lua`:
```lua
Webhook = {
    webhook = 'YOUR_DISCORD_WEBHOOK_URL',
    name = 'RSG Horses',
    image = 'https://your-image-url.png'
}
```

### Logged Events

1. **Horse Purchase**
   - Player info
   - Horse name, model, gender
   - Price paid
   - Stable location

2. **Horse Feed**
   - Player info
   - Item used
   - Timestamp

3. **Horse Brush**
   - Player info
   - Timestamp

4. **Horse Equipment**
   - Player info
   - Item equipped (lantern, holster)
   - Timestamp

5. **Horse Revival**
   - Player info
   - Horse name
   - Timestamp

### Custom Logging

To add custom webhook logs, use the functions in `server/webhook.lua`:

```lua
-- Example: Log custom event
local function LogCustomEvent(source, data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    local webHook = {
        {
            ['color'] = 3447003,
            ['title'] = '**Custom Horse Event**',
            ['description'] = 'Custom event description',
            ['footer'] = {
                ['text'] = os.date('%c'),
            },
        }
    }
    
    TriggerEvent('rsg-log:server:CreateLog', 'horses', 'Custom Event', 'blue', webHook, false)
end
```

---

## Troubleshooting

### Common Issues

#### Horse Won't Spawn
**Symptoms:** No horse appears when called
**Solutions:**
1. Check database: `SELECT * FROM player_horses WHERE citizenid='YOURCITIZENID'`
2. Verify `active = 1` for one horse
3. Check console for errors
4. Ensure `rsg-core` is running
5. Verify player has permission

#### Components Not Applying
**Symptoms:** Horse looks default despite customization
**Solutions:**
1. Check `components` column in database (should be valid JSON)
2. Verify component hashes in `shared/horse_comp.lua`
3. Clear cache and respawn horse
4. Check for conflicting scripts

#### XP Not Increasing
**Symptoms:** Horse level stays at 1
**Solutions:**
1. Verify trainer system is implemented (not included in base script)
2. Check `horsexp` column in database
3. Manually set XP for testing: 
   ```sql
   UPDATE player_horses SET horsexp=500 WHERE id=YOURHORSEID
   ```

#### Horse Dies Immediately
**Symptoms:** Horse spawns dead or dies right away
**Solutions:**
1. Check `born` timestamp in database
2. Verify `Config.HorseDieAge` is reasonable (default 365 days)
3. For testing, set to 0: `Config.HorseDieAge = 0` (disables aging)

#### Inventory Not Working
**Symptoms:** Can't access horse inventory
**Solutions:**
1. Ensure `rsg-inventory` is installed and running
2. Check hotkey binding (`Config.HorseInvKey`)
3. Verify horse is spawned and active
4. Check for permission issues

#### Stable NPC Missing
**Symptoms:** No NPC at stable location
**Solutions:**
1. Check `Config.DistanceSpawn` (increase if too small)
2. Verify NPC model hash is correct
3. Check for conflicting population scripts
4. Ensure player is within spawn distance

### Debug Mode

Enable debug in `shared/config.lua`:
```lua
Config.Debug = true
```

This will print additional console information for:
- Horse spawning
- Component application
- XP calculations
- Event triggers

### Performance Optimization

If experiencing lag:

1. **Reduce check frequency:**
   ```lua
   Config.CheckCycle = 60  -- Increase from 30 to 60 minutes
   ```

2. **Disable unused features:**
   ```lua
   Config.ObjectAction = false  -- Disable auto-actions
   Config.EnableServerNotify = false
   ```

3. **Limit stable count:** Remove unused stables from `Config.StableSettings`

4. **Optimize spawn distance:**
   ```lua
   Config.DistanceSpawn = 10.0  -- Reduce from 20.0
   ```

### Database Maintenance

**Clean orphaned horses:**
```sql
-- Remove horses from players who no longer exist
DELETE FROM player_horses 
WHERE citizenid NOT IN (SELECT citizenid FROM players);
```

**Reset all active horses:**
```sql
UPDATE player_horses SET active = 0;
```

**Clear old dead horses:**
```sql
-- Remove horses older than 1 year
DELETE FROM player_horses 
WHERE (UNIX_TIMESTAMP() - born) > 31536000;
```

---

## Advanced Topics

### Multi-Language Support

To add a new language:

1. Create `locales/yourlang.json`:
```json
{
    "cf_menu_horse_blip_name": "Stable",
    "cl_action_lay": "Lay Down",
    "sv_error_no_cash": "Not enough money"
}
```

2. Restart server (auto-detected by ox_lib)

### Custom Animations

Animations are defined in `Config.Anim` (client/client.lua context):
```lua
Config.Anim = {
    Drink  = { dict = 'amb_creature_mammal@world_horse_drink_ground@base', 
               anim = 'base', 
               duration = 20 },
    CustomAnim = { dict = 'your_dict', 
                   anim = 'your_anim', 
                   duration = 10 }
}
```

### Integration with Other Scripts

**Example: Job-locked stables**
```lua
-- In client/npcs.lua or similar
if RSGCore.Functions.GetPlayerData().job.name ~= 'rancher' then
    -- Don't show stable prompt
    return
end
```

**Example: Custom horse spawn location**
```lua
-- Override spawn function
exports['rsg-horses']:SpawnHorseAt(x, y, z, heading)
```

---

## Credits

- **Humanity Is Insanity#3505 & Zee#2115** — The Crossroads RP (system inspiration)
- **RedEM-RP** — Menu base inspiration
- **Goghor#9453** — Bonding system development
- **RSG / Rexshack-RedM** — Framework and community
- **Contributors** — Various community members

## License

**GPL-3.0** - See LICENSE file for details

---

## Support & Community

- **GitHub Issues**: [Report bugs](https://github.com/Rexshack-RedM/rsg-horses/issues)
- **Discord**: Join RSG Community Discord
- **Documentation**: This file + inline code comments

---

## Changelog

### Version 2.1.7
- Current stable release
- Multiple stable locations
- Component customization system
- XP/Bonding mechanics
- Webhook logging
- Multi-language support

---

**Last Updated:** 2025  
**Maintained By:** RSG Framework Team  
**Framework Version:** RedM / RSG Core
