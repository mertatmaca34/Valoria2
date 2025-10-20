function openStatsMenu(id)
    local data = PLAYER_DATA[id]
    if not data then return end

    local stats = data.stats
    local points = data.statPoints or 0

    -- Menu Basligi
    local title = Lang.get(id, "menu_stats") .. " [" .. points .. " pts]"

    -- Menu Secenekleri
    local options = {
        Lang.get(id, "stat_hp") .. "|" .. (stats.hp or 0),
        Lang.get(id, "stat_attack") .. "|" .. (stats.attack or 0),
        Lang.get(id, "stat_defense") .. "|" .. (stats.defense or 0),
        Lang.get(id, "stat_speed") .. "|" .. (stats.speed or 0),
        Lang.get(id, "stat_crit") .. "|" .. (stats.crit or 0),
        "", -- bos satir
        Lang.get(id, "remaining_points") .. ": " .. points
    }

    MenuPager.menuFromTable(id, title, options)
end

-- Menude bir seye tiklayinca (istatistik secilince)
addhook("menu", "onStatsMenuClick")
function onStatsMenuClick(id, title, button)
    if not string.find(title, Lang.get(id, "menu_stats")) then return end
    if button >= 1 and button <= 5 then -- sadece 1-5 arasi statlar
        upgradeStat(id, button)
    end
end

function upgradeStat(id, button)
    local data = PLAYER_DATA[id]
    if not data then return end

    local points = data.statPoints or 0
    if points <= 0 then
        sendMessage(id, "warning", Lang.get(id, "no_stat_point"))
        return
    end

    local statKeys = { "hp", "attack", "defense", "speed", "crit" }
    local key = statKeys[button]

    local current = data.stats[key] or 0
    if current >= 24 then
        sendMessage(id, "warning", Lang.get(id, "max_stat_limit"))
        return
    end

    -- Stati arttir
    data.stats[key] = current + 1
    data.statPoints = points - 1

    PlayerDataService.save(id)

    sendMessage(id, "success", Lang.get(id, "stat_upgraded") .. " " .. string.upper(key) .. " +1")
    applyStats(id)

    -- Menu guncellensin
    openStatsMenu(id)
end
