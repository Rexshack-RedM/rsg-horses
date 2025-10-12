<img width="2948" height="497" alt="rsg_framework" src="https://github.com/user-attachments/assets/638791d8-296d-4817-a596-785325c1b83a" />

# 🐎 rsg-horses
**Advanced horse management and interaction system for RedM using RSG Core.**

![Platform](https://img.shields.io/badge/platform-RedM-darkred)
![License](https://img.shields.io/badge/license-GPL--3.0-green)

> Complete, fully interactive horse system featuring shops, components, XP/bonding, grooming, accessories, and persistent horse data.  
> This README preserves the original control notes and credits from the upstream resource.

---

## 🛠️ Dependencies
- [**rsg-core**](https://github.com/Rexshack-RedM/rsg-core)
- [**rsg-inventory**](https://github.com/Rexshack-RedM/rsg-inventory)
- [**ox_lib**](https://github.com/overextended/ox_lib) *(menus, prompts, localization)*
- [**oxmysql**](https://github.com/overextended/oxmysql) *(horse data storage)*

**Locales:** `en`, `fr`, `es`, `pt-br`, `el`, `it`, `pt`.  
**SQL:** Import `rsg-horses.sql`.

---

## ✨ Features
- Persistent **horse ownership**, name, and stats.
- **Stable shop** with breeds/prices (`shared/config.lua`).
- **Component system** (saddle, blanket, mane, tail, bags, horn, etc.) via `shared/horse_comp.lua` & `shared/horse_settings.lua`.
- **XP / Bonding** improves health, stamina, ability, speed, acceleration, inventory slots & weight. *(See “Controls & Info”)*
- **Usable items**: `horse_brush`, `horse_lantern`, `sugarcube`, etc.
- Localized prompts & notifications (7 languages).

---

## 🎮 Controls & Info (from the original README)
> - Some keys require **bonding level** to work.  
> - May depend on your **RDR2 keybinds** settings.  
> - **Inventory slots & weight depend on horse EXP.**  
> - **Horse EXP** is gained by **hiring a horse trainer**.  
> - Horse EXP improves: **health / stamina / ability / speed / acceleration / inventory‑slots / inventory‑weight**.

Controls (excerpt preserved from original):
- **[W]** move forward
- **[S]** backward
- *(other standard riding controls follow your RDR2 settings)*
- **[LCTRL]** skid when moving
- **[SPACEBAR]** horse jump
- **[SPACEBAR] + [L]** strafe left
- **[SPACEBAR] + [R]** strafe right
- **[LCTRL] + [SPACEBAR]** rear up (when not moving, bonding level required)

> If you customize keybinds in RDR2, the effective keys can differ.

---

## 📜 Commands
| Command | Description |
|--------|-------------|
| `/sethorsename` | Rename your active horse |

---

## 🗺️ Example Configuration
```lua
-- shared/config.lua
Config.horsesShopItems = {
  { name = "horse_morgan_flaxchestnut", label = "Morgan Flax Chestnut", price = 50, xp = 0 },
  { name = "horse_turkoman_gold",        label = "Turkoman Gold",        price = 300, xp = 10 },
}

Config.Stables = {
  {
    name = "valentine",
    coords = vector3(-366.48, 786.45, 116.15),
    showblip = true,
    blipsprite = "blip_shop_stable",
    blipscale = 0.25,
  },
}
```


## ⚙️ Detailed Configuration (shared/)

### `shared/config.lua`
- `horsesShopItems`: Items sold by stable NPCs (e.g., `horse_brush`, `horse_lantern`, `sugarcube`) with `{ amount, price }`. Shown in the stable shop UI.
- `PersistStock` (boolean): If `true`, the shop stock persists in database and is restored after server restarts.

**Stable NPC & UI**
- `DistanceSpawn` (float): Radius within which the stable scene (NPC/horse display) is spawned in world.
- `FadeIn` (boolean): Fade‑in effect after teleporting the player to the stable showcase.

**Stable locations** (array of objects in `StableSettings`):
Each entry defines one stable with:
  - `stableid` (string): Unique ID used to map horses to a specific stable.
  - `coords` (vector3): Marker / prompt position for the stable.
  - `npcmodel` (hash/backtick): Ped model for the stablehand NPC (e.g., ``u_m_m_bwmstablehand_01``).
  - `npccoords` (vector4): Exact spawn coords & heading for the stablehand NPC.
  - `horsecustom` (vec4): Coords & heading where the preview horse is shown.
  - `showblip` (boolean): If `true`, shows a blip on the map for this stable.

### `shared/horse_settings.lua`
Defines the stable **catalog**: which horses appear at which stable, their price and preview placement.
Each entry contains:
  - `horsecoords` (vector4): The exact world position & heading where the preview horse is placed.
  - `horsemodel` (string): RDR2 horse model name (e.g., `a_c_horse_mustang_wildbay`).
  - `horseprice` (number): Purchase price in dollars.
  - `horsename` (string): Display name shown in the shop/menu.
  - `stableid` (string): Must match a `stableid` from `StableSettings` in `shared/config.lua`.

> Tip: You can add/remove horses per stable by editing this list. The order is the in‑world display order.

### `shared/horse_comp.lua`
Defines **customization components** available in the stables menu. Top‑level categories detected include:
`blankets`, `saddles`, `saddlebags`, `stirrups`, `horns`, `manes`, `tails`, `masks`, `mustaches`, `bedrolls`.

**Component entry fields:**
  - `hashid` (int): Local incremental identifier for the component entry.
  - `category` (string): Category key (e.g., `saddles`, `blankets`, `manes`).
  - `category_hash` (hex): Native category hash for the component type.
  - `hash` (hex): The game hash for this specific appearance variant.
  - `hash_dec_signed` (int, optional): Signed decimal equivalent of `hash`.
  - `category_hash_dec_signed` (int, optional): Signed decimal equivalent of `category_hash`.

> These hashes are used by natives to apply the appearance on the horse entity. Do not change unless you know the exact in‑game mapping.


---

## 📂 Installation
1. Place `rsg-horses` inside `resources/[rsg]`.
2. Import `rsg-horses.sql`.
3. Ensure `rsg-core`, `rsg-inventory`, `ox_lib`, `oxmysql` are installed.
4. Add to `server.cfg`:
   ```cfg
   ensure ox_lib
   ensure rsg-core
   ensure rsg-inventory
   ensure rsg-horses
   ```
5. Restart your server.

---

## 🌍 Locales
Available: `en`, `fr`, `es`, `pt-br`, `el`, `it`, `pt` (auto‑loaded via `lib.locale()`).

---

## 💎 Credits (from the original README)
- **Humanity Is Insanity#3505 & Zee#2115** — The Crossroads RP (code inspiration & system)  
- **RedEM-RP** — menu base inspiration: https://github.com/RedEM-RP/redemrp_menu_base  
- **Goghor#9453** — coding assistance / horse bonding work  
- **RSG / Rexshack-RedM** and community contributors  
- License: **GPL‑3.0**  
