local nuiOpen = false
local lastCoords = vector3(0.0, 0.0, 0.0)
local lastMovedAt = GetGameTimer()
local spawned = false
local lastToggleAt = 0

local function nui(payload)
    SendNUIMessage(payload)
end

local function forceClosed()
    nuiOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    nui({ action = 'close' })
end

local function setOpen(state)
    nuiOpen = state and true or false
    SetNuiFocus(nuiOpen, nuiOpen)
    SetNuiFocusKeepInput(false)
    if nuiOpen then
        nui({ action = 'open' })
    else
        nui({ action = 'close' })
    end
end

local function isPlayerInCity()
    if not spawned then return false end
    if not NetworkIsPlayerActive(PlayerId()) then return false end
    if IsPauseMenuActive() then return false end
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) or IsEntityDead(ped) then return false end
    return true
end

AddEventHandler('playerSpawned', function()
    spawned = true
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    spawned = true
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    spawned = false
    forceClosed()
end)

RegisterNetEvent('esx:playerLoaded', function()
    spawned = true
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    spawned = false
    forceClosed()
end)

local function requestOpen()
    local now = GetGameTimer()
    if (now - lastToggleAt) < 450 then return end
    lastToggleAt = now

    if nuiOpen then
        setOpen(false)
        return
    end
    TriggerServerEvent('djfivem_battlepass:server:requestOpen')
end

RegisterCommand(Config.OpenCommand, function()
    requestOpen()
end, false)

RegisterCommand('djfivem_battlepass', function()
    requestOpen()
end, false)

RegisterKeyMapping('djfivem_battlepass', 'Open DJFIVEM Battle Pass', 'keyboard', Config.OpenKey)

RegisterNetEvent('djfivem_battlepass:client:open', function(payload)
    nui({
        action = 'open',
        data = payload
    })
    nuiOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
end)

-- Progress updates never open the menu. Only apply while it is already open.
RegisterNetEvent('djfivem_battlepass:client:update', function(payload)
    if not nuiOpen then return end
    nui({
        action = 'update',
        data = payload
    })
end)

RegisterNetEvent('djfivem_battlepass:client:tierUp', function(tier, rewardName)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(('Battle Pass: Tier %d unlocked — %s'):format(tier, rewardName or ''))
    EndTextCommandThefeedPostTicker(false, true)
    if nuiOpen then
        nui({
            action = 'tierUp',
            tier = tier,
            name = rewardName
        })
    end
end)

RegisterNetEvent('djfivem_battlepass:client:notify', function(message, nType)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message or '')
    EndTextCommandThefeedPostTicker(nType == 'error', true)
end)

RegisterNUICallback('close', function(_, cb)
    forceClosed()
    cb({ ok = true })
end)

RegisterNUICallback('claim', function(data, cb)
    if not nuiOpen then
        cb({ ok = false })
        return
    end
    local tier = tonumber(data and data.tier)
    if not tier then
        cb({ ok = false })
        return
    end
    TriggerServerEvent('djfivem_battlepass:server:claim', tier)
    cb({ ok = true })
end)

RegisterNUICallback('claimAll', function(_, cb)
    if not nuiOpen then
        cb({ ok = false })
        return
    end
    TriggerServerEvent('djfivem_battlepass:server:claimAll')
    cb({ ok = true })
end)

RegisterNUICallback('ready', function(_, cb)
    forceClosed()
    cb({ ok = true, inGame = true })
end)

CreateThread(function()
    forceClosed()
    while true do
        if nuiOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 322, true)
            DisableControlAction(0, 106, true)
            DisableControlAction(0, 199, true)
            DisableControlAction(0, 200, true)
            if IsDisabledControlJustReleased(0, 322) or IsControlJustReleased(0, 322) then
                forceClosed()
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(2000)
        if isPlayerInCity() then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            if lastCoords.x == 0.0 and lastCoords.y == 0.0 then
                lastCoords = coords
                lastMovedAt = GetGameTimer()
            elseif #(coords - lastCoords) >= (Config.AfkMoveThreshold or 1.25) then
                lastCoords = coords
                lastMovedAt = GetGameTimer()
            end
        end
    end
end)

CreateThread(function()
    local interval = math.max(15, tonumber(Config.XpIntervalSeconds) or 60) * 1000
    while true do
        Wait(interval)
        if isPlayerInCity() then
            local idleMs = GetGameTimer() - lastMovedAt
            local afkMs = (tonumber(Config.AfkTimeoutSeconds) or 180) * 1000
            if afkMs <= 0 or idleMs < afkMs then
                TriggerServerEvent('djfivem_battlepass:server:tickXp')
            end
        end
    end
end)

AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    forceClosed()
end)

CreateThread(function()
    Wait(1500)
    if NetworkIsPlayerActive(PlayerId()) and DoesEntityExist(PlayerPedId()) and HasCollisionLoadedAroundEntity(PlayerPedId()) then
        spawned = true
    end
    forceClosed()
end)
