Config = {}

-- Oyuncu Baslangic Degerleri
Config.DefaultStats = {
    hp = 0,
    attack = 0,
    defense = 0,
    speed = -10, -- Oyuncular -10 speed ile baslar
    crit = 0
}

Config.DefaultGold = 0
Config.DefaultMode = "idle"
Config.DefaultSpawnX = 100
Config.DefaultSpawnY = 100
Config.DefaultInventoryCapacity = 20
Config.DefaultDepotUnlocked = false

Config.BASE_SPEED = 100
Config.CombatTagDuration = 8 -- saniye
Config.LevelStatReward = 5

-- Market Ayarlari
Config.MarketPriceOptions = {50, 100, 250, 500}
Config.MarketStorageFile = "sys/lua/Valoria2/database/market.lua"

-- Market Ayarları
Config.MarketPriceOptions = {50, 100, 250, 500}
Config.MarketStorageFile = "sys/lua/Valoria2/database/market.lua"

-- Ekipman Slotları
Config.EquipmentSlots = {
    weapon = { nameKey = "equip_slot_weapon", type = "weapon" },
    armor = { nameKey = "equip_slot_armor", type = "armor" },
    accessory = { nameKey = "equip_slot_accessory", type = "accessory" }
}

-- Durumlar
Config.Statuses = {
    idle = { nameKey = "status_idle", descriptionKey = "status_idle_desc" },
    trade = { nameKey = "status_trade", descriptionKey = "status_trade_desc" },
    afk = { nameKey = "status_afk", descriptionKey = "status_afk_desc" },
    combat = { nameKey = "status_combat", descriptionKey = "status_combat_desc", locked = true }
}

-- Gorev Ayarlari
Config.QuestDefinitions = {
    first_steps = {
        id = "first_steps",
        nameKey = "quest_first_steps_name",
        descriptionKey = "quest_first_steps_desc",
        requirementTextKey = "quest_first_steps_requirement",
        type = "kill",
        target = "player",
        amount = 5,
        reward = { exp = 150, gold = 50 },
        completionMessageKey = "quest_first_steps_complete"
    },
    healer_help = {
        id = "healer_help",
        nameKey = "quest_healer_help_name",
        descriptionKey = "quest_healer_help_desc",
        requirementTextKey = "quest_healer_help_requirement",
        type = "collect",
        amount = 3,
        targetItemId = "herb_green",
        reward = {
            exp = 80,
            gold = 30,
            item = {
                itemId = "potion_small",
                nameKey = "item_small_potion",
                quantity = 1,
                type = "consumable",
                stackable = true,
                bonuses = { heal = 35 }
            }
        },
        completionMessageKey = "quest_healer_help_complete"
    }
}

-- Dil Ayarlari
Config.DefaultLanguage = "en"
