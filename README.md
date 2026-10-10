# Pepper RP-Commands

Free roleplay commands for FiveM · Standalone (works with ESX, QBCore, Qbox or no framework at all)

**Pepper Scripts** · More scripts: https://pepper-scripts.tebex.store · Support: https://discord.gg/6NaFJWKDYu

---

## 🇬🇧 English

### Features
- `/me`, `/do`, `/try` and `/roll` with text above the character's head
- Optional chat line for everyone in range
- `/try` and `/roll` are decided on the server, so nobody can fake a result
- Only players in range receive the text (same routing bucket); optional line-of-sight check, so nothing shows through walls
- Input is cleaned on the server: length limit, colour codes and control characters removed, cooldown per player
- English and German included, command names, colours, range and duration set in `config.lua`
- No dependencies; the draw loop only runs while a text is visible

### Commands
| Command | Example | Result above the head |
|---|---|---|
| `/me [text]` | `/me opens the trunk` | `* opens the trunk` |
| `/do [text]` | `/do The door is locked.` | `* The door is locked. *` |
| `/try [text]` | `/try pick the lock` | `* tries to pick the lock – succeeds` or `– fails` |
| `/roll [sides]` | `/roll 20` | `* rolls 14 (1–20)` |

### Installation
1. Put the `pepper_rpcommands` folder into your `resources` folder.
2. Add to your `server.cfg`:
   ```
   ensure pepper_rpcommands
   ```
3. Remove other resources that register `/me` or `/do`, otherwise both will answer.
4. Set `Config.Locale` in `config.lua` and restart the server.

### Settings (`config.lua`)
| Option | Meaning |
|---|---|
| `Config.Locale` | `en` or `de` |
| `Config.Distance` | Range in metres |
| `Config.Duration` | How long the text stays, in milliseconds |
| `Config.RequireLineOfSight` | Hide the text behind walls |
| `Config.MaxLength` | Max input length (80 at most) |
| `Config.Cooldown` | Wait between two commands per player, in milliseconds |
| `Config.Chat` | Chat line on/off |
| `Config.Commands` | Name, colour and on/off per command; `chance` for `/try`, `default` and `max` for `/roll` |
| `Config.GetName` | Which name the chat line shows (default: FiveM name) |

Character name instead of the FiveM name, for example with ESX:
```lua
Config.GetName = function(source)
    local xPlayer = exports.es_extended:getSharedObject().GetPlayerFromId(source)
    return xPlayer and xPlayer.getName() or GetPlayerName(source)
end
```

---

## 🇩🇪 Deutsch

### Features
- `/me`, `/do`, `/try` und `/roll` mit Text über dem Kopf des Charakters
- Optional eine Chat-Zeile für alle in Reichweite
- `/try` und `/roll` entscheidet der Server – niemand kann ein Ergebnis fälschen
- Nur Spieler in Reichweite bekommen den Text (gleiche Dimension); auf Wunsch nur bei Sichtkontakt, also nicht durch Wände
- Eingaben werden auf dem Server bereinigt: Höchstlänge, Farbcodes und Steuerzeichen entfernt, Wartezeit je Spieler
- Deutsch und Englisch dabei; Befehlsnamen, Farben, Reichweite und Dauer in der `config.lua`
- Keine Abhängigkeiten; die Zeichenschleife läuft nur, solange ein Text sichtbar ist

### Installation
1. Ordner `pepper_rpcommands` in deinen `resources`-Ordner legen.
2. In der `server.cfg` eintragen:
   ```
   ensure pepper_rpcommands
   ```
3. Andere Ressourcen entfernen, die `/me` oder `/do` anmelden – sonst antworten beide.
4. `Config.Locale = 'de'` in der `config.lua` setzen und den Server neu starten.

Befehle und Einstellungen stehen oben im englischen Teil.

---

MIT License · Pepper Scripts is not affiliated with Rockstar Games, Take-Two Interactive or Cfx.re.
