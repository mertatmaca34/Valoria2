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

-- Temel Savas ve Hareket Ayarlari
Config.BASE_SPEED = 100
Config.CombatTagDuration = 8 -- saniye
Config.LevelStatReward = 5

-- Market Ayarlari
Config.MarketPriceOptions = {50, 100, 250, 500}
Config.MarketStorageFile = "sys/lua/Valoria2/database/market.lua"

-- Ekipman Slotlari
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

-- Item Ayarlari
Config.ItemPickupRadius = 24
Config.ItemDefinitions = {
    iron_sword = {
        id = "iron_sword",
        nameKey = "item_iron_sword",
        descriptionKey = "item_iron_sword_desc",
        type = "weapon",
        stackable = false,
        bonuses = { attack = 3 },
        groundSprite = "gfx/valoria/items/iron_sword_ground.png",
        equippedSprite = "gfx/valoria/items/iron_sword_equipped.png",
        equippedOffset = { x = 6, y = -2 }
    },
    leather_armor = {
        id = "leather_armor",
        nameKey = "item_leather_armor",
        descriptionKey = "item_leather_armor_desc",
        type = "armor",
        stackable = false,
        bonuses = { defense = 2, hp = 1 },
        groundSprite = "gfx/valoria/items/leather_armor_ground.png",
        equippedSprite = "gfx/valoria/items/leather_armor_equipped.png",
        equippedOffset = { x = 0, y = 6 }
    },
    forest_amulet = {
        id = "forest_amulet",
        nameKey = "item_forest_amulet",
        descriptionKey = "item_forest_amulet_desc",
        type = "accessory",
        stackable = false,
        bonuses = { crit = 2, speed = 1 },
        groundSprite = "gfx/valoria/items/forest_amulet_ground.png",
        equippedSprite = "gfx/valoria/items/forest_amulet_equipped.png",
        equippedOffset = { x = 2, y = -10 }
    },
    potion_small = {
        id = "potion_small",
        nameKey = "item_small_potion",
        descriptionKey = "item_small_potion_desc",
        type = "consumable",
        stackable = true,
        bonuses = { heal = 35 },
        groundSprite = "gfx/valoria/items/potion_small_ground.png",
        equippedSprite = "gfx/valoria/items/potion_small_equipped.png",
        equippedOffset = { x = -4, y = 4 }
    },
    herb_green = {
        id = "herb_green",
        nameKey = "item_herb_green",
        descriptionKey = "item_herb_green_desc",
        type = "material",
        stackable = true,
        bonuses = {},
        groundSprite = "gfx/valoria/items/herb_green_ground.png",
        equippedSprite = "gfx/valoria/items/herb_green_equipped.png",
        equippedOffset = { x = 0, y = 0 }
    },
    wolf_pelt = {
        id = "wolf_pelt",
        nameKey = "item_wolf_pelt",
        descriptionKey = "item_wolf_pelt_desc",
        type = "material",
        stackable = true,
        bonuses = {},
        groundSprite = "gfx/valoria/items/wolf_pelt_ground.png",
        equippedSprite = "gfx/valoria/items/wolf_pelt_equipped.png",
        equippedOffset = { x = 2, y = 6 }
    },
    goblin_ear = {
        id = "goblin_ear",
        nameKey = "item_goblin_ear",
        descriptionKey = "item_goblin_ear_desc",
        type = "material",
        stackable = true,
        bonuses = {},
        groundSprite = "gfx/valoria/items/goblin_ear_ground.png",
        equippedSprite = "gfx/valoria/items/goblin_ear_equipped.png",
        equippedOffset = { x = -2, y = 6 }
    }
}

Config.ItemGroundSpawns = {
    { itemId = "iron_sword", quantity = 1, x = 140, y = 120 },
    { itemId = "leather_armor", quantity = 1, x = 150, y = 128 },
    { itemId = "forest_amulet", quantity = 1, x = 132, y = 136 },
    { itemId = "potion_small", quantity = 2, x = 142, y = 142 },
    { itemId = "herb_green", quantity = 3, x = 118, y = 116 }
}

-- NPC Ayarlari
Config.NPCInteractionRadius = 32
Config.NPCDefinitions = {
    healer = {
        id = "healer",
        nameKey = "npc_healer_name",
        dialogueKey = "npc_healer_dialogue",
        sprite = "gfx/valoria/npcs/healer.png",
        position = { x = 180, y = 140 }
    },
    merchant = {
        id = "merchant",
        nameKey = "npc_merchant_name",
        dialogueKey = "npc_merchant_dialogue",
        sprite = "gfx/valoria/npcs/merchant.png",
        position = { x = 188, y = 148 }
    },
    guard = {
        id = "guard",
        nameKey = "npc_guard_name",
        dialogueKey = "npc_guard_dialogue",
        sprite = "gfx/valoria/npcs/guard.png",
        position = { x = 172, y = 148 }
    }
}

-- Canavar Ayarlari
Config.BasePlayerAttack = 5
Config.MonsterAttackRange = 36
Config.MonsterRespawnTime = 18
Config.MonsterDefinitions = {
    forest_wolf = {
        id = "forest_wolf",
        nameKey = "monster_forest_wolf_name",
        maxHealth = 60,
        attack = 7,
        defense = 2,
        exp = 65,
        gold = 25,
        sprite = "gfx/valoria/monsters/forest_wolf.png",
        drops = {
            { itemId = "wolf_pelt", chance = 60, min = 1, max = 2 },
            { itemId = "herb_green", chance = 25, min = 1, max = 1 }
        }
    },
    cave_goblin = {
        id = "cave_goblin",
        nameKey = "monster_cave_goblin_name",
        maxHealth = 80,
        attack = 9,
        defense = 4,
        exp = 90,
        gold = 40,
        sprite = "gfx/valoria/monsters/cave_goblin.png",
        drops = {
            { itemId = "goblin_ear", chance = 70, min = 1, max = 2 },
            { itemId = "potion_small", chance = 20, min = 1, max = 1 }
        }
    }
}

Config.MonsterSpawns = {
    { spawnId = "forest_wolf_1", monsterId = "forest_wolf", x = 260, y = 220, respawn = 20 },
    { spawnId = "forest_wolf_2", monsterId = "forest_wolf", x = 240, y = 208, respawn = 18 },
    { spawnId = "cave_goblin_1", monsterId = "cave_goblin", x = 300, y = 240, respawn = 24 }
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
