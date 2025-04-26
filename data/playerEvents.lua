-- Oyuncu servera katıldığında
addhook("join", "onPlayerJoin")
function onPlayerJoin(id)
    PlayerDataService.load(id)
    sendMessage(id, "info", Lang.get(id, "welcome"))
end

-- Oyuncu serverdan ayrıldığında
addhook("leave", "onPlayerLeave")
function onPlayerLeave(id)
    -- Çıkarken anlık pozisyon kaydediyoruz
    local data = PLAYER_DATA[id]
    if data then
        data.position = {
            x = player(id, "x"),
            y = player(id, "y")
        }
        PlayerDataService.save(id)
        PlayerDataService.remove(id)
    end
end

-- Oyuncu spawn olduğunda pozisyonuna ışınlıyoruz
addhook("spawn", "onPlayerSpawn")
function onPlayerSpawn(id)
    local data = PLAYER_DATA[id]
    if not data or not data.position then return end

    local x = data.position.x
    local y = data.position.y

    if x and y then
        parse("setpos " .. id .. " " .. x .. " " .. y)
    end
end
