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

CreateThread(function()
    Wait(500)
    Framework.name = detectFramework()
    Framework.inventory = detectInventory()
    print(('[DJFIVEM-Battlepass] Framework=%s inventory=%s'):format(Framework.name, Framework.inventory))
end)

local QBCore, QBX, ESX

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

function Framework.GetIdentifier(src)
    if Framework.name == 'qb' then
        local player = qb() and qb().Functions.GetPlayer(src)
        if player then return player.PlayerData.citizenid end
    elseif Framework.name == 'qbx' then
        local player = qbxPlayer(src)
        if player and player.PlayerData then return player.PlayerData.citizenid end
    elseif Framework.name == 'esx' then
        local xPlayer = esx() and esx().GetPlayerFromId(src)
        if xPlayer then return xPlayer.identifier end
    end

    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:sub(1, 8) == 'license:' then
            return id
        end
    end
    return GetPlayerIdentifier(src, 0)
end

function Framework.GetName(src)
    if Framework.name == 'qb' then
        local player = qb() and qb().Functions.GetPlayer(src)
        if player then
            local c = player.PlayerData.charinfo or {}
            return ((c.firstname or '') .. ' ' .. (c.lastname or '')):gsub('^%s+', ''):gsub('%s+$', '')
        end
    elseif Framework.name == 'qbx' then
        local player = qbxPlayer(src)
        if player and player.PlayerData and player.PlayerData.charinfo then
            local c = player.PlayerData.charinfo
            return ((c.firstname or '') .. ' ' .. (c.lastname or '')):gsub('^%s+', '')
        end
    elseif Framework.name == 'esx' then
        local xPlayer = esx() and esx().GetPlayerFromId(src)
        if xPlayer then
            if xPlayer.getName then return xPlayer.getName() end
        end
    end
    return GetPlayerName(src) or ('ID ' .. tostring(src))
end

function Framework.HasItem(src, item, amount)
    amount = amount or 1
    if not item then return false end
    if Framework.inventory == 'ox' then
        local count = exports.ox_inventory:Search(src, 'count', item) or 0
        return count >= amount
    end
    if Framework.name == 'qb' or Framework.name == 'qbx' then
        local player = (Framework.name == 'qbx' and qbxPlayer(src)) or (qb() and qb().Functions.GetPlayer(src))
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

function Framework.AddItem(src, item, amount, metadata)
    amount = amount or 1
    if Framework.inventory == 'ox' then
        return exports.ox_inventory:AddItem(src, item, amount, metadata)
    end
    if Framework.name == 'qb' or Framework.name == 'qbx' then
        local player = (Framework.name == 'qbx' and qbxPlayer(src)) or (qb() and qb().Functions.GetPlayer(src))
        if not player then return false end
        return player.Functions.AddItem(item, amount, false, metadata)
    end
    if Framework.name == 'esx' then
        local xPlayer = esx() and esx().GetPlayerFromId(src)
        if not xPlayer then return false end
        xPlayer.addInventoryItem(item, amount)
        return true
    end
    return false
end

function Framework.AddMoney(src, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    if Framework.name == 'qb' then
        local player = qb() and qb().Functions.GetPlayer(src)
        if not player then return false end
        player.Functions.AddMoney('cash', amount, 'djfivem-battlepass')
        return true
    end
    if Framework.name == 'qbx' then
        local player = qbxPlayer(src)
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

    -- Standalone: try ox_inventory cash, otherwise notify only.
    if Framework.inventory == 'ox' then
        local ok = exports.ox_inventory:AddItem(src, 'money', amount)
        if ok then return true end
    end
    return false
end

function Framework.GiveWeapon(src, weapon, ammo)
    ammo = ammo or 1
    local name = weapon
    if type(name) == 'string' then
        name = name:lower()
    end

    if Framework.inventory == 'ox' then
        return exports.ox_inventory:AddItem(src, weapon, 1)
    end
    if Framework.name == 'qb' or Framework.name == 'qbx' then
        local player = (Framework.name == 'qbx' and qbxPlayer(src)) or (qb() and qb().Functions.GetPlayer(src))
        if not player then return false end
        return player.Functions.AddItem(weapon, 1)
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
