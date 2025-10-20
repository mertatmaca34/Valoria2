InventorySystem = {}
InventorySystem.ActiveMenus = {}
InventorySystem.DetailMenus = {}

local function ensureData(id)
    local data = PLAYER_DATA[id]
    if not data then return nil end

    data.inventory = data.inventory or {}
    data.invCapacity = data.invCapacity or Config.DefaultInventoryCapacity
    return data
end

function InventorySystem.getCapacity(id)
    local data = ensureData(id)
    if not data then return 0 end
    return data.invCapacity or Config.DefaultInventoryCapacity
end

function InventorySystem.getItemCount(id)
    local data = ensureData(id)
    if not data then return 0 end
    return #data.inventory
end

function InventorySystem.addItem(id, itemId, name, quantity, itemType, stackable, bonuses)
    local data = ensureData(id)
    if not data then return false, "no_player" end

    quantity = quantity or 1
    if quantity <= 0 then return false, "invalid_quantity" end

    local inventory = data.inventory
    local capacity = InventorySystem.getCapacity(id)
    stackable = stackable ~= false
    itemType = itemType or "misc"
    bonuses = bonuses or {}

    if stackable then
        for _, item in ipairs(inventory) do
            if item.itemId == itemId then
                item.quantity = item.quantity + quantity
                PlayerDataService.save(id)
                if QuestSystem and QuestSystem.onItemCollected then
                    QuestSystem.onItemCollected(id, itemId, quantity)
                end
                sendMessage(id, "success", Lang.get(id, "inventory_item_added") .. " " .. item.name .. " x" .. quantity)
                return true
            end
        end
    end

    if #inventory >= capacity then
        sendMessage(id, "error", Lang.get(id, "inventory_full"))
        return false, "inventory_full"
    end

    table.insert(inventory, {
        itemId = itemId,
        name = name,
        quantity = quantity,
        type = itemType,
        stackable = stackable,
        bonuses = bonuses
    })

    PlayerDataService.save(id)
    if QuestSystem and QuestSystem.onItemCollected then
        QuestSystem.onItemCollected(id, itemId, quantity)
    end
    sendMessage(id, "success", Lang.get(id, "inventory_item_added") .. " " .. name .. " x" .. quantity)
    return true
end

function InventorySystem.removeItem(id, index, quantity)
    local data = ensureData(id)
    if not data then return false, "no_player" end

    local inventory = data.inventory
    local item = inventory[index]
    if not item then return false, "no_item" end

    quantity = quantity or 1
    if quantity <= 0 then return false, "invalid_quantity" end

    if quantity >= item.quantity then
        table.remove(inventory, index)
    else
        item.quantity = item.quantity - quantity
    end

    PlayerDataService.save(id)
    return true
end

function InventorySystem.findItemById(id, itemId)
    local data = ensureData(id)
    if not data then return nil end
    for index, item in ipairs(data.inventory) do
        if item.itemId == itemId then
            return index, item
        end
    end
    return nil
end

local function getPagedItems(items, page, perPage)
    local startIndex = (page - 1) * perPage + 1
    local result = {}
    for i = startIndex, math.min(startIndex + perPage - 1, #items) do
        table.insert(result, { index = i, item = items[i] })
    end
    return result
end

function InventorySystem.openMenu(id, page)
    local data = ensureData(id)
    if not data then return end

    page = page or 1
    local perPage = 8
    local inventory = data.inventory
    local capacity = InventorySystem.getCapacity(id)
    local totalPages = math.max(1, math.ceil(math.max(#inventory, 1) / perPage))

    if page > totalPages then page = totalPages end

    local title = Lang.get(id, "menu_inventory") .. " [" .. #inventory .. "/" .. capacity .. "]"
    local options = {}
    local map = {}

    if #inventory == 0 then
        table.insert(options, Lang.get(id, "inventory_empty"))
        table.insert(map, { action = "none" })
    else
        for _, entry in ipairs(getPagedItems(inventory, page, perPage)) do
            local item = entry.item
            local bonusText = ""
            if item.bonuses and next(item.bonuses) then
                local bonusParts = {}
                for stat, value in pairs(item.bonuses) do
                    table.insert(bonusParts, string.upper(stat) .. "+" .. value)
                end
                bonusText = " (" .. table.concat(bonusParts, ",") .. ")"
            end
            table.insert(options, item.name .. " x" .. item.quantity .. bonusText)
            table.insert(map, { action = "detail", index = entry.index })
        end
    end

    if page > 1 then
        table.insert(options, Lang.get(id, "menu_prev_page"))
        table.insert(map, { action = "prev", page = page - 1 })
    end

    if page < totalPages then
        table.insert(options, Lang.get(id, "menu_next_page"))
        table.insert(map, { action = "next", page = page + 1 })
    end

    InventorySystem.ActiveMenus[id] = {
        title = title,
        map = map,
        page = page
    }

    local menuArg = title
    for _, option in ipairs(options) do
        menuArg = menuArg .. "," .. option
    end
    menu(id, menuArg)
end

function InventorySystem.openItemDetail(id, index)
    local data = ensureData(id)
    if not data then return end

    local item = data.inventory[index]
    if not item then return end

    local options = { Lang.get(id, "inventory_use_item"), Lang.get(id, "inventory_equip_item"), Lang.get(id, "inventory_drop_item"), Lang.get(id, "menu_back") }
    local title = item.name .. " x" .. item.quantity

    InventorySystem.DetailMenus[id] = {
        title = title,
        index = index
    }

    local menuArg = title
    for _, option in ipairs(options) do
        menuArg = menuArg .. "," .. option
    end

    menu(id, menuArg)
end

function InventorySystem.useItem(id, index)
    local data = ensureData(id)
    if not data then return end

    local item = data.inventory[index]
    if not item then return end

    if item.type ~= "consumable" then
        sendMessage(id, "warning", Lang.get(id, "inventory_cannot_use"))
        return
    end

    local heal = item.bonuses and item.bonuses.heal or 0
    if heal > 0 then
        local current = player(id, "health")
        local max = player(id, "maxhealth")
        local newHealth = math.min(max, current + heal)
        parse("sethealth " .. id .. " " .. newHealth)
        sendMessage(id, "success", Lang.get(id, "inventory_item_used") .. " " .. item.name)
    else
        sendMessage(id, "info", Lang.get(id, "inventory_item_used") .. " " .. item.name)
    end

    InventorySystem.removeItem(id, index, 1)
end

function InventorySystem.dropItem(id, index)
    local data = ensureData(id)
    if not data then return end

    local item = data.inventory[index]
    if not item then return end

    InventorySystem.removeItem(id, index, 1)
    sendMessage(id, "info", Lang.get(id, "inventory_item_dropped") .. " " .. item.name)
end

addhook("menu", "InventorySystem.onMenuSelect")
function InventorySystem.onMenuSelect(id, title, button)
    local active = InventorySystem.ActiveMenus[id]
    if active and title == active.title then
        if button == 0 then
            InventorySystem.ActiveMenus[id] = nil
            return
        end

        local map = active.map[button]
        if not map then return end

        if map.action == "detail" then
            InventorySystem.openItemDetail(id, map.index)
        elseif map.action == "prev" or map.action == "next" then
            InventorySystem.openMenu(id, map.page)
        end
        return
    end

    local detail = InventorySystem.DetailMenus[id]
    if detail and title == detail.title then
        if button == 0 then
            InventorySystem.DetailMenus[id] = nil
            InventorySystem.openMenu(id, InventorySystem.ActiveMenus[id] and InventorySystem.ActiveMenus[id].page or 1)
            return
        end

        if button == 1 then
            InventorySystem.useItem(id, detail.index)
        elseif button == 2 then
            if EquipmentSystem and EquipmentSystem.equipFromInventory then
                EquipmentSystem.equipFromInventory(id, detail.index)
            else
                sendMessage(id, "warning", Lang.get(id, "inventory_cannot_equip"))
            end
        elseif button == 3 then
            InventorySystem.dropItem(id, detail.index)
        end

        InventorySystem.DetailMenus[id] = nil
        InventorySystem.openMenu(id, InventorySystem.ActiveMenus[id] and InventorySystem.ActiveMenus[id].page or 1)
    end
end

return InventorySystem
