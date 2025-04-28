PlayerDataService = {}

PLAYER_DATA = {}

-- Oyuncunun dosya anahtarını oluşturur
function PlayerDataService.getPlayerKey(id)
    local usgnid = player(id, "usgn")
    local steamid = player(id, "steamid")
    
    if usgnid ~= 0 then
        return "usgn_" .. usgnid
    elseif steamid ~= 0 then
        return "steam_" .. steamid
    else
        return nil
    end
end

-- Varsayılan oyuncu datası oluşturur
function PlayerDataService.createDefault()
    return {
        level = 1,
        exp = 0,
        stats = table.deepCopy(Config.DefaultStats),
        statPoints = 0,
        gold = Config.DefaultGold,
        inventory = {},
        equipment = {},
        quests = {},
        depot = {},
        pazar = {},
        status = Config.DefaultMode,
        position = { x = Config.DefaultSpawnX, y = Config.DefaultSpawnY },
        invCapacity = Config.DefaultInventoryCapacity,
        depotUnlocked = Config.DefaultDepotUnlocked,
        lang = Config.DefaultLanguage
    }
end

-- Veriyi yükler veya oluşturur
function PlayerDataService.load(id)
    local key = PlayerDataService.getPlayerKey(id)
    if not key then
        print("[Valoria] Failed to get player key for id: " .. id)
        return
    end
    local path = "sys/lua/Valoria2/database/players/" .. key .. ".lua"
    if fileExists(path) then
        PLAYER_DATA[id] = dofile(path)
    else
        PLAYER_DATA[id] = PlayerDataService.createDefault()
    end

    Lang.setPlayerLang(id, PLAYER_DATA[id].lang or Config.DefaultLanguage)
end

-- Veriyi kaydeder
function PlayerDataService.save(id)
    local data = PLAYER_DATA[id]
    if not data then return end

    local key = PlayerDataService.getPlayerKey(id)
    if not key then
        print("[Valoria] Failed to get player key for save id: " .. id)
        return
    end

    local path = "sys/lua/Valoria2/database/players/" .. key .. ".lua"
    table.save(data, path)
end

-- Oyuncu verisini memoryden temizler
function PlayerDataService.remove(id)
    PLAYER_DATA[id] = nil
    Lang.removePlayer(id)
end
