# CODEMAP — ash_pausemenu

> Généré par `codemap.py` v2 : **ne pas modifier à la main**. Régénérer après chaque modification du code.
> Format : `nom` suivi du numéro de ligne → lire seulement les lignes utiles (Read avec offset).

**5 fichiers · 3520 lignes** · 4 lua · 1 html

## Ressources FiveM

- **ash_pausemenu** (fx cerulean, v 1.16.0, lua54 yes)
  - partagé : `@ox_lib/init.lua`, `config.lua`
  - client : `client.lua`
  - serveur : `@oxmysql/lib/MySQL.lua`, `server.lua`
  - ui_page : `html/index.html`
  - dépendances : `qb-core`, `ox_lib`, `oxmysql`

## ⚠ Points d'attention

- Callback `ash_vipdaily:server:resume` appelé `client.lua:124` mais **déclaré nulle part** ici
- NUI : le JS appelle `cam3d` `html/index.html:1671` mais **aucun RegisterNUICallback** ne le reçoit
- NUI : le JS appelle `clearWaypoint` `html/index.html:1489` mais **aucun RegisterNUICallback** ne le reçoit
- NUI : le JS appelle `heights` `html/index.html:1706` mais **aucun RegisterNUICallback** ne le reçoit
- NUI : le JS appelle `map` `html/index.html:1872`, `html/index.html:1947` mais **aucun RegisterNUICallback** ne le reçoit
- NUI : le JS appelle `map3d` `html/index.html:1737`, `html/index.html:1758` mais **aucun RegisterNUICallback** ne le reçoit
- NUI : le JS appelle `mapData` `html/index.html:1545` mais **aucun RegisterNUICallback** ne le reçoit
- NUI : le JS appelle `pick3d` `html/index.html:1816` mais **aucun RegisterNUICallback** ne le reçoit
- NUI : le JS appelle `quit` `html/index.html:2005` mais **aucun RegisterNUICallback** ne le reçoit
- NUI : le JS appelle `report` `html/index.html:1957` mais **aucun RegisterNUICallback** ne le reçoit
- NUI : le JS appelle `route` `html/index.html:1495` mais **aucun RegisterNUICallback** ne le reçoit
- NUI : le JS appelle `settings` `html/index.html:1948` mais **aucun RegisterNUICallback** ne le reçoit
- NUI : le JS appelle `streamer` `html/index.html:1953` mais **aucun RegisterNUICallback** ne le reçoit
- NUI : le JS appelle `vipgps` `html/index.html:2032` mais **aucun RegisterNUICallback** ne le reçoit
- NUI : le JS appelle `waypoint` `html/index.html:1479` mais **aucun RegisterNUICallback** ne le reçoit
- Wait(0) : boucle à chaque frame, vérifier qu'elle ne tourne pas au repos : `client.lua:363`, `client.lua:378`, `client.lua:663`, `client.lua:663`, `client.lua:695`

## Liens entre fichiers

- callback `ash_pausemenu:activeJobs` : déclaré `server.lua:165` ← appelé `client.lua:538`
- callback `ash_pausemenu:getStats` : déclaré `server.lua:9` ← appelé `client.lua:273`
- callback `ash_pausemenu:quit` : déclaré `server.lua:46` ← appelé `client.lua:781`
- NUI `close` : JS `html/index.html:1946`, `html/index.html:2058` → Lua `client.lua:403`
- NUI `view` : JS `html/index.html:617` → Lua `client.lua:414`
- NUI action `activeJobs` : Lua `client.lua:542` → JS `html/index.html:2106`
- NUI action `cal3d` : Lua `client.lua:670` → JS `html/index.html:2105`
- NUI action `close` : Lua `client.lua:328` → JS `html/index.html:2101`
- NUI action `headshot` : Lua `client.lua:210`, `client.lua:221` → JS `html/index.html:2104`
- NUI action `stats` : Lua `client.lua:271`, `client.lua:275` → JS `html/index.html:2102`
- NUI action `vipdaily` : Lua `client.lua:121`, `client.lua:134` → JS `html/index.html:2103`

## Fichiers

### client.lua — client · 855 l.
- framework : QBCore, ox_lib
- écoute (events) : `QBCore:Client:OnPlayerLoaded` 388, `onClientResourceStart` 389, `QBCore:Client:OnPlayerUnload` 834, `onResourceStop` 841
- émet (local) : `ash_pausemenu:streamerMode` 78
- callbacks appelés : `ash_vipdaily:server:resume` 124, `ash_pausemenu:getStats` 273, `ash_pausemenu:activeJobs` 538, `ash_pausemenu:quit` 781
- NUI : callbacks reçus : `close` 403, `view` 414
- NUI : messages envoyés : `vipdaily` 121, `vipdaily` 134, `headshot` 210, `headshot` 221, `stats` 271, `stats` 275, `close` 328, `activeJobs` 542, `cal3d` 670
- exports fournis : `IsOpen` 853, `Close` 854, `IsStreamerMode` 855
- exports utilisés : `qb-core:GetCoreObject` 1
- fonctions : `reglagesNotif()` 32, `ressourceNotif(N)` 44, `notifier(titre, message, typeNotif)` 57, `applyStreamer(enabled, silent)` 74, `playerInfo()` 91, `vipDailyActif()` 112, `sendVipDaily()` 118, `setBlur(on)` 142, `startPreview()` 150, `stopPreview(instant)` 180, `pedLook(ped)` 197, `sendHeadshot()` 206, `openMenu()` 226, `toggleOtherHuds(show)` 291, `setClouds(visible)` 305, `stop3d()` 310, `closeMenu(instant)` 323, `openNative(menuHash)` 335, `restoreStreamer()` 385, `onNui(name, handler)` 396, `collectBlips()` 429, `cachedBlips()` 461, `r10(v)` 470, `routePoints(slot)` 474, `gpsRoute()` 489, `findRouteBlip()` 498, `blipRoute()` 515, `cachedActiveJobs()` 532, `waypointCoords()` 548, `groundZ(x, y)` 601, `camAxes(h, p)` 607, `readPose(d)` 615, `n(v, lo, hi, def)` 616, `applyPose(pose)` 627
- threads : 7 (l. 217, 338, 355, 659, 685, 773, 803)

### config.lua — config · 333 l.
- clés de config : `Config.ServerName` 4, `Config.Subtitle` 5, `Config.Discord` 6, `Config.Shop` 7, `Config.Blur` 10, `Config.OverrideP` 11, `Config.HoldToQuit` 12, `Config.Notifications` 20, `Config.BlockQuitWhenRestrained` 29, `Config.BlockQuitInCombat` 33, `Config.QuitMessage` 36, `Config.Preview` 47, `Config.CayoNative` 64, `Config.Map` 80, `Config.ReportCommand` 212, `Config.VipDaily` 221, `Config.Streamer` 237, `Config.RulesIntro` 246, `Config.Rules` 248, `Config.Keys` 286, `Config.Locale` 326

### fxmanifest.lua — manifeste · 35 l.
- (aucun symbole)

### server.lua — serveur · 187 l.
- framework : QBCore, ox_lib
- écoute (events) : `weaponDamageEvent` 28, `playerDropped` 109
- callbacks déclarés : `ash_pausemenu:getStats` 9, `ash_pausemenu:quit` 46, `ash_pausemenu:activeJobs` 165
- exports utilisés : `qb-core:GetCoreObject` 1, `ash_dclogs:SetDropReason` 94
- fonctions : `parseCoords(raw)` 122, `loadJobBlips()` 138

### html/index.html — NUI · 2110 l.
- NUI : callbacks envoyés au Lua : `view` 617, `waypoint` 1479, `clearWaypoint` 1489, `route` 1495, `mapData` 1545, `cam3d` 1671, `heights` 1706, `map3d` 1737, `map3d` 1758, `pick3d` 1816, `map` 1872, `close` 1946, `map` 1947, `settings` 1948, `streamer` 1953, `report` 1957, `quit` 2005, `vipgps` 2032, `close` 2058
- NUI : actions reçues : `layer` 900, `resume` 1946, `map` 1947, `settings` 1948, `rules` 1949, `keys` 1950, `streamer` 1951, `report` 1957, `discord` 1958, `shop` 1959, `quit` 1960, `mousedown` 1980, `open` 2100, `close` 2101, `stats` 2102, `vipdaily` 2103, `headshot` 2104, `cal3d` 2105, `activeJobs` 2106
- fonctions : `post(name, data = {})` 574, `esc(s)` 579, `buttons()` 590, `select(i)` 591, `renumber()` 597, `setHeadshot(txd)` 603, `notifyView(name)` 612, `renderPlayer()` 623, `pad2(n)` 645, `fmtSession(s)` 646, `tick()` 650, `highlight(text, q)` 658, `norm(s)` 671, `renderRules()` 673, `keyRow(b)` 693, `renderKeys()` 694, `setTitle(crumb, title)` 703, `openView(name)` 705, `closeView()` 739, `catOf(id)` 761, `fmtDist(m)` 762, `latlng(x, y)` 763, `loadLeaflet()` 773, `initMap()` 789, `keyTile(p, W, H, sat)` 837, `composeTile(ctx, ly, S, z, x, y, land)` 873, `fetchBmp(urls)` 892, `startWorker()` 922, `loadImg(urls)` 934, `mainTile(job, ly)` 943, `buildTile(job, ly)` 965, `getTile(o, coords)` 977, `localImg(url)` 1007, `MapTiles()` 1017, `free()` 1025, `setLayer(id)` 1035, `markLayers()` 1072, `zoomClasses()` 1076, `meIcon(h)` 1085, `roundRect(ctx, x, y, w, h, r)` 1091, `blipPath(ctx, shape, x, y, r)` 1099, `poly(pts)` 1100, `BlipMark()` 1108, `dotRadius()` 1138, `allPlaces()` 1140, `saveHidden()` 1159, `typeKey(p)` 1162, `isHidden(p)` 1163, `eyeSvg(on)` 1164, `renderLegend()` 1167, `legendClick(e)` 1207, `goNearest(list)` 1233, `toggleBlips()` 1245, `placeKey(p)` 1258, `readStyles()` 1260, `clean(o)` 1261, `styleOf(p)` 1272, `closeBlipEdit(save)` 1274, `applyBlipEdit()` 1282, `openBlipEdit(p, pt)` 1289, `setActiveJobs(list)` 1324, `activeJobs()` 1337, `byUnknownFirst(a, b)` 1344, `renderJobRings()` 1347, `renderBlips()` 1355, `loadPostals()` 1383, `postalsAt(z)` 1401, `PostalTiles()` 1420, `showPostals()` 1440, `nearestPostal(x, y)` 1454, `setWhere(r)` 1459, `setDest(x, y, label)` 1464, `setWaypoint(x, y, send, label)` 1471, `clearWaypoint()` 1483, `refreshRoute()` 1493, `routeWithHalo(ll, color, halo, haloOpacity)` 1501, `setRoute(pts)` 1507, `setBlipRoute(r)` 1519, `centerMe(zoom)` 1534, `openMap()` 1538, `clamp(v, lo, hi)` 1573, `dot3(a, b)` 1574, `camAxes(o)` 1578, `camView(o, W, H, scale = R3.scale)` 1583, `project(v, x, y, z)` 1589, `hzKey(x, y)` 1595, `groundAt(x, y, z)` 1596, `build3d()` 1598, `add(cls, html, x, y, z, lift, label, onClick)` 1604, `draw3d()` 1628, `render3d()` 1629, `path(pts)` 1651, `send3d()` 1667, `requestHeights()` 1689, `want(x, y, z)` 1692, `cal3d(m)` 1720, `curtain(on)` 1729, `enter3d()` 1730, `exit3d()` 1753, `reset3d()` 1764, `r3Go(x, y)` 1777, `zoom3d(n)` 1778, `showResults(on)` 1832, `renderResults()` 1833, `dist(p)` 1837, `moveResult(dir)` 1851, `pickResult(i)` 1857, `setVipDaily(e)` 1886, `show(msg)` 1902, `hide()` 1932, `run(action)` 1944, `openModal()` 1965, `closeModal()` 1970, `modalOpen()` 1971, `resetHold()` 1973, `startHold(e)` 1978, `step(t)` 1984, `stopHold()` 1999, `doQuit()` 2001
- méthodes : `createTile(coords, done)` 1018, `_labelW()` 1110, `_updateBounds()` 1115, `_updatePath()` 1119, `createTile(coords)` 1421
- écrans / sections : `rules` 407, `keys` 408
- script intégré : `<script>` 572
