# CODEMAP — ash_pausemenu

> Généré par `codemap.py` v2 : **ne pas modifier à la main**. Régénérer après chaque modification du code.
> Format : `nom` suivi du numéro de ligne → lire seulement les lignes utiles (Read avec offset).

**5 fichiers · 2914 lignes** · 4 lua · 1 html

## Ressources FiveM

- **ash_pausemenu** (fx cerulean, v 1.11.5, lua54 yes)
  - partagé : `@ox_lib/init.lua`, `config.lua`
  - client : `client.lua`
  - serveur : `server.lua`
  - ui_page : `html/index.html`
  - dépendances : `qb-core`, `ox_lib`

## ⚠ Points d'attention

- Callback `ash_vipdaily:server:ouvrir` appelé `client.lua:124` mais **déclaré nulle part** ici
- NUI : `RegisterNUICallback('close')` `client.lua:382` jamais appelé par le JS
- NUI : `RegisterNUICallback('view')` `client.lua:393` jamais appelé par le JS
- Wait(0) : boucle à chaque frame, vérifier qu'elle ne tourne pas au repos : `client.lua:342`, `client.lua:357`, `client.lua:578`, `client.lua:578`, `client.lua:601`

## Liens entre fichiers

- callback `ash_pausemenu:getStats` : déclaré `server.lua:9` ← appelé `client.lua:267`
- callback `ash_pausemenu:quit` : déclaré `server.lua:22` ← appelé `client.lua:687`

## Fichiers

### client.lua — client · 751 l.
- framework : QBCore, ox_lib
- écoute (events) : `QBCore:Client:OnPlayerLoaded` 367, `onClientResourceStart` 368, `onResourceStop` 737
- émet (local) : `ash_pausemenu:streamerMode` 78
- callbacks appelés : `ash_vipdaily:server:ouvrir` 124, `ash_pausemenu:getStats` 267, `ash_pausemenu:quit` 687
- NUI : callbacks reçus : `close` 382, `view` 393
- NUI : messages envoyés : `vipdaily` 121, `vipdaily` 134, `headshot` 210, `headshot` 221, `stats` 265, `stats` 269, `close` 307, `cal3d` 585
- exports fournis : `IsOpen` 749, `Close` 750, `IsStreamerMode` 751
- exports utilisés : `qb-core:GetCoreObject` 1
- fonctions : `reglagesNotif()` 32, `ressourceNotif(N)` 44, `notifier(titre, message, typeNotif)` 57, `applyStreamer(enabled, silent)` 74, `playerInfo()` 91, `vipDailyActif()` 112, `sendVipDaily()` 118, `setBlur(on)` 142, `startPreview()` 150, `stopPreview(instant)` 180, `pedLook(ped)` 197, `sendHeadshot()` 206, `openMenu()` 226, `toggleOtherHuds(show)` 281, `stop3d()` 291, `closeMenu(instant)` 302, `openNative(menuHash)` 314, `restoreStreamer()` 364, `onNui(name, handler)` 375, `collectBlips()` 408, `cachedBlips()` 440, `r10(v)` 449, `gpsRoute()` 452, `waypointCoords()` 466, `groundZ(x, y)` 516, `camAxes(h, p)` 522, `readPose(d)` 530, `n(v, lo, hi, def)` 531, `applyPose(pose)` 542
- threads : 7 (l. 217, 317, 334, 574, 598, 679, 709)

### config.lua — config · 292 l.
- clés de config : `Config.ServerName` 4, `Config.Subtitle` 5, `Config.Discord` 6, `Config.Shop` 7, `Config.Blur` 10, `Config.OverrideP` 11, `Config.HoldToQuit` 12, `Config.Notifications` 20, `Config.BlockQuitWhenRestrained` 29, `Config.QuitMessage` 32, `Config.Preview` 43, `Config.CayoNative` 60, `Config.Map` 76, `Config.ReportCommand` 172, `Config.VipDaily` 181, `Config.Streamer` 197, `Config.RulesIntro` 206, `Config.Rules` 208, `Config.Keys` 246, `Config.Locale` 286

### fxmanifest.lua — manifeste · 29 l.
- (aucun symbole)

### server.lua — serveur · 67 l.
- framework : QBCore, ox_lib
- écoute (events) : `playerDropped` 64
- callbacks déclarés : `ash_pausemenu:getStats` 9, `ash_pausemenu:quit` 22
- exports utilisés : `qb-core:GetCoreObject` 1

### html/index.html — NUI · 1775 l.
- écrans / sections : `rules` 391, `keys` 392
- script intégré : `<script>` 553
