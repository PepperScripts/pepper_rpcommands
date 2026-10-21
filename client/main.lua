-- Pepper RP-Commands – Client: zeigt Sprechblasen und Status über den Köpfen und schreibt die Chat-Zeile
local bubbles = {}   -- [Server-ID] = { { id, kind, text, color, icon, distance, expires }, ... }
local statuses = {}  -- [Server-ID] = Text
local losCache = {}  -- [Server-ID] = { at = GetGameTimer(), clear = bool }
local running = false
local hidden = false -- per Export ausgeblendet (z. B. Kinomodus)
local nextId = 0
local nuiHasContent = false

local STYLE = (Config.Style == 'minimal' or Config.Style == 'classic') and Config.Style or 'modern'
local USE_NUI = STYLE ~= 'classic'
local MAX_STACK = math.max(1, tonumber(Config.MaxStack) or 3)
local DURATION = tonumber(Config.Duration) or 7000
local DEFAULT_DISTANCE = tonumber(Config.Distance) or 15.0
local HEAD_BONE = 31086
local LOS_INTERVAL = 250 -- Sichtprüfung (Raycast) höchstens alle 250 ms je Spieler

local function myServerId()
    return GetPlayerServerId(PlayerId())
end

local function pedOf(serverId)
    if serverId == myServerId() then return PlayerPedId() end
    local player = GetPlayerFromServerId(serverId)
    if player == -1 then return nil end -- nicht in Reichweite / nicht geladen
    local ped = GetPlayerPed(player)
    return ped ~= 0 and ped or nil
end

local function hasSight(serverId, myPed, ped, now)
    if ped == myPed or not Config.RequireLineOfSight then return true end
    local entry = losCache[serverId]
    if not entry or now - entry.at > LOS_INTERVAL then
        entry = { at = now, clear = HasEntityClearLosToEntity(myPed, ped, 17) }
        losCache[serverId] = entry
    end
    return entry.clear
end

-- ---------------------------------------------------------------- klassische GTA-Schrift
local MAX_BYTES = 99 -- so viel nimmt eine GTA-Textkomponente höchstens an

local function fitBytes(text)
    if #text <= MAX_BYTES then return text end
    local cut = MAX_BYTES - 3
    while cut > 0 and (text:byte(cut + 1) & 0xC0) == 0x80 do cut = cut - 1 end
    return text:sub(1, cut) .. '...'
end

-- Bricht nach Wörtern um (ca. 45 Zeichen je Zeile)
local function wrap(text, width)
    local lines, current = {}, ''
    for word in text:gmatch('%S+') do
        local candidate = current == '' and word or (current .. ' ' .. word)
        if (utf8.len(candidate) or #candidate) > width and current ~= '' then
            lines[#lines + 1] = fitBytes(current)
            current = word
        else
            current = candidate
        end
    end
    if current ~= '' then lines[#lines + 1] = fitBytes(current) end
    return lines
end

local function drawClassic(x, y, z, text, color, scale)
    SetDrawOrigin(x, y, z, 0)
    SetTextScale(0.35 * scale, 0.35 * scale)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(color[1], color[2], color[3], 235)
    SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

local function renderClassic(head, items, scale)
    local lineHeight = 0.12 * scale
    local rows = {}
    for _, item in ipairs(items) do
        local text = item.kind == 'shout' and item.text:upper() or item.text
        if item.kind == 'do' then text = '* ' .. text .. ' *'
        elseif not item.status and item.kind ~= 'looc' then text = '* ' .. text end
        for _, line in ipairs(wrap(text, 45)) do rows[#rows + 1] = { text = line, color = item.color } end
    end
    -- unterste Zeile direkt über dem Kopf, ältere rücken nach oben
    for i = 1, #rows do
        local z = head.z + (#rows - i) * lineHeight
        drawClassic(head.x, head.y, z, rows[i].text, rows[i].color, scale)
    end
end

-- ---------------------------------------------------------------- Hauptschleife
-- Läuft nur, solange es Texte oder Status gibt – im Leerlauf existiert die Schleife nicht.
local function collect(serverId, list, status, now, myPed, myCoords, out)
    local ped = pedOf(serverId)
    if not ped then
        losCache[serverId] = nil
        return false
    end
    local coords = GetEntityCoords(ped)
    local distance = #(coords - myCoords)

    local items = {}
    if status and distance <= DEFAULT_DISTANCE then
        items[#items + 1] = { id = 's' .. serverId, kind = 'status', text = status,
            color = Config.Commands.status and Config.Commands.status.color or { 200, 205, 215 },
            icon = Config.Commands.status and Config.Commands.status.icon or 'status', status = true }
    end
    if list then
        for _, item in ipairs(list) do
            if distance <= item.distance then items[#items + 1] = item end
        end
    end
    if #items == 0 or not hasSight(serverId, myPed, ped, now) then return false end

    local head = GetPedBoneCoords(ped, HEAD_BONE, 0.0, 0.0, 0.0) + vector3(0.0, 0.0, 0.42)
    -- näher = größer, weiter weg = kleiner
    local scale = math.max(0.6, math.min(1.1, 1.15 - (distance / math.max(DEFAULT_DISTANCE, 1.0)) * 0.55))
        * (tonumber(Config.Scale) or 1.0)

    if not USE_NUI then
        renderClassic(head, items, scale)
        return true
    end

    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(head.x, head.y, head.z)
    if not onScreen then return false end
    local payload = {}
    for i, item in ipairs(items) do
        payload[i] = { id = item.id, kind = item.kind, text = item.text, color = item.color, icon = item.icon, status = item.status }
    end
    out[#out + 1] = { id = serverId, x = sx, y = sy, s = scale, items = payload }
    return true
end

local function startLoop()
    if running then return end
    running = true
    CreateThread(function()
        while next(bubbles) or next(statuses) do
            local now = GetGameTimer()

            -- abgelaufene Texte entfernen
            for serverId, list in pairs(bubbles) do
                for i = #list, 1, -1 do
                    if list[i].expires <= now then table.remove(list, i) end
                end
                if #list == 0 then bubbles[serverId] = nil end
            end

            local groups, visible = {}, false
            if not hidden and not IsPauseMenuActive() and not IsScreenFadedOut() then
                local myPed = PlayerPedId()
                local myCoords = GetEntityCoords(myPed)
                for serverId, list in pairs(bubbles) do
                    if collect(serverId, list, statuses[serverId], now, myPed, myCoords, groups) then visible = true end
                end
                for serverId, status in pairs(statuses) do
                    if not bubbles[serverId] and collect(serverId, nil, status, now, myPed, myCoords, groups) then
                        visible = true
                    end
                end
            end

            if USE_NUI and (visible or nuiHasContent) then
                SendNUIMessage({ action = 'frame', style = STYLE, groups = groups })
                nuiHasContent = visible
            end

            -- Nur Status weit weg und keine Texte: selten prüfen statt jeden Frame
            Wait((visible or next(bubbles)) and 0 or 250)
        end
        if USE_NUI and nuiHasContent then
            SendNUIMessage({ action = 'frame', groups = {} })
            nuiHasContent = false
        end
        running = false
    end)
end

local function addBubble(serverId, data)
    local command = Config.Commands[data.kind] or {}
    nextId = nextId + 1
    local list = bubbles[serverId] or {}
    bubbles[serverId] = list
    list[#list + 1] = {
        id = 'b' .. nextId,
        kind = data.kind,
        text = tostring(data.overhead),
        color = data.color or command.color or { 255, 255, 255 },
        icon = data.icon or command.icon or 'me',
        distance = tonumber(data.distance) or tonumber(command.distance) or DEFAULT_DISTANCE,
        expires = GetGameTimer() + (tonumber(data.duration) or DURATION),
    }
    while #list > MAX_STACK do table.remove(list, 1) end
    startLoop()
end

-- ---------------------------------------------------------------- Ereignisse vom Server
RegisterNetEvent('pepper_rpcommands:show', function(serverId, data)
    if type(data) ~= 'table' then return end
    local command = Config.Commands[data.kind] or {}
    local ped = pedOf(serverId)
    local range = tonumber(data.distance) or DEFAULT_DISTANCE
    if not ped or #(GetEntityCoords(ped) - GetEntityCoords(PlayerPedId())) > range then return end

    if data.overhead then addBubble(serverId, data) end
    if data.chat and Config.Chat then
        TriggerEvent('chat:addMessage', { color = data.color or command.color or { 255, 255, 255 }, args = { tostring(data.chat) } })
    end
end)

RegisterNetEvent('pepper_rpcommands:status', function(serverId, text)
    statuses[serverId] = text or nil
    if text then startLoop() end
end)

RegisterNetEvent('pepper_rpcommands:statusList', function(list)
    for id, text in pairs(list or {}) do statuses[tonumber(id)] = text end
    if next(statuses) then startLoop() end
end)

RegisterNetEvent('pepper_rpcommands:clear', function(serverId)
    if serverId then
        bubbles[serverId] = nil
        statuses[serverId] = nil
    else
        bubbles, statuses = {}, {}
    end
end)

RegisterNetEvent('pepper_rpcommands:hint', function(text)
    TriggerEvent('chat:addMessage', { color = { 200, 200, 200 }, args = { tostring(text) } })
end)

RegisterNetEvent('pepper_rpcommands:adminSuggestions', function(names)
    if type(names) ~= 'table' then return end
    local id = { name = L('param_id'), help = L('param_id_help') }
    if names.clear then TriggerEvent('chat:addSuggestion', '/' .. names.clear, L('help_rpclear'), { id }) end
    if names.mute then
        TriggerEvent('chat:addSuggestion', '/' .. names.mute, L('help_rpmute'),
            { id, { name = L('param_minutes'), help = L('param_minutes_help') } })
    end
    if names.unmute then TriggerEvent('chat:addSuggestion', '/' .. names.unmute, L('help_rpunmute'), { id }) end
end)

-- ---------------------------------------------------------------- Exports für andere Ressourcen
-- Nur für diesen Spieler sichtbar: exports.pepper_rpcommands:ShowLocalText(serverId, 'Text', { color = {255,0,0}, icon = 'do', duration = 4000 })
exports('ShowLocalText', function(serverId, text, options)
    options = type(options) == 'table' and options or {}
    text = tostring(text or ''):gsub('~', ''):sub(1, 250)
    if text == '' then return false end
    addBubble(tonumber(serverId) or myServerId(), {
        kind = 'custom', overhead = text, color = options.color, icon = options.icon,
        duration = options.duration, distance = options.distance,
    })
    return true
end)

-- Alles ausblenden, z. B. für Kinomodus oder Screenshots: exports.pepper_rpcommands:SetHidden(true)
exports('SetHidden', function(state)
    hidden = state == true
end)

-- ---------------------------------------------------------------- Start
CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(500) end
    TriggerServerEvent('pepper_rpcommands:ready')
end)

-- Vorschläge im Chat, sobald jemand "/" tippt
CreateThread(function()
    local action = { { name = L('param_action'), help = L('param_action_help') } }
    local suggestions = {
        me = { L('help_me'), action },
        ['do'] = { L('help_do'), action },
        try = { L('help_try'), action },
        roll = { L('help_roll'), { { name = L('param_sides'),
            help = L('param_sides_help', { default = Config.Commands.roll and Config.Commands.roll.default or 6 }) } } },
        dice = { L('help_dice'), { { name = L('param_dice'), help = L('param_dice_help') } } },
        coin = { L('help_coin'), {} },
        status = { L('help_status'), { { name = L('param_status'), help = L('param_status_help') } } },
        looc = { L('help_looc'), { { name = L('param_message'), help = L('param_message_help') } } },
        whisper = { L('help_whisper'), action },
        shout = { L('help_shout'), action },
    }
    for kind, entry in pairs(suggestions) do
        local command = Config.Commands[kind]
        if command and command.enabled then
            TriggerEvent('chat:addSuggestion', '/' .. command.name, entry[1], entry[2])
        end
    end
end)
