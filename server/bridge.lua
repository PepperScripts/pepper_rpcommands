-- Pepper RP-Commands – Brücke zu ESX / QBCore / Qbox: Charaktername und Admin-Rechte. Ohne Framework: FiveM-Name + ACE.
RP = RP or {}

-- Fehlt config_server.lua (z. B. nach einem Update nur mit alter Config), gelten diese Standardwerte.
ServerConfig = ServerConfig or {}
ServerConfig.Filter = ServerConfig.Filter or { mode = 'off', words = {} }
ServerConfig.Admin = ServerConfig.Admin or {
    groups = { 'god', 'superadmin', 'admin', 'mod' },
    commands = { clear = 'rpclear', mute = 'rpmute', unmute = 'rpunmute' },
    defaultMuteMinutes = 30,
}

local esx, qbcore

-- Frameworks erst beim ersten Bedarf holen: sie starten oft nach dieser Ressource.
local function getESX()
    if esx then return esx end
    if GetResourceState('es_extended') ~= 'started' then return nil end
    local ok, object = pcall(function() return exports.es_extended:getSharedObject() end)
    if ok and object then esx = object end
    return esx
end

local function getQBCore()
    if qbcore then return qbcore end
    if GetResourceState('qb-core') ~= 'started' then return nil end
    local ok, object = pcall(function() return exports['qb-core']:GetCoreObject() end)
    if ok and object then qbcore = object end
    return qbcore
end

local function fullName(first, last)
    if type(first) ~= 'string' or first == '' then return nil end
    if type(last) == 'string' and last ~= '' then return first .. ' ' .. last end
    return first
end

local function characterName(source)
    -- Qbox
    if GetResourceState('qbx_core') == 'started' then
        local ok, name = pcall(function()
            local player = exports.qbx_core:GetPlayer(source)
            local info = player and player.PlayerData and player.PlayerData.charinfo
            return info and fullName(info.firstname, info.lastname)
        end)
        if ok and name then return name end
    end
    -- QBCore
    local qb = getQBCore()
    if qb then
        local ok, name = pcall(function()
            local player = qb.Functions.GetPlayer(source)
            local info = player and player.PlayerData and player.PlayerData.charinfo
            return info and fullName(info.firstname, info.lastname)
        end)
        if ok and name then return name end
    end
    -- ESX
    local object = getESX()
    if object then
        local ok, name = pcall(function()
            local xPlayer = object.GetPlayerFromId(source)
            if not xPlayer then return nil end
            if xPlayer.getName then return xPlayer.getName() end
            return xPlayer.name
        end)
        if ok and type(name) == 'string' and name ~= '' then return name end
    end
    return nil
end

-- Name für Chat-Zeile und Protokoll (ungefiltert – wird in main.lua bereinigt).
function RP.rawName(source)
    if type(Config.GetName) == 'function' then
        local ok, name = pcall(Config.GetName, source)
        if ok and type(name) == 'string' and name ~= '' then return name end
    elseif Config.NameMode ~= 'fivem' then
        local name = characterName(source)
        if name then return name end
    end
    return GetPlayerName(source) or ('#' .. tostring(source))
end

local function esxGroup(source)
    local object = getESX()
    if not object then return nil end
    local ok, group = pcall(function()
        local xPlayer = object.GetPlayerFromId(source)
        return xPlayer and xPlayer.getGroup and xPlayer.getGroup() or nil
    end)
    return ok and group or nil
end

local function qbHasPermission(source, permission)
    local qb = getQBCore()
    if not qb or not qb.Functions or not qb.Functions.HasPermission then return false end
    local ok, allowed = pcall(qb.Functions.HasPermission, source, permission)
    return ok and allowed == true
end

-- source 0 = Server-Konsole, darf alles.
function RP.isAdmin(source)
    if source == 0 then return true end
    if IsPlayerAceAllowed(source, 'pepperrp.admin') then return true end
    local group = esxGroup(source)
    for _, name in ipairs(ServerConfig.Admin.groups or {}) do
        -- Qbox und neuere QBCore-Versionen vergeben die Gruppen als ACE (admin, mod, god)
        if group == name or IsPlayerAceAllowed(source, name) or qbHasPermission(source, name) then
            return true
        end
    end
    return false
end
