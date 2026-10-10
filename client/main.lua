-- Pepper RP-Commands – Client: zeichnet die Texte über den Köpfen und schreibt die Chat-Zeile
local active = {} -- [Server-ID] = { { text, color, expires }, ... }
local drawing = false

local LINE_HEIGHT = 0.13 -- Abstand zwischen zwei Zeilen über demselben Spieler (Meter)
local MAX_LINES = 3      -- mehr Zeilen je Spieler werden nicht gestapelt
local MAX_BYTES = 99     -- so viel nimmt eine GTA-Textkomponente höchstens an

-- Kürzt auf MAX_BYTES, ohne ein UTF-8-Zeichen (z. B. Umlaut) zu zerschneiden.
local function fit(text)
    if #text <= MAX_BYTES then return text end
    local cut = MAX_BYTES - 3
    while cut > 0 and (text:byte(cut + 1) & 0xC0) == 0x80 do cut = cut - 1 end
    return text:sub(1, cut) .. '...'
end

local function pedOf(serverId)
    if serverId == GetPlayerServerId(PlayerId()) then return PlayerPedId() end
    local player = GetPlayerFromServerId(serverId)
    if player == -1 then return nil end -- nicht in Reichweite / nicht geladen
    local ped = GetPlayerPed(player)
    return ped ~= 0 and ped or nil
end

local function drawText(coords, text, color)
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    SetTextScale(0.35, 0.35)
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

-- Läuft nur, solange es etwas zu zeichnen gibt – im Leerlauf existiert die Schleife nicht.
local function startDrawing()
    if drawing then return end
    drawing = true
    CreateThread(function()
        while next(active) do
            local now = GetGameTimer()
            local myPed = PlayerPedId()
            local myCoords = GetEntityCoords(myPed)

            for serverId, lines in pairs(active) do
                for i = #lines, 1, -1 do
                    if lines[i].expires <= now then table.remove(lines, i) end
                end

                local ped = #lines > 0 and pedOf(serverId) or nil
                if not ped then
                    active[serverId] = nil
                else
                    local coords = GetEntityCoords(ped)
                    local visible = #(coords - myCoords) <= Config.Distance
                        and (ped == myPed or not Config.RequireLineOfSight or HasEntityClearLosToEntity(myPed, ped, 17))
                    if visible then
                        for i = 1, #lines do
                            -- neueste Zeile unten, ältere rücken nach oben
                            local z = coords.z + 1.05 + (#lines - i) * LINE_HEIGHT
                            drawText(vector3(coords.x, coords.y, z), lines[i].text, lines[i].color)
                        end
                    end
                end
            end
            Wait(0)
        end
        drawing = false
    end)
end

RegisterNetEvent('pepper_rpcommands:show', function(serverId, kind, overhead, chat)
    local command = Config.Commands[kind]
    local ped = pedOf(serverId)
    if not command or not ped then return end
    if #(GetEntityCoords(ped) - GetEntityCoords(PlayerPedId())) > Config.Distance then return end

    local lines = active[serverId] or {}
    active[serverId] = lines
    lines[#lines + 1] = { text = fit(tostring(overhead)), color = command.color, expires = GetGameTimer() + Config.Duration }
    while #lines > MAX_LINES do table.remove(lines, 1) end
    startDrawing()

    if Config.Chat then
        TriggerEvent('chat:addMessage', { color = command.color, args = { tostring(chat) } })
    end
end)

RegisterNetEvent('pepper_rpcommands:hint', function(text)
    TriggerEvent('chat:addMessage', { color = { 200, 200, 200 }, args = { tostring(text) } })
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
    }
    for kind, entry in pairs(suggestions) do
        local command = Config.Commands[kind]
        if command and command.enabled then
            TriggerEvent('chat:addSuggestion', '/' .. command.name, entry[1], entry[2])
        end
    end
end)
