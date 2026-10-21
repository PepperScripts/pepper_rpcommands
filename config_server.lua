-- Einstellungen, die nur der Server kennt (werden nie an Spieler geschickt)
-- Settings only the server knows (never sent to players)
ServerConfig = {}

-- Discord-Webhook für das Protokoll aller RP-Befehle ('' = aus) · Discord webhook for the log of all commands ('' = off)
ServerConfig.Webhook = ''

-- Zusätzlich jede Zeile in der Server-Konsole ausgeben · Also print every line to the server console
ServerConfig.ConsoleLog = false

-- Wortfilter: 'censor' ersetzt durch Sternchen, 'block' verwirft den Befehl, 'off' schaltet ihn ab
-- Word filter: 'censor' replaces with asterisks, 'block' rejects the command, 'off' disables it
ServerConfig.Filter = {
    mode = 'censor',
    words = {
        -- 'beispielwort', 'example word',
    },
}

-- Admin-Befehle · Admin commands
--   Erlaubt mit ACE "pepperrp.admin" (server.cfg: add_ace group.admin pepperrp.admin allow)
--   oder einer der Gruppen aus ESX / QBCore / Qbox.
--   Allowed with ACE "pepperrp.admin" or one of the ESX / QBCore / Qbox groups.
ServerConfig.Admin = {
    groups = { 'god', 'superadmin', 'admin', 'mod' },
    commands = {
        clear = 'rpclear',   -- /rpclear [ID]  Texte + Status entfernen (ohne ID: alle) · remove texts + status (no ID: everyone)
        mute = 'rpmute',     -- /rpmute ID [Minuten]  RP-Befehle sperren · block RP commands
        unmute = 'rpunmute', -- /rpunmute ID
    },
    defaultMuteMinutes = 30,
}
