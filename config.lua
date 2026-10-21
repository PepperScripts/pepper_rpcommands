Config = {}

-- Sprache: 'en', 'de', 'fr', 'es' oder 'nl' (Dateien in locales/) · Language: 'en', 'de', 'fr', 'es' or 'nl'
Config.Locale = 'en'

-- Aussehen der Texte über dem Kopf · Look of the text above the head
--   'modern'  Sprechblase mit Symbol (NUI) · speech bubble with icon (NUI)
--   'minimal' nur Text mit Schatten (NUI) · text with shadow only (NUI)
--   'classic' GTA-Schrift wie in Version 1 · GTA font like version 1
Config.Style = 'modern'

-- Größe der Sprechblasen (1.0 = normal) · Size of the bubbles (1.0 = normal)
Config.Scale = 1.0

-- Standard-Reichweite in Metern (einzelne Befehle können eine eigene haben) · Default range in metres
Config.Distance = 15.0

-- Wie lange ein Text über dem Kopf bleibt (Millisekunden) · How long a text stays above the head (ms)
Config.Duration = 7000

-- So viele Texte stapeln sich über einem Spieler, ältere verschwinden · Texts stacked above one player
Config.MaxStack = 3

-- Text nur bei Sichtkontakt zeigen (nicht durch Wände) · Only show with line of sight (not through walls)
Config.RequireLineOfSight = true

-- Höchstlänge einer Eingabe in Zeichen (bis 250, lange Texte werden umgebrochen) · Max input length (up to 250)
Config.MaxLength = 150

-- Wartezeit zwischen zwei Befehlen je Spieler (ms) · Cooldown between two commands per player (ms)
Config.Cooldown = 1500

-- Zusätzlich eine Zeile im Chat für alle in Reichweite · Also print a chat line for everyone in range
Config.Chat = true

-- Name in der Chat-Zeile · Name in the chat line
--   'character' Charaktername aus ESX, QBCore oder Qbox (sonst FiveM-Name) · character name from ESX/QBCore/Qbox
--   'fivem'     immer der FiveM-Name · always the FiveM name
Config.NameMode = 'character'

-- Eigene Namensabfrage (läuft auf dem Server). nil = NameMode benutzen · Own name lookup (server). nil = use NameMode
-- Config.GetName = function(source) return GetPlayerName(source) end
Config.GetName = nil

-- Befehle · Commands
--   enabled   false schaltet den Befehl ab · false turns the command off
--   name      Befehlsname ohne / · command name without /
--   color     Rot, Grün, Blau (0–255) · red, green, blue (0–255)
--   icon      me, do, try, dice, coin, status, ooc, whisper, shout
--   distance  eigene Reichweite (sonst Config.Distance) · own range (otherwise Config.Distance)
--   overhead  Text über dem Kopf zeigen · show text above the head
--   chat      Chat-Zeile (nur wenn Config.Chat = true) · chat line (only if Config.Chat = true)
Config.Commands = {
    me      = { enabled = true, name = 'me',      color = { 255, 196, 107 }, icon = 'me' },
    ['do']  = { enabled = true, name = 'do',      color = { 143, 176, 255 }, icon = 'do' },
    try     = { enabled = true, name = 'try',     color = { 196, 160, 255 }, icon = 'try', chance = 50 }, -- chance = Erfolg in %
    roll    = { enabled = true, name = 'roll',    color = { 120, 220, 160 }, icon = 'dice', default = 6, max = 1000 },
    dice    = { enabled = true, name = 'dice',    color = { 120, 220, 160 }, icon = 'dice', maxDice = 10, maxSides = 100 }, -- /dice 2d6
    coin    = { enabled = true, name = 'coin',    color = { 255, 214, 92 },  icon = 'coin' },
    status  = { enabled = true, name = 'status',  color = { 200, 205, 215 }, icon = 'status', maxLength = 60, maxMinutes = 60 }, -- 0 = bleibt bis Ausloggen
    looc    = { enabled = true, name = 'looc',    color = { 160, 170, 185 }, icon = 'ooc' },
    whisper = { enabled = true, name = 'whisper', color = { 190, 215, 230 }, icon = 'whisper', distance = 3.0 },
    shout   = { enabled = true, name = 'shout',   color = { 255, 120, 110 }, icon = 'shout', distance = 35.0 },
}
