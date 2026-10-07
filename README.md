# ash_pausemenu — Menu pause ASH City

Remplace le menu pause GTA (ÉCHAP, et P en option) par un menu au thème ASH.

## Fonctions
- Reprendre, Carte et Paramètres (menus natifs GTA)
- Onglet **Règlement** avec recherche (insensible aux accents) et onglet **Touches**
- **Mode streamer** : masque nom RP, ID et CitizenID ; mémorisé par joueur
- **Signaler / Report** : ouvre le report de Luxu Admin (commande configurable)
- **Récompenses VIP** (ash_vipdaily) : état du jour (disponible / série / réservé aux VIP) et ouverture de `/recompenses` ; bouton masqué si la ressource n'est pas démarrée
- Liens **Discord** et **Boutique VIP**
- **Quitter la session** : confirmation par maintien, refusée si menotté / à terre / mort, anti-spam

## Dépendances
`qb-core`, `ox_lib` — optionnel : `ash_vipdaily`

## Installation (Nitrado)
1. Déposer le dossier dans `resources/` via FTP.
2. `server.cfg` : `ensure ash_pausemenu` après `qb-core` et `ox_lib`.
3. Régler `config.lua` : liens Discord / boutique, `Config.ReportCommand`, `Config.VipDaily`, règlement, touches.

## Pour les autres ressources
- `exports.ash_pausemenu:IsOpen()` / `exports.ash_pausemenu:Close()`
- `exports.ash_pausemenu:IsStreamerMode()`, `LocalPlayer.state.streamerMode`
- event client `ash_pausemenu:streamerMode` (booléen)

## Performances
Côté serveur : rien ne tourne au repos (stats en cache 5 s).
Côté client : une seule boucle par frame, obligatoire pour bloquer le menu pause GTA (`DisableControlAction` n'agit que sur la frame en cours) ; elle dort tant que le personnage n'est pas chargé.

## Limite connue
Pas de dossier `bridge/` : la ressource est écrite pour QBCore uniquement.
