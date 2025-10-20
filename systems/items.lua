ItemSystem = {}
ItemSystem.Definitions = Config.ItemDefinitions or {}
ItemSystem.WorldItems = {}
ItemSystem.EquippedVisuals = {}
ItemSystem.NextInstanceId = 1
ItemSystem.PickupRadius = Config.ItemPickupRadius or 24
ItemSystem.GroundSpawns = Config.ItemGroundSpawns or {}

local function cloneBonuses(source)
    if not source then return {} end
    return table.deepCopy(source)
end

function ItemSystem.getDefinition(itemId)
    return ItemSystem.Definitions[itemId]
end

function ItemSystem.getDisplayName(playerId, itemId)
    local def = ItemSystem.getDefinition(itemId)
    if not def then
        return itemId
    end
    if def.nameKey then
        return Lang.get(playerId, def.nameKey)
    end
    return def.name or itemId
end

function ItemSystem.spawnGroundItem(itemId, x, y, quantity)
    local def = ItemSystem.getDefinition(itemId)
    if not def then return nil end

    quantity = math.max(1, quantity or 1)

    local instanceId = ItemSystem.NextInstanceId
    ItemSystem.NextInstanceId = ItemSystem.NextInstanceId + 1

    local imageId
    if def.groundSprite then
        imageId = image(def.groundSprite, x, y, 1)
        imagealpha(imageId, 1)
        imageblend(imageId, 1)
    end

    ItemSystem.WorldItems[instanceId] = {
        itemId = itemId,
        quantity = quantity,
        x = x,
        y = y,
        imageId = imageId
    }

    return instanceId
end

function ItemSystem.removeGroundItem(instanceId)
    local groundItem = ItemSystem.WorldItems[instanceId]
    if not groundItem then return end

    if groundItem.imageId then
        freeimage(groundItem.imageId)
    end

    ItemSystem.WorldItems[instanceId] = nil
end

local function addToInventory(playerId, itemId, quantity)
    local def = ItemSystem.getDefinition(itemId)
    local name = ItemSystem.getDisplayName(playerId, itemId)
    local bonuses = cloneBonuses(def and def.bonuses)
    local itemType = (def and def.type) or "misc"
    local stackable = def and (def.stackable ~= false) or true

    return InventorySystem.addItem(
        playerId,
        itemId,
        name,
        quantity,
        itemType,
        stackable,
        bonuses
    )
end

function ItemSystem.tryPickup(playerId, instanceId)
    local groundItem = ItemSystem.WorldItems[instanceId]
    if not groundItem then return false end

    if addToInventory(playerId, groundItem.itemId, groundItem.quantity) then
        ItemSystem.removeGroundItem(instanceId)
        return true
    end

    return false
end

function ItemSystem.tryPickupNearby(playerId)
    local px = player(playerId, "x")
    local py = player(playerId, "y")

    for instanceId, data in pairs(ItemSystem.WorldItems) do
        local dx = px - data.x
        local dy = py - data.y
        local distance = math.sqrt(dx * dx + dy * dy)
        if distance <= ItemSystem.PickupRadius then
            if ItemSystem.tryPickup(playerId, instanceId) then
                break
            end
        end
    end
end

function ItemSystem.giveItem(playerId, itemId, quantity)
    return addToInventory(playerId, itemId, math.max(1, quantity or 1))
end

local function ensureVisualStore(playerId)
    if not ItemSystem.EquippedVisuals[playerId] then
        ItemSystem.EquippedVisuals[playerId] = {}
    end
    return ItemSystem.EquippedVisuals[playerId]
end

function ItemSystem.clearEquipmentVisual(playerId, slotKey)
    local visuals = ItemSystem.EquippedVisuals[playerId]
    if not visuals then return end

    local slotVisual = visuals[slotKey]
    if slotVisual and slotVisual.imageId then
        freeimage(slotVisual.imageId)
    end

    visuals[slotKey] = nil
end

function ItemSystem.updateEquipmentVisual(playerId, slotKey)
    local visuals = ItemSystem.EquippedVisuals[playerId]
    if not visuals then return end

    local slotVisual = visuals[slotKey]
    if not slotVisual or not slotVisual.imageId then return end

    if player(playerId, "exists") == 0 then return end

    local px = player(playerId, "x")
    local py = player(playerId, "y")
    local offset = slotVisual.offset or { x = 0, y = 0 }

    imagepos(slotVisual.imageId, px + (offset.x or 0), py + (offset.y or 0), 0)
end

function ItemSystem.applyEquipmentVisual(playerId, slotKey, itemId)
    ItemSystem.clearEquipmentVisual(playerId, slotKey)

    local def = ItemSystem.getDefinition(itemId)
    if not def or not def.equippedSprite then return end

    if player(playerId, "exists") == 0 then return end

    local px = player(playerId, "x")
    local py = player(playerId, "y")

    local imageId = image(def.equippedSprite, px, py, 3)
    imagealpha(imageId, 1)
    imageblend(imageId, 1)

    local visuals = ensureVisualStore(playerId)
    visuals[slotKey] = {
        imageId = imageId,
        offset = def.equippedOffset or { x = 0, y = 0 }
    }

    ItemSystem.updateEquipmentVisual(playerId, slotKey)
end

function ItemSystem.clearAllVisuals(playerId)
    local visuals = ItemSystem.EquippedVisuals[playerId]
    if not visuals then return end

    for slotKey, slotVisual in pairs(visuals) do
        if slotVisual.imageId then
            freeimage(slotVisual.imageId)
        end
        visuals[slotKey] = nil
    end
end

function ItemSystem.restoreEquipmentVisuals(playerId)
    local data = PLAYER_DATA[playerId]
    if not data or not data.equipment then return end

    for slotKey, item in pairs(data.equipment) do
        ItemSystem.applyEquipmentVisual(playerId, slotKey, item.itemId)
    end
end

function ItemSystem.refreshPlayerVisuals(playerId)
    if player(playerId, "exists") == 0 then return end

    local visuals = ItemSystem.EquippedVisuals[playerId]
    if not visuals then return end

    for slotKey in pairs(visuals) do
        ItemSystem.updateEquipmentVisual(playerId, slotKey)
    end
end

local function spawnConfiguredItems()
    for _, spawn in ipairs(ItemSystem.GroundSpawns) do
        ItemSystem.spawnGroundItem(spawn.itemId, spawn.x, spawn.y, spawn.quantity)
    end
end

function ItemSystem.onSecond()
    for _, playerId in pairs(player(0, "table")) do
        if player(playerId, "exists") == 1 and player(playerId, "health") > 0 then
            ItemSystem.tryPickupNearby(playerId)
        end
    end
end

function ItemSystem.onMs100()
    for playerId, visuals in pairs(ItemSystem.EquippedVisuals) do
        if player(playerId, "exists") == 1 and player(playerId, "health") > 0 then
            for slotKey in pairs(visuals) do
                ItemSystem.updateEquipmentVisual(playerId, slotKey)
            end
        end
    end
end

addhook("second", "ItemSystem.onSecond")
addhook("ms100", "ItemSystem.onMs100")

spawnConfiguredItems()

return ItemSystem
