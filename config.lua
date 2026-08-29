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

-- Chapter 1 Season 1 is a free track. Every unlocked tier is claimable.
Config.AllTiersFree = true
Config.PremiumXpMultiplier = 2.0
Config.PremiumItem = 'battlepass_premium'
Config.PremiumCommand = 'bppgive'

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
    28-tier Chapter 1 Season 1 track. All tiers are FREE.
    Order is randomized. Pet Pug is late (26). WEAPON_4THARP is last (28).
    Amounts with no listed qty are 1. Weapons grant as inventory items first.
]]
Config.Tiers = {
    {
        tier = 1,
        name = 'Black Silver Crown',
        description = 'A black and silver crown. Wear it like you own the block.',
        type = 'item',
        item = 'black_silver_crown',
        amount = 1,
        rarity = 'epic',
        premium = false,
        icon = 'tier_01.svg'
    },
    {
        tier = 2,
        name = 'Capybara Plushie',
        description = 'A shop capybara plush. Chill energy only.',
        type = 'item',
        item = 'capivara_plushie_shop',
        amount = 1,
        rarity = 'rare',
        premium = false,
        icon = 'tier_02.svg'
    },
    {
        tier = 3,
        name = '.44 Ammo',
        description = '75x .44 caliber rounds. Heavy hitters.',
        type = 'item',
        item = 'ammo-44',
        amount = 75,
        rarity = 'rare',
        premium = false,
        icon = 'tier_03.svg'
    },
    {
        tier = 4,
        name = 'Silver Black Crown',
        description = 'The silver-black twin crown. Matching flex.',
        type = 'item',
        item = 'silver_black_crown',
        amount = 1,
        rarity = 'epic',
        premium = false,
        icon = 'tier_04.svg'
    },
    {
        tier = 5,
        name = 'Chameleon 215',
        description = 'Chameleon paint 215. Color shift on the ride.',
        type = 'item',
        item = 'chameleonpaint_215',
        amount = 1,
        rarity = 'epic',
        premium = false,
        icon = 'tier_05.svg'
    },
    {
        tier = 6,
        name = 'Crayon Bat',
        description = 'WEAPON_CRAYONBAT. Soft colors, hard swing.',
        type = 'weapon',
        item = 'WEAPON_CRAYONBAT',
        amount = 1,
        rarity = 'epic',
        premium = false,
        icon = 'tier_06.svg'
    },
    {
        tier = 7,
        name = 'Crayon AP',
        description = 'WEAPON_CRAYONAP. A colorful armor-piercing sidearm.',
        type = 'weapon',
        item = 'WEAPON_CRAYONAP',
        amount = 1,
        rarity = 'epic',
        premium = false,
        icon = 'tier_07.svg'
    },
    {
        tier = 8,
        name = 'Rebel Rolls',
        description = '50x rebel rolls. Snack the night away.',
        type = 'item',
        item = 'rebel_rolls',
        amount = 50,
        rarity = 'rare',
        premium = false,
        icon = 'tier_08.svg'
    },
    {
        tier = 9,
        name = 'Multitail Fox',
        description = 'did_multitail_fox. A rare multi-tail fox piece.',
        type = 'item',
        item = 'did_multitail_fox',
        amount = 1,
        rarity = 'epic',
        premium = false,
        icon = 'tier_09.svg'
    },
    {
        tier = 10,
        name = 'Bear Plushie',
        description = 'bear_04 shop plush. Soft, but you earned it.',
        type = 'item',
        item = 'bear_04_plushie_shop',
        amount = 1,
        rarity = 'rare',
        premium = false,
        icon = 'tier_10.svg'
    },
    {
        tier = 11,
        name = 'Red Karambit',
        description = 'WEAPON_REDKARAMBIT. A red curve blade.',
        type = 'weapon',
        item = 'WEAPON_REDKARAMBIT',
        amount = 1,
        rarity = 'epic',
        premium = false,
        icon = 'tier_11.svg'
    },
    {
        tier = 12,
        name = 'Elfbar Grape',
        description = '10x grape Elfbars. Cloud up.',
        type = 'item',
        item = 'vape_elfbar_grape',
        amount = 10,
        rarity = 'rare',
        premium = false,
        icon = 'tier_12.svg'
    },
    {
        tier = 13,
        name = 'Lava Skeleton',
        description = 'did_lava_skeleton. Molten bones, season drip.',
        type = 'item',
        item = 'did_lava_skeleton',
        amount = 1,
        rarity = 'epic',
        premium = false,
        icon = 'tier_13.svg'
    },
    {
        tier = 14,
        name = 'Chameleon 198',
        description = 'Chameleon paint 198. Another shift for the garage.',
        type = 'item',
        item = 'chameleonpaint_198',
        amount = 1,
        rarity = 'epic',
        premium = false,
        icon = 'tier_14.svg'
    },
    {
        tier = 15,
        name = 'Chameleon 169',
        description = 'Chameleon paint 169. Rare flip finish.',
        type = 'item',
        item = 'chameleonpaint_169',
        amount = 1,
        rarity = 'epic',
        premium = false,
        icon = 'tier_15.svg'
    },
    {
        tier = 16,
        name = 'Island Pills',
        description = '50x island pills. Pack them tight.',
        type = 'item',
        item = 'island_pills',
        amount = 50,
        rarity = 'rare',
        premium = false,
        icon = 'tier_16.svg'
    },
    {
        tier = 17,
        name = 'Sandwiches',
        description = '5x sandwiches. Eat, then get back to the grind.',
        type = 'item',
        item = 'sandwich',
        amount = 5,
        rarity = 'common',
        premium = false,
        icon = 'tier_17.svg'
    },
    {
        tier = 18,
        name = 'Rifle Ammo',
        description = '100x rifle rounds. Stay loaded.',
        type = 'item',
        item = 'ammo-rifle',
        amount = 100,
        rarity = 'rare',
        premium = false,
        icon = 'tier_18.svg'
    },
    {
        tier = 19,
        name = 'Girly CX',
        description = 'WEAPON_GIRLYCX. Pretty hardware.',
        type = 'weapon',
        item = 'WEAPON_GIRLYCX',
        amount = 1,
        rarity = 'epic',
        premium = false,
        icon = 'tier_19.svg'
    },
    {
        tier = 20,
        name = 'Water',
        description = '5x water. Stay hydrated in the city.',
        type = 'item',
        item = 'water',
        amount = 5,
        rarity = 'common',
        premium = false,
        icon = 'tier_20.svg'
    },
    {
        tier = 21,
        name = '9mm Ammo',
        description = '50x 9mm rounds for the sidearm.',
        type = 'item',
        item = 'ammo-9',
        amount = 50,
        rarity = 'rare',
        premium = false,
        icon = 'tier_21.svg'
    },
    {
        tier = 22,
        name = 'Apple Refill',
        description = '5x apple vape refill. Keep the tank wet.',
        type = 'item',
        item = 'vape_refill_apple',
        amount = 5,
        rarity = 'common',
        premium = false,
        icon = 'tier_22.svg'
    },
    {
        tier = 23,
        name = 'Vape',
        description = 'A vape. Simple, ready to use.',
        type = 'item',
        item = 'vape',
        amount = 1,
        rarity = 'common',
        premium = false,
        icon = 'tier_23.svg'
    },
    {
        tier = 24,
        name = 'Pink Halo',
        description = 'halo_pink. A glowing pink halo.',
        type = 'item',
        item = 'halo_pink',
        amount = 1,
        rarity = 'epic',
        premium = false,
        icon = 'tier_24.svg'
    },
    {
        tier = 25,
        name = 'Mushroom Plushie',
        description = 'mushroom_01 shop plush. Cute and rare.',
        type = 'item',
        item = 'mushroom_01_plushie_shop',
        amount = 1,
        rarity = 'rare',
        premium = false,
        icon = 'tier_25.svg'
    },
    {
        tier = 26,
        name = 'Pet Pug',
        description = 'A pet pug. Late-track companion.',
        type = 'item',
        item = 'pet_pug',
        amount = 1,
        rarity = 'legendary',
        premium = false,
        icon = 'tier_26.svg'
    },
    {
        tier = 27,
        name = 'Pink Energy',
        description = '50x pink energy. Stay up for the finale.',
        type = 'item',
        item = 'pink_energy',
        amount = 50,
        rarity = 'rare',
        premium = false,
        icon = 'tier_27.svg'
    },
    {
        tier = 28,
        name = '4th ARP',
        description = 'WEAPON_4THARP. Season 1 closer. The last claim.',
        type = 'weapon',
        item = 'WEAPON_4THARP',
        amount = 1,
        rarity = 'legendary',
        premium = false,
        icon = 'tier_28.svg'
    },
}

-- Admin / utility commands (server). Require Config.AdminAce unless noted.
Config.Commands = {
    givePremium = 'bppgive',     -- /bppgive [id]
    addXp       = 'bpxp',        -- /bpxp [id] [amount]
    resetPlayer = 'bpreset',     -- /bpreset [id]
    setTier     = 'bptier'       -- /bptier [id] [tier]
}
