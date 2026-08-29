Config = {}

-- Resource display name shown in the NUI header.
Config.ResourceTitle = 'DJFIVEM-Battlepass'

-- Chapter 1 / Season 1. Change these when you start a new season.
Config.Chapter = 1
Config.Season = 1
Config.SeasonId = 'c1s1'
Config.SeasonLabel = 'CHAPTER 1  ·  SEASON 1'

-- 30-day season. Set SeasonStart (UTC) to the moment you go live.
-- Format: 'YYYY-MM-DD HH:MM:SS' (UTC). Players share this countdown.
Config.SeasonStart = '2026-08-29 00:00:00'
Config.SeasonDurationDays = 30

-- F12 opens the pass. /battlepass also works.
Config.OpenKey = 'F12'
Config.OpenCommand = 'battlepass'

-- XP is earned by being spawned in the city (playtime), not from kills.
-- Default: 8 XP per minute ≈ 28 tiers (56,000 XP) in ~30 days at 4 hours/day.
Config.XpPerTier = 2000
Config.XpIntervalSeconds = 60
Config.XpPerTick = 8
-- 0 = award XP even while standing still. 180 = pause XP after 3 minutes without movement.
Config.AfkTimeoutSeconds = 180
Config.AfkMoveThreshold = 1.25 -- metres that count as "moved"

-- Premium pass: 2x city XP and access to premium-only tiers.
Config.PremiumXpMultiplier = 2.0
Config.PremiumItem = 'battlepass_premium' -- optional inventory item that unlocks premium
Config.PremiumCommand = 'bppgive' -- /bppgive [id] (ace: djfivem.battlepass.admin)

-- Framework is auto-detected: qb-core, qbx_core, es_extended, then standalone.
Config.Framework = 'auto' -- 'auto' | 'qb' | 'qbx' | 'esx' | 'standalone'
Config.Inventory = 'auto' -- 'auto' | 'ox' | 'qb' | 'esx' | 'none'

-- Notifications: ox_lib if started, otherwise native GTA help text.
Config.Notify = 'auto'

-- Persistence: oxmysql when started, otherwise data/players.json
Config.UseDatabase = true

-- Admin ACE permission for XP/premium/reset commands.
Config.AdminAce = 'djfivem.battlepass.admin'

-- Close key shown in the UI.
Config.CloseKeyLabel = 'ESC'

-- Optional event fired after a vehicle-type reward is claimed.
-- Use this to insert into your garage. Payload: source, model, reward table.
Config.VehicleGrantEvent = 'djfivem_battlepass:server:grantVehicle'

--[[
    28-tier Chapter 1 Season 1 track.

    Swap `item` / `amount` to match your inventory. Types:
      money   - cash via the detected framework
      item    - inventory item
      weapon  - weapon item (or ESX addWeapon)
      vehicle - fires Config.VehicleGrantEvent (and gives a voucher item if set)

    premium = false  →  tagged FREE, claimable without a premium pass
    rarity  = common | rare | epic | legendary
]]
Config.Tiers = {
    {
        tier = 1,
        name = 'Street Starter',
        description = 'A little cash to get you moving through the city.',
        type = 'money',
        item = 'money',
        amount = 2500,
        rarity = 'common',
        premium = false,
        icon = 'tier_01.svg'
    },
    {
        tier = 2,
        name = 'Bandage Bundle',
        description = 'Ten field bandages. Patch up and keep grinding.',
        type = 'item',
        item = 'bandage',
        amount = 10,
        rarity = 'common',
        premium = true,
        icon = 'tier_02.svg'
    },
    {
        tier = 3,
        name = 'Big Drinks',
        description = 'A fridge pack of cold drinks for long nights in the city.',
        type = 'item',
        item = 'ecola',
        amount = 15,
        rarity = 'common',
        premium = true,
        icon = 'tier_03.svg'
    },
    {
        tier = 4,
        name = 'LSD',
        description = 'A small bag of tabs. Handle with care.',
        type = 'item',
        item = 'lsd',
        amount = 5,
        rarity = 'rare',
        premium = true,
        icon = 'tier_04.svg'
    },
    {
        tier = 5,
        name = 'Knife',
        description = 'A sharp blade for when words stop working.',
        type = 'weapon',
        item = 'weapon_knife',
        amount = 1,
        rarity = 'common',
        premium = false,
        icon = 'tier_05.svg'
    },
    {
        tier = 6,
        name = 'Lockpick Kit',
        description = 'Eight lockpicks. Quiet hands, open doors.',
        type = 'item',
        item = 'lockpick',
        amount = 8,
        rarity = 'common',
        premium = true,
        icon = 'tier_06.svg'
    },
    {
        tier = 7,
        name = 'Adrenaline Shots',
        description = 'Five syringes. Get back on your feet fast.',
        type = 'item',
        item = 'adrenaline',
        amount = 5,
        rarity = 'rare',
        premium = true,
        icon = 'tier_07.svg'
    },
    {
        tier = 8,
        name = 'Black and Cyan Crown',
        description = 'Season 1 flex piece. Wear it like you earned it.',
        type = 'item',
        item = 'crown_blackcyan',
        amount = 1,
        rarity = 'epic',
        premium = true,
        icon = 'tier_08.svg'
    },
    {
        tier = 9,
        name = '44MM Ammo',
        description = '85x .44 caliber rounds, spend them wisely.',
        type = 'item',
        item = 'ammo-44',
        amount = 85,
        rarity = 'rare',
        premium = true,
        icon = 'tier_09.svg'
    },
    {
        tier = 10,
        name = 'Bag of Money',
        description = 'A stuffed bag of dirty city cash.',
        type = 'money',
        item = 'money',
        amount = 10000,
        rarity = 'rare',
        premium = true,
        icon = 'tier_10.svg'
    },
    {
        tier = 11,
        name = 'Tec-9',
        description = 'A compact machine pistol. Free track hardware.',
        type = 'weapon',
        item = 'weapon_machinepistol',
        amount = 1,
        rarity = 'rare',
        premium = false,
        icon = 'tier_11.svg'
    },
    {
        tier = 12,
        name = '10x Sprunks',
        description = 'Ten ice-cold Sprunks. Stay sharp.',
        type = 'item',
        item = 'sprunk',
        amount = 10,
        rarity = 'common',
        premium = true,
        icon = 'tier_12.svg'
    },
    {
        tier = 13,
        name = 'A Box of Money',
        description = 'A sealed box packed with city bills.',
        type = 'money',
        item = 'money',
        amount = 20000,
        rarity = 'epic',
        premium = true,
        icon = 'tier_13.svg'
    },
    {
        tier = 14,
        name = 'Dino Plan',
        description = 'A rare collectible blueprint. Frame it or flip it.',
        type = 'item',
        item = 'dino_plan',
        amount = 1,
        rarity = 'epic',
        premium = true,
        icon = 'tier_14.svg'
    },
    {
        tier = 15,
        name = 'Heavy Armor',
        description = 'Two heavy vests rated for a bad night.',
        type = 'item',
        item = 'armor',
        amount = 2,
        rarity = 'rare',
        premium = true,
        icon = 'tier_15.svg'
    },
    {
        tier = 16,
        name = 'Gold Chain',
        description = 'Thick gold. Let them know you are climbing the pass.',
        type = 'item',
        item = 'goldchain',
        amount = 1,
        rarity = 'rare',
        premium = true,
        icon = 'tier_16.svg'
    },
    {
        tier = 17,
        name = 'AP Pistol',
        description = 'Armor-piercing sidearm. Free track, high value.',
        type = 'weapon',
        item = 'weapon_appistol',
        amount = 1,
        rarity = 'epic',
        premium = false,
        icon = 'tier_17.svg'
    },
    {
        tier = 18,
        name = 'Cash Drop',
        description = 'Twenty-five thousand, no questions asked.',
        type = 'money',
        item = 'money',
        amount = 25000,
        rarity = 'rare',
        premium = true,
        icon = 'tier_18.svg'
    },
    {
        tier = 19,
        name = 'Encrypted Radio',
        description = 'A tuned radio for crews that do not like scanners.',
        type = 'item',
        item = 'radio',
        amount = 1,
        rarity = 'rare',
        premium = true,
        icon = 'tier_19.svg'
    },
    {
        tier = 20,
        name = 'SMG Ammo Crate',
        description = '200 rounds of SMG ammo, crate and all.',
        type = 'item',
        item = 'ammo-9',
        amount = 200,
        rarity = 'rare',
        premium = true,
        icon = 'tier_20.svg'
    },
    {
        tier = 21,
        name = 'Thick Envelope',
        description = 'Forty thousand in a fat envelope. Free track payday.',
        type = 'money',
        item = 'money',
        amount = 40000,
        rarity = 'epic',
        premium = false,
        icon = 'tier_21.svg'
    },
    {
        tier = 22,
        name = 'Drift Plate',
        description = 'A custom plate voucher for your next build.',
        type = 'item',
        item = 'licenseplate',
        amount = 1,
        rarity = 'epic',
        premium = true,
        icon = 'tier_22.svg'
    },
    {
        tier = 23,
        name = 'Combat PDW',
        description = 'A compact PDW for close city work.',
        type = 'weapon',
        item = 'weapon_combatpdw',
        amount = 1,
        rarity = 'epic',
        premium = true,
        icon = 'tier_23.svg'
    },
    {
        tier = 24,
        name = 'Season Crate',
        description = 'A sealed Chapter 1 crate. Open it when you are ready.',
        type = 'item',
        item = 'season_crate',
        amount = 1,
        rarity = 'legendary',
        premium = true,
        icon = 'tier_24.svg'
    },
    {
        tier = 25,
        name = 'Vault Stack',
        description = 'Seventy-five thousand. The free track does pay.',
        type = 'money',
        item = 'money',
        amount = 75000,
        rarity = 'legendary',
        premium = false,
        icon = 'tier_25.svg'
    },
    {
        tier = 26,
        name = 'Garage Voucher',
        description = 'Priority garage slot voucher for your next ride.',
        type = 'item',
        item = 'garage_voucher',
        amount = 1,
        rarity = 'epic',
        premium = true,
        icon = 'tier_26.svg'
    },
    {
        tier = 27,
        name = 'Diamond Rolex',
        description = 'Iced out. Chapter 1 status on your wrist.',
        type = 'item',
        item = 'rolex',
        amount = 1,
        rarity = 'legendary',
        premium = true,
        icon = 'tier_27.svg'
    },
    {
        tier = 28,
        name = 'Champion 1F',
        description = 'Season 1 champion vehicle. The city will see you coming.',
        type = 'vehicle',
        item = 'sultanrs',
        amount = 1,
        rarity = 'legendary',
        premium = true,
        icon = 'tier_28.svg'
    }
}

-- Admin / utility commands (server). Require Config.AdminAce unless noted.
Config.Commands = {
    givePremium = 'bppgive',     -- /bppgive [id]
    addXp       = 'bpxp',        -- /bpxp [id] [amount]
    resetPlayer = 'bpreset',     -- /bpreset [id]
    setTier     = 'bptier'       -- /bptier [id] [tier]
}
