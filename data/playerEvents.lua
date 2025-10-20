-- Oyuncu servera katildiginda
addhook("join", "onPlayerJoin")
function onPlayerJoin(id)
    PlayerDataService.load(id)
    sendMessage(id, "info", Lang.get(id, "welcome"))
    if MarketSystem and MarketSystem.onPlayerLoad then
        MarketSystem.onPlayerLoad(id)
    end
    if StatusSystem and StatusSystem.setStatus then
        StatusSystem.setStatus(id, PLAYER_DATA[id].status or Config.DefaultMode, true)
    end
    if ItemSystem and ItemSystem.restoreEquipmentVisuals then
        ItemSystem.restoreEquipmentVisuals(id)
    end
end

-- Oyuncu serverdan ayrildiginda
addhook("leave", "onPlayerLeave")
function onPlayerLeave(id)
    -- Cikarken anlik pozisyon kaydediyoruz
    local data = PLAYER_DATA[id]
    if data then
        data.position = {
            x = player(id, "x"),
            y = player(id, "y")
        }
        PlayerDataService.save(id)
        PlayerDataService.remove(id)
    end
    if ItemSystem and ItemSystem.clearAllVisuals then
        ItemSystem.clearAllVisuals(id)
    end
end

-- Oyuncu spawn oldugunda pozisyonuna isinliyoruz
addhook("spawn", "onPlayerSpawn")
function onPlayerSpawn(id)
    local data = PLAYER_DATA[id]
    if not data or not data.position then return end

    local x = data.position.x
    local y = data.position.y

    if x and y then
        parse("setpos " .. id .. " " .. x .. " " .. y)
    end

    applyStats(id)
    if ItemSystem and ItemSystem.refreshPlayerVisuals then
        ItemSystem.refreshPlayerVisuals(id)
    end
end

function applyStats(id)
    local data = PLAYER_DATA[id]
    if not data then return end

    local bonuses = EquipmentSystem and EquipmentSystem.getTotalBonuses(data) or {}

    local hpStat = (data.stats.hp or 0) + (bonuses.hp or 0)
    -- HP etkisi
    local baseHealth = 100
    local extraHealth = hpStat * 6.25
    parse("setmaxhealth " .. id .. " " .. math.floor(baseHealth + extraHealth))

    -- Speed etkisi
    local speedStat = (data.stats.speed or 0) + (bonuses.speed or 0)
    local baseSpeed = (Config.BASE_SPEED or 100) + speedStat
    parse("speedmod " .. id .. " " .. math.floor(baseSpeed))
end
