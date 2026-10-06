local QBCore = exports['qb-core']:GetCoreObject()
local quitting = {}

-- Stats mises en cache 5 s : 50 joueurs qui ouvrent le menu = 1 seul GetPlayers()
local maxClients = GetConvarInt('sv_maxclients', 48)
local stats      = { players = 0, max = maxClients }
local statsAt    = -1e9

lib.callback.register('ash_pausemenu:getStats', function(src)
    -- lecture seule (nombre de joueurs), mais on ne répond qu'à un joueur chargé
    if not QBCore.Functions.GetPlayer(src) then return nil end
    local now = GetGameTimer()
    if now - statsAt > 5000 then
        stats.players = #GetPlayers()
        statsAt = now
    end
    return stats
end)

local lastQuitTry = {}

lib.callback.register('ash_pausemenu:quit', function(src)
    if quitting[src] then return true end

    -- anti-spam : une demande par seconde max par joueur
    local now = GetGameTimer()
    if lastQuitTry[src] and now - lastQuitTry[src] < 1000 then
        return false, Config.Locale.wait
    end
    lastQuitTry[src] = now

    if Config.BlockQuitWhenRestrained then
        local xPlayer = QBCore.Functions.GetPlayer(src)
        local md      = xPlayer and xPlayer.PlayerData.metadata or {}
        local state   = Player(src).state

        if md.ishandcuffed then
            return false, Config.Locale.cuffed
        end
        -- metadata QBCore + statebags éventuels posés par wasabi_ambulance
        if md.isdead or md.inlaststand or state.dead or state.isDead then
            return false, Config.Locale.dead
        end
    end

    quitting[src] = true
    print(('[ash_pausemenu] %s (id %s) a quitté via le menu pause'):format(GetPlayerName(src) or '?', src))

    -- petit délai pour que la réponse arrive à la NUI ("Déconnexion…") avant le drop.
    -- qb-core sauvegarde le joueur sur playerDropped, et ash_leaveped réagit normalement.
    SetTimeout(400, function()
        if GetPlayerName(src) then
            DropPlayer(src, Config.QuitMessage)
        end
        quitting[src] = nil
    end)

    return true
end)

AddEventHandler('playerDropped', function()
    quitting[source] = nil
    lastQuitTry[source] = nil
end)
