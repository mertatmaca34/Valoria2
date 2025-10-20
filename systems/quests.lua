QuestSystem = {}
QuestSystem.ActiveMenus = {}
QuestSystem.DetailMenus = {}
QuestSystem.Definitions = Config.QuestDefinitions or {}

local function ensureData(id)
    local data = PLAYER_DATA[id]
    if not data then return nil end

    data.quests = data.quests or {}
    return data
end

local function getQuestState(playerData, questId)
    playerData.quests[questId] = playerData.quests[questId] or { status = "not_started", progress = 0 }
    return playerData.quests[questId]
end

function QuestSystem.openMenu(id)
    local data = ensureData(id)
    if not data then return end

    local title = Lang.get(id, "menu_quests")
    local options = {}
    local map = {}

    local questIds = {}
    for questId in pairs(QuestSystem.Definitions) do
        table.insert(questIds, questId)
    end
    table.sort(questIds)

    for _, questId in ipairs(questIds) do
        local quest = QuestSystem.Definitions[questId]
        local state = getQuestState(data, questId)
        local statusKey = "quest_status_" .. state.status
        local name = Lang.get(id, quest.nameKey)
        local statusText = Lang.get(id, statusKey)
        table.insert(options, name .. "|" .. statusText)
        table.insert(map, { action = "detail", questId = questId })
    end

    QuestSystem.ActiveMenus[id] = {
        title = title,
        map = map
    }

    local menuArg = title
    for _, option in ipairs(options) do
        menuArg = menuArg .. "," .. option
    end
    menu(id, menuArg)
end

function QuestSystem.openQuestDetail(id, questId)
    local data = ensureData(id)
    if not data then return end

    local quest = QuestSystem.Definitions[questId]
    if not quest then return end

    local state = getQuestState(data, questId)
    local title = Lang.get(id, quest.nameKey)
    local description = Lang.get(id, quest.descriptionKey)
    local requirement = Lang.get(id, quest.requirementTextKey)
    local progress = state.progress or 0
    local goal = quest.amount or 0
    local options = {
        description,
        requirement .. " (" .. progress .. "/" .. goal .. ")"
    }
    local map = {
        { action = "noop" },
        { action = "noop" }
    }

    if state.status == "not_started" then
        table.insert(options, Lang.get(id, "quest_accept"))
        table.insert(map, { action = "accept", questId = questId })
    elseif state.status == "in_progress" then
        table.insert(options, Lang.get(id, "quest_abandon"))
        table.insert(map, { action = "abandon", questId = questId })
    elseif state.status == "ready_to_claim" then
        table.insert(options, Lang.get(id, "quest_claim_reward"))
        table.insert(map, { action = "claim", questId = questId })
    elseif state.status == "completed" then
        table.insert(options, Lang.get(id, "quest_completed"))
        table.insert(map, { action = "noop" })
    end

    table.insert(options, Lang.get(id, "menu_back"))
    table.insert(map, { action = "back" })

    QuestSystem.DetailMenus[id] = {
        title = title,
        questId = questId,
        optionsCount = #options,
        map = map
    }

    local menuArg = title
    for _, option in ipairs(options) do
        menuArg = menuArg .. "," .. option
    end

    menu(id, menuArg)
end

function QuestSystem.acceptQuest(id, questId)
    local data = ensureData(id)
    if not data then return end

    local quest = QuestSystem.Definitions[questId]
    if not quest then return end

    local state = getQuestState(data, questId)
    if state.status ~= "not_started" then
        sendMessage(id, "warning", Lang.get(id, "quest_already_started"))
        return
    end

    state.status = "in_progress"
    state.progress = 0
    PlayerDataService.save(id)
    sendMessage(id, "success", Lang.get(id, "quest_started") .. " " .. Lang.get(id, quest.nameKey))
end

function QuestSystem.abandonQuest(id, questId)
    local data = ensureData(id)
    if not data then return end

    local state = getQuestState(data, questId)
    if state.status ~= "in_progress" then
        sendMessage(id, "warning", Lang.get(id, "quest_cannot_abandon"))
        return
    end

    state.status = "not_started"
    state.progress = 0
    PlayerDataService.save(id)
    sendMessage(id, "info", Lang.get(id, "quest_abandoned"))
end

local function applyReward(id, quest)
    if quest.reward then
        if quest.reward.gold and quest.reward.gold > 0 then
            local data = PLAYER_DATA[id]
            data.gold = (data.gold or 0) + quest.reward.gold
            sendMessage(id, "success", Lang.get(id, "quest_reward_gold") .. " " .. quest.reward.gold)
        end
        if quest.reward.exp and quest.reward.exp > 0 and CombatSystem and CombatSystem.addExperience then
            CombatSystem.addExperience(id, quest.reward.exp)
            sendMessage(id, "success", Lang.get(id, "quest_reward_exp") .. " " .. quest.reward.exp)
        end
        if quest.reward.item then
            local rewardItem = quest.reward.item
            local name = rewardItem.nameKey and Lang.get(id, rewardItem.nameKey) or rewardItem.name or "Item"
            InventorySystem.addItem(
                id,
                rewardItem.itemId,
                name,
                rewardItem.quantity or 1,
                rewardItem.type or "misc",
                rewardItem.stackable ~= false,
                rewardItem.bonuses or {}
            )
        end
    end
end

function QuestSystem.claimReward(id, questId)
    local data = ensureData(id)
    if not data then return end

    local quest = QuestSystem.Definitions[questId]
    if not quest then return end

    local state = getQuestState(data, questId)
    if state.status ~= "ready_to_claim" then
        sendMessage(id, "warning", Lang.get(id, "quest_not_ready"))
        return
    end

    state.status = "completed"
    PlayerDataService.save(id)

    applyReward(id, quest)
    sendMessage(id, "success", Lang.get(id, quest.completionMessageKey or "quest_complete_generic"))
end

function QuestSystem.progress(id, questId, amount)
    local data = ensureData(id)
    if not data then return end

    local quest = QuestSystem.Definitions[questId]
    if not quest then return end

    local state = getQuestState(data, questId)
    if state.status ~= "in_progress" then return end

    state.progress = state.progress + (amount or 1)

    local goal = quest.amount or 0
    if goal > 0 and state.progress > goal then
        state.progress = goal
    end

    if state.progress >= goal and goal > 0 then
        state.status = "ready_to_claim"
        sendMessage(id, "success", Lang.get(id, "quest_ready_to_claim"))
    else
        sendMessage(id, "info", Lang.get(id, "quest_progress_update") .. " " .. state.progress .. "/" .. goal)
    end

    PlayerDataService.save(id)
end

function QuestSystem.onKill(killer, victim)
    if killer <= 0 or killer > 32 then return end
    local data = ensureData(killer)
    if not data then return end

    for questId, quest in pairs(QuestSystem.Definitions) do
        if quest.type == "kill" then
            local state = getQuestState(data, questId)
            if state.status == "in_progress" then
                if not quest.target or quest.target == "player" then
                    QuestSystem.progress(killer, questId, 1)
                end
            end
        end
    end
end

function QuestSystem.onMonsterKilled(id, monsterId)
    local data = ensureData(id)
    if not data then return end

    for questId, quest in pairs(QuestSystem.Definitions) do
        if quest.type == "kill" then
            local state = getQuestState(data, questId)
            if state.status == "in_progress" then
                if quest.target == "monster" then
                    if not quest.targetMonsterId or quest.targetMonsterId == monsterId then
                        QuestSystem.progress(id, questId, 1)
                    end
                elseif quest.target == "any_monster" then
                    QuestSystem.progress(id, questId, 1)
                end
            end
        end
    end
end

function QuestSystem.onItemCollected(id, itemId, amount)
    local data = ensureData(id)
    if not data then return end

    for questId, quest in pairs(QuestSystem.Definitions) do
        if quest.type == "collect" and quest.targetItemId == itemId then
            local state = getQuestState(data, questId)
            if state.status == "in_progress" then
                QuestSystem.progress(id, questId, amount)
            end
        end
    end
end

addhook("kill", "QuestSystem.onKill")

addhook("menu", "QuestSystem.onMenuSelect")
function QuestSystem.onMenuSelect(id, title, button)
    local active = QuestSystem.ActiveMenus[id]
    if active and title == active.title then
        if button == 0 then
            QuestSystem.ActiveMenus[id] = nil
            return
        end

        local map = active.map[button]
        if not map then return end

        if map.action == "detail" then
            QuestSystem.openQuestDetail(id, map.questId)
        end
        return
    end

    local detail = QuestSystem.DetailMenus[id]
    if detail and title == detail.title then
        if button == 0 then
            QuestSystem.DetailMenus[id] = nil
            QuestSystem.openMenu(id)
            return
        end

        local quest = QuestSystem.Definitions[detail.questId]
        if not quest then return end

        local action = detail.map and detail.map[button]
        if not action then return end

        if action.action == "back" then
            QuestSystem.DetailMenus[id] = nil
            QuestSystem.openMenu(id)
            return
        end

        local data = ensureData(id)
        local state = getQuestState(data, detail.questId)

        if action.action == "accept" then
            QuestSystem.acceptQuest(id, detail.questId)
        elseif action.action == "abandon" then
            QuestSystem.abandonQuest(id, detail.questId)
        elseif action.action == "claim" then
            QuestSystem.claimReward(id, detail.questId)
        end

        QuestSystem.DetailMenus[id] = nil
        QuestSystem.openQuestDetail(id, detail.questId)
    end
end

return QuestSystem
