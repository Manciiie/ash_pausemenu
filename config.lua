Config = {}

-- Affichage
Config.ServerName = 'ASH'
Config.Subtitle   = 'City / Roleplay'
Config.Discord    = 'https://discord.gg/tonlien'   -- '' pour masquer le bouton Discord
Config.Shop       = 'https://tonserveur.tebex.io'  -- lien de la boutique VIP ('' pour masquer le bouton)

-- Comportement
Config.Blur       = true    -- flou de l'écran derrière le menu
Config.OverrideP  = true    -- la touche P ouvre aussi le menu ASH (au lieu du menu pause GTA)
Config.HoldToQuit = 1500    -- durée (ms) à maintenir le bouton pour confirmer la déconnexion

-- Anti "déco en pleine action" : refuse de quitter via le menu si le joueur est
-- menotté, à terre ou mort. (Ça n'empêche pas ALT+F4 / F8 quit, c'est un garde-fou RP.)
Config.BlockQuitWhenRestrained = true

-- Message affiché au joueur à la déconnexion
Config.QuitMessage = 'Tu as quitté ASH City. Ton personnage a été sauvegardé. À bientôt !'

------------------------------------------------------------------------
-- Signaler (menu report de Luxu Admin)
-- Luxu n'expose pas d'export pour ouvrir les reports : on exécute sa commande.
-- Mets le nom de la commande SANS le "/" (celle que tes joueurs tapent en jeu).
-- '' pour masquer le bouton.
------------------------------------------------------------------------
Config.ReportCommand = 'report'

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
            { key = 'L',      label = 'Verrouiller / déverrouiller' },
            { key = 'G',      label = 'Moteur' },
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
