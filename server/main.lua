-- Pepper RP-Commands – Server: prüft Eingaben, würfelt, verwaltet Status + Sperren und schickt Texte an Spieler in der Nähe
RP = RP or {}

local MAX_LENGTH_LIMIT = 250
local lastUse = {}  -- [source] = GetGameTimer()
local mutes = {}    -- [Lizenz oder Server-ID] = os.time(), bis wann gesperrt (über Lizenz: gilt auch nach Reconnect)
local statuses = {} -- [source] = { text = '…', expires = os.time() oder nil }

local function commandConfig(kind)
    return Config.Commands[kind]
end

-- Entfernt Steuerzeichen, GTA-Formatcodes (~r~), Chat-Farbcodes (^1) und spitze Klammern, kürzt auf max Zeichen.
local function clean(text, max)
    text = tostring(text or '')
    text = text:gsub('%c', ' '):gsub('<[^>]*>', ''):gsub('~%a~', ''):gsub('~', ''):gsub('%^%d', ''):gsub('[<>]', '')
    text = text:gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '')

    max = math.max(1, math.min(tonumber(max) or 150, MAX_LENGTH_LIMIT))
    local length = utf8.len(text)
    if length == nil then
        text = text:sub(1, max) -- ungültiges UTF-8: nach Bytes kürzen
    elseif length > max then
        text = text:sub(1, utf8.offset(text, max + 1) - 1)
    end
    return text
end

-- Wortfilter. Liefert den (ggf. zensierten) Text oder nil, wenn er blockiert werden soll.
local function escapePattern(word)
    return (word:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]', '%%%0'))
end

local function filter(text)
    local settings = ServerConfig.Filter or {}
    if settings.mode == 'off' or type(settings.words) ~= 'table' or #settings.words == 0 then return text end
    local lower = text:lower()
    for _, word in ipairs(settings.words) do
        word = tostring(word):lower()
        if word ~= '' then
            local pattern = escapePattern(word)
            if lower:find(pattern) then
                if settings.mode == 'block' then return nil end
                -- Gleiche Stelle im Original ersetzen (Groß-/Kleinschreibung egal)
                local result, position = {}, 1
                while true do
                    local from, to = lower:find(pattern, position)
                    if not from then break end
                    result[#result + 1] = text:sub(position, from - 1)
                    result[#result + 1] = ('*'):rep(utf8.len(text:sub(from, to)) or (to - from + 1))
                    position = to + 1
                end
                result[#result + 1] = text:sub(position)
                text = table.concat(result)
                lower = text:lower()
            end
        end
    end
    return text
end

local function hint(source, key, vars)
    local text = L(key, vars)
    if source == 0 then return print('[pepper_rpcommands] ' .. text) end
    TriggerClientEvent('pepper_rpcommands:hint', source, text)
end

local function onCooldown(source)
    local now = GetGameTimer()
    if lastUse[source] and now - lastUse[source] < (tonumber(Config.Cooldown) or 1500) then return true end
    lastUse[source] = now
    return false
end

local function muteKey(source)
    local license = GetPlayerIdentifierByType and GetPlayerIdentifierByType(source, 'license') or nil
    return license or ('id:' .. tostring(source))
end

local function mutedMinutes(source)
    if not source then return nil end
    local key = muteKey(source)
    local untilTime = mutes[key]
    if not untilTime then return nil end
    local left = untilTime - os.time()
    if left <= 0 then
        mutes[key] = nil
        return nil
    end
    return math.ceil(left / 60)
end

local function playerName(source)
    return clean(RP.rawName(source), 40)
end

local function rangeOf(kind, override)
    local command = commandConfig(kind)
    return tonumber(override) or (command and tonumber(command.distance)) or tonumber(Config.Distance) or 15.0
end

-- Mit OneSync kennt der Server die Positionen und schickt den Text nur an Spieler in Reichweite
-- (gleiche Dimension). Ohne Positionen geht er an alle; der Client prüft die Entfernung ohnehin selbst.
local function broadcast(source, payload)
    payload.distance = rangeOf(payload.kind, payload.distance)
    local ped = GetPlayerPed(source)
    local origin = ped and ped ~= 0 and GetEntityCoords(ped) or nil
    if not origin or (origin.x == 0.0 and origin.y == 0.0 and origin.z == 0.0) then
        TriggerClientEvent('pepper_rpcommands:show', -1, source, payload)
        return
    end

    local bucket = GetPlayerRoutingBucket(source)
    local range = payload.distance + 2.0
    for _, id in ipairs(GetPlayers()) do
        local target = tonumber(id)
        local targetPed = GetPlayerPed(target)
        if targetPed and targetPed ~= 0 and GetPlayerRoutingBucket(target) == bucket
            and #(GetEntityCoords(targetPed) - origin) <= range then
            TriggerClientEvent('pepper_rpcommands:show', target, source, payload)
        end
    end
end

-- ---------------------------------------------------------------- Status (Dauertext)
local function syncStatus(source)
    local entry = statuses[source]
    TriggerClientEvent('pepper_rpcommands:status', -1, source, entry and entry.text or false)
end

local function setStatus(source, text, minutes)
    if text == nil or text == '' then
        if not statuses[source] then return false end
        statuses[source] = nil
    else
        minutes = tonumber(minutes)
        statuses[source] = { text = text, expires = minutes and minutes > 0 and os.time() + minutes * 60 or nil }
    end
    syncStatus(source)
    return true
end

-- Abgelaufene Status entfernen (prüft nur, solange es überhaupt welche gibt)
CreateThread(function()
    while true do
        Wait(30000)
        local now = os.time()
        for source, entry in pairs(statuses) do
            if entry.expires and entry.expires <= now then setStatus(source, nil) end
        end
    end
end)

-- ---------------------------------------------------------------- Befehle
-- build(text, args, command, source) liefert die Platzhalter für die Texte – oder nil, key, vars für einen Hinweis.
local function register(kind, needsText, build)
    local command = commandConfig(kind)
    if not command or not command.enabled then return end

    RegisterCommand(command.name, function(source, args)
        if source == 0 then return end -- nicht von der Konsole
        local muted = mutedMinutes(source)
        if muted then return hint(source, 'muted', { minutes = muted }) end
        if onCooldown(source) then return hint(source, 'cooldown') end

        local text = clean(table.concat(args, ' '), command.maxLength or Config.MaxLength)
        if needsText and text == '' then return hint(source, 'usage', { command = command.name }) end
        if text ~= '' then
            text = filter(text)
            if not text then return hint(source, 'blocked') end
        end

        local vars, hintKey, hintVars = build(text, args, command, source)
        if not vars then
            if hintKey then hint(source, hintKey, hintVars) end
            return
        end
        vars.name = playerName(source)
        local overhead = L('overhead_' .. kind, vars)
        RP.log(command.name, source, vars.name, overhead)
        broadcast(source, {
            kind = kind,
            overhead = command.overhead ~= false and overhead or nil,
            chat = command.chat ~= false and L('chat_' .. kind, vars) or nil,
        })
    end, false)
end

local function textOnly(text)
    return { text = text }
end

register('me', true, textOnly)
register('do', true, textOnly)
register('looc', true, textOnly)
register('whisper', true, textOnly)
register('shout', true, textOnly)

register('try', true, function(text, _, command)
    local success = math.random(1, 100) <= (tonumber(command.chance) or 50)
    return { text = text, result = L(success and 'try_success' or 'try_fail') }
end)

register('roll', false, function(_, args, command)
    local limit = math.max(2, tonumber(command.max) or 1000)
    local sides = math.floor(tonumber(args[1]) or tonumber(command.default) or 6)
    sides = math.max(2, math.min(limit, sides))
    return { result = math.random(1, sides), max = sides }
end)

-- /dice 2d6 · /dice d20 · /dice 3 (= 3d6)
register('dice', false, function(_, args, command)
    local input = tostring(args[1] or '1d6'):lower()
    local count, sides = input:match('^(%d*)d(%d+)$')
    if not sides and input:match('^%d+$') then
        count, sides = input, '6'
    end
    count = tonumber(count ~= '' and count or 1)
    sides = tonumber(sides)
    local maxDice = math.max(1, tonumber(command.maxDice) or 10)
    local maxSides = math.max(2, tonumber(command.maxSides) or 100)
    if not count or not sides or count < 1 or count > maxDice or sides < 2 or sides > maxSides then
        return nil, 'dice_usage', { command = command.name, dice = maxDice, sides = maxSides }
    end
    local rolls, total = {}, 0
    for i = 1, count do
        rolls[i] = math.random(1, sides)
        total = total + rolls[i]
    end
    local detail = count > 1 and (table.concat(rolls, ' + ') .. ' = ' .. total) or tostring(total)
    return { dice = count .. 'd' .. sides, result = detail, total = total }
end)

register('coin', false, function()
    return { result = L(math.random(1, 2) == 1 and 'coin_heads' or 'coin_tails') }
end)

-- /status [Text] setzt einen Dauertext, /status ohne Text entfernt ihn
do
    local command = commandConfig('status')
    if command and command.enabled then
        RegisterCommand(command.name, function(source, args)
            if source == 0 then return end
            local muted = mutedMinutes(source)
            if muted then return hint(source, 'muted', { minutes = muted }) end
            if onCooldown(source) then return hint(source, 'cooldown') end

            local text = clean(table.concat(args, ' '), command.maxLength or 60)
            if text == '' then
                if setStatus(source, nil) then
                    RP.log(command.name, source, playerName(source), '(removed)')
                    return hint(source, 'status_cleared')
                end
                return hint(source, 'status_usage', { command = command.name })
            end
            text = filter(text)
            if not text then return hint(source, 'blocked') end
            setStatus(source, text, command.maxMinutes)
            RP.log(command.name, source, playerName(source), text)
            hint(source, 'status_set', { command = command.name })
        end, false)
    end
end

-- Neuer Spieler: alle aktiven Status schicken (+ Admin-Vorschläge, wenn berechtigt)
local requested = {}
RegisterNetEvent('pepper_rpcommands:ready', function()
    local source = source
    if requested[source] then return end
    requested[source] = true
    local list = {}
    for id, entry in pairs(statuses) do list[tostring(id)] = entry.text end
    TriggerClientEvent('pepper_rpcommands:statusList', source, list)
    if RP.isAdmin(source) then TriggerClientEvent('pepper_rpcommands:adminSuggestions', source, ServerConfig.Admin.commands or {}) end
end)

-- ---------------------------------------------------------------- Admin
local function adminCommand(name, handler)
    if not name or name == '' then return end
    RegisterCommand(name, function(source, args)
        if not RP.isAdmin(source) then return hint(source, 'no_permission') end
        handler(source, args)
    end, false)
end

local function onlineTarget(source, value)
    local target = tonumber(value)
    if not target or not GetPlayerName(target) then
        hint(source, 'player_not_found', { id = tostring(value or '?') })
        return nil
    end
    return target
end

local adminNames = ServerConfig.Admin.commands or {}

adminCommand(adminNames.clear, function(source, args)
    if args[1] then
        local target = onlineTarget(source, args[1])
        if not target then return end
        setStatus(target, nil)
        TriggerClientEvent('pepper_rpcommands:clear', -1, target)
        hint(source, 'cleared_player', { id = target })
    else
        for id in pairs(statuses) do statuses[id] = nil end
        TriggerClientEvent('pepper_rpcommands:clear', -1, false)
        hint(source, 'cleared_all')
    end
    RP.log(adminNames.clear, source, source == 0 and 'Console' or playerName(source), args[1] or 'all')
end)

adminCommand(adminNames.mute, function(source, args)
    local target = onlineTarget(source, args[1])
    if not target then return end
    local minutes = math.floor(tonumber(args[2]) or tonumber(ServerConfig.Admin.defaultMuteMinutes) or 30)
    minutes = math.max(1, math.min(minutes, 10080))
    mutes[muteKey(target)] = os.time() + minutes * 60
    setStatus(target, nil)
    hint(source, 'muted_player', { id = target, minutes = minutes })
    hint(target, 'muted', { minutes = minutes })
    RP.log(adminNames.mute, source, source == 0 and 'Console' or playerName(source), ('%s (%s min)'):format(target, minutes))
end)

adminCommand(adminNames.unmute, function(source, args)
    local target = onlineTarget(source, args[1])
    if not target then return end
    mutes[muteKey(target)] = nil
    hint(source, 'unmuted_player', { id = target })
    hint(target, 'unmuted')
    RP.log(adminNames.unmute, source, source == 0 and 'Console' or playerName(source), tostring(target))
end)

-- ---------------------------------------------------------------- Exports für andere Ressourcen
-- exports.pepper_rpcommands:ShowText(source, 'öffnet den Kofferraum', { color = {255,0,0}, icon = 'me', duration = 5000, distance = 10.0, chat = '* Max öffnet …' })
exports('ShowText', function(source, text, options)
    source = tonumber(source)
    if not source or not GetPlayerName(source) then return false end
    options = type(options) == 'table' and options or {}
    text = clean(text, MAX_LENGTH_LIMIT)
    if text == '' then return false end
    local color = type(options.color) == 'table' and #options.color >= 3 and options.color or nil
    broadcast(source, {
        kind = 'custom',
        overhead = text,
        chat = type(options.chat) == 'string' and clean(options.chat, MAX_LENGTH_LIMIT) or nil,
        color = color and { tonumber(color[1]) or 255, tonumber(color[2]) or 255, tonumber(color[3]) or 255 } or nil,
        icon = type(options.icon) == 'string' and options.icon or nil,
        duration = tonumber(options.duration),
        distance = tonumber(options.distance),
    })
    return true
end)

-- exports.pepper_rpcommands:SetStatus(source, 'verletzt', 10)  (Minuten optional, nil = bis zum Ausloggen)
exports('SetStatus', function(source, text, minutes)
    source = tonumber(source)
    if not source or not GetPlayerName(source) then return false end
    text = clean(text, 60)
    return setStatus(source, text ~= '' and text or nil, minutes)
end)

exports('ClearStatus', function(source)
    return setStatus(tonumber(source), nil)
end)

exports('GetStatus', function(source)
    local entry = statuses[tonumber(source)]
    return entry and entry.text or nil
end)

exports('IsMuted', function(source)
    return mutedMinutes(tonumber(source)) ~= nil
end)

AddEventHandler('playerDropped', function()
    local id = source
    lastUse[id] = nil
    requested[id] = nil
    if statuses[id] then setStatus(id, nil) end
    mutes['id:' .. tostring(id)] = nil -- nur Sperren ohne Lizenz; die Server-ID wird neu vergeben
end)
