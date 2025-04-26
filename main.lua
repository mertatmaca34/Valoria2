-- Core Modüller
dofile("sys/lua/Valoria2/core/colors.lua")
dofile("sys/lua/Valoria2/core/utils.lua")
dofile("sys/lua/Valoria2/core/lang.lua")
dofile("sys/lua/Valoria2/core/menu.lua")

-- Projeye Özel Dil Paketleri
dofile("sys/lua/Valoria2/lang/en.lua")
dofile("sys/lua/Valoria2/lang/tr.lua")

-- Data işlemleri
dofile("sys/lua/Valoria2/data/playerDataService.lua")

-- Sistemler
dofile("sys/lua/Valoria2/systems/menu.lua")
dofile("sys/lua/Valoria2/systems/stats.lua")
dofile("sys/lua/Valoria2/systems/status.lua")
dofile("sys/lua/Valoria2/systems/combat.lua")
dofile("sys/lua/Valoria2/systems/inventory.lua")
dofile("sys/lua/Valoria2/systems/equipment.lua")
dofile("sys/lua/Valoria2/systems/quests.lua")
dofile("sys/lua/Valoria2/systems/market.lua")

-- Default Language
DEFAULT_LANG = "en"

-- Oyuncu oyuna bağlandığında welcome mesajı gönder
addhook("join", "onPlayerJoinWelcome")

function onPlayerJoinWelcome(id)
    if not Lang.PlayerLang[id] then
        Lang.setPlayerLang(id, DEFAULT_LANG)
    end

    sendMessage(id, "info", Lang.get(id, "welcome"))
end
