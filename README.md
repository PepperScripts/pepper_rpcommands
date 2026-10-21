# Pepper RP-Commands

Free roleplay commands with speech bubbles for FiveM · Standalone (works with ESX, QBCore, Qbox or no framework at all)

**Pepper Scripts** · More scripts: https://pepper-scripts.tebex.store · Support: https://discord.gg/6NaFJWKDYu

---

## 🇬🇧 English

### Features
- 10 commands: `/me`, `/do`, `/try`, `/roll`, `/dice`, `/coin`, `/status`, `/looc`, `/whisper`, `/shout`
- Modern speech bubbles above the head with an icon per command – or `minimal` (text with shadow) or `classic` (GTA font)
- `/status` keeps a text above your head (e.g. "injured") until you remove it
- Several texts stack above a player, long texts wrap
- Character name from ESX, QBCore or Qbox in the chat line – detected automatically
- `/try`, `/roll`, `/dice` and `/coin` are decided on the server, so nobody can fake a result
- Only players in range receive the text (same routing bucket); optional line-of-sight check, so nothing shows through walls
- Discord webhook log, word filter, admin commands to clear texts and mute players
- Exports for other resources
- English, German, French, Spanish and Dutch
- No dependencies; 0.00 ms while no text is visible

### Commands
| Command | Example | Above the head |
|---|---|---|
| `/me [text]` | `/me opens the trunk` | opens the trunk |
| `/do [text]` | `/do The door is locked.` | The door is locked. |
| `/try [text]` | `/try pick the lock` | tries to pick the lock – succeeds / fails |
| `/roll [sides]` | `/roll 20` | rolls 14 (1–20) |
| `/dice [dice]` | `/dice 2d6` | rolls 2d6: 3 + 5 = 8 |
| `/coin` | `/coin` | flips a coin: heads |
| `/status [text]` | `/status injured` | lasting text; `/status` alone removes it |
| `/looc [text]` | `/looc brb` | (( brb )) |
| `/whisper [text]` | `/whisper over here` | only visible within 3 m |
| `/shout [text]` | `/shout Police!` | visible within 35 m |

Admin (ACE `pepperrp.admin` or the groups in `config_server.lua`):

| Command | Meaning |
|---|---|
| `/rpclear [ID]` | Remove texts and status of one player – without ID of everyone |
| `/rpmute ID [minutes]` | Block RP commands for a player (stays after reconnecting) |
| `/rpunmute ID` | Unblock |

### Installation
1. Put the `pepper_rpcommands` folder into your `resources` folder.
2. Add to your `server.cfg`:
   ```
   ensure pepper_rpcommands
   ```
3. Remove other resources that register `/me` or `/do`, otherwise both will answer.
4. Set `Config.Locale` in `config.lua` and restart the server.
5. Optional – admin rights via ACE:
   ```
   add_ace group.admin pepperrp.admin allow
   ```

**Updating from 1.x:** replace the whole folder. If you changed `config.lua`, copy your values into the new file – the new commands only appear with the new config.

### Settings
`config.lua` (shared):

| Option | Meaning |
|---|---|
| `Config.Locale` | `en`, `de`, `fr`, `es` or `nl` |
| `Config.Style` | `modern`, `minimal` or `classic` |
| `Config.Scale` | Size of the bubbles (1.0 = normal) |
| `Config.Distance` | Default range in metres |
| `Config.Duration` | How long a text stays, in milliseconds |
| `Config.MaxStack` | Texts stacked above one player |
| `Config.RequireLineOfSight` | Hide texts behind walls |
| `Config.MaxLength` | Max input length (up to 250) |
| `Config.Cooldown` | Wait between two commands per player, in milliseconds |
| `Config.Chat` | Chat line on/off |
| `Config.NameMode` | `character` (ESX/QBCore/Qbox name) or `fivem` |
| `Config.GetName` | Own name function (overrides `NameMode`) |
| `Config.Commands` | Per command: `enabled`, `name`, `color`, `icon`, `distance`, `overhead`, `chat` and extra options |

`config_server.lua` (never sent to players): `ServerConfig.Webhook`, `ServerConfig.ConsoleLog`, `ServerConfig.Filter`, `ServerConfig.Admin`.

### Exports
```lua
-- Server
exports.pepper_rpcommands:ShowText(source, 'opens the safe', { color = { 255, 196, 107 }, icon = 'me', duration = 5000, distance = 10.0 })
exports.pepper_rpcommands:SetStatus(source, 'handcuffed', 10) -- minutes optional
exports.pepper_rpcommands:ClearStatus(source)
exports.pepper_rpcommands:GetStatus(source)  -- text or nil
exports.pepper_rpcommands:IsMuted(source)    -- true / false

-- Client
exports.pepper_rpcommands:ShowLocalText(serverId, 'only you see this', { icon = 'do' })
exports.pepper_rpcommands:SetHidden(true) -- hide everything, e.g. for a cinematic mode
```
Icons: `me`, `do`, `try`, `dice`, `coin`, `status`, `ooc`, `whisper`, `shout`, `chat`.

---

## 🇩🇪 Deutsch

### Features
- 10 Befehle: `/me`, `/do`, `/try`, `/roll`, `/dice`, `/coin`, `/status`, `/looc`, `/whisper`, `/shout`
- Moderne Sprechblasen über dem Kopf mit Symbol je Befehl – oder `minimal` (Text mit Schatten) bzw. `classic` (GTA-Schrift)
- `/status` hält einen Text über dem Kopf (z. B. „verletzt“), bis du ihn entfernst
- Mehrere Texte stapeln sich über einem Spieler, lange Texte werden umgebrochen
- Charaktername aus ESX, QBCore oder Qbox in der Chat-Zeile – wird automatisch erkannt
- `/try`, `/roll`, `/dice` und `/coin` entscheidet der Server – niemand kann ein Ergebnis fälschen
- Nur Spieler in Reichweite bekommen den Text (gleiche Dimension); auf Wunsch nur bei Sichtkontakt, also nicht durch Wände
- Discord-Webhook-Protokoll, Wortfilter, Admin-Befehle zum Entfernen von Texten und Sperren von Spielern
- Exports für andere Ressourcen
- Englisch, Deutsch, Französisch, Spanisch und Niederländisch
- Keine Abhängigkeiten; 0.00 ms, solange kein Text sichtbar ist

### Befehle
| Befehl | Beispiel | Über dem Kopf |
|---|---|---|
| `/me [Text]` | `/me öffnet den Kofferraum` | öffnet den Kofferraum |
| `/do [Text]` | `/do Die Tür ist verschlossen.` | Die Tür ist verschlossen. |
| `/try [Text]` | `/try das Schloss knacken` | versucht: das Schloss knacken – gelingt / misslingt |
| `/roll [Seiten]` | `/roll 20` | würfelt 14 (1–20) |
| `/dice [Würfel]` | `/dice 2d6` | würfelt 2d6: 3 + 5 = 8 |
| `/coin` | `/coin` | wirft eine Münze: Kopf |
| `/status [Text]` | `/status verletzt` | Dauertext; `/status` ohne Text entfernt ihn |
| `/looc [Text]` | `/looc bin gleich zurück` | (( bin gleich zurück )) |
| `/whisper [Text]` | `/whisper hier rüber` | nur im Umkreis von 3 m sichtbar |
| `/shout [Text]` | `/shout Polizei!` | im Umkreis von 35 m sichtbar |

Befehlsnamen lassen sich in `Config.Commands` ändern, z. B. `name = 'fluestern'` (ohne Umlaute).

Admin (ACE `pepperrp.admin` oder die Gruppen aus `config_server.lua`): `/rpclear [ID]`, `/rpmute ID [Minuten]`, `/rpunmute ID`.

### Installation
1. Ordner `pepper_rpcommands` in deinen `resources`-Ordner legen.
2. In der `server.cfg` eintragen:
   ```
   ensure pepper_rpcommands
   ```
3. Andere Ressourcen entfernen, die `/me` oder `/do` anmelden – sonst antworten beide.
4. `Config.Locale = 'de'` in der `config.lua` setzen und den Server neu starten.
5. Optional – Admin-Rechte per ACE: `add_ace group.admin pepperrp.admin allow`

**Update von 1.x:** den ganzen Ordner ersetzen. Wer die `config.lua` angepasst hat, überträgt seine Werte in die neue Datei – die neuen Befehle erscheinen nur mit der neuen Config.

Einstellungen und Exports stehen oben im englischen Teil.

---

MIT License · Pepper Scripts is not affiliated with Rockstar Games, Take-Two Interactive or Cfx.re.
