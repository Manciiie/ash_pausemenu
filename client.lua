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

-- Notifications : ash_notify si démarrée, sinon ox_lib --------------------------
-- Valeurs par défaut si Config.Notifications manque (un ancien config.lua ne doit pas retomber sur ox_lib)
local NOTIF_DEFAUT = {
    systeme    = 'ash_notify',
    ressources = { 'ash_notify' },
    duree      = 5000,
    son        = { success = true, error = true, warning = false, info = false },
}
local TYPES_ASH = { inform = 'info', info = 'info', success = 'success', error = 'error', warning = 'warning' }
local secoursSignale = false

local function reglagesNotif()
    local N = Config.Notifications
    if type(N) ~= 'table' then return NOTIF_DEFAUT end
    return {
        systeme    = N.systeme or NOTIF_DEFAUT.systeme,
        ressources = N.ressources or (N.ressource and { N.ressource }) or NOTIF_DEFAUT.ressources,
        duree      = N.duree or NOTIF_DEFAUT.duree,
        son        = N.son or NOTIF_DEFAUT.son,
    }
end

-- Ressource ash_notify si elle est démarrée, sinon nil
local function ressourceNotif(N)
    if N.systeme ~= 'ash_notify' then return nil end
    for _, nom in ipairs(N.ressources) do
        if GetResourceState(nom) == 'started' then return nom end
    end
    if not secoursSignale then
        secoursSignale = true
        print(('^3[%s] aucune ressource de notification démarrée (%s) : notifications ox_lib utilisées^0')
            :format(GetCurrentResourceName(), table.concat(N.ressources, ', ')))
    end
    return nil
end

local function notifier(titre, message, typeNotif)
    local N = reglagesNotif()
    local ressource = ressourceNotif(N)
    if ressource then
        local typeAsh = TYPES_ASH[typeNotif or 'inform'] or 'info'
        local ok, err = pcall(function()
            exports[ressource]:SendAlert(titre, message, N.duree, typeAsh, N.son[typeAsh] or false)
        end)
        if ok then return end
        print(('^1[%s] %s en erreur, ox_lib utilisé : %s^0'):format(GetCurrentResourceName(), ressource, tostring(err)))
    end
    lib.notify({ title = titre, description = message, type = typeNotif or 'inform' })
end

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
        notifier('Mode streamer',
            enabled and Config.Locale.streamerOn or Config.Locale.streamerOff,
            enabled and 'success' or 'inform')
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

-- Récompenses VIP (ash_vipdaily) ------------------------------------------------
local vd = Config.VipDaily or {}
local vipCache, vipCacheAt = nil, -1e9

local function vipDailyActif()
    return vd.Ressource and vd.Ressource ~= '' and GetResourceState(vd.Ressource) == 'started'
end

-- Récupère l'état du jour auprès d'ash_vipdaily (son callback serveur vérifie tout),
-- avec un petit cache pour ne pas interroger le serveur à chaque ÉCHAP
local function sendVipDaily()
    local now = GetGameTimer()
    if vipCache and now - vipCacheAt < (vd.Cache or 30) * 1000 then
        SendNUIMessage({ action = 'vipdaily', etat = vipCache })
        return
    end
    lib.callback('ash_vipdaily:server:ouvrir', false, function(d)
        if type(d) ~= 'table' then return end
        vipCache = {
            vip        = d.vip == true,
            disponible = d.disponible == true,
            recupere   = d.dejaRecupere == true,
            serie      = tonumber(d.serie) or 0,
            secondes   = tonumber(d.secondes) or 0,
        }
        vipCacheAt = GetGameTimer()
        if isOpen then SendNUIMessage({ action = 'vipdaily', etat = vipCache }) end
    end)
end

-- Prévisualisation du personnage (vue Aperçu) ------------------------------------
local pv = Config.Preview or {}
local previewCam, blurOn, headshot = nil, false, nil

local function setBlur(on)
    on = on and Config.Blur or false
    if on == blurOn then return end
    blurOn = on
    if on then TriggerScreenblurFadeIn(250) else TriggerScreenblurFadeOut(250) end
end

-- Caméra face au personnage, décalée pour qu'il apparaisse à droite de l'écran
local function startPreview()
    if previewCam then return true end
    local ped = PlayerPedId()
    if not pv.Enabled or IsPedInAnyVehicle(ped, false) or IsEntityDead(ped) or IsPedRagdoll(ped) then return false end

    local dist, height = pv.Distance or 2.6, pv.Height or 0.15
    local head = GetPedBoneCoords(ped, 31086, 0.0, 0.0, 0.0)   -- SKEL_Head
    local camPos = GetOffsetFromEntityInWorldCoords(ped, 0.0, dist, height)

    -- mur ou objet entre le perso et la caméra : on la rapproche, ou on abandonne si c'est trop serré
    local ray = StartExpensiveSynchronousShapeTestLosProbe(head.x, head.y, head.z, camPos.x, camPos.y, camPos.z, 1 | 16, ped, 0)
    local _, hit, hitPos = GetShapeTestResult(ray)
    if hit == 1 then
        local d = #(hitPos - head) - 0.35
        if d < 1.3 then return false end
        dist = d
        camPos = GetOffsetFromEntityInWorldCoords(ped, 0.0, dist, height)
    end

    -- viser à droite du perso (= à gauche pour la caméra) le pousse vers la droite de l'écran
    local shift = (pv.Shift or 1.0) * dist / (pv.Distance or 2.6)
    local aim = GetOffsetFromEntityInWorldCoords(ped, shift, 0.0, pv.AimHeight or -0.05)
    previewCam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', camPos.x, camPos.y, camPos.z, 0.0, 0.0, 0.0, pv.Fov or 42.0, false, 0)
    PointCamAtCoord(previewCam, aim.x, aim.y, aim.z)
    SetCamActive(previewCam, true)
    RenderScriptCams(true, true, 500, true, true)
    if pv.LookAtCamera ~= false then TaskLookAtCoord(ped, camPos.x, camPos.y, camPos.z, -1, 2048, 3) end
    return true
end

local function stopPreview(instant)
    if not previewCam then return end
    local cam = previewCam
    previewCam = nil
    RenderScriptCams(false, not instant, instant and 0 or 400, true, true)
    TaskClearLookAt(PlayerPedId())
    SetTimeout(instant and 0 or 450, function()
        SetCamActive(cam, false)
        DestroyCam(cam, false)
    end)
end

-- Portrait du perso (avatar + secours quand la caméra n'est pas possible).
-- Réutilisé tant que le perso a la même tête et la même tenue : GTA ne refait pas un rendu à chaque ÉCHAP.
local headshotLook
local LOOK_PARTS = { 0, 1, 2, 3, 8, 11 }   -- tête, barbe, cheveux, torse, sous-haut, haut

local function pedLook(ped)
    local t = { ped, GetEntityModel(ped) }
    for _, c in ipairs(LOOK_PARTS) do
        t[#t + 1] = GetPedDrawableVariation(ped, c)
        t[#t + 1] = GetPedTextureVariation(ped, c)
    end
    return table.concat(t, ':')
end

local function sendHeadshot()
    local ped = PlayerPedId()
    local look = pedLook(ped)
    if headshot and look == headshotLook and IsPedheadshotValid(headshot) and IsPedheadshotReady(headshot) then
        SendNUIMessage({ action = 'headshot', txd = GetPedheadshotTxdString(headshot) })
        return
    end
    if headshot then UnregisterPedheadshot(headshot) end
    headshotLook = look
    headshot = RegisterPedheadshotTransparent(ped)
    local id = headshot
    CreateThread(function()
        local timeout = GetGameTimer() + 3000
        while id == headshot and not IsPedheadshotReady(id) and GetGameTimer() < timeout do Wait(50) end
        if id == headshot and IsPedheadshotReady(id) and isOpen then
            SendNUIMessage({ action = 'headshot', txd = GetPedheadshotTxdString(id) })
        end
    end)
end

local function openMenu()
    isOpen = true
    lastToggle = GetGameTimer()
    SetNuiFocus(true, true)
    -- le flou est géré par la vue (callback 'view') : pas de flou derrière l'aperçu du perso
    if not pv.Enabled then setBlur(true) end

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
            vipdaily = vipDailyActif() and true or false,
            hold     = Config.HoldToQuit,
        },
    }
    if not staticSent then
        local m = Config.Map or {}
        msg.static = {
            rules = Config.Rules, rulesIntro = Config.RulesIntro, keys = Config.Keys,
            map = m.Enabled and {
                tiles = m.Tiles, tilesFallback = m.TilesFallback, layers = m.Layers, calib = m.Calibration,
                categories = m.Categories, categoryOrder = m.CategoryOrder, places = m.Places,
                showUnknown = m.ShowUnknown ~= false,
                realistic = (m.Realistic or {}).Enabled ~= false and {
                    distance = (m.Realistic or {}).Distance, pitch = (m.Realistic or {}).Pitch, fov = (m.Realistic or {}).Fov,
                    minDistance = (m.Realistic or {}).MinDistance, maxDistance = (m.Realistic or {}).MaxDistance,
                } or nil,
                cayo = m.Cayo and m.Cayo.Enabled and { bounds = m.Cayo.Bounds, images = m.Cayo.Images } or nil,
                postals = m.Postals and m.Postals.Enabled ~= false and { file = m.Postals.File, minZoom = m.Postals.MinZoom } or nil,
            } or nil,
        }
        staticSent = true
    end
    SendNUIMessage(msg)

    lib.callback('ash_pausemenu:getStats', false, function(stats)
        if isOpen and stats then
            SendNUIMessage({ action = 'stats', players = stats.players, max = stats.max })
        end
    end)

    if msg.config.vipdaily then sendVipDaily() end
    sendHeadshot()
end

-- Carte réaliste : caméra scriptée au-dessus de la vraie ville, pilotée par la NUI (voir 'map3d' plus bas)
local r3d = nil   -- { cam, pose } tant que la vue réaliste est affichée

-- HUD d'autres ressources masqués pendant la vue (Config.Map.Realistic.HideHuds : ressource = export(show))
local function toggleOtherHuds(show)
    local huds = ((Config.Map or {}).Realistic or {}).HideHuds or {}
    for res, fn in pairs(huds) do
        if GetResourceState(res) == 'started' then
            local ok, err = pcall(function() local e = exports[res]; e[fn](e, show) end)   -- = exports[res]:fn(show)
            if not ok then print(('^3[%s] %s:%s a échoué : %s^0'):format(GetCurrentResourceName(), res, fn, tostring(err))) end
        end
    end
end

local function stop3d()
    if not r3d then return end
    local cam = r3d.cam
    r3d = nil
    toggleOtherHuds(true)
    RenderScriptCams(false, false, 0, true, true)
    SetCamActive(cam, false)
    DestroyCam(cam, false)
    ClearFocus()
end

local function closeMenu(instant)
    if not isOpen then return end
    isOpen = false
    lastToggle = GetGameTimer()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    stop3d()
    stopPreview(instant)
    setBlur(false)
end

-- Ouvre un menu natif GTA (carte / paramètres) puis rend la main quand il se ferme
local function openNative(menuHash)
    closeMenu(true)
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
-- Les callbacks qui agissent (GPS, commandes, déconnexion…) ne répondent que menu ouvert :
-- une autre page NUI ou un script ne peut pas les déclencher pendant le jeu.
local function onNui(name, handler)
    RegisterNUICallback(name, function(data, cb)
        if not isOpen then return cb({ ok = false }) end
        handler(type(data) == 'table' and data or {}, cb)
    end)
end

RegisterNUICallback('close', function(_, cb)
    closeMenu()
    cb('ok')
end)

onNui('map', function(_, cb)
    openNative(`FE_MENU_VERSION_MP_PAUSE`)
    cb('ok')
end)

-- Vue affichée par la NUI : caméra sur le perso dans l'Aperçu, flou ailleurs
RegisterNUICallback('view', function(data, cb)
    local overview = type(data) == 'table' and data.name == 'overview'
    local preview = false
    if isOpen and overview then preview = startPreview() else stopPreview() end
    if isOpen then setBlur(not preview and not r3d) end
    cb({ preview = preview })
end)

-- Carte NUI ----------------------------------------------------------------------
local mapCfg = Config.Map or {}
local SPRITE_MAX = 970   -- dernier sprite de blip connu (docs FiveM)
local ENTITY_BLIP = { [1] = true, [2] = true, [3] = true }   -- véhicule / ped / objet : joueurs et PNJ exclus
local cayoEdgeBlip                                           -- blip technique de Cayo (carte native), jamais affiché dans le NUI

-- Blips fixes visibles sur la carte GTA du joueur (scannés à l'ouverture de la carte uniquement)
local function collectBlips()
    local list, seen = {}, {}
    local sprites = mapCfg.Sprites or {}
    for sprite = 1, SPRITE_MAX do
        if sprite ~= 8 then   -- 8 = point GPS, envoyé à part
            local blip = GetFirstBlipInfoId(sprite)
            while DoesBlipExist(blip) do
                local display = GetBlipInfoIdDisplay(blip)
                if not ENTITY_BLIP[GetBlipInfoIdType(blip)] and display ~= 0 and display ~= 5 and blip ~= cayoEdgeBlip then
                    local c = GetBlipInfoIdCoord(blip)
                    local key = ('%d:%d:%d'):format(sprite, math.floor(c.x), math.floor(c.y))
                    if not seen[key] then
                        seen[key] = true
                        local def = sprites[sprite]
                        list[#list + 1] = {
                            x = math.floor(c.x * 10) / 10, y = math.floor(c.y * 10) / 10,
                            -- hauteur pour la carte réaliste (beaucoup de blips sont créés à z = 0 : sol cherché par la NUI)
                            z = math.abs(c.z) > 0.5 and math.floor(c.z * 10) / 10 or nil,
                            label = def and def[1] or nil, cat = def and def[2] or 'poi',
                            unknown = def == nil or nil,
                        }
                    end
                end
                blip = GetNextBlipInfoId(sprite)
            end
        end
    end
    return list
end

-- Scan réutilisé 15 s : rouvrir la carte plusieurs fois de suite ne rescanne pas les ~970 sprites
local blipCache, blipCacheAt = nil, -1e9
local function cachedBlips()
    local now = GetGameTimer()
    if not blipCache or now - blipCacheAt > 15000 then
        blipCache, blipCacheAt = collectBlips(), now
    end
    return blipCache
end

local DIRS = { 'N', 'NO', 'O', 'SO', 'S', 'SE', 'E', 'NE' }
local function r10(v) return math.floor(v * 10 + 0.5) / 10 end

-- Itinéraire GPS vers le point GPS, en points {x, y, z, x, y, z, ...} (une centaine au plus)
local function gpsRoute()
    if not IsWaypointActive() then return nil end
    local len = GetGpsBlipRouteLength()
    local step = len and len > 0 and math.max(15.0, len / 150) or 40.0
    local pts, last, d = {}, nil, 0.0
    for _ = 1, 200 do
        local ok, p = GetPosAlongGpsTypeRoute(true, d, 0)
        if not ok or (last and #(p - last) < 1.0) then break end   -- fin de l'itinéraire
        pts[#pts + 1], pts[#pts + 2], pts[#pts + 3] = r10(p.x), r10(p.y), r10(p.z)
        last, d = p, d + step
    end
    return #pts >= 6 and pts or nil
end

local function waypointCoords()
    if not IsWaypointActive() then return nil end
    local w = GetBlipInfoIdCoord(GetFirstBlipInfoId(8))
    return { x = w.x, y = w.y }
end

onNui('mapData', function(_, cb)
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local s1, s2 = GetStreetNameAtCoord(c.x, c.y, c.z)
    local street = GetStreetNameFromHashKey(s1)
    if s2 ~= 0 then street = street .. ' / ' .. GetStreetNameFromHashKey(s2) end

    cb({
        me       = { x = c.x, y = c.y, z = c.z, heading = heading },
        dir      = DIRS[math.floor(((heading + 22.5) % 360) / 45) + 1],
        street   = street,
        zone     = GetLabelText(GetNameOfZone(c.x, c.y, c.z)),
        blips    = cachedBlips(),
        waypoint = waypointCoords(),
        route    = gpsRoute(),
    })
end)

-- Itinéraire seul, redemandé par la NUI juste après un nouveau point GPS (GTA le calcule en quelques images)
onNui('route', function(_, cb)
    cb({ waypoint = waypointCoords(), route = gpsRoute() })
end)

onNui('waypoint', function(data, cb)
    local x, y = tonumber(data.x), tonumber(data.y)
    if x and y and math.abs(x) < 10000 and math.abs(y) < 10000 then
        SetNewWaypoint(x + 0.0, y + 0.0)
        cb({ ok = true })
    else
        cb({ ok = false })
    end
end)

onNui('clearWaypoint', function(_, cb)
    SetWaypointOff()
    cb('ok')
end)

-- Carte réaliste ------------------------------------------------------------------
-- La NUI garde la pose de la caméra (point visé tx/ty/tz, cap h, inclinaison p, distance dist) et calcule
-- elle-même la position de chaque blip à l'écran avec la même formule : ici on ne fait que poser la caméra.
local real = mapCfg.Realistic or {}

local function groundZ(x, y)
    local found, z = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, 1000.0, false)
    if found then return z end
end

-- Vecteurs de la caméra GTA pour un cap h et une inclinaison p (degrés), comme dans la NUI
local function camAxes(h, p)
    local rh, rp = math.rad(h), math.rad(p)
    local fwd = vector3(-math.sin(rh) * math.cos(rp), math.cos(rh) * math.cos(rp), -math.sin(rp))
    local right = vector3(math.cos(rh), math.sin(rh), 0.0)
    return fwd, right
end

-- Pose reçue de la NUI, bornée (une valeur absurde ne doit pas envoyer la caméra n'importe où)
local function readPose(d)
    local n = function(v, lo, hi, def) v = tonumber(v) or def; return math.max(lo, math.min(hi, v)) end
    local pose = {
        tx = n(d.tx, -8000, 10000, 0), ty = n(d.ty, -9000, 11000, 0), tz = n(d.tz, -200, 1500, 30),
        h = (tonumber(d.h) or 0) % 360, p = n(d.p, 20, 89, 56),
        dist = n(d.dist, real.MinDistance or 90.0, real.MaxDistance or 3200.0, 850),
    }
    local fwd = camAxes(pose.h, pose.p)
    pose.pos = vector3(pose.tx, pose.ty, pose.tz) - fwd * pose.dist
    return pose
end

local function applyPose(pose)
    SetCamCoord(r3d.cam, pose.pos.x, pose.pos.y, pose.pos.z)
    -- la caméra vise le point visé : le cap et l'inclinaison découlent de sa position (calculée comme dans la NUI).
    -- SetCamRot(-p, 0, h) laissait la caméra presque à l'horizontale en jeu : blips dans le ciel.
    PointCamAtCoord(r3d.cam, pose.tx, pose.ty, pose.tz)
    SetFocusPosAndVel(pose.tx, pose.ty, pose.tz, 0.0, 0.0, 0.0)   -- charge la ville autour du point visé
    r3d.pose = pose
end

onNui('map3d', function(data, cb)
    if data.active ~= true then
        stop3d()
        setBlur(true)
        return cb({ ok = true })
    end
    if real.Enabled == false then return cb({ ok = false }) end
    stopPreview(true)
    setBlur(false)
    if not r3d then
        local cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, real.Fov or 45.0, false, 2)
        r3d = { cam = cam }
        toggleOtherHuds(false)
        SetCamActive(cam, true)
        RenderScriptCams(true, false, 0, true, true)   -- la NUI masque la bascule par un fondu au noir
    end
    local pose = readPose(data.pose or {})
    applyPose(pose)
    cb({ ok = true, fov = real.Fov or 45.0 })

    -- étalonnage : où GTA affiche vraiment un point à droite du centre, pour caler la projection de la NUI
    -- sur le champ de vision réel (rapport largeur / hauteur de l'écran, réglages du joueur)
    local cam = r3d.cam
    CreateThread(function()
        Wait(120)
        if not r3d or r3d.cam ~= cam then return end
        local ps = r3d.pose
        Wait(0); Wait(0)   -- deux images rendues avec cette pose
        if not r3d or r3d.pose ~= ps then return end
        local _, right = camAxes(ps.h, ps.p)
        local off = ps.dist * 0.35
        local pt = vector3(ps.tx, ps.ty, ps.tz) + right * off
        local onScreen, sx = GetScreenCoordFromWorldCoord(pt.x, pt.y, pt.z)
        if onScreen then
            SendNUIMessage({ action = 'cal3d', sx = sx, off = off,
                pose = { tx = ps.tx, ty = ps.ty, tz = ps.tz, h = ps.h, p = ps.p, dist = ps.dist } })
        end
        -- contrôle : le point visé doit être au centre de l'écran, sinon les blips de la NUI seront décalés
        local okT, cx, cy = GetScreenCoordFromWorldCoord(ps.tx, ps.ty, ps.tz)
        local rot = GetCamRot(cam, 2)
        if not okT or math.abs(cx - 0.5) > 0.03 or math.abs(cy - 0.5) > 0.03 then
            print(('^3[%s] carte réaliste décalée : point visé à l\'écran (%.3f, %.3f), rotation caméra (%.1f, %.1f, %.1f), attendu (%.1f, 0, %.1f)^0')
                :format(GetCurrentResourceName(), cx or -1, cy or -1, rot.x, rot.y, rot.z, -ps.p, ps.h))
        end
    end)

    -- tant que la vue est ouverte : pas de HUD ni de minimap par-dessus la ville
    CreateThread(function()
        while r3d and r3d.cam == cam do
            HideHudAndRadarThisFrame()
            Wait(0)
        end
    end)
end)

-- Nouvelle pose de la caméra. Réponse : sol sous le point visé et quartier, pour suivre le relief.
local lastZoneAt = 0
onNui('cam3d', function(data, cb)
    if not r3d then return cb({ ok = false }) end
    local pose = readPose(data)
    applyPose(pose)
    local res = { ok = true, gz = groundZ(pose.tx, pose.ty) }
    local now = GetGameTimer()
    if now - lastZoneAt > 250 then
        lastZoneAt = now
        res.zone = GetLabelText(GetNameOfZone(pose.tx, pose.ty, pose.tz))
    end
    cb(res)
end)

-- Hauteur du sol sous des points (blips créés à z = 0, point GPS). nil = zone pas encore chargée.
onNui('heights', function(data, cb)
    local out = {}
    if r3d and type(data.pts) == 'table' then
        for i = 1, math.min(#data.pts, 100) do   -- la NUI en envoie 80 au plus par appel
            local p = data.pts[i]
            out[i] = type(p) == 'table' and tonumber(p[1]) and tonumber(p[2]) and groundZ(p[1], p[2]) or false
        end
    end
    cb(out)
end)

-- Clic sur la ville : rayon depuis la caméra (direction calculée par la NUI), point GPS là où il touche
onNui('pick3d', function(data, cb)
    if not r3d then return cb({ ok = false }) end
    local dx, dy, dz = tonumber(data.dx), tonumber(data.dy), tonumber(data.dz)
    if not (dx and dy and dz) then return cb({ ok = false }) end
    local o = r3d.pose.pos
    local dir = vector3(dx, dy, dz)
    local len = #dir
    if len < 0.001 then return cb({ ok = false }) end
    local e = o + dir / len * 9000.0
    local ray = StartExpensiveSynchronousShapeTestLosProbe(o.x, o.y, o.z, e.x, e.y, e.z, 1 | 16, 0, 7)
    local _, hit, pos = GetShapeTestResult(ray)
    if hit ~= 1 then
        -- rien de chargé sous le clic (mer, très loin) : croisement avec l'altitude du point visé
        if dz >= 0 then return cb({ ok = false }) end
        pos = o + dir * ((r3d.pose.tz - o.z) / dz)
    end
    if math.abs(pos.x) > 10000 or math.abs(pos.y) > 10000 then return cb({ ok = false }) end
    SetNewWaypoint(pos.x + 0.0, pos.y + 0.0)
    cb({ ok = true, x = r10(pos.x), y = r10(pos.y), z = r10(pos.z) })
end)

-- Carte « Récompense VIP » : point GPS sur le PNJ d'ash_vipdaily (la récompense se récupère auprès de lui)
onNui('vipgps', function(_, cb)
    if not vipDailyActif() then return cb({ ok = false }) end
    local ok, place = pcall(function() return exports[vd.Ressource]:GuiderVersPnj() end)
    if not ok then
        print(('^3[ash_pausemenu] %s : point GPS du PNJ impossible (%s), ash_vipdaily v1.4.1 ou plus récent requis^0'):format(vd.Ressource, tostring(place)))
        return cb({ ok = false })
    end
    cb({ ok = place == true })
end)

onNui('settings', function(_, cb)
    openNative(`FE_MENU_VERSION_LANDING_MENU`)
    cb('ok')
end)

onNui('streamer', function(data, cb)
    applyStreamer(data.enabled == true)
    cb({ enabled = streamer, player = playerInfo() })
end)

onNui('report', function(_, cb)
    cb('ok')
    closeMenu()
    CreateThread(function()
        Wait(150)   -- laisse le focus NUI se libérer avant d'ouvrir l'interface de Luxu
        if Config.ReportCommand and Config.ReportCommand ~= '' then ExecuteCommand(Config.ReportCommand) end
    end)
end)


onNui('quit', function(_, cb)
    local ok, reason = lib.callback.await('ash_pausemenu:quit', false)
    cb({ ok = ok == true, reason = reason })
end)

-- Cayo Perico sur la carte GTA native ---------------------------------------------
-- Menu pause GTA : on force la carte de l'île (intérieur radar "h4_fake_islandx") à chaque image.
-- Minimap : carte de l'île quand on est à moins de Distance mètres, sinon carte normale.
local cayoCfg = Config.CayoNative or {}
if cayoCfg.Enabled then
    local CAYO          = vector2(4858.0, -5171.0)
    local ISLAND_RADAR  = `h4_fake_islandx`
    local SET_USE_ISLAND_MAP = 0x5E1460624D194A38   -- SET_USE_ISLAND_MAP(toggle), à appeler à chaque image
    local distance      = cayoCfg.Distance or 2200.0

    -- blip invisible au coin sud-est de l'île : la carte GTA s'arrête au dernier blip,
    -- sans lui on ne peut pas faire défiler la carte jusqu'à Cayo
    cayoEdgeBlip = AddBlipForCoord(5943.0, -6272.0, 0.0)
    SetBlipSprite(cayoEdgeBlip, 575)
    SetBlipScale(cayoEdgeBlip, 0.0)
    SetBlipAsShortRange(cayoEdgeBlip, false)
    SetBlipDisplay(cayoEdgeBlip, 4)

    CreateThread(function()
        local islandMinimap = false
        while true do
            local wait = 500
            local ped = PlayerPedId()
            local near = cayoCfg.Minimap ~= false and #(GetEntityCoords(ped).xy - CAYO) < distance
            if islandMinimap and not near then
                Citizen.InvokeNative(SET_USE_ISLAND_MAP, false)   -- retour à la minimap de Los Santos
                islandMinimap = false
            end
            if IsPauseMenuActive() then
                -- dans un intérieur on laisse GTA afficher le plan de l'intérieur
                if GetInteriorFromEntity(ped) == 0 then
                    Citizen.InvokeNative(SET_USE_ISLAND_MAP, false)
                    SetRadarAsExteriorThisFrame()
                    SetRadarAsInteriorThisFrame(ISLAND_RADAR, 4700.0, -5145.0, 0, 0)
                    wait = 0
                end
            elseif near then
                Citizen.InvokeNative(SET_USE_ISLAND_MAP, true)
                islandMinimap = true
                wait = 0
            end
            Wait(wait)
        end
    end)
end

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if cayoEdgeBlip and DoesBlipExist(cayoEdgeBlip) then RemoveBlip(cayoEdgeBlip) end
    if isOpen then
        SetNuiFocus(false, false)
        TriggerScreenblurFadeOut(0)
    end
    stop3d()
    stopPreview(true)
    if headshot then UnregisterPedheadshot(headshot) end
end)

exports('IsOpen', function() return isOpen end)
exports('Close', closeMenu)
exports('IsStreamerMode', function() return streamer end)
