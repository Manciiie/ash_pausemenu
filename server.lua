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

-- Anti déco en plein combat : dernier tir donné ou reçu par joueur (GetGameTimer), vu par le serveur.
-- Même détection qu'ash_dclogs (weaponDamageEvent, OneSync) : le client ne peut pas l'effacer.
local lastCombat = {}
local combatDelai = (tonumber(Config.BlockQuitInCombat) or 60) * 1000   -- 0 = désactivé

if combatDelai > 0 then
    AddEventHandler('weaponDamageEvent', function(sender, data)
        if type(data) ~= 'table' then return end
        local netId = data.hitGlobalId or (data.hitGlobalIds and data.hitGlobalIds[1])
        if not netId or netId == 0 then return end
        local ent = NetworkGetEntityFromNetworkId(netId)
        if ent == 0 or not IsPedAPlayer(ent) then return end
        local victim = NetworkGetEntityOwner(ent)
        sender = tonumber(sender)
        if not victim or not sender or victim == sender then return end
        local now = GetGameTimer()
        lastCombat[sender], lastCombat[victim] = now, now
    end)
end

-- Dimension (routing bucket) propre à chaque joueur qui quitte, et attente avant l'expulsion (ms)
local ISOLEMENT_BUCKET = 900000
local ISOLEMENT_DELAI  = 1500

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

    if combatDelai > 0 and lastCombat[src] and now - lastCombat[src] < combatDelai then
        local reste = math.ceil((combatDelai - (now - lastCombat[src])) / 1000)
        print(('[ash_pausemenu] %s (id %s) : départ refusé, combat il y a moins de %d s')
            :format(GetPlayerName(src) or '?', src, combatDelai // 1000))
        return false, (Config.Locale.combat or 'Tu ne peux pas quitter en plein combat. Réessaie dans %d s.'):format(reste)
    end

    quitting[src] = true
    print(('[ash_pausemenu] %s (id %s) a quitté via le menu pause'):format(GetPlayerName(src) or '?', src))

    -- petit délai pour que la réponse arrive à la NUI ("Déconnexion…") avant le drop.
    -- qb-core sauvegarde le joueur sur playerDropped, et ash_leaveped réagit normalement.
    SetTimeout(400, function()
        if not GetPlayerName(src) then
            quitting[src] = nil
            return
        end
        -- Le joueur passe seul dans une dimension à part avant l'expulsion : son personnage sort de la vue
        -- des joueurs proches comme s'il s'éloignait, au lieu de disparaître d'un coup (crash possible chez eux).
        -- ash_dclogs : départ volontaire (et non "kick"), à signaler avant le changement de dimension
        if GetResourceState('ash_dclogs') == 'started' then
            local ok, err = pcall(function() exports.ash_dclogs:SetDropReason(src, 'A quitté via le menu pause', 'quit') end)
            if not ok then print(('^3[ash_pausemenu] ash_dclogs:SetDropReason a échoué : %s^0'):format(tostring(err))) end
        end
        SetPlayerRoutingBucket(src, ISOLEMENT_BUCKET + src)
        SetTimeout(ISOLEMENT_DELAI, function()
            if GetPlayerName(src) then
                DropPlayer(src, Config.QuitMessage)
            end
            quitting[src] = nil
        end)
    end)

    return true
end)

AddEventHandler('playerDropped', function()
    quitting[source] = nil
    lastQuitTry[source] = nil
    lastCombat[source] = nil
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

-- Métiers jamais signalés : police et secours (type QBCore 'leo' / 'ems') et la liste Ignore de la config.
-- Sinon la carte dirait à tout le monde si la police est en service.
local ignoreJobs = {}
for _, nom in ipairs(jobCfg.Ignore or { 'police', 'sheriff', 'bcso', 'ambulance', 'ems' }) do ignoreJobs[nom] = true end
local IGNORE_TYPES = { leo = true, ems = true }

local sqlErreur = false   -- l'erreur SQL n'est écrite qu'une fois

local function loadJobBlips()
    local ok, rows = pcall(MySQL.query.await, 'SELECT job_name, coords FROM qs_jobs_data WHERE blip_id IS NOT NULL AND blip_id > 0')
    if not ok then
        -- table absente (qs-jobs-creator non installé) ou base indisponible : anneaux désactivés, signalé une fois
        if not sqlErreur then
            sqlErreur = true
            print(('^3[ash_pausemenu] lecture de qs_jobs_data impossible, métiers ouverts non affichés : %s^0'):format(tostring(rows)))
        end
        return
    end
    sqlErreur = false
    local list = {}
    for _, r in ipairs(rows or {}) do
        local x, y, z = parseCoords(r.coords)
        if x and y then list[#list + 1] = { job = r.job_name, x = x, y = y, z = z } end
    end
    jobBlips = list
end

-- lecture des blips dès que la base est prête : la première ouverture de carte n'attend pas la requête SQL
if jobCfg.Enabled ~= false then
    MySQL.ready(function()
        jobBlipsAt = GetGameTimer()
        loadJobBlips()
    end)
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
            if job and job.onduty and not ignoreJobs[job.name] and not IGNORE_TYPES[job.type] then
                onDuty[job.name] = true
            end
        end
        for _, b in ipairs(jobBlips) do
            if onDuty[b.job] then list[#list + 1] = { x = b.x, y = b.y, z = b.z } end
        end
        activeJobs = list
    end
    return activeJobs
end)
