StatusSystem = {}
StatusSystem.ActiveMenus = {}
StatusSystem.CombatTimers = {}

local function ensureData(id)
    local data = PLAYER_DATA[id]
    if not data then return nil end
    data.status = data.status or Config.DefaultMode
    return data
end

function StatusSystem.getStatus(id)
    local data = ensureData(id)
    if not data then return Config.DefaultMode end
    return data.status or Config.DefaultMode
end

local function isLocked(statusKey)
    local cfg = Config.Statuses[statusKey]
    return cfg and cfg.locked
end

function StatusSystem.setStatus(id, statusKey, silent)
    local data = ensureData(id)
    if not data then return end

    if not Config.Statuses[statusKey] then
        sendMessage(id, "warning", Lang.get(id, "status_not_found"))
        return
    end

    if data.status == statusKey then
        if not silent then
            sendMessage(id, "info", Lang.get(id, "status_already"))
        end
        return
    end

    data.status = statusKey
    PlayerDataService.save(id)

    if not silent then
        local statusName = Lang.get(id, Config.Statuses[statusKey].nameKey)
        sendMessage(id, "info", Lang.get(id, "status_changed") .. " " .. statusName)
    end
end

function StatusSystem.enterCombat(id)
    local data = ensureData(id)
    if not data then return end

    if StatusSystem.getStatus(id) ~= "combat" then
        StatusSystem.setStatus(id, "combat", true)
        local statusName = Lang.get(id, Config.Statuses["combat"].nameKey)
        sendMessage(id, "warning", Lang.get(id, "status_combat_warning") .. " " .. statusName)
    end

    if StatusSystem.CombatTimers[id] then
        freetimer(StatusSystem.CombatTimers[id])
    end

    StatusSystem.CombatTimers[id] = timer(Config.CombatTagDuration * 1000, "StatusSystem.leaveCombat", id)
end

function StatusSystem.leaveCombat(id)
    StatusSystem.CombatTimers[id] = nil
    local data = ensureData(id)
    if not data then return end

    if data.status == "combat" then
        StatusSystem.setStatus(id, "idle", true)
        sendMessage(id, "info", Lang.get(id, "status_return_idle"))
    end
end

function StatusSystem.openMenu(id)
    local data = ensureData(id)
    if not data then return end

    local title = Lang.get(id, "menu_status")
    local options = {}
    local map = {}

    local keys = {}
    for key in pairs(Config.Statuses) do
        table.insert(keys, key)
    end
    table.sort(keys)

    for _, key in ipairs(keys) do
        local cfg = Config.Statuses[key]
        if not cfg.locked or key == StatusSystem.getStatus(id) then
            local name = Lang.get(id, cfg.nameKey)
            local desc = Lang.get(id, cfg.descriptionKey)
            local prefix = (key == StatusSystem.getStatus(id)) and "* " or ""
            table.insert(options, prefix .. name .. "|" .. desc)
            table.insert(map, { action = "change", status = key })
        end
    end

    StatusSystem.ActiveMenus[id] = {
        title = title,
        map = map
    }

    local menuArg = title
    for _, option in ipairs(options) do
        menuArg = menuArg .. "," .. option
    end
    menu(id, menuArg)
end

addhook("menu", "StatusSystem.onMenuSelect")
function StatusSystem.onMenuSelect(id, title, button)
    local active = StatusSystem.ActiveMenus[id]
    if not active or title ~= active.title then return end

    if button == 0 then
        StatusSystem.ActiveMenus[id] = nil
        return
    end

    local map = active.map[button]
    if not map then return end

    if map.action == "change" then
        if map.status == StatusSystem.getStatus(id) then
            sendMessage(id, "info", Lang.get(id, "status_already"))
        elseif isLocked(map.status) then
            sendMessage(id, "warning", Lang.get(id, "status_locked"))
        else
            StatusSystem.setStatus(id, map.status)
        end
    end
end

function StatusSystem.onPlayerJoin(id)
    StatusSystem.setStatus(id, StatusSystem.getStatus(id), true)
end

function StatusSystem.onPlayerLeave(id)
    if StatusSystem.CombatTimers[id] then
        freetimer(StatusSystem.CombatTimers[id])
    end
    StatusSystem.CombatTimers[id] = nil
    StatusSystem.ActiveMenus[id] = nil
end

addhook("join", "StatusSystem.onPlayerJoin")
addhook("leave", "StatusSystem.onPlayerLeave")

return StatusSystem
