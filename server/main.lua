-- Pepper RP-Commands – Server: prüft die Eingabe, würfelt und schickt den Text an Spieler in der Nähe
local lastUse = {}

-- Entfernt Steuerzeichen, GTA-Formatcodes (~r~), Chat-Farbcodes (^1) und spitze Klammern, kürzt auf die Höchstlänge.
local function clean(text)
    text = tostring(text or '')
    text = text:gsub('%c', ' '):gsub('~', ''):gsub('%^%d', ''):gsub('[<>]', '')
    text = text:gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '')

    local max = math.min(tonumber(Config.MaxLength) or 80, 80)
    local length = utf8.len(text)
    if length == nil then
        text = text:sub(1, max) -- ungültiges UTF-8: nach Bytes kürzen
    elseif length > max then
        text = text:sub(1, utf8.offset(text, max + 1) - 1)
    end
    return text
end

local function hint(source, key, vars)
    TriggerClientEvent('pepper_rpcommands:hint', source, L(key, vars))
end

local function onCooldown(source)
    local now = GetGameTimer()
    if lastUse[source] and now - lastUse[source] < Config.Cooldown then return true end
    lastUse[source] = now
    return false
end

-- Mit OneSync kennt der Server die Positionen und schickt den Text nur an Spieler in Reichweite
-- (gleiche Dimension). Ohne Positionen geht er an alle; der Client prüft die Entfernung ohnehin selbst.
local function broadcast(source, kind, overhead, chat)
    local ped = GetPlayerPed(source)
    local origin = ped and ped ~= 0 and GetEntityCoords(ped) or nil
    if not origin or (origin.x == 0.0 and origin.y == 0.0 and origin.z == 0.0) then
        TriggerClientEvent('pepper_rpcommands:show', -1, source, kind, overhead, chat)
        return
    end

    local bucket = GetPlayerRoutingBucket(source)
    local range = Config.Distance + 5.0
    for _, id in ipairs(GetPlayers()) do
        local target = tonumber(id)
        local targetPed = GetPlayerPed(target)
        if targetPed and targetPed ~= 0 and GetPlayerRoutingBucket(target) == bucket
            and #(GetEntityCoords(targetPed) - origin) <= range then
            TriggerClientEvent('pepper_rpcommands:show', target, source, kind, overhead, chat)
        end
    end
end

local function playerName(source)
    local ok, name = pcall(Config.GetName, source)
    return clean(ok and name or GetPlayerName(source) or ('#' .. source))
end

-- Gemeinsamer Ablauf für alle Befehle: build(text, args) liefert die Platzhalter für die Texte oder nil.
local function register(kind, needsText, build)
    local command = Config.Commands[kind]
    if not command or not command.enabled then return end

    RegisterCommand(command.name, function(source, args)
        if source == 0 then return end -- nicht von der Konsole
        if onCooldown(source) then return hint(source, 'cooldown') end

        local text = clean(table.concat(args, ' '))
        if needsText and text == '' then return hint(source, 'usage', { command = command.name }) end

        local vars = build(text, args, command)
        vars.name = playerName(source)
        broadcast(source, kind, L('overhead_' .. kind, vars), L('chat_' .. kind, vars))
    end, false)
end

register('me', true, function(text)
    return { text = text }
end)

register('do', true, function(text)
    return { text = text }
end)

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

AddEventHandler('playerDropped', function()
    lastUse[source] = nil
end)
