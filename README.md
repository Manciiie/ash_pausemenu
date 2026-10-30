# ash_pausemenu — Menu pause ASH City

Remplace le menu pause GTA (ÉCHAP, et P en option) par un menu au thème ASH.

## Fonctions
- Interface : barre latérale PAUSE + vue **Aperçu** (métier, ID / CitizenID, temps de session, état VIP, accès rapides)
- **Aperçu du personnage** : une caméra filme ton perso à droite de l'écran avec son nom, son métier et ses identifiants (pas de flou sur cette vue). En véhicule, à terre ou collé à un mur, le portrait du perso s'affiche à la place. Réglages dans `Config.Preview`
- Raccourcis inchangés : ↑↓ / ENTRÉE, touches 1 à 0 dans le même ordre qu'avant, ÉCHAP pour revenir ou reprendre
- **Carte NUI** (touche 2) : carte de Los Santos Atlas / Satellite, ta position et ta direction, rue et quartier, blips fixes de ta carte GTA classés par catégorie (filtrables), recherche de lieux, clic = point GPS, clic droit = effacer, bouton « Carte GTA » pour la carte native. **Cayo Perico** inclus (images GTABase 1920 px, mer recolorée, en WebP dans `html/cayo/`, calées via `Config.Map.Cayo`). Les blips non classés s'affichent en petits points jusqu'au zoom rapproché (`ShowUnknown = false` pour les masquer). Réglages dans `Config.Map` (`Enabled = false` pour revenir à la carte GTA)
- **Îles de map** : les 3 îles de coca de `kq_islands_pack` sont posées sur la carte NUI comme Cayo (textures de minimap de la ressource, calées sur ses ymap ; vue Satellite tirée d'une image aérienne des îles). Images dans `html/islands/`. Réglages dans `Config.Map.Islands`
- **Cayo Perico sur la carte GTA native** : l'île s'affiche dans le menu pause GTA (bouton « Carte GTA ») et la minimap passe sur la carte de l'île à moins de 2,2 km. Réglages dans `Config.CayoNative`
- **Bouton « Blips »** (carte plane et réaliste) : masque ou réaffiche tous les blips d'un clic, mémorisé sur le PC du joueur. Blips dessinés en petit (12 px) pour ne pas cacher la carte
- **Style des blips** : clic droit sur un blip de la carte plane pour régler sa taille et sa forme (carré, rond, losange, triangle, hexagone), pour ce blip seul ou tous ceux du même type. Bouton « Enregistrer », réglages gardés sur le PC du joueur et repris par la carte réaliste
- **Métiers ouverts** : les blips de qs-jobs-creator (table `qs_jobs_data`) ont un anneau vert pulsant quand au moins un employé est en service, sur la carte plane et la réaliste, pour tous les joueurs. État relu à chaque ouverture de la carte (10 s de cache). Réglages dans `Config.Map.ActiveJobs`
- **Légende « Lieux »** : un œil par catégorie et par type de lieu (ex. « Supérette ») pour masquer des blips, bouton « Tout masquer / Tout afficher », clic sur un type = aller au plus proche. Le choix est mémorisé sur le PC du joueur et vaut aussi pour la carte réaliste
- **Carte réaliste** (bouton « Réaliste ») : la caméra du jeu monte au-dessus de la vraie ville ; glisser = déplacer, clic droit glissé = tourner / incliner, molette = zoom, clic = point GPS là où on vise (bâtiment compris), ÉCHAP = retour à la carte plane. Blips, point GPS et itinéraire GPS dessinés sur les bâtiments. Réglages dans `Config.Map.Realistic` (`Enabled = false` pour retirer le bouton)
- **Itinéraire GPS** tracé sur la carte plane comme sur la réaliste, ainsi que la route posée par un script sur un blip (`SetBlipRoute` : taxi, jobs, missions), dans la couleur du blip
- **Codes postaux** (bouton « Postaux ») : numéros écrits sur la carte Atlas et Satellite à partir du zoom 3, recherche par numéro (ex. « 7054 » = point GPS), code postal le plus proche sous « TU ES À ». Jeu new-postals de DevBlocky/nearest-postal (licence MIT, `html/postals/LICENSE`), réglages dans `Config.Map.Postals`
- **Océan stylisé** sous les deux cartes (dégradé, hauts-fonds, écume, nuages ; turquoise pour Atlas, bleu nuit pour Satellite) : images WebP dans `html/map/`, la mer des tuiles est rendue transparente à l'affichage pour laisser voir cet océan
- Tuiles de la carte servies par GitHub Pages, avec jsDelivr en secours tuile par tuile (jsDelivr seul refusait certaines tuiles : le dépôt dépasse sa limite de 50 Mo)
- Reprendre et Paramètres (menus natifs GTA)
- Onglet **Règlement** avec recherche (insensible aux accents) et onglet **Touches**
- **Mode streamer** : masque nom RP, ID et CitizenID ; mémorisé par joueur
- **Signaler / Report** : ouvre le report de Luxu Admin (commande configurable)
- **Récompense VIP** (ash_vipdaily) : carte dans l'Aperçu (disponible, temps avant la prochaine, série, réservé aux VIP) ; un clic place le point GPS sur le PNJ des récompenses (ash_vipdaily v1.4.1 ou plus) ; masquée si la ressource n'est pas démarrée
- Liens **Discord** et **Boutique VIP**
- **Quitter la session** : confirmation par maintien, refusée si menotté / à terre / mort, anti-spam

## Dépendances
`qb-core`, `ox_lib`, `oxmysql` — optionnel : `ash_notify` (notifications, secours ox_lib), `ash_vipdaily`

## Installation (Nitrado)
1. Déposer le dossier dans `resources/` via FTP.
2. `server.cfg` : `ensure ash_pausemenu` après `qb-core`, `ox_lib` et `ash_notify`.
3. Régler `config.lua` : `Config.Notifications`, liens Discord / boutique, `Config.ReportCommand`, `Config.VipDaily`, règlement, touches.

## Pour les autres ressources
- `exports.ash_pausemenu:IsOpen()` / `exports.ash_pausemenu:Close()`
- `exports.ash_pausemenu:IsStreamerMode()`, `LocalPlayer.state.streamerMode`
- event client `ash_pausemenu:streamerMode` (booléen)

## Sécurité
- Les callbacks NUI qui agissent (GPS, commandes, report, déconnexion) ne répondent que menu ouvert.
- Déconnexion validée côté serveur : joueur chargé, anti-spam 1 s, refus si menotté / à terre / mort.
- Leaflet chargé avec empreintes SRI : un fichier modifié sur le CDN est refusé.
- Tout texte affiché dans le NUI (noms, règlement, blips) est échappé.

## Performances
Côté serveur : rien ne tourne au repos (stats en cache 5 s).
Côté client : une seule boucle par frame, obligatoire pour bloquer le menu pause GTA (`DisableControlAction` n'agit que sur la frame en cours) ; elle dort tant que le personnage n'est pas chargé.

Carte : Leaflet n'est téléchargé qu'à la première ouverture de la carte et le scan des blips est réutilisé 15 s. Les tuiles (océan, Cayo, terre détourée) sont fabriquées dans un worker puis affichées comme de simples images, et gardées en mémoire (400 dernières) : le fil de l'interface reste libre pendant les déplacements. Tous les blips et leurs étiquettes sont dessinés sur un seul canvas (aucun élément HTML par blip). Pas de flou d'arrière-plan sur les panneaux de la carte. Carte réaliste : la NUI calcule elle-même la position des marqueurs à l'écran et n'envoie au jeu que la pose de la caméra, une requête à la fois.

## Limite connue
La carte NUI charge ses images depuis GitHub Pages, ou jsDelivr en secours (dépôt GitHub meesvrh/GTAV-Map-Tiles) et Leaflet depuis cdnjs : il faut internet côté joueur. Si les images ne chargent pas, la carte propose d'ouvrir la carte GTA native.

Pas de dossier `bridge/` : la ressource est écrite pour QBCore uniquement.
