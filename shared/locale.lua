-- Lädt die Texte aus locales/<Sprache>.json; fehlende Schlüssel fallen auf Englisch zurück.
local function load(lang)
    local raw = LoadResourceFile(GetCurrentResourceName(), ('locales/%s.json'):format(lang))
    return raw and json.decode(raw) or nil
end

local fallback = load('en') or {}
local strings = load(Config.Locale or 'en') or fallback

-- L('key', { name = 'Max' }) ersetzt {name} im Text.
function L(key, vars)
    local text = strings[key] or fallback[key] or key
    if vars then
        text = text:gsub('{(%w+)}', function(name)
            local value = vars[name]
            return value ~= nil and tostring(value) or nil
        end)
    end
    return text
end
