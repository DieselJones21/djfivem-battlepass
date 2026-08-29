# DJFIVEM-Battlepass

Chapter **1** / Season **1** battle pass for FiveM. **28 free tiers**, **30-day** season, XP for being in the city, open with **F12**.

```
ensure DJFIVEM-Battlepass
```

## What it does

- **F12** opens the pass (`/battlepass` also works). **ESC** closes it.
- Players earn XP while spawned in the city. AFK (no movement for 3 minutes) pauses XP — set `Config.AfkTimeoutSeconds` in `config.lua`.
- **2000 XP** per tier. Default **8 XP per minute**. Season is **30 days** from `Config.SeasonStart` (UTC).
- **Every tier is free.** Unlock it with city XP, then claim.

## Season 1 rewards (randomized)

Pet Pug is late (tier 26). **WEAPON_4THARP** is last (tier 28). Quantities with no number are **1**.

| Tier | Reward | Item | Qty |
| ---: | --- | --- | ---: |
| 1 | Black Silver Crown | `black_silver_crown` | 1 |
| 2 | Capybara Plushie | `capivara_plushie_shop` | 1 |
| 3 | .44 Ammo | `ammo-44` | 75 |
| 4 | Silver Black Crown | `silver_black_crown` | 1 |
| 5 | Chameleon 215 | `chameleonpaint_215` | 1 |
| 6 | Crayon Bat | `WEAPON_CRAYONBAT` | 1 |
| 7 | Crayon AP | `WEAPON_CRAYONAP` | 1 |
| 8 | Rebel Rolls | `rebel_rolls` | 50 |
| 9 | Multitail Fox | `did_multitail_fox` | 1 |
| 10 | Bear Plushie | `bear_04_plushie_shop` | 1 |
| 11 | Red Karambit | `WEAPON_REDKARAMBIT` | 1 |
| 12 | Elfbar Grape | `vape_elfbar_grape` | 10 |
| 13 | Lava Skeleton | `did_lava_skeleton` | 1 |
| 14 | Chameleon 198 | `chameleonpaint_198` | 1 |
| 15 | Chameleon 169 | `chameleonpaint_169` | 1 |
| 16 | Island Pills | `island_pills` | 50 |
| 17 | Sandwiches | `sandwich` | 5 |
| 18 | Rifle Ammo | `ammo-rifle` | 100 |
| 19 | Girly CX | `WEAPON_GIRLYCX` | 1 |
| 20 | Water | `water` | 5 |
| 21 | 9mm Ammo | `ammo-9` | 50 |
| 22 | Apple Refill | `vape_refill_apple` | 5 |
| 23 | Vape | `vape` | 1 |
| 24 | Pink Halo | `halo_pink` | 1 |
| 25 | Mushroom Plushie | `mushroom_01_plushie_shop` | 1 |
| 26 | Pet Pug | `pet_pug` | 1 |
| 27 | Pink Energy | `pink_energy` | 50 |
| 28 | 4th ARP | `WEAPON_4THARP` | 1 |

These names must exist in your inventory. Item art loads from `ox_inventory/web/images/{item}.png` (then `.webp` / lowercase). Missing files fall back to the built-in SVG. Set `Config.InventoryImageResource` / `Config.InventoryImageFolder` if your path differs. Weapons grant as inventory items first (exact name, then lowercase).

## Going live

1. Set `Config.SeasonStart` in `config.lua` (UTC).
2. Optional: run `sql/install.sql` for oxmysql. Otherwise progress is `data/players.json`.
3. Restart the resource.

## Commands (ACE `djfivem.battlepass.admin`)

| Command | Action |
| --- | --- |
| `/battlepass` | Open the UI |
| `/bpxp [id] [amount]` | Add XP |
| `/bptier [id] [tier]` | Set unlocked tier |
| `/bpreset [id]` | Reset this season |

```
add_ace group.admin djfivem.battlepass.admin allow
```

## Preview without FiveM

```bash
cd html && python3 -m http.server 4173
```
