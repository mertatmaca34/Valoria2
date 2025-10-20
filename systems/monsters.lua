MonsterSystem = {}
MonsterSystem.Definitions = Config.MonsterDefinitions or {}
MonsterSystem.Spawns = {}
MonsterSystem.Active = {}
MonsterSystem.RespawnQueue = {}
MonsterSystem.AttackRange = Config.MonsterAttackRange or 36
MonsterSystem.RespawnDelay = Config.MonsterRespawnTime or 18
MonsterSystem.BasePlayerAttack = Config.BasePlayerAttack or 5

math.randomseed(os.time())

local function registerSpawns()
    for _, spawn in ipairs(Config.MonsterSpawns or {}) do
        if spawn.spawnId and spawn.monsterId then
            MonsterSystem.Spawns[spawn.spawnId] = spawn
        end
    end
end

local function createMonster(spawnId, spawnCfg)
    local def = MonsterSystem.Definitions[spawnCfg.monsterId]
    if not def then return end

    local imageId
    if def.sprite then
        imageId = image(def.sprite, spawnCfg.x, spawnCfg.y, 1)
        imagealpha(imageId, 1)
        imageblend(imageId, 1)
    end

    MonsterSystem.Active[spawnId] = {
        spawnId = spawnId,
        defId = spawnCfg.monsterId,
        health = def.maxHealth or 50,
        maxHealth = def.maxHealth or 50,
        position = { x = spawnCfg.x, y = spawnCfg.y },
        imageId = imageId
    }
end

local function freeMonsterVisual(monster)
    if monster and monster.imageId then
        freeimage(monster.imageId)
    end
end

function MonsterSystem.spawn(spawnId)
    local spawnCfg = MonsterSystem.Spawns[spawnId]
    if not spawnCfg then return end

    freeMonsterVisual(MonsterSystem.Active[spawnId])
    MonsterSystem.Active[spawnId] = nil

    createMonster(spawnId, spawnCfg)
end

local function queueRespawn(spawnId)
    local spawnCfg = MonsterSystem.Spawns[spawnId]
    if not spawnCfg then return end

    MonsterSystem.RespawnQueue[spawnId] = spawnCfg.respawn or MonsterSystem.RespawnDelay
end

local function getMonsterName(playerId, monster)
    local def = MonsterSystem.Definitions[monster.defId]
    if def and def.nameKey then
        return Lang.get(playerId, def.nameKey)
    end
    return monster.defId
end

local function getPlayerAttackValue(playerId)
    local data = PLAYER_DATA[playerId]
    if not data then return MonsterSystem.BasePlayerAttack end

    local total = MonsterSystem.BasePlayerAttack + (data.stats.attack or 0)

    if data.equipment then
        for _, item in pairs(data.equipment) do
            if item.bonuses and item.bonuses.attack then
                total = total + item.bonuses.attack
            end
        end
    end

    return total
end

local function findNearestMonster(playerId)
    if player(playerId, "exists") == 0 then return nil end

    local px = player(playerId, "x")
    local py = player(playerId, "y")

    local nearestId
    local nearestDistance = MonsterSystem.AttackRange + 1

    for spawnId, monster in pairs(MonsterSystem.Active) do
        if monster.health > 0 then
            local pos = monster.position
            local dx = px - pos.x
            local dy = py - pos.y
            local distance = math.sqrt(dx * dx + dy * dy)
            if distance <= MonsterSystem.AttackRange and distance < nearestDistance then
                nearestDistance = distance
                nearestId = spawnId
            end
        end
    end

    if nearestId then
        return nearestId, MonsterSystem.Active[nearestId]
    end

    return nil
end

local function dropLoot(monster, killerId)
    local def = MonsterSystem.Definitions[monster.defId]
    if not def or not def.drops then return end

    for _, drop in ipairs(def.drops) do
        if math.random(1, 100) <= (drop.chance or 0) then
            local quantity
            if drop.min and drop.max then
                quantity = math.random(drop.min, drop.max)
            else
                quantity = drop.quantity or 1
            end

            ItemSystem.spawnGroundItem(drop.itemId, monster.position.x, monster.position.y, quantity)
            local itemName = ItemSystem.getDisplayName(killerId, drop.itemId)
            sendMessage(killerId, "success", Lang.get(killerId, "monster_loot_drop") .. " " .. itemName .. " x" .. quantity)
        end
    end
end

local function rewardPlayer(monster, killerId)
    local def = MonsterSystem.Definitions[monster.defId]
    if not def then return end

    local name = getMonsterName(killerId, monster)

    if def.exp and def.exp > 0 and CombatSystem and CombatSystem.addExperience then
        CombatSystem.addExperience(killerId, def.exp)
    end

    if def.gold and def.gold > 0 and CombatSystem and CombatSystem.addGold then
        CombatSystem.addGold(killerId, def.gold)
    end

    sendMessage(killerId, "info", Lang.get(killerId, "monster_defeated") .. " " .. name)

    if QuestSystem and QuestSystem.onMonsterKilled then
        QuestSystem.onMonsterKilled(killerId, monster.defId)
    end
end

local function handleMonsterDeath(spawnId, monster, killerId)
    freeMonsterVisual(monster)
    MonsterSystem.Active[spawnId] = nil
    queueRespawn(spawnId)
    rewardPlayer(monster, killerId)
    dropLoot(monster, killerId)
end

local function applyDamage(spawnId, monster, damage, killerId)
    if not monster then return end

    monster.health = math.max(0, monster.health - damage)

    if monster.health <= 0 then
        handleMonsterDeath(spawnId, monster, killerId)
    else
        sendMessage(killerId, "info", Lang.get(killerId, "monster_damaged") .. " " .. damage)
    end
end

function MonsterSystem.onAttack(playerId)
    local spawnId, monster = findNearestMonster(playerId)
    if not spawnId or not monster then return end

    local def = MonsterSystem.Definitions[monster.defId]
    if not def then return end

    StatusSystem.enterCombat(playerId)

    local attackValue = getPlayerAttackValue(playerId)
    local defense = def.defense or 0
    local damage = math.max(1, attackValue - defense)

    applyDamage(spawnId, monster, damage, playerId)
end

function MonsterSystem.onSecond()
    for spawnId, time in pairs(MonsterSystem.RespawnQueue) do
        time = time - 1
        if time <= 0 then
            MonsterSystem.RespawnQueue[spawnId] = nil
            MonsterSystem.spawn(spawnId)
        else
            MonsterSystem.RespawnQueue[spawnId] = time
        end
    end
end

function MonsterSystem.cleanup()
    for spawnId, monster in pairs(MonsterSystem.Active) do
        freeMonsterVisual(monster)
        MonsterSystem.Active[spawnId] = nil
    end
    MonsterSystem.RespawnQueue = {}
end

addhook("attack", "MonsterSystem.onAttack")
addhook("second", "MonsterSystem.onSecond")

registerSpawns()

for spawnId in pairs(MonsterSystem.Spawns) do
    MonsterSystem.spawn(spawnId)
end

return MonsterSystem
