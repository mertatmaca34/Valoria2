-- Core Modüller
dofile("sys/lua/Valoria2/core/utils.lua")
dofile("sys/lua/Valoria2/core/colors.lua")
dofile("sys/lua/Valoria2/core/lang.lua")
dofile("sys/lua/Valoria2/core/menu.lua")

-- Config
dofile("sys/lua/Valoria2/config.lua") -- <--- CONFIG'İ ÖNCE YÜKLE

-- Dil Paketleri
dofile("sys/lua/Valoria2/lang/en.lua")
dofile("sys/lua/Valoria2/lang/tr.lua")

-- Data işlemleri
dofile("sys/lua/Valoria2/data/playerDataService.lua") -- <--- config yüklenince artık hata vermez
dofile("sys/lua/Valoria2/data/playerEvents.lua")

-- Sistemler
dofile("sys/lua/Valoria2/systems/menu.lua")
dofile("sys/lua/Valoria2/systems/stats.lua")
dofile("sys/lua/Valoria2/systems/status.lua")
dofile("sys/lua/Valoria2/systems/inventory.lua")
dofile("sys/lua/Valoria2/systems/equipment.lua")
dofile("sys/lua/Valoria2/systems/quests.lua")
dofile("sys/lua/Valoria2/systems/combat.lua")
dofile("sys/lua/Valoria2/systems/market.lua")