NPCSystem = {}
NPCSystem.Definitions = Config.NPCDefinitions or {}
NPCSystem.NPCs = {}
NPCSystem.InteractionRadius = Config.NPCInteractionRadius or 32

local function spawnNPC(def)
    if not def.position then return end

    local imageId
    if def.sprite then
        imageId = image(def.sprite, def.position.x, def.position.y, 1)
        imagealpha(imageId, 1)
        imageblend(imageId, 1)
    end

    NPCSystem.NPCs[def.id] = {
        def = def,
        imageId = imageId,
        position = def.position
    }
end

function NPCSystem.initialize()
    for id, def in pairs(NPCSystem.Definitions) do
        def.id = def.id or id
        spawnNPC(def)
    end
end

local function getNPCName(playerId, npc)
    if not npc or not npc.def then return "" end
    if npc.def.nameKey then
        return Lang.get(playerId, npc.def.nameKey)
    end
    return npc.def.name or npc.def.id
end

local function getNPCDialogue(playerId, npc)
    if not npc or not npc.def then return "" end
    if npc.def.dialogueKey then
        return Lang.get(playerId, npc.def.dialogueKey)
    end
    return Lang.get(playerId, "npc_generic_dialogue")
end

function NPCSystem.findNearby(playerId)
    if player(playerId, "exists") == 0 then return nil end

    local px = player(playerId, "x")
    local py = player(playerId, "y")

    for _, npc in pairs(NPCSystem.NPCs) do
        local pos = npc.position
        if pos then
            local dx = px - pos.x
            local dy = py - pos.y
            local distance = math.sqrt(dx * dx + dy * dy)
            if distance <= NPCSystem.InteractionRadius then
                return npc
            end
        end
    end

    return nil
end

function NPCSystem.showDialogue(playerId, npc)
    if not npc then return end

    local name = getNPCName(playerId, npc)
    local dialogue = getNPCDialogue(playerId, npc)

    sendMessage(playerId, "info", name .. ": " .. dialogue)
end

function NPCSystem.onUse(playerId)
    local npc = NPCSystem.findNearby(playerId)
    if not npc then return end

    NPCSystem.showDialogue(playerId, npc)
end

function NPCSystem.onSecond()
    -- Placeholder for future behaviors such as animations or patrols
end

addhook("use", "NPCSystem.onUse")
addhook("second", "NPCSystem.onSecond")

NPCSystem.initialize()

return NPCSystem
