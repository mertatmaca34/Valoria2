EquipmentSystem = {}
EquipmentSystem.ActiveMenus = {}
EquipmentSystem.SlotMenus = {}

local function ensureData(id)
    local data = PLAYER_DATA[id]
    if not data then return nil end

    data.equipment = data.equipment or {}
    data.equipmentBonuses = data.equipmentBonuses or {}
    return data
end

local function getSlotConfig(slotKey)
    return Config.EquipmentSlots[slotKey]
end

function EquipmentSystem.getEquipped(id, slotKey)
    local data = ensureData(id)
    if not data then return nil end
    return data.equipment[slotKey]
end

function EquipmentSystem.getTotalBonuses(data)
    local bonuses = {}
    if not data or not data.equipment then return bonuses end

    for _, item in pairs(data.equipment) do
        if item and item.bonuses then
            for stat, value in pairs(item.bonuses) do
                bonuses[stat] = (bonuses[stat] or 0) + value
            end
        end
    end

    return bonuses
end

local function applyBonuses(id)
    local data = ensureData(id)
    if not data then return end

    data.equipmentBonuses = EquipmentSystem.getTotalBonuses(data)
    applyStats(id)
end

function EquipmentSystem.equipFromInventory(id, inventoryIndex)
    local data = ensureData(id)
    if not data then return end
    local inventory = data.inventory or {}
    local item = inventory[inventoryIndex]
    if not item then return end

    local slotKey
    for key, slot in pairs(Config.EquipmentSlots) do
        if slot.type == item.type then
            slotKey = key
            break
        end
    end

    if not slotKey then
        sendMessage(id, "warning", Lang.get(id, "equipment_wrong_type"))
        return
    end

    EquipmentSystem.equipItem(id, slotKey, inventoryIndex)
end

function EquipmentSystem.equipItem(id, slotKey, inventoryIndex)
    local data = ensureData(id)
    if not data then return end
    local inventory = data.inventory or {}
    local item = inventory[inventoryIndex]
    if not item then
        sendMessage(id, "warning", Lang.get(id, "equipment_no_item"))
        return
    end

    local slotConfig = getSlotConfig(slotKey)
    if not slotConfig or slotConfig.type ~= item.type then
        sendMessage(id, "warning", Lang.get(id, "equipment_wrong_type"))
        return
    end

    local equipped = data.equipment[slotKey]
    if equipped then
        local restored = InventorySystem.addItem(id, equipped.itemId, equipped.name, 1, equipped.type, false, equipped.bonuses)
        if not restored then
            sendMessage(id, "warning", Lang.get(id, "inventory_full"))
            return
        end
    end

    data.equipment[slotKey] = {
        itemId = item.itemId,
        name = item.name,
        type = item.type,
        bonuses = item.bonuses
    }

    InventorySystem.removeItem(id, inventoryIndex, 1)
    sendMessage(id, "success", Lang.get(id, "equipment_equipped") .. " " .. item.name)
    PlayerDataService.save(id)
    applyBonuses(id)
end

function EquipmentSystem.unequipSlot(id, slotKey)
    local data = ensureData(id)
    if not data then return end
    local equipped = data.equipment[slotKey]
    if not equipped then
        sendMessage(id, "warning", Lang.get(id, "equipment_empty_slot"))
        return
    end

    local success = InventorySystem.addItem(id, equipped.itemId, equipped.name, 1, equipped.type, false, equipped.bonuses)
    if success then
        data.equipment[slotKey] = nil
        sendMessage(id, "info", Lang.get(id, "equipment_unequipped") .. " " .. equipped.name)
        PlayerDataService.save(id)
        applyBonuses(id)
    end
end

function EquipmentSystem.openMenu(id)
    local data = ensureData(id)
    if not data then return end

    local title = Lang.get(id, "menu_equipment")
    local options = {}
    local map = {}

    for slotKey, slotConfig in pairs(Config.EquipmentSlots) do
        local equipped = data.equipment[slotKey]
        local slotName = Lang.get(id, slotConfig.nameKey)
        local value = equipped and equipped.name or Lang.get(id, "equipment_slot_empty")
        table.insert(options, slotName .. " | " .. value)
        table.insert(map, { action = "slot", slot = slotKey })
    end

    EquipmentSystem.ActiveMenus[id] = {
        title = title,
        map = map
    }

    local menuArg = title
    for _, option in ipairs(options) do
        menuArg = menuArg .. "," .. option
    end

    menu(id, menuArg)
end

function EquipmentSystem.openSlotMenu(id, slotKey)
    local data = ensureData(id)
    if not data then return end

    local slotConfig = getSlotConfig(slotKey)
    if not slotConfig then return end

    local slotName = Lang.get(id, slotConfig.nameKey)
    local options = { Lang.get(id, "equipment_choose_item"), Lang.get(id, "equipment_unequip"), Lang.get(id, "menu_back") }

    EquipmentSystem.SlotMenus[id] = {
        title = slotName,
        slot = slotKey
    }

    local menuArg = slotName
    for _, option in ipairs(options) do
        menuArg = menuArg .. "," .. option
    end
    menu(id, menuArg)
end

function EquipmentSystem.openItemSelection(id, slotKey)
    local data = ensureData(id)
    if not data then return end
    local slotConfig = getSlotConfig(slotKey)
    if not slotConfig then return end

    local inventory = data.inventory or {}
    local options = {}
    local map = {}
    local title = Lang.get(id, "equipment_select_for") .. " " .. Lang.get(id, slotConfig.nameKey)

    for index, item in ipairs(inventory) do
        if item.type == slotConfig.type then
            table.insert(options, item.name .. " x" .. item.quantity)
            table.insert(map, { action = "equip", slot = slotKey, index = index })
        end
    end

    if #options == 0 then
        table.insert(options, Lang.get(id, "equipment_no_match"))
        table.insert(map, { action = "none" })
    end

    EquipmentSystem.ActiveMenus[id] = {
        title = title,
        map = map
    }

    local menuArg = title
    for _, option in ipairs(options) do
        menuArg = menuArg .. "," .. option
    end

    menu(id, menuArg)
end

addhook("menu", "EquipmentSystem.onMenuSelect")
function EquipmentSystem.onMenuSelect(id, title, button)
    local slotMenu = EquipmentSystem.SlotMenus[id]
    if slotMenu and title == slotMenu.title then
        if button == 0 or button == 3 then
            EquipmentSystem.SlotMenus[id] = nil
            EquipmentSystem.openMenu(id)
            return
        end

        if button == 1 then
            EquipmentSystem.SlotMenus[id] = nil
            EquipmentSystem.openItemSelection(id, slotMenu.slot)
        elseif button == 2 then
            EquipmentSystem.SlotMenus[id] = nil
            EquipmentSystem.unequipSlot(id, slotMenu.slot)
            EquipmentSystem.openMenu(id)
        end
        return
    end

    local active = EquipmentSystem.ActiveMenus[id]
    if not active or title ~= active.title then return end

    if button == 0 then
        EquipmentSystem.ActiveMenus[id] = nil
        return
    end

    local map = active.map[button]
    if not map then return end

    if map.action == "slot" then
        EquipmentSystem.openSlotMenu(id, map.slot)
    elseif map.action == "equip" then
        EquipmentSystem.equipItem(id, map.slot, map.index)
        EquipmentSystem.openMenu(id)
    end
end

return EquipmentSystem
