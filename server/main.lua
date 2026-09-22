local players = {} -- [src] = { identifier, xp, claimed = {}, premium = bool }
local lastTick = {} -- [src] = os.time()
local claiming = {} -- [src] = true while a claim is in flight
local jsonStore = {}
local usingMysql = false
local resourceName = GetCurrentResourceName()
local persistQueue = {}
local publicTierCache = nil
local tiersByNumber = {}
local maxXpCached = nil

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

local function rebuildTierIndex()
    tiersByNumber = {}
    for _, t in ipairs(Config.Tiers or {}) do
        if t.tier then
            tiersByNumber[t.tier] = t
        end
    end
    publicTierCache = nil
    maxXpCached = nil
end

local function getReward(tier)
    return tiersByNumber[tonumber(tier)]
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

local seasonStartAt, seasonEndsAt

local function refreshSeasonWindow()
    seasonStartAt = parseSeasonStart()
    seasonEndsAt = seasonStartAt + (tonumber(Config.SeasonDurationDays) or 30) * 24 * 60 * 60
end

local function seasonWindow()
    if not seasonStartAt then refreshSeasonWindow() end
    return seasonStartAt, seasonEndsAt
end

local function seasonActive()
    local now = os.time()
    local startAt, endsAt = seasonWindow()
    return now >= startAt and now < endsAt, startAt, endsAt, now
end

local function maxXp()
    if not maxXpCached then
        maxXpCached = (#Config.Tiers) * (tonumber(Config.XpPerTier) or 2000)
    end
    return maxXpCached
end

local function tierFromXp(xp)
    local per = tonumber(Config.XpPerTier) or 2000
    local t = math.floor((tonumber(xp) or 0) / per)
    if t < 0 then t = 0 end
    local cap = #Config.Tiers
    if t > cap then t = cap end
    return t
end

local function claimedSet(list)
    local set = {}
    for _, n in ipairs(list or {}) do
        local tier = tonumber(n)
        if tier then set[tier] = true end
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
    if not row or not row.identifier then return end
    if dbReady() then
        local ok, err = pcall(function()
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
        end)
        if not ok then
            print(('[DJFIVEM-Battlepass] persist failed identifier=%s err=%s'):format(row.identifier, tostring(err)))
        end
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

local function persistSoon(row)
    if not row then return end
    persistQueue[row.identifier] = row
end

local function flushPersist()
    if next(persistQueue) == nil then return end
    for _, row in pairs(persistQueue) do
        persist(row)
    end
    persistQueue = {}
end

CreateThread(function()
    while true do
        Wait(15000)
        flushPersist()
    end
end)

local function fetchRow(identifier)
    if dbReady() then
        local ok, row = pcall(sqlSingle, 'SELECT xp, claimed, premium FROM djfivem_battlepass WHERE identifier = ? AND season = ?', { identifier, Config.SeasonId })
        if not ok or not row then
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

local function resolveOxItem(item)
    if type(item) ~= 'string' or item == '' then
        return nil, nil
    end
    if not resourceStarted('ox_inventory') then
        return nil, item
    end

    local function lookup(name)
        local ok, def = pcall(function()
            return exports.ox_inventory:Items(name)
        end)
        if ok and type(def) == 'table' and (def.name or def.label) then
            return def
        end
        return nil
    end

    local def = lookup(item) or lookup(item:lower()) or lookup(item:upper())
    if not def then
        return nil, item, false
    end

    local image = def.client and def.client.image
    if type(image) ~= 'string' or image == '' then
        image = nil
    end
    return image, def.name or item, true
end

local function publicTiers()
    if publicTierCache then return publicTierCache end
    local list = {}
    for _, t in ipairs(Config.Tiers) do
        local oxImage, imageName = resolveOxItem(t.item)
        list[#list + 1] = {
            tier = t.tier,
            name = t.name,
            description = t.description,
            type = t.type,
            amount = t.amount,
            rarity = t.rarity,
            premium = t.premium and true or false,
            icon = t.icon,
            item = t.item,
            oxImage = oxImage,
            imageName = imageName or t.item
        }
    end
    publicTierCache = list
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
    local _, startAt, endsAt, now = seasonActive()
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
        imageExts = Config.InventoryImageExtensions or { 'png', 'webp' },
        premiumMultiplier = Config.PremiumXpMultiplier or 2.0,
        remainingSeconds = math.max(0, (endsAt or now) - now),
        seasonEndsAt = endsAt,
        seasonStartsAt = startAt,
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
    persistSoon(row)

    local after = tierFromXp(row.xp)
    if after > before then
        for t = before + 1, after do
            local reward = getReward(t)
            TriggerClientEvent('djfivem_battlepass:client:tierUp', src, t, reward and reward.name or '')
        end
    end
    push(src)
    return true, reason
end

local function canClaim(row, tier)
    local reward = getReward(tier)
    if not reward then return false, 'invalid' end
    if claimedSet(row.claimed)[tier] then return false, 'claimed' end
    if tierFromXp(row.xp) < tier then return false, 'locked' end
    if reward.premium and not row.premium and not Config.AllTiersFree then
        return false, 'premium'
    end
    local active, startAt, endsAt, now = seasonActive()
    if now < startAt then return false, 'not_started' end
    if now >= endsAt then return false, 'ended' end
    return true, reward, active
end

local function grantReward(src, reward)
    if Framework.inventory == 'none' or Framework.name == 'standalone' then
        Framework.Refresh()
    end
    if reward.type == 'money' then
        local ok = Framework.AddMoney(src, reward.amount)
        if not ok then
            print(('[DJFIVEM-Battlepass] money grant failed src=%s amount=%s'):format(src, reward.amount))
            return false, 'give_failed'
        end
        return true
    end

    if reward.type == 'weapon' then
        local _, _, exists = resolveOxItem(reward.item)
        if Framework.inventory == 'ox' and exists == false then
            print(('[DJFIVEM-Battlepass] weapon grant failed src=%s item=%s — item missing from ox_inventory'):format(src, reward.item))
            return false, 'give_failed'
        end
        if not Framework.CanCarry(src, reward.item, reward.amount or 1) then
            return false, 'no_space'
        end
        if Framework.AddItem(src, reward.item, reward.amount or 1) then return true end
        if Framework.GiveWeapon(src, reward.item, reward.amount or 1) then return true end
        print(('[DJFIVEM-Battlepass] weapon grant failed src=%s item=%s — check ox_inventory items'):format(src, reward.item))
        return false, 'give_failed'
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

    local _, _, exists = resolveOxItem(reward.item)
    if Framework.inventory == 'ox' and exists == false then
        print(('[DJFIVEM-Battlepass] item grant failed src=%s item=%s — item missing from ox_inventory'):format(src, tostring(reward.item)))
        return false, 'give_failed'
    end
    if not Framework.CanCarry(src, reward.item, reward.amount or 1) then
        return false, 'no_space'
    end
    local ok = Framework.AddItem(src, reward.item, reward.amount or 1)
    if not ok then
        print(('[DJFIVEM-Battlepass] item grant failed src=%s item=%s x%s — add the item to ox_inventory'):format(
            src, tostring(reward.item), tostring(reward.amount)
        ))
        return false, 'give_failed'
    end
    return true
end

local grantErrors = {
    no_space = 'Not enough inventory space for that reward.',
    give_failed = 'Could not give that reward. Check ox_inventory items.',
    claimed = 'Already claimed.',
    locked = 'That tier is still locked.',
    premium = 'Premium required.',
    not_started = 'The season has not started yet.',
    ended = 'The season has ended.',
    invalid = 'Invalid tier.',
    no_player = 'Player not ready.',
    busy = 'Please wait…'
}

local function claimTier(src, tier)
    if claiming[src] then return false, 'busy' end
    local row = ensurePlayer(src)
    if not row then return false, 'no_player' end
    local ok, rewardOrErr = canClaim(row, tier)
    if not ok then return false, rewardOrErr end

    claiming[src] = true
    local granted, grantErr = grantReward(src, rewardOrErr)
    claiming[src] = nil
    if not granted then
        Framework.Notify(src, grantErrors[grantErr] or 'Could not claim that reward.', 'error')
        return false, grantErr
    end

    row.claimed[#row.claimed + 1] = tier
    table.sort(row.claimed)
    persist(row)
    push(src)
    Framework.Notify(src, ('Claimed Tier %d — %s'):format(tier, rewardOrErr.name), 'success')
    return true
end

rebuildTierIndex()
refreshSeasonWindow()

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

    -- Re-resolve ox images after inventory finishes starting.
    Wait(1500)
    publicTierCache = nil
    publicTiers()
end)

AddEventHandler('playerDropped', function()
    local src = source
    local row = players[src]
    if row then
        persistQueue[row.identifier] = nil
        persist(row)
    end
    players[src] = nil
    lastTick[src] = nil
    claiming[src] = nil
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= resourceName then return end
    flushPersist()
    for _, row in pairs(players) do
        persist(row)
    end
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
    if not active or now < startAt or now >= endsAt then return end

    local last = lastTick[src] or 0
    local interval = math.max(15, tonumber(Config.XpIntervalSeconds) or 60)
    if (now - last) < (interval - 2) then return end
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
    if claiming[src] then
        Framework.Notify(src, grantErrors.busy, 'error')
        return
    end
    local row = ensurePlayer(src)
    if not row then return end

    claiming[src] = true
    local claimed = 0
    local blocked
    for _, reward in ipairs(Config.Tiers) do
        local ok, rewardOrErr = canClaim(row, reward.tier)
        if ok then
            local granted, grantErr = grantReward(src, rewardOrErr)
            if granted then
                row.claimed[#row.claimed + 1] = reward.tier
                claimed = claimed + 1
            else
                blocked = grantErr
                break
            end
        end
    end
    claiming[src] = nil

    if claimed == 0 then
        Framework.Notify(src, blocked and (grantErrors[blocked] or 'Nothing to claim right now.') or 'Nothing to claim right now.', 'error')
        return
    end
    table.sort(row.claimed)
    persist(row)
    push(src)
    if blocked then
        Framework.Notify(src, ('Claimed %d reward%s. %s'):format(claimed, claimed == 1 and '' or 's', grantErrors[blocked] or ''), 'error')
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
