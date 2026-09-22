-- Framework + inventory adapters. Auto-detects qb-core, qbx_core, es_extended, ox_inventory.

Framework = {
    name = 'standalone',
    inventory = 'none'
}

local function resourceStarted(name)
    local state = GetResourceState(name)
    return state == 'started' or state == 'starting'
end

local function detectFramework()
    if Config.Framework ~= 'auto' then
        return Config.Framework
    end
    if resourceStarted('qbx_core') then return 'qbx' end
    if resourceStarted('qb-core') then return 'qb' end
    if resourceStarted('es_extended') then return 'esx' end
    return 'standalone'
end

local function detectInventory()
    if Config.Inventory ~= 'auto' then
        return Config.Inventory
    end
    if resourceStarted('ox_inventory') then return 'ox' end
    if Framework.name == 'qb' or Framework.name == 'qbx' then return 'qb' end
    if Framework.name == 'esx' then return 'esx' end
    return 'none'
end

local function refreshAdapters()
    Framework.name = detectFramework()
    Framework.inventory = detectInventory()
end

function Framework.Refresh()
    refreshAdapters()
    return Framework.name, Framework.inventory
end

refreshAdapters()

CreateThread(function()
    Wait(500)
    refreshAdapters()
    print(('[DJFIVEM-Battlepass] Framework=%s inventory=%s'):format(Framework.name, Framework.inventory))
end)

local QBCore, ESX

local function qb()
    if not QBCore then
        local ok, core = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        if ok then QBCore = core end
    end
    return QBCore
end

local function qbxPlayer(src)
    if resourceStarted('qbx_core') then
        return exports.qbx_core:GetPlayer(src)
    end
    return nil
end

local function esx()
    if not ESX then
        local ok, obj = pcall(function()
            return exports['es_extended']:getSharedObject()
        end)
        if ok then ESX = obj end
        if not ESX then
            TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        end
    end
    return ESX
end

local function qbPlayer(src)
    if Framework.name == 'qbx' then
        return qbxPlayer(src)
    end
    return qb() and qb().Functions.GetPlayer(src) or nil
end

function Framework.GetIdentifier(src)
    if Framework.name == 'qb' then
        local player = qbPlayer(src)
        if player then return player.PlayerData.citizenid end
    elseif Framework.name == 'qbx' then
        local player = qbxPlayer(src)
        if player and player.PlayerData then return player.PlayerData.citizenid end
    elseif Framework.name == 'esx' then
        local xPlayer = esx() and esx().GetPlayerFromId(src)
        if xPlayer then return xPlayer.identifier end
    end

    local identifiers = GetPlayerIdentifiers(src)
    if type(identifiers) == 'table' then
        for _, id in ipairs(identifiers) do
            if type(id) == 'string' and id:sub(1, 8) == 'license:' then
                return id
            end
        end
    end
    return GetPlayerIdentifier(src, 0)
end

function Framework.GetName(src)
    if Framework.name == 'qb' or Framework.name == 'qbx' then
        local player = qbPlayer(src)
        if player and player.PlayerData and player.PlayerData.charinfo then
            local c = player.PlayerData.charinfo
            local name = ((c.firstname or '') .. ' ' .. (c.lastname or '')):gsub('^%s+', ''):gsub('%s+$', '')
            if name ~= '' then return name end
        end
    elseif Framework.name == 'esx' then
        local xPlayer = esx() and esx().GetPlayerFromId(src)
        if xPlayer and xPlayer.getName then
            return xPlayer.getName()
        end
    end
    return GetPlayerName(src) or ('ID ' .. tostring(src))
end

function Framework.HasItem(src, item, amount)
    amount = amount or 1
    if not item then return false end
    if Framework.inventory == 'ox' then
        local ok, count = pcall(function()
            return exports.ox_inventory:Search(src, 'count', item) or 0
        end)
        return ok and (tonumber(count) or 0) >= amount
    end
    if Framework.name == 'qb' or Framework.name == 'qbx' then
        local player = qbPlayer(src)
        if not player then return false end
        local data = player.Functions.GetItemByName(item)
        return data and (data.amount or data.count or 0) >= amount
    end
    if Framework.name == 'esx' then
        local xPlayer = esx() and esx().GetPlayerFromId(src)
        if not xPlayer then return false end
        local data = xPlayer.getInventoryItem(item)
        return data and (data.count or data.amount or 0) >= amount
    end
    return false
end

function Framework.CanCarry(src, item, amount)
    amount = math.max(1, math.floor(tonumber(amount) or 1))
    if not item then return false end
    if Framework.inventory == 'ox' then
        local ok, can = pcall(function()
            return exports.ox_inventory:CanCarryItem(src, item, amount)
        end)
        if ok then return can ~= false end
        return true
    end
    return true
end

local function addInventoryItem(src, item, amount, metadata)
    if Framework.inventory == 'ox' then
        return exports.ox_inventory:AddItem(src, item, amount, metadata) and true or false
    end
    if Framework.name == 'qb' or Framework.name == 'qbx' then
        local player = qbPlayer(src)
        if not player then return false end
        return player.Functions.AddItem(item, amount, false, metadata) and true or false
    end
    if Framework.name == 'esx' then
        local xPlayer = esx() and esx().GetPlayerFromId(src)
        if not xPlayer then return false end
        xPlayer.addInventoryItem(item, amount)
        return true
    end
    return false
end

function Framework.AddItem(src, item, amount, metadata)
    amount = math.max(1, math.floor(tonumber(amount) or 1))
    if type(item) ~= 'string' or item == '' then return false end
    if addInventoryItem(src, item, amount, metadata) then return true end
    local lower = item:lower()
    if lower ~= item then
        return addInventoryItem(src, lower, amount, metadata)
    end
    return false
end

function Framework.AddMoney(src, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    if Framework.name == 'qb' or Framework.name == 'qbx' then
        local player = qbPlayer(src)
        if not player then return false end
        player.Functions.AddMoney('cash', amount, 'djfivem-battlepass')
        return true
    end
    if Framework.name == 'esx' then
        local xPlayer = esx() and esx().GetPlayerFromId(src)
        if not xPlayer then return false end
        xPlayer.addMoney(amount)
        return true
    end

    if Framework.inventory == 'ox' then
        local ok = exports.ox_inventory:AddItem(src, 'money', amount)
        if ok then return true end
    end
    return false
end

function Framework.GiveWeapon(src, weapon, ammo)
    ammo = ammo or 1
    if type(weapon) ~= 'string' or weapon == '' then return false end

    if Framework.inventory == 'ox' then
        if exports.ox_inventory:AddItem(src, weapon, 1) then return true end
        local lower = weapon:lower()
        if lower ~= weapon then
            return exports.ox_inventory:AddItem(src, lower, 1) and true or false
        end
        return false
    end
    if Framework.name == 'qb' or Framework.name == 'qbx' then
        local player = qbPlayer(src)
        if not player then return false end
        if player.Functions.AddItem(weapon, 1) then return true end
        local lower = weapon:lower()
        if lower ~= weapon then
            return player.Functions.AddItem(lower, 1) and true or false
        end
        return false
    end
    if Framework.name == 'esx' then
        local xPlayer = esx() and esx().GetPlayerFromId(src)
        if not xPlayer then return false end
        if xPlayer.addWeapon then
            xPlayer.addWeapon(weapon:upper(), ammo)
            return true
        end
        xPlayer.addInventoryItem(weapon, 1)
        return true
    end
    return false
end

function Framework.Notify(src, message, nType)
    nType = nType or 'success'
    if Config.Notify == 'ox' or (Config.Notify == 'auto' and resourceStarted('ox_lib')) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Battle Pass', description = message, type = nType })
        return
    end
    if Framework.name == 'qb' or Framework.name == 'qbx' then
        TriggerClientEvent('QBCore:Notify', src, message, nType)
        return
    end
    if Framework.name == 'esx' then
        TriggerClientEvent('esx:showNotification', src, message)
        return
    end
    TriggerClientEvent('djfivem_battlepass:client:notify', src, message, nType)
end
