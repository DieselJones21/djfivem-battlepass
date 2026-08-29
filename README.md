# DJFIVEM-Battlepass

Chapter **1** / Season **1** battle pass for FiveM. **28 tiers**, **30-day** season, XP for being in the city, open with **F12**.

Drop this folder into `resources` as `DJFIVEM-Battlepass` (or `djfivem-battlepass`) and add:

```
ensure DJFIVEM-Battlepass
```

## What it does

- **F12** opens the pass (`/battlepass` also works). **ESC** closes it.
- Players earn XP automatically while they are spawned in the city (not in the pause menu). Standing still too long counts as AFK and pauses XP — change `Config.AfkTimeoutSeconds` in `config.lua`.
- Each tier costs **2000 XP** (56,000 XP to finish). Default rate is **8 XP per minute**, so a player on ~4 hours a day finishes in about 30 days. Premium players earn **2x city XP**.
- Season length is **30 days** from `Config.SeasonStart` (UTC). The UI countdown is shared by everyone.
- Free tiers (1, 5, 11, 17, 21, 25) can be claimed without premium. All other tiers need premium.

## Season 1 rewards (edit these)

All 28 rewards live in `config.lua` → `Config.Tiers`. Swap `name`, `description`, `item`, `amount`, `type`, and `premium` to match your inventory.

| Tier | Reward | Track |
| ---: | --- | --- |
| 1 | Street Starter ($2,500) | Free |
| 2 | Bandage Bundle (10) | Premium |
| 3 | Big Drinks | Premium |
| 4 | LSD | Premium |
| 5 | Knife | Free |
| 6 | Lockpick Kit | Premium |
| 7 | Adrenaline Shots | Premium |
| 8 | Black and Cyan Crown | Premium |
| 9 | 44MM Ammo (85) | Premium |
| 10 | Bag of Money ($10,000) | Premium |
| 11 | Tec-9 | Free |
| 12 | 10x Sprunks | Premium |
| 13 | A Box of Money ($20,000) | Premium |
| 14 | Dino Plan | Premium |
| 15 | Heavy Armor | Premium |
| 16 | Gold Chain | Premium |
| 17 | AP Pistol | Free |
| 18 | Cash Drop ($25,000) | Premium |
| 19 | Encrypted Radio | Premium |
| 20 | SMG Ammo Crate | Premium |
| 21 | Thick Envelope ($40,000) | Free |
| 22 | Drift Plate | Premium |
| 23 | Combat PDW | Premium |
| 24 | Season Crate | Premium |
| 25 | Vault Stack ($75,000) | Free |
| 26 | Garage Voucher | Premium |
| 27 | Diamond Rolex | Premium |
| 28 | Champion 1F (Sultan RS voucher) | Premium |

Item spawn names (`bandage`, `weapon_knife`, `ammo-44`, …) are placeholders. Change them to whatever your `qb-core` / `ox_inventory` / ESX items are called, or the grant will log a warning and the claim will still be marked.

Custom images: put a PNG/SVG in `html/icons/` and set `icon = 'yourfile.png'` on that tier. Remember to add the file to `fxmanifest.lua` if you leave the current `html/icons/*.svg` glob.

## Going live

1. Set `Config.SeasonStart` in `config.lua` to your launch time (UTC), e.g. `'2026-08-29 00:00:00'`.
2. Run `sql/install.sql` if you use **oxmysql**. If oxmysql is not started, progress is saved to `data/players.json`.
3. Give yourself premium to test paid tiers: `/bppgive` (or `/bppgive [id]`).
4. Restart the resource.

## Commands (ACE `djfivem.battlepass.admin`)

| Command | Action |
| --- | --- |
| `/battlepass` | Open the UI (everyone) |
| `/bppgive [id]` | Grant premium |
| `/bpxp [id] [amount]` | Add XP |
| `/bptier [id] [tier]` | Set unlocked tier |
| `/bpreset [id]` | Reset this season's progress |

server.cfg example:

```
add_ace group.admin djfivem.battlepass.admin allow
```

## Frameworks

Auto-detects **qbx_core**, **qb-core**, **es_extended**, then standalone. Inventory auto-detects **ox_inventory**, then QB/ESX.

Vehicle rewards fire `djfivem_battlepass:server:grantVehicle` (`source`, `model`, `reward`) so you can insert into your garage. A voucher item `battlepass_vehicle_voucher` is also granted when possible.

## Exports

```lua
exports['djfivem-battlepass']:GetPlayerXp(src)
exports['djfivem-battlepass']:GetPlayerTier(src)
exports['djfivem-battlepass']:AddXP(src, amount)
exports['djfivem-battlepass']:GivePremium(src)
exports['djfivem-battlepass']:IsPremium(src)
```

Use your actual resource folder name in the export if it differs.

## Preview the UI without FiveM

```bash
cd html && python3 -m http.server 4173
```

Open `http://localhost:4173` — the page loads with mock Chapter 1 Season 1 progress so you can click, drag-scroll, and claim in the browser.
