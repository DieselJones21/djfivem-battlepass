local players = {} -- [src] = { identifier, xp, claimed = {}, premium = bool }
local lastTick = {} -- [src] = os.time()
local jsonStore = {}
local usingMysql = false
local resourceName = GetCurrentResourceName()

local function resourceStarted(name)
    local state = GetResourceState(name)
    return state == 'started' or state == 'starting'
end

local function encode(tbl)
    return json.encode(tbl)
end

local function decode(str, fallback)
    if type(str) ~= 'string' or str == '' then return fallback end
    local ok, data = pcall(json.decode, str)
    if ok and type(data) == 'table' then return data end
    return fallback
end

local function parseSeasonStart()
    local raw = Config.SeasonStart or '2026-08-29 00:00:00'
    local y, m, d, h, min, s = raw:match('^(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)$')
    if not y then
        y, m, d = raw:match('^(%d+)%-(%d+)%-(%d+)$')
        h, min, s = 0, 0, 0
    end
    return os.time({
        year = tonumber(y) or 2026,
        month = tonumber(m) or 8,
        day = tonumber(d) or 29,
        hour = tonumber(h) or 0,
        min = tonumber(min) or 0,
        sec = tonumber(s) or 0,
        isdst = false
    })
end

local function seasonWindow()
    local startAt = parseSeasonStart()
    local endsAt = startAt + (tonumber(Config.SeasonDurationDays) or 30) * 24 * 60 * 60
    return startAt, endsAt
end

local function seasonActive()
    local now = os.time()
    local startAt, endsAt = seasonWindow()
    return now >= startAt and now < endsAt, startAt, endsAt, now
end

local function maxXp()
    return (#Config.Tiers) * (tonumber(Config.XpPerTier) or 2000)
end

local function tierFromXp(xp)
    local per = tonumber(Config.XpPerTier) or 2000
    local t = math.floor((tonumber(xp) or 0) / per)
    if t < 0 then t = 0 end
    if t > #Config.Tiers then t = #Config.Tiers end
    return t
end

local function claimedSet(list)
    local set = {}
    for _, n in ipairs(list or {}) do
        set[tonumber(n)] = true
    end
    return set
end

local function loadJsonStore()
    local raw = LoadResourceFile(resourceName, 'data/players.json')
    jsonStore = decode(raw, {})
end

local function saveJsonStore()
    SaveResourceFile(resourceName, 'data/players.json', encode(jsonStore), -1)
end

local function dbReady()
    return usingMysql
end

local function sqlUpdate(query, params)
    return exports.oxmysql:update_async(query, params)
end

local function sqlSingle(query, params)
    return exports.oxmysql:single_async(query, params)
end

local function sqlQuery(query, params)
    return exports.oxmysql:query_async(query, params)
end

local function persist(row)
    if dbReady() then
        sqlUpdate([[
            INSERT INTO djfivem_battlepass (identifier, season, xp, claimed, premium)
            VALUES (?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE xp = VALUES(xp), claimed = VALUES(claimed), premium = VALUES(premium)
        ]], {
            row.identifier,
            Config.SeasonId,
            row.xp,
            encode(row.claimed),
            row.premium and 1 or 0
        })
        return
    end
    jsonStore[row.identifier] = jsonStore[row.identifier] or {}
    jsonStore[row.identifier][Config.SeasonId] = {
        xp = row.xp,
        claimed = row.claimed,
        premium = row.premium and true or false
    }
    saveJsonStore()
end

local function fetchRow(identifier)
    if dbReady() then
        local row = sqlSingle(
            'SELECT xp, claimed, premium FROM djfivem_battlepass WHERE identifier = ? AND season = ?',
            { identifier, Config.SeasonId }
        )
        if not row then
            return { identifier = identifier, xp = 0, claimed = {}, premium = false }
        end
        return {
            identifier = identifier,
            xp = tonumber(row.xp) or 0,
            claimed = decode(row.claimed, {}),
            premium = tonumber(row.premium) == 1 or row.premium == true
        }
    end

    local season = jsonStore[identifier] and jsonStore[identifier][Config.SeasonId]
    if not season then
        return { identifier = identifier, xp = 0, claimed = {}, premium = false }
    end
    return {
        identifier = identifier,
        xp = tonumber(season.xp) or 0,
        claimed = season.claimed or {},
        premium = season.premium and true or false
    }
end

local function publicTiers()
    local list = {}
    for _, t in ipairs(Config.Tiers) do
        list[#list + 1] = {
            tier = t.tier,
            name = t.name,
            description = t.description,
            type = t.type,
            amount = t.amount,
            rarity = t.rarity,
            premium = t.premium and true or false,
            icon = t.icon,
            item = t.item
        }
    end
    return list
end

local function buildPayload(src)
    local row = players[src]
    if not row then return nil end
    local per = tonumber(Config.XpPerTier) or 2000
    local xp = tonumber(row.xp) or 0
    local unlocked = tierFromXp(xp)
    local into = xp % per
    if unlocked >= #Config.Tiers then
        into = per
    end
    local _, endsAt, now = select(2, seasonActive())
    local claimed = claimedSet(row.claimed)
    local claimedCount = 0
    for _ in pairs(claimed) do claimedCount = claimedCount + 1 end
    local level = unlocked >= #Config.Tiers and #Config.Tiers or (unlocked + 1)

    return {
        title = Config.ResourceTitle,
        chapter = Config.Chapter,
        season = Config.Season,
        seasonId = Config.SeasonId,
        seasonLabel = Config.SeasonLabel,
        playerName = Framework.GetName(src),
        xp = xp,
        xpPerTier = per,
        xpIntoTier = into,
        maxXp = maxXp(),
        level = level,
        unlocked = unlocked,
        claimed = row.claimed,
        claimedCount = claimedCount,
        premium = row.premium and true or false,
        allFree = Config.AllTiersFree and true or false,
        imageResource = Config.InventoryImageResource or 'ox_inventory',
        imageFolder = Config.InventoryImageFolder or 'web/images',
        premiumMultiplier = Config.PremiumXpMultiplier or 2.0,
        remainingSeconds = math.max(0, (endsAt or now) - now),
        seasonEndsAt = endsAt,
        serverNow = now,
        totalTiers = #Config.Tiers,
        closeKey = Config.CloseKeyLabel,
        openKey = Config.OpenKey,
        tiers = publicTiers()
    }
end

local function ensurePlayer(src)
    if players[src] then return players[src] end
    local identifier = Framework.GetIdentifier(src)
    if not identifier then return nil end
    local row = fetchRow(identifier)
    -- Premium item in inventory also counts.
    if not row.premium and Config.PremiumItem and Config.PremiumItem ~= '' then
        if Framework.HasItem(src, Config.PremiumItem, 1) then
            row.premium = true
            persist(row)
        end
    end
    players[src] = row
    return row
end

local function push(src)
    local payload = buildPayload(src)
    if payload then
        TriggerClientEvent('djfivem_battlepass:client:update', src, payload)
    end
end

local function addXp(src, amount, reason)
    local row = ensurePlayer(src)
    if not row then return false, 'no_player' end
    amount = math.floor(tonumber(amount) or 0)
    if amount == 0 then return true end

    local before = tierFromXp(row.xp)
    local cap = maxXp()
    row.xp = math.max(0, math.min(cap, row.xp + amount))
    persist(row)

    local after = tierFromXp(row.xp)
    if after > before then
        for t = before + 1, after do
            local reward = Config.Tiers[t]
            TriggerClientEvent('djfivem_battlepass:client:tierUp', src, t, reward and reward.name or '')
        end
    end
    push(src)
    return true, reason
end

local function canClaim(row, tier)
    local reward = Config.Tiers[tier]
    if not reward then return false, 'invalid' end
    if claimedSet(row.claimed)[tier] then return false, 'claimed' end
    if tierFromXp(row.xp) < tier then return false, 'locked' end
    if reward.premium and not row.premium and not Config.AllTiersFree then
        return false, 'premium'
    end
    local _, _, endsAt, now = seasonActive()
    -- Allow claiming after start; block after season ends.
    if now < select(1, seasonWindow()) then return false, 'not_started' end
    if now >= endsAt then return false, 'ended' end
    return true, reward
end

local function tryGiveItem(src, item, amount)
    if not item or item == '' then return false end
    if Framework.AddItem(src, item, amount) then return true end
    local lower = item:lower()
    if lower ~= item and Framework.AddItem(src, lower, amount) then return true end
    return false
end

local function grantReward(src, reward)
    if reward.type == 'money' then
        local ok = Framework.AddMoney(src, reward.amount)
        if not ok then
            print(('[DJFIVEM-Battlepass] money grant fallback src=%s amount=%s'):format(src, reward.amount))
        end
        return true
    end
    if reward.type == 'weapon' then
        -- Custom WEAPON_* items are usually inventory entries. Try the item first.
        if tryGiveItem(src, reward.item, reward.amount or 1) then return true end
        local ok = Framework.GiveWeapon(src, reward.item, reward.amount or 1)
        if not ok then
            print(('[DJFIVEM-Battlepass] weapon grant failed src=%s item=%s — check inventory items'):format(src, reward.item))
        end
        return true
    end
    if reward.type == 'vehicle' then
        if reward.item and reward.item ~= '' then
            Framework.AddItem(src, 'battlepass_vehicle_voucher', 1, {
                model = reward.item,
                season = Config.SeasonId,
                label = reward.name
            })
        end
        TriggerEvent(Config.VehicleGrantEvent, src, reward.item, reward)
        return true
    end
    -- item (default)
    local ok = Framework.AddItem(src, reward.item, reward.amount or 1)
    if not ok then
        print(('[DJFIVEM-Battlepass] item grant failed src=%s item=%s x%s — add the item to your inventory'):format(
            src, tostring(reward.item), tostring(reward.amount)
        ))
    end
    return true
end

local function claimTier(src, tier)
    local row = ensurePlayer(src)
    if not row then return false, 'no_player' end
    local ok, rewardOrErr = canClaim(row, tier)
    if not ok then return false, rewardOrErr end
    grantReward(src, rewardOrErr)
    row.claimed[#row.claimed + 1] = tier
    table.sort(row.claimed)
    persist(row)
    push(src)
    Framework.Notify(src, ('Claimed Tier %d — %s'):format(tier, rewardOrErr.name), 'success')
    return true
end

CreateThread(function()
    loadJsonStore()
    if Config.UseDatabase and resourceStarted('oxmysql') then
        usingMysql = true
        pcall(function()
            sqlQuery([[
                CREATE TABLE IF NOT EXISTS `djfivem_battlepass` (
                    `identifier` VARCHAR(64)  NOT NULL,
                    `season`     VARCHAR(32)  NOT NULL DEFAULT 'c1s1',
                    `xp`         INT          NOT NULL DEFAULT 0,
                    `claimed`    LONGTEXT     NOT NULL,
                    `premium`    TINYINT(1)   NOT NULL DEFAULT 0,
                    `updated_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                    PRIMARY KEY (`identifier`, `season`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
            ]], {})
        end)
        print('[DJFIVEM-Battlepass] persistence=oxmysql')
    else
        print('[DJFIVEM-Battlepass] persistence=data/players.json')
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    players[src] = nil
    lastTick[src] = nil
end)

RegisterNetEvent('djfivem_battlepass:server:requestOpen', function()
    local src = source
    if not ensurePlayer(src) then return end
    local payload = buildPayload(src)
    TriggerClientEvent('djfivem_battlepass:client:open', src, payload)
end)

RegisterNetEvent('djfivem_battlepass:server:tickXp', function()
    local src = source
    local active, startAt, endsAt, now = seasonActive()
    if not active then return end
    if now < startAt or now >= endsAt then return end

    local last = lastTick[src] or 0
    local interval = math.max(15, tonumber(Config.XpIntervalSeconds) or 60)
    if (now - last) < (interval - 2) then return end -- anti-spam
    lastTick[src] = now

    local row = ensurePlayer(src)
    if not row then return end

    local amount = tonumber(Config.XpPerTick) or 8
    if row.premium then
        amount = math.floor(amount * (tonumber(Config.PremiumXpMultiplier) or 2.0))
    end
    addXp(src, amount, 'city')
end)

RegisterNetEvent('djfivem_battlepass:server:claim', function(tier)
    local src = source
    claimTier(src, tonumber(tier))
end)

RegisterNetEvent('djfivem_battlepass:server:claimAll', function()
    local src = source
    local row = ensurePlayer(src)
    if not row then return end
    local claimed = 0
    for _, reward in ipairs(Config.Tiers) do
        local ok = canClaim(row, reward.tier)
        if ok then
            if claimTier(src, reward.tier) then
                claimed = claimed + 1
            end
        end
    end
    if claimed == 0 then
        Framework.Notify(src, 'Nothing to claim right now.', 'error')
    else
        Framework.Notify(src, ('Claimed %d reward%s.'):format(claimed, claimed == 1 and '' or 's'), 'success')
    end
end)

local function isAdmin(src)
    return IsPlayerAceAllowed(src, Config.AdminAce) or IsPlayerAceAllowed(src, 'command')
end

local function targetId(src, raw)
    local id = tonumber(raw)
    if id and GetPlayerName(id) then return id end
    return src
end

RegisterCommand(Config.Commands.givePremium, function(src, args)
    if src ~= 0 and not isAdmin(src) then return end
    local target = targetId(src, args[1])
    local row = ensurePlayer(target)
    if not row then return end
    row.premium = true
    persist(row)
    push(target)
    Framework.Notify(target, 'Premium Battle Pass activated.', 'success')
    if src ~= 0 then Framework.Notify(src, ('Premium granted to %s'):format(GetPlayerName(target)), 'success') end
end, true)

RegisterCommand(Config.Commands.addXp, function(src, args)
    if src ~= 0 and not isAdmin(src) then return end
    local target = targetId(src, args[1])
    local amount = tonumber(args[2]) or 0
    addXp(target, amount, 'admin')
    if src ~= 0 then Framework.Notify(src, ('Added %s XP to %s'):format(amount, GetPlayerName(target)), 'success') end
end, true)

RegisterCommand(Config.Commands.resetPlayer, function(src, args)
    if src ~= 0 and not isAdmin(src) then return end
    local target = targetId(src, args[1])
    local row = ensurePlayer(target)
    if not row then return end
    row.xp = 0
    row.claimed = {}
    persist(row)
    push(target)
    Framework.Notify(target, 'Battle Pass progress has been reset.', 'error')
end, true)

RegisterCommand(Config.Commands.setTier, function(src, args)
    if src ~= 0 and not isAdmin(src) then return end
    local target = targetId(src, args[1])
    local tier = math.max(0, math.min(#Config.Tiers, tonumber(args[2]) or 0))
    local row = ensurePlayer(target)
    if not row then return end
    row.xp = tier * (tonumber(Config.XpPerTier) or 2000)
    persist(row)
    push(target)
    Framework.Notify(target, ('Battle Pass set to tier %d.'):format(tier), 'success')
end, true)

exports('GetPlayerXp', function(src)
    local row = ensurePlayer(src)
    return row and row.xp or 0
end)

exports('GetPlayerTier', function(src)
    local row = ensurePlayer(src)
    return row and tierFromXp(row.xp) or 0
end)

exports('AddXP', function(src, amount)
    return addXp(src, amount, 'export')
end)

exports('GivePremium', function(src)
    local row = ensurePlayer(src)
    if not row then return false end
    row.premium = true
    persist(row)
    push(src)
    return true
end)

exports('IsPremium', function(src)
    local row = ensurePlayer(src)
    return row and row.premium or false
end)

AddEventHandler('djfivem_battlepass:server:grantVehicle', function(src, model, reward)
    print(('[DJFIVEM-Battlepass] vehicle reward src=%s model=%s (%s) — hook this event to insert into your garage'):format(
        src, tostring(model), reward and reward.name or ''
    ))
end)
