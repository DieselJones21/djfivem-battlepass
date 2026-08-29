local nuiOpen = false
local lastCoords = vector3(0.0, 0.0, 0.0)
local lastMovedAt = GetGameTimer()
local spawned = false

local function nui(payload)
    SendNUIMessage(payload)
end

local function setOpen(state)
    nuiOpen = state
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(false)
    nui({ action = state and 'open' or 'close' })
end

local function isPlayerInCity()
    if not NetworkIsPlayerActive(PlayerId()) then return false end
    if IsPauseMenuActive() then return false end
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) or IsEntityDead(ped) then return false end
    -- Player must have actually spawned into the world (not still in loading/multichar).
    if not spawned and not HasCollisionLoadedAroundEntity(ped) then return false end
    return true
end

RegisterNetEvent('djfivem_battlepass:client:setSpawned', function(state)
    spawned = state and true or false
end)

AddEventHandler('playerSpawned', function()
    spawned = true
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    spawned = true
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    spawned = false
    if nuiOpen then setOpen(false) end
end)

RegisterNetEvent('esx:playerLoaded', function()
    spawned = true
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    spawned = false
    if nuiOpen then setOpen(false) end
end)

local function requestOpen()
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
        action = 'hydrate',
        data = payload
    })
    setOpen(true)
end)

RegisterNetEvent('djfivem_battlepass:client:update', function(payload)
    nui({
        action = 'hydrate',
        data = payload
    })
end)

RegisterNetEvent('djfivem_battlepass:client:tierUp', function(tier, rewardName)
    nui({
        action = 'tierUp',
        tier = tier,
        name = rewardName
    })
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(('Battle Pass: Tier %d unlocked — %s'):format(tier, rewardName or ''))
    EndTextCommandThefeedPostTicker(false, true)
end)

RegisterNetEvent('djfivem_battlepass:client:notify', function(message, nType)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message or '')
    EndTextCommandThefeedPostTicker(nType == 'error', true)
end)

RegisterNUICallback('close', function(_, cb)
    setOpen(false)
    cb({ ok = true })
end)

RegisterNUICallback('claim', function(data, cb)
    local tier = tonumber(data and data.tier)
    if not tier then
        cb({ ok = false })
        return
    end
    TriggerServerEvent('djfivem_battlepass:server:claim', tier)
    cb({ ok = true })
end)

RegisterNUICallback('claimAll', function(_, cb)
    TriggerServerEvent('djfivem_battlepass:server:claimAll')
    cb({ ok = true })
end)

RegisterNUICallback('ready', function(_, cb)
    cb({ ok = true, inGame = true })
end)

-- Keep mouse/camera locked while the pass is open. ESC closes.
CreateThread(function()
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
                setOpen(false)
            end
            Wait(0)
        else
            Wait(400)
        end
    end
end)

-- City playtime XP: tick on the server only if the player is spawned and not AFK.
CreateThread(function()
    while true do
        Wait(1000)
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
            -- 0 disables the AFK gate so any spawned player in the city earns XP.
            if afkMs <= 0 or idleMs < afkMs then
                TriggerServerEvent('djfivem_battlepass:server:tickXp')
            end
        end
    end
end)

-- If the resource restarts while the player is already in the city.
CreateThread(function()
    Wait(2500)
    if NetworkIsPlayerActive(PlayerId()) and DoesEntityExist(PlayerPedId()) then
        spawned = true
    end
end)
