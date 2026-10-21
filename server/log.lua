-- Pepper RP-Commands – Protokoll: sammelt Zeilen und schickt sie gebündelt an Discord (und auf Wunsch in die Konsole)
RP = RP or {}

local FLUSH_MS = 5000
local buffer = {}
local scheduled = false

local function webhookUrl()
    local url = ServerConfig.Webhook
    return type(url) == 'string' and url:match('^https://') and url or nil
end

local function send(lines)
    local url = webhookUrl()
    if not url then return end
    -- Discord nimmt höchstens 2000 Zeichen je Nachricht: in Blöcke teilen.
    local chunk, size = {}, 0
    local function post()
        if #chunk == 0 then return end
        PerformHttpRequest(url, function() end, 'POST', json.encode({
            username = 'Pepper RP-Commands',
            content = '```\n' .. table.concat(chunk, '\n') .. '\n```',
            allowed_mentions = { parse = {} }, -- keine Erwähnungen auslösen
        }), { ['Content-Type'] = 'application/json' })
        chunk, size = {}, 0
    end
    for _, line in ipairs(lines) do
        line = line:gsub('`', "'"):sub(1, 600)
        if size + #line + 1 > 1800 then post() end
        chunk[#chunk + 1] = line
        size = size + #line + 1
    end
    post()
end

local function flush()
    scheduled = false
    if #buffer == 0 then return end
    local lines = buffer
    buffer = {}
    send(lines)
end

local function license(source)
    for _, id in ipairs(GetPlayerIdentifiers(source) or {}) do
        if id:sub(1, 8) == 'license:' then return id:sub(9, 20) end
    end
    return '-'
end

-- RP.log('me', 12, 'Max Muster', 'öffnet den Kofferraum') → "[14:03:21] /me Max Muster (12, 1a2b3c4d5e6f): öffnet …"
function RP.log(kind, source, name, text)
    local console = ServerConfig.ConsoleLog == true
    if not console and not webhookUrl() then return end
    local who = source == 0 and 'Console' or ('%s (%s, %s)'):format(name, source, license(source))
    local line = ('[%s] /%s %s: %s'):format(os.date('%H:%M:%S'), kind, who, text)
    if console then print('^5[pepper_rpcommands]^7 ' .. line) end
    if not webhookUrl() then return end
    buffer[#buffer + 1] = line
    if not scheduled then
        scheduled = true
        SetTimeout(FLUSH_MS, flush)
    end
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then flush() end
end)
