# Changelog

## [Unreleased]

## [2.0.0] - 2026-10-21

- New: modern speech bubbles above the head (NUI) with an icon per command, fade in/out and size by distance
- New: three styles in `Config.Style` – `modern`, `minimal` and `classic` (the GTA text from version 1)
- New: `/status [text]` – lasting text above the head until removed with `/status` (optional time limit)
- New: `/looc` (local OOC chat), `/whisper` (3 m), `/shout` (35 m), `/coin` and `/dice 2d6`
- New: character name from ESX, QBCore or Qbox in the chat line (`Config.NameMode`), FiveM name as fallback
- New: Discord webhook log of all RP commands with name, server ID and licence (`config_server.lua`)
- New: admin commands `/rpclear`, `/rpmute` and `/rpunmute` (ACE `pepperrp.admin` or framework group); a mute survives reconnecting
- New: word filter (`censor` or `block`)
- New: exports `ShowText`, `SetStatus`, `ClearStatus`, `GetStatus`, `IsMuted` (server) and `ShowLocalText`, `SetHidden` (client)
- New: French, Spanish and Dutch
- Changed: long texts wrap instead of being cut (`Config.MaxLength` up to 250, default 150)
- Changed: own range per command (`distance`), chat line and text above the head can be switched off per command
- Changed: line-of-sight check runs at most every 250 ms per player; still 0.00 ms while nothing is visible
- Upgrade: replace `config.lua` with the new one and add `config_server.lua` – old configs keep working, but the new commands only appear with the new config

## [1.0.0] - 2026-10-10

- First version.
