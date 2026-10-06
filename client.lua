local QBCore = exports['qb-core']:GetCoreObject()

-- natives utilisées dans la boucle par frame, mises en locales (évite une recherche globale à chaque frame)
local DisableControlAction         = DisableControlAction
local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local IsNuiFocused                 = IsNuiFocused
local IsPauseMenuActive            = IsPauseMenuActive
local GetGameTimer                 = GetGameTimer
local Wait                         = Wait

local CTRL_ESC, CTRL_P = 200, 199
local overrideP = Config.OverrideP

local isOpen       = false
local nativeOpen   = false   -- menu pause GTA (carte / paramètres) ouvert depuis notre menu
local lastToggle   = 0
local lastForeignNui = 0     -- dernière fois qu'une autre NUI (téléphone, chat...) avait le focus
local sessionStart = GetGameTimer()
local staticSent   = false   -- règlement / touches envoyés une seule fois à la NUI

-- Mode streamer (mémorisé sur le PC du joueur)
local streamer = GetResourceKvpInt('ash_streamer') == 1

local function applyStreamer(enabled, silent)
    streamer = enabled
    SetResourceKvpInt('ash_streamer', enabled and 1 or 0)
    LocalPlayer.state:set('streamerMode', enabled, false)
    TriggerEvent('ash_pausemenu:streamerMode', enabled)

    for _, cmd in ipairs(enabled and Config.Streamer.commandsOn or Config.Streamer.commandsOff) do
        ExecuteCommand(cmd)
    end

    if not silent then
        lib.notify({
            title = 'Mode streamer',
            description = enabled and Config.Locale.streamerOn or Config.Locale.streamerOff,
            type = enabled and 'success' or 'inform',
        })
    end
end

local function playerInfo()
    local pd  = QBCore.Functions.GetPlayerData() or {}
    local ci  = pd.charinfo or {}
    local job = pd.job or {}

    local name = (('%s %s'):format(ci.firstname or '', ci.lastname or '')):match('^%s*(.-)%s*$')
    if name == '' then name = GetPlayerName(PlayerId()) end

    return {
        name      = name,
        job       = job.label or 'Sans emploi',
        grade     = job.grade and job.grade.name or nil,
        id        = GetPlayerServerId(PlayerId()),
        citizenid = pd.citizenid or '—',
    }
end

local function openMenu()
    isOpen = true
    lastToggle = GetGameTimer()
    SetNuiFocus(true, true)
    if Config.Blur then TriggerScreenblurFadeIn(250) end

    local msg = {
        action   = 'open',
        player   = playerInfo(),
        session  = math.floor((GetGameTimer() - sessionStart) / 1000),
        streamer = streamer,
        config   = {
            server   = Config.ServerName,
            subtitle = Config.Subtitle,
            discord  = Config.Discord,
            shop     = Config.Shop,
            report   = Config.ReportCommand ~= nil and Config.ReportCommand ~= '',
            hold     = Config.HoldToQuit,
        },
    }
    if not staticSent then
        msg.static = { rules = Config.Rules, rulesIntro = Config.RulesIntro, keys = Config.Keys }
        staticSent = true
    end
    SendNUIMessage(msg)

    lib.callback('ash_pausemenu:getStats', false, function(stats)
        if isOpen and stats then
            SendNUIMessage({ action = 'stats', players = stats.players, max = stats.max })
        end
    end)
end

local function closeMenu()
    if not isOpen then return end
    isOpen = false
    lastToggle = GetGameTimer()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    if Config.Blur then TriggerScreenblurFadeOut(250) end
end

-- Ouvre un menu natif GTA (carte / paramètres) puis rend la main quand il se ferme
local function openNative(menuHash)
    closeMenu()
    nativeOpen = true
    CreateThread(function()
        Wait(50)
        ActivateFrontendMenu(menuHash, false, -1)
        -- attend que le menu GTA soit réellement ouvert (1 s max), puis qu'il se ferme
        local timeout = GetGameTimer() + 1000
        while not IsPauseMenuActive() and GetGameTimer() < timeout do Wait(50) end
        while IsPauseMenuActive() do Wait(100) end
        lastToggle = GetGameTimer()
        nativeOpen = false
    end)
end

-- Boucle principale : on bloque le menu pause GTA et on ouvre le nôtre à la place.
-- Tant que le personnage n'est pas chargé (sélection de perso, spawn), le script dort
-- et le menu pause GTA reste normal.
local playerState = LocalPlayer.state

CreateThread(function()
    while true do
        if nativeOpen or not playerState.isLoggedIn then
            Wait(250)
        elseif isOpen then
            -- menu ouvert : la NUI a le clavier, on empêche juste GTA d'ouvrir son menu derrière
            DisableControlAction(0, CTRL_ESC, true)
            if overrideP then DisableControlAction(0, CTRL_P, true) end
            Wait(0)
        else
            DisableControlAction(0, CTRL_ESC, true)
            if overrideP then DisableControlAction(0, CTRL_P, true) end

            if IsNuiFocused() then
                lastForeignNui = GetGameTimer()          -- téléphone, chat, inventaire… ont la main
            elseif IsDisabledControlJustPressed(0, CTRL_ESC) or (overrideP and IsDisabledControlJustPressed(0, CTRL_P)) then
                local now = GetGameTimer()
                if now - lastToggle > 400                -- anti double appui après fermeture
                    and now - lastForeignNui > 300       -- l'ÉCHAP qui ferme le téléphone ne rouvre pas le menu
                    and not IsPauseMenuActive() then
                    openMenu()
                end
            end
            Wait(0)
        end
    end
end)

-- Applique le mode streamer mémorisé une fois le personnage chargé
-- (les commandes des autres scripts existent alors à coup sûr)
local function restoreStreamer()
    if streamer then applyStreamer(true, true) end
end
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', restoreStreamer)
AddEventHandler('onClientResourceStart', function(res)
    if res == GetCurrentResourceName() and playerState.isLoggedIn then restoreStreamer() end
end)

-- Callbacks NUI
RegisterNUICallback('close', function(_, cb)
    closeMenu()
    cb('ok')
end)

RegisterNUICallback('map', function(_, cb)
    openNative(`FE_MENU_VERSION_MP_PAUSE`)
    cb('ok')
end)

RegisterNUICallback('settings', function(_, cb)
    openNative(`FE_MENU_VERSION_LANDING_MENU`)
    cb('ok')
end)

RegisterNUICallback('streamer', function(data, cb)
    applyStreamer(data and data.enabled == true)
    cb({ enabled = streamer, player = playerInfo() })
end)

RegisterNUICallback('report', function(_, cb)
    cb('ok')
    closeMenu()
    CreateThread(function()
        Wait(150)   -- laisse le focus NUI se libérer avant d'ouvrir l'interface de Luxu
        ExecuteCommand(Config.ReportCommand)
    end)
end)

RegisterNUICallback('quit', function(_, cb)
    local ok, reason = lib.callback.await('ash_pausemenu:quit', false)
    cb({ ok = ok == true, reason = reason })
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if isOpen then
        SetNuiFocus(false, false)
        TriggerScreenblurFadeOut(0)
    end
end)

exports('IsOpen', function() return isOpen end)
exports('Close', closeMenu)
exports('IsStreamerMode', function() return streamer end)
