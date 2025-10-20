CombatSystem = {}

local function ensureData(id)
    return PLAYER_DATA[id]
end

function CombatSystem.getRequiredExp(level)
    level = math.max(1, level or 1)
    return math.floor(150 * (level ^ 1.2))
end

local function levelUp(id)
    local data = ensureData(id)
    if not data then return end

    data.level = data.level + 1
    data.statPoints = (data.statPoints or 0) + Config.LevelStatReward
    sendMessage(id, "success", Lang.get(id, "combat_level_up") .. " " .. data.level)
    applyStats(id)
end

function CombatSystem.addExperience(id, amount)
    local data = ensureData(id)
    if not data then return end

    amount = math.max(0, amount or 0)
    if amount <= 0 then return end

    data.exp = (data.exp or 0) + amount
    sendMessage(id, "info", Lang.get(id, "combat_exp_gained") .. " " .. amount)

    local required = CombatSystem.getRequiredExp(data.level or 1)
    while data.exp >= required do
        data.exp = data.exp - required
        levelUp(id)
        required = CombatSystem.getRequiredExp(data.level or 1)
    end

    PlayerDataService.save(id)
end

function CombatSystem.addGold(id, amount)
    local data = ensureData(id)
    if not data then return end
    amount = math.max(0, amount or 0)
    if amount <= 0 then return end

    data.gold = (data.gold or 0) + amount
    sendMessage(id, "success", Lang.get(id, "combat_gold_gained") .. " " .. amount)
    PlayerDataService.save(id)
end

function CombatSystem.onHit(attacker, victim, weapon, x, y)
    if attacker > 0 and attacker <= 32 then
        StatusSystem.enterCombat(attacker)
    end
    if victim > 0 and victim <= 32 then
        StatusSystem.enterCombat(victim)
    end
end

function CombatSystem.onKill(killer, victim, weapon, x, y)
    if killer <= 0 or killer > 32 then return end

    local killerData = ensureData(killer)
    if not killerData then return end

    StatusSystem.enterCombat(killer)

    local baseExp = 50
    local baseGold = 20
    local victimLevel = (PLAYER_DATA[victim] and PLAYER_DATA[victim].level) or 1
    local expGain = baseExp + (victimLevel * 10)
    local goldGain = baseGold + math.floor(victimLevel * 5)

    CombatSystem.addExperience(killer, expGain)
    CombatSystem.addGold(killer, goldGain)
end

addhook("hit", "CombatSystem.onHit")
addhook("kill", "CombatSystem.onKill")

return CombatSystem
