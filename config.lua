Config = {}

-- Affichage
Config.ServerName = 'ASH'
Config.Subtitle   = 'City / Roleplay'
Config.Discord    = 'https://discord.gg/ATczKRMWT'   -- '' pour masquer le bouton Discord
Config.Shop       = 'https://tonserveur.tebex.io'  -- lien de la boutique VIP ('' pour masquer le bouton)

-- Comportement
Config.Blur       = true    -- flou de l'écran derrière le menu
Config.OverrideP  = true    -- la touche P ouvre aussi le menu ASH (au lieu du menu pause GTA)
Config.HoldToQuit = 1500    -- durée (ms) à maintenir le bouton pour confirmer la déconnexion

------------------------------------------------------------------------
-- Notifications : ash_notify (exports['ash_notify']:SendAlert)
--   systeme   : 'ash_notify' ou 'ox_lib'
--   ressource : nom du dossier d'ash_notify sur le serveur (ensure ash_notify AVANT ash_pausemenu)
-- Si ash_notify n'est pas démarrée, ox_lib prend le relais (une ligne jaune l'indique en F8).
------------------------------------------------------------------------
Config.Notifications = {
    systeme   = 'ash_notify',
    ressource = 'ash_notify',
    duree     = 5000,   -- ms
    son       = { success = true, error = true, warning = false, info = false },
}

-- Anti "déco en pleine action" : refuse de quitter via le menu si le joueur est
-- menotté, à terre ou mort. (Ça n'empêche pas ALT+F4 / F8 quit, c'est un garde-fou RP.)
Config.BlockQuitWhenRestrained = true

-- Message affiché au joueur à la déconnexion
Config.QuitMessage = 'Tu as quitté ASH City. Ton personnage a été sauvegardé. À bientôt !'

------------------------------------------------------------------------
-- Aperçu : prévisualisation du personnage
-- Une caméra filme ton perso à droite de l'écran tant que l'onglet Aperçu est
-- affiché (pas de flou à ce moment-là). Impossible en véhicule, à terre ou
-- collé à un mur : le menu affiche alors le portrait du perso à la place.
--   Distance : recul de la caméra (m)    Height : hauteur de la caméra / bassin (m)
--   Shift    : décalage vers la droite de l'écran (m, plus grand = plus à droite)
--   Fov      : champ de vision (plus petit = perso plus grand)
------------------------------------------------------------------------
Config.Preview = {
    Enabled      = true,
    Distance     = 2.6,
    Height       = 0.15,
    AimHeight    = -0.05,
    Shift        = 1.0,
    Fov          = 42.0,
    LookAtCamera = true,   -- le perso tourne la tête vers la caméra
}

------------------------------------------------------------------------
-- Cayo Perico sur la carte GTA native (menu pause GTA / bouton "Carte GTA")
-- et sur la minimap quand on est près de l'île.
--   Minimap  : false = la minimap reste celle de Los Santos même sur l'île
--   Distance : rayon (m) autour de l'île où la minimap passe sur Cayo
-- Ne charge pas l'île elle-même (IPL) : ça reste le rôle de ta ressource Cayo.
------------------------------------------------------------------------
Config.CayoNative = {
    Enabled  = true,
    Minimap  = true,
    Distance = 2200.0,
}

------------------------------------------------------------------------
-- Carte NUI (touche 2 / bouton Carte)
-- Carte de Los Santos dans le menu : ta position, les blips visibles sur ta
-- carte GTA, recherche, clic = point GPS, clic droit = effacer le point.
-- Enabled = false : le bouton Carte rouvre la carte GTA native comme avant.
-- Les images viennent du dépôt GitHub meesvrh/GTAV-Map-Tiles (GitHub Pages, secours jsDelivr) :
-- rien à télécharger pour les joueurs, mais il faut internet côté client.
-- jsDelivr seul ne suffit pas : le dépôt dépasse sa limite de 50 Mo et certaines tuiles
-- non encore en cache sont refusées (carré vide sur la carte).
------------------------------------------------------------------------
Config.Map = {
    Enabled = true,
    Tiles         = 'https://meesvrh.github.io/GTAV-Map-Tiles/tiles/{layer}/{z}/{x}/{y}.jpg',
    TilesFallback = 'https://cdn.jsdelivr.net/gh/meesvrh/GTAV-Map-Tiles@main/tiles/{layer}/{z}/{x}/{y}.jpg',
    Layers  = {
        { id = 'atlas',     label = 'Atlas' },
        { id = 'satellite', label = 'Satellite' },
    },
    -- Calage coordonnées GTA -> image (vérifié sur LSIA, Sandy Shores, Zancudo, Paleto)
    Calibration = { ax = 0.02072, bx = 117.3, ay = 0.0205, by = 172.8 },

    -- Cayo Perico : image posée par-dessus la carte (images 1920 px de GTABase, mer rendue transparente pour laisser
    -- voir l'océan de html/map/, en WebP dans html/cayo/).
    -- Bounds = zone GTA couverte par l'image, calée sur l'aérodrome (4494, -4525) et la villa d'El Rubio (5010, -5753).
    -- Si l'île paraît décalée en jeu, ajuste ces 4 valeurs (en mètres GTA).
    Cayo = {
        Enabled = true,
        Bounds  = { minX = 3592.5, maxX = 5870.0, minY = -6304.0, maxY = -4027.0 },
        Images  = { atlas = 'cayo/atlas.webp', satellite = 'cayo/satellite.webp' },
    },

    -- Îles ajoutées par des ressources de map, posées comme Cayo (une image par île, mer transparente).
    -- Par défaut les 3 îles de coca de kq_islands_pack : textures de minimap de la ressource, calées sur ses ymap.
    -- Images dans html/islands/. Islands = {} pour les retirer.
    Islands = {
        { Bounds = { minX = 4163.2,  maxX = 4410.4,  minY = 7576.6,  maxY = 7854.7 },
          Images = { atlas = 'islands/kq_coca_2_atlas.webp', satellite = 'islands/kq_coca_2_satellite.webp' } },
        { Bounds = { minX = -6474.4, maxX = -6165.6, minY = 2693.0,  maxY = 2982.1 },
          Images = { atlas = 'islands/kq_coca_3_atlas.webp', satellite = 'islands/kq_coca_3_satellite.webp' } },
        { Bounds = { minX = 4934.8,  maxX = 5334.2,  minY = -1307.6, maxY = -918.6 },
          Images = { atlas = 'islands/kq_coca_4_atlas.webp', satellite = 'islands/kq_coca_4_satellite.webp' } },
    },

    -- Ordre d'affichage des catégories dans la légende
    CategoryOrder = { 'public', 'sante', 'shop', 'garage', 'job', 'poi' },
    -- Blips non listés dans Sprites : petits points tant qu'on n'a pas zoomé (false = masqués)
    ShowUnknown = true,

    -- Blips repris de la carte GTA : seuls les blips fixes (pas ceux des joueurs / véhicules).
    -- Nom et catégorie par numéro de sprite (https://docs.fivem.net/docs/game-references/blips/).
    -- Un sprite absent de la liste s'affiche en « Point d'intérêt ».
    Categories = {
        public  = { label = 'Services publics', color = '#4f8cff' },
        sante   = { label = 'Santé',            color = '#ff5d8f' },
        shop    = { label = 'Commerces',        color = '#ff9a3c' },
        garage  = { label = 'Garages',          color = '#22c55e' },
        job     = { label = 'Métiers',          color = '#b49cff' },
        poi     = { label = "Points d'intérêt", color = '#f5c542' },
    },
    Sprites = {
        [60]  = { 'Commissariat', 'public' },       -- radar_police_station
        [137] = { 'Commissariat', 'public' },       -- radar_police_station_blue
        [61]  = { 'Hôpital', 'sante' },             -- radar_hospital
        [108] = { 'Banque', 'public' },             -- radar_financier_strand
        [207] = { 'Banque', 'public' },             -- radar_financier_strand_grey
        [52]  = { 'Supérette', 'shop' },            -- radar_crim_holdups
        [361] = { 'Station-service', 'shop' },      -- radar_jerry_can
        [73]  = { 'Vêtements', 'shop' },            -- radar_clothes_store
        [71]  = { 'Coiffeur', 'shop' },             -- radar_barber
        [75]  = { 'Tatoueur', 'shop' },             -- radar_tattoo
        [110] = { 'Ammu-Nation', 'shop' },          -- radar_gun_shop
        [93]  = { 'Bar', 'shop' },                  -- radar_bar
        [831] = { 'Concession', 'shop' },           -- radar_car_showroom
        [830] = { 'Concession de luxe', 'shop' },   -- radar_luxury_car_showroom
        [357] = { 'Garage', 'garage' },             -- radar_garage
        [856] = { 'Parking', 'garage' },            -- radar_multistorey_garage
        [446] = { 'Mécanicien', 'garage' },         -- radar_bennys
        [72]  = { 'Mécanicien', 'garage' },         -- radar_car_mod_shop
        [402] = { 'Réparation', 'garage' },         -- radar_repair
        [100] = { 'Lavage', 'garage' },             -- radar_car_wash
        [68]  = { 'Fourrière', 'garage' },          -- radar_tow_truck
        [198] = { 'Taxi', 'job' },                  -- radar_taxi
        [318] = { 'Éboueur', 'job' },               -- radar_garbage
        [477] = { 'Camionneur', 'job' },            -- radar_truck
        [513] = { 'Bus', 'job' },                   -- radar_bus
        [40]  = { 'Maison', 'poi' },                -- radar_safehouse
        [350] = { 'Propriété à vendre', 'poi' },    -- radar_property_for_sale
        [374] = { 'Entreprise', 'poi' },            -- radar_business
        [138] = { 'Aéroport', 'poi' },              -- radar_airport
        [360] = { 'Héliport', 'poi' },              -- radar_helipad
    },
    -- Lieux en plus dans la recherche (sans blip). Ex : { label = 'Mairie', x = -544.9, y = -204.2, cat = 'public' }
    Places = {},

    -- Onglet « Réaliste » : la caméra monte au-dessus de la vraie ville, on la déplace à la souris
    -- (glisser = déplacer, clic droit glissé = tourner / incliner, molette = zoom, clic = point GPS),
    -- avec les blips, le point GPS et l'itinéraire dessinés sur les bâtiments.
    Realistic = {
        Enabled     = true,
        Fov         = 45.0,    -- champ de vision de la caméra (degrés)
        Distance    = 850.0,   -- recul de départ (mètres)
        Pitch       = 56.0,    -- inclinaison de départ (90 = vue du dessus)
        MinDistance = 90.0,
        MaxDistance = 3200.0,
        -- HUD d'autres ressources cachés pendant la vue puis réaffichés : [ressource] = export qui prend true / false
        -- (jg-hud : exports['jg-hud']:toggleHud(show), docs.jgscripts.com/hud/exports). Ressource arrêtée = ignorée.
        HideHuds = {
            ['jg-hud'] = 'toggleHud',
        },
    },

    -- Codes postaux écrits sur la carte plane (bouton « Postaux »), cherchables par numéro dans la recherche,
    -- et code postal le plus proche sous « TU ES À ». Fichier au format nearest-postal : [{ "x", "y", "code" }].
    -- Par défaut new-postals de DevBlocky/nearest-postal (licence MIT, html/postals/LICENSE).
    -- Autre jeu de codes : dépose son JSON dans html/postals/ et indique son chemin ici.
    Postals = {
        Enabled = true,
        File    = 'postals/new-postals.json',
        MinZoom = 3,   -- zoom à partir duquel les numéros s'affichent (carte de 1 à 5)
    },

    -- Blips de métier qs-jobs-creator (table qs_jobs_data) entourés d'un anneau vert quand au moins
    -- un employé est en service. Vaut pour tous les joueurs, sur la carte plane et la réaliste.
    ActiveJobs = {
        Enabled = true,
        Refresh = 300,   -- secondes entre deux relectures des blips en base
    },
}

------------------------------------------------------------------------
-- Signaler (menu report de Luxu Admin)
-- Luxu n'expose pas d'export pour ouvrir les reports : on exécute sa commande.
-- Mets le nom de la commande SANS le "/" (celle que tes joueurs tapent en jeu).
-- '' pour masquer le bouton.
------------------------------------------------------------------------
Config.ReportCommand = 'report'

------------------------------------------------------------------------
-- Récompenses VIP quotidiennes (ressource ash_vipdaily)
-- Carte « Récompense VIP » dans l'Aperçu : disponible, temps avant la prochaine, série,
-- ou réservé aux VIP. Un clic place le point GPS sur le PNJ d'ash_vipdaily (v1.4.1 ou plus),
-- où la récompense se récupère. N'apparaît que si la ressource est démarrée.
-- Ressource = '' pour masquer la carte.
------------------------------------------------------------------------
Config.VipDaily = {
    Ressource = 'ash_vipdaily',
    Cache     = 30,   -- secondes pendant lesquelles l'état est réutilisé entre deux ouvertures du menu
}

------------------------------------------------------------------------
-- Mode streamer
-- Masque dans le menu : nom RP, ID serveur et CitizenID. Le choix est mémorisé
-- sur le PC du joueur (reste actif après reco).
-- Les autres ressources peuvent le lire :
--   exports.ash_pausemenu:IsStreamerMode()
--   LocalPlayer.state.streamerMode
--   AddEventHandler('ash_pausemenu:streamerMode', function(enabled) ... end)
-- Tu peux aussi lancer des commandes d'autres scripts à l'activation/désactivation
-- (ex : masquer un HUD d'ID). Sans le "/".
------------------------------------------------------------------------
Config.Streamer = {
    commandsOn  = {},   -- ex : { 'hideids' }
    commandsOff = {},   -- ex : { 'showids' }
}

------------------------------------------------------------------------
-- Onglet Règlement
-- Chaque règle : { title = 'Titre court', text = 'Explication' }  (title optionnel)
------------------------------------------------------------------------
Config.RulesIntro = 'En jouant sur ASH City, tu acceptes ce règlement. Le staff peut sanctionner tout manquement. En cas de doute, ouvre un report.'

Config.Rules = {
    {
        title = 'Général',
        items = {
            { title = 'Respect',        text = 'Aucune insulte HRP, discrimination ou harcèlement. Le respect des joueurs et du staff est obligatoire.' },
            { title = 'Micro',          text = 'Un micro de qualité correcte est obligatoire. Pas de soundboard ni de modificateur de voix.' },
            { title = 'Âge minimum',    text = 'Le serveur est réservé aux joueurs de 16 ans et plus.' },
            { title = 'Triche',         text = 'Tout mod menu, exploit de bug ou logiciel tiers donnant un avantage est interdit et entraîne un ban définitif.' },
        },
    },
    {
        title = 'Roleplay',
        items = {
            { title = 'HRP',            text = 'Parler hors personnage en jeu est interdit, sauf en cas de problème technique ou à la demande du staff.' },
            { title = 'MetaGaming',     text = "Utiliser des infos obtenues hors RP (stream, Discord, vocal) dans ton RP est interdit." },
            { title = 'PowerGaming',    text = "Réaliser des actions impossibles dans la réalité ou forcer une action sur un autre joueur sans lui laisser le choix." },
            { title = 'No Fear',        text = "Ton personnage tient à sa vie : sous la menace d'une arme, tu obéis." },
            { title = 'No Pain',        text = 'Tu joues tes blessures : pas de course ou de combat juste après une fusillade.' },
            { title = 'FreeKill',       text = "Tuer sans raison RP valable et sans interaction préalable est interdit." },
            { title = 'RevengeKill',    text = "Après ta mort, tu oublies la scène qui y a mené. Pas de vengeance sur les mêmes personnes." },
            { title = 'Déco en scène',  text = "Se déconnecter pour échapper à une scène (arrestation, braquage, soins) est interdit." },
        },
    },
    {
        title = 'Illégal',
        items = {
            { title = 'Zones safe',     text = "Aucune action illégale dans les hôpitaux, commissariats et zones d'apparition." },
            { title = 'Braquages',      text = 'Un minimum de policiers en service est requis. Les otages doivent être joués, pas forcés.' },
            { title = 'Prise d\'otage', text = "Interdit de prendre en otage un EMS ou un policier en service pour éviter une arrestation." },
        },
    },
}

------------------------------------------------------------------------
-- Onglet Touches
-- Vérifie/adapte selon tes ressources (les touches peuvent aussi être changées
-- par chaque joueur dans Paramètres > Raccourcis clavier > FiveM).
------------------------------------------------------------------------
Config.Keys = {
    {
        title = 'Général',
        binds = {
            { key = 'ÉCHAP',  label = 'Menu pause ASH' },
            { key = 'T',      label = 'Chat' },
            { key = 'F1',     label = 'Téléphone' },
            { key = 'ALT',    label = 'Interagir (ciblage)' },
            { key = 'TAB',    label = 'Inventaire' },
        },
    },
    {
        title = 'Voix',
        binds = {
            { key = 'N',      label = 'Parler' },
            { key = 'F11',    label = 'Changer la portée de voix' },
        },
    },
    {
        title = 'Véhicule',
        binds = {
            { key = 'K',      label = 'Verrouiller / déverrouiller' },
            { key = 'B',      label = 'Ceinture' },
        },
    },
    {
        title = 'Métiers',
        binds = {
            { key = 'F6',     label = 'File de soins (EMS)' },
        },
    },
    {
        title = 'Commandes',
        binds = {
            { key = '/me',    label = 'Action de ton personnage' },
            { key = '/report',label = 'Contacter le staff' },
        },
    },
}

Config.Locale = {
    cuffed      = 'Tu ne peux pas quitter en étant menotté.',
    dead        = 'Tu ne peux pas quitter en étant à terre. Attends les secours.',
    wait        = 'Patiente une seconde avant de réessayer.',
    streamerOn  = 'Mode streamer activé.',
    streamerOff = 'Mode streamer désactivé.',
}
