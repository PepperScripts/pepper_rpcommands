Config = {}

-- Sprache der Texte: 'de' oder 'en' (Dateien in locales/) · Language: 'de' or 'en' (files in locales/)
Config.Locale = 'en'

-- Reichweite in Metern, in der andere den Text sehen · Range in metres in which others see the text
Config.Distance = 15.0

-- Wie lange der Text über dem Kopf bleibt (Millisekunden) · How long the text stays above the head
Config.Duration = 7000

-- Text nur zeigen, wenn Sichtkontakt besteht (nicht durch Wände) · Only show with line of sight (not through walls)
Config.RequireLineOfSight = true

-- Höchstlänge einer Eingabe in Zeichen (maximal 80, GTA zeigt nicht mehr) · Max input length (80 at most)
Config.MaxLength = 80

-- Wartezeit zwischen zwei Befehlen je Spieler (Millisekunden) · Cooldown between two commands per player
Config.Cooldown = 1500

-- Zusätzlich eine Zeile im Chat für alle in Reichweite · Also print a chat line for everyone in range
Config.Chat = true

-- Befehle: Name änderbar, enabled = false schaltet einen Befehl ab, color = Rot, Grün, Blau (0–255)
-- Commands: rename freely, enabled = false turns a command off, color = red, green, blue (0–255)
Config.Commands = {
    me   = { enabled = true, name = 'me',   color = { 255, 196, 107 } },
    ['do'] = { enabled = true, name = 'do',   color = { 143, 176, 255 } },
    try  = { enabled = true, name = 'try',  color = { 196, 160, 255 }, chance = 50 }, -- chance = Erfolg in Prozent
    roll = { enabled = true, name = 'roll', color = { 120, 220, 160 }, default = 6, max = 1000 },
}

-- Welcher Name in der Chat-Zeile steht. Standard: der FiveM-Name. Für den Charakternamen hier dein Framework abfragen.
-- Which name the chat line shows. Default: the FiveM name. Query your framework here for the character name.
-- Läuft nur auf dem Server · Runs on the server only.
Config.GetName = function(source)
    return GetPlayerName(source)
end
