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

    -- personnage pas chargé (sélection de perso, spawn) : rien à quitter via ce menu
    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not xPlayer then return false, Config.Locale.wait end

    if Config.BlockQuitWhenRestrained then
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

-- Métiers ouverts (carte) : blips de qs-jobs-creator dont le métier a au moins un employé en service.
-- Blips relus en base toutes les Refresh secondes, liste des métiers ouverts réutilisée 10 s.
local jobCfg = (Config.Map or {}).ActiveJobs or {}
local jobBlips, jobBlipsAt = {}, -1e9
local activeJobs, activeJobsAt = {}, -1e9

-- coords en JSON { x, y, z } ou texte « x, y, z » / vector3(x, y, z)
local function parseCoords(raw)
    local ok, t = pcall(json.decode, raw or '')
    if ok and type(t) == 'table' and t.x and t.y then return tonumber(t.x), tonumber(t.y), tonumber(t.z) end
    local n, text = {}, (tostring(raw):gsub('vector%d', ''))
    for v in text:gmatch('-?%d+%.?%d*') do n[#n + 1] = tonumber(v) end
    return n[1], n[2], n[3]
end

local function loadJobBlips()
    local ok, rows = pcall(MySQL.query.await, 'SELECT job_name, coords FROM qs_jobs_data WHERE blip_id IS NOT NULL AND blip_id > 0')
    if not ok then return end   -- table absente : qs-jobs-creator non installé
    local list = {}
    for _, r in ipairs(rows or {}) do
        local x, y, z = parseCoords(r.coords)
        if x and y then list[#list + 1] = { job = r.job_name, x = x, y = y, z = z } end
    end
    jobBlips = list
end

lib.callback.register('ash_pausemenu:activeJobs', function(src)
    if jobCfg.Enabled == false or not QBCore.Functions.GetPlayer(src) then return nil end
    local now = GetGameTimer()
    if now - activeJobsAt > 10000 then
        activeJobsAt = now
        if now - jobBlipsAt > (jobCfg.Refresh or 300) * 1000 then
            jobBlipsAt = now
            loadJobBlips()
        end
        local onDuty, list = {}, {}
        for _, p in pairs(QBCore.Functions.GetQBPlayers()) do
            local job = p.PlayerData.job
            if job and job.onduty then onDuty[job.name] = true end
        end
        for _, b in ipairs(jobBlips) do
            if onDuty[b.job] then list[#list + 1] = { x = b.x, y = b.y, z = b.z } end
        end
        activeJobs = list
    end
    return activeJobs
end)
