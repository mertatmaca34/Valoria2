MarketSystem = {}
MarketSystem.ActiveMenus = {}
MarketSystem.BrowseMenus = {}
MarketSystem.MyMenus = {}
MarketSystem.CreateState = {}

local storageFile = Config.MarketStorageFile or "sys/lua/Valoria2/database/market.lua"

local function loadData()
    if fileExists(storageFile) then
        local ok, data = pcall(dofile, storageFile)
        if ok and type(data) == "table" then
            MarketSystem.Listings = data.listings or {}
            MarketSystem.PendingGold = data.pendingGold or {}
            MarketSystem.NextId = data.nextId or 1
            return
        end
    end

    MarketSystem.Listings = {}
    MarketSystem.PendingGold = {}
    MarketSystem.NextId = 1
end

local function saveData()
    table.save({
        listings = MarketSystem.Listings,
        pendingGold = MarketSystem.PendingGold,
        nextId = MarketSystem.NextId
    }, storageFile)
end

loadData()

local function getPlayerKey(id)
    return PlayerDataService.getPlayerKey(id)
end

local function getPlayerData(id)
    return PLAYER_DATA[id]
end

local function formatListingOption(id, listing)
    local seller = listing.sellerName or "Unknown"
    return string.format("%s x%d - %dG | %s", listing.item.name, listing.quantity, listing.price, seller)
end

function MarketSystem.openMenu(id)
    local title = Lang.get(id, "menu_market")
    local options = {
        Lang.get(id, "market_browse"),
        Lang.get(id, "market_my_listings"),
        Lang.get(id, "market_claim_gold"),
        Lang.get(id, "menu_back")
    }

    MarketSystem.ActiveMenus[id] = {
        title = title,
        mode = "root"
    }

    local menuArg = title
    for _, option in ipairs(options) do
        menuArg = menuArg .. "," .. option
    end
    menu(id, menuArg)
end

function MarketSystem.openBrowse(id, page)
    page = page or 1
    local perPage = 8
    local listings = {}

    for listingId, listing in pairs(MarketSystem.Listings) do
        if listing and listing.quantity > 0 then
            table.insert(listings, {
                id = listingId,
                data = listing
            })
        end
    end

    table.sort(listings, function(a, b)
        return a.id < b.id
    end)

    local totalPages = math.max(1, math.ceil(math.max(#listings, 1) / perPage))
    if page > totalPages then page = totalPages end

    local startIndex = (page - 1) * perPage + 1
    local options = {}
    local map = {}

    for i = startIndex, math.min(startIndex + perPage - 1, #listings) do
        local entry = listings[i]
        table.insert(options, formatListingOption(id, entry.data))
        table.insert(map, { action = "buy", listingId = entry.id })
    end

    if #options == 0 then
        table.insert(options, Lang.get(id, "market_no_listings"))
        table.insert(map, { action = "none" })
    end

    if page > 1 then
        table.insert(options, Lang.get(id, "menu_prev_page"))
        table.insert(map, { action = "prev", page = page - 1 })
    end
    if page < totalPages then
        table.insert(options, Lang.get(id, "menu_next_page"))
        table.insert(map, { action = "next", page = page + 1 })
    end

    table.insert(options, Lang.get(id, "menu_back"))
    table.insert(map, { action = "back" })

    local title = Lang.get(id, "market_browse") .. " [" .. page .. "/" .. totalPages .. "]"
    MarketSystem.BrowseMenus[id] = {
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

local function getPlayerListings(id)
    local key = getPlayerKey(id)
    if not key then return {} end
    local result = {}

    for listingId, listing in pairs(MarketSystem.Listings) do
        if listing.sellerKey == key then
            table.insert(result, { id = listingId, data = listing })
        end
    end

    table.sort(result, function(a, b)
        return a.id < b.id
    end)

    return result
end

function MarketSystem.openMyListings(id)
    local listings = getPlayerListings(id)
    local options = {}
    local map = {}

    for _, entry in ipairs(listings) do
        table.insert(options, formatListingOption(id, entry.data))
        table.insert(map, { action = "remove", listingId = entry.id })
    end

    table.insert(options, Lang.get(id, "market_create_listing"))
    table.insert(map, { action = "create" })

    table.insert(options, Lang.get(id, "menu_back"))
    table.insert(map, { action = "back" })

    local title = Lang.get(id, "market_my_listings")
    MarketSystem.MyMenus[id] = {
        title = title,
        map = map
    }

    local menuArg = title
    for _, option in ipairs(options) do
        menuArg = menuArg .. "," .. option
    end
    menu(id, menuArg)
end

function MarketSystem.openInventorySelection(id)
    local data = getPlayerData(id)
    if not data then return end

    local inventory = data.inventory or {}
    local options = {}
    local map = {}

    for index, item in ipairs(inventory) do
        table.insert(options, item.name .. " x" .. item.quantity)
        table.insert(map, { action = "select_item", index = index })
    end

    if #options == 0 then
        table.insert(options, Lang.get(id, "inventory_empty"))
        table.insert(map, { action = "none" })
    end

    table.insert(options, Lang.get(id, "menu_back"))
    table.insert(map, { action = "back" })

    local title = Lang.get(id, "market_select_item")
    MarketSystem.ActiveMenus[id] = {
        title = title,
        map = map,
        mode = "create",
        stage = "select_item"
    }

    local menuArg = title
    for _, option in ipairs(options) do
        menuArg = menuArg .. "," .. option
    end
    menu(id, menuArg)
end

function MarketSystem.openQuantitySelection(id, index)
    local data = getPlayerData(id)
    if not data then return end
    local item = data.inventory and data.inventory[index]
    if not item then return end

    local maxQuantity = math.min(5, item.quantity)
    local options = {}
    local map = {}

    for i = 1, maxQuantity do
        table.insert(options, Lang.get(id, "market_quantity_option") .. " " .. i)
        table.insert(map, { action = "select_quantity", quantity = i, index = index })
    end

    if item.quantity > maxQuantity then
        table.insert(options, Lang.get(id, "market_quantity_all") .. " (" .. item.quantity .. ")")
        table.insert(map, { action = "select_quantity", quantity = item.quantity, index = index })
    end

    table.insert(options, Lang.get(id, "menu_back"))
    table.insert(map, { action = "back" })

    local title = Lang.get(id, "market_select_quantity")
    MarketSystem.ActiveMenus[id] = {
        title = title,
        map = map,
        mode = "create",
        stage = "select_quantity"
    }

    local menuArg = title
    for _, option in ipairs(options) do
        menuArg = menuArg .. "," .. option
    end
    menu(id, menuArg)
end

function MarketSystem.openPriceSelection(id)
    local options = {}
    local map = {}

    for _, price in ipairs(Config.MarketPriceOptions or {}) do
        table.insert(options, price .. "G")
        table.insert(map, { action = "select_price", price = price })
    end

    table.insert(options, Lang.get(id, "menu_back"))
    table.insert(map, { action = "back" })

    local title = Lang.get(id, "market_select_price")
    MarketSystem.ActiveMenus[id] = {
        title = title,
        map = map,
        mode = "create",
        stage = "select_price"
    }

    local menuArg = title
    for _, option in ipairs(options) do
        menuArg = menuArg .. "," .. option
    end
    menu(id, menuArg)
end

local function resetCreateState(id)
    MarketSystem.CreateState[id] = nil
end

local function ensureCreateState(id)
    MarketSystem.CreateState[id] = MarketSystem.CreateState[id] or {}
    return MarketSystem.CreateState[id]
end

function MarketSystem.createListing(id)
    local state = MarketSystem.CreateState[id]
    if not state or not state.item or not state.price or not state.quantity then return end

    local data = getPlayerData(id)
    if not data then return end

    if data.gold and data.gold < 0 then data.gold = 0 end

    local inventory = data.inventory or {}
    local item = inventory[state.index]
    if not item then
        sendMessage(id, "error", Lang.get(id, "market_item_missing"))
        resetCreateState(id)
        return
    end

    if item.quantity < state.quantity then
        sendMessage(id, "error", Lang.get(id, "market_not_enough_quantity"))
        resetCreateState(id)
        return
    end

    local listingId = MarketSystem.NextId
    MarketSystem.NextId = MarketSystem.NextId + 1

    local sellerKey = getPlayerKey(id)
    MarketSystem.Listings[listingId] = {
        item = state.item,
        quantity = state.quantity,
        price = state.price,
        sellerKey = sellerKey,
        sellerName = player(id, "name")
    }

    InventorySystem.removeItem(id, state.index, state.quantity)
    saveData()
    PlayerDataService.save(id)

    sendMessage(id, "success", Lang.get(id, "market_listing_created"))
    resetCreateState(id)
    MarketSystem.ActiveMenus[id] = nil
    MarketSystem.openMyListings(id)
end

function MarketSystem.removeListing(id, listingId)
    local key = getPlayerKey(id)
    if not key then return end

    local listing = MarketSystem.Listings[listingId]
    if not listing then
        sendMessage(id, "error", Lang.get(id, "market_listing_missing"))
        return
    end

    if listing.sellerKey ~= key then
        sendMessage(id, "error", Lang.get(id, "market_not_owner"))
        return
    end

    local success = InventorySystem.addItem(id, listing.item.itemId, listing.item.name, listing.quantity, listing.item.type, listing.item.stackable, listing.item.bonuses)
    if not success then
        return
    end
    MarketSystem.Listings[listingId] = nil
    saveData()
    PlayerDataService.save(id)
    sendMessage(id, "info", Lang.get(id, "market_listing_removed"))
    MarketSystem.openMyListings(id)
end

function MarketSystem.buyListing(id, listingId)
    local data = getPlayerData(id)
    if not data then return end

    local listing = MarketSystem.Listings[listingId]
    if not listing then
        sendMessage(id, "error", Lang.get(id, "market_listing_missing"))
        return
    end

    local buyerKey = getPlayerKey(id)
    if listing.sellerKey == buyerKey then
        sendMessage(id, "warning", Lang.get(id, "market_cannot_buy_own"))
        return
    end

    data.gold = data.gold or 0
    if data.gold < listing.price then
        sendMessage(id, "error", Lang.get(id, "market_not_enough_gold"))
        return
    end

    local success = InventorySystem.addItem(id, listing.item.itemId, listing.item.name, listing.quantity, listing.item.type, listing.item.stackable, listing.item.bonuses)
    if not success then
        return
    end

    data.gold = data.gold - listing.price
    PlayerDataService.save(id)

    MarketSystem.PendingGold[listing.sellerKey] = (MarketSystem.PendingGold[listing.sellerKey] or 0) + listing.price
    MarketSystem.Listings[listingId] = nil
    saveData()

    sendMessage(id, "success", Lang.get(id, "market_purchase_success"))

    for _, pid in pairs(player(0, "table")) do
        if PlayerDataService.getPlayerKey(pid) == listing.sellerKey then
            sendMessage(pid, "success", Lang.get(pid, "market_item_sold"))
            break
        end
    end

    MarketSystem.openBrowse(id, MarketSystem.BrowseMenus[id] and MarketSystem.BrowseMenus[id].page or 1)
end

function MarketSystem.claimPendingGold(id)
    local key = getPlayerKey(id)
    if not key then return end

    local pending = MarketSystem.PendingGold[key] or 0
    if pending <= 0 then
        sendMessage(id, "info", Lang.get(id, "market_no_pending_gold"))
        return
    end

    local data = getPlayerData(id)
    data.gold = (data.gold or 0) + pending
    MarketSystem.PendingGold[key] = nil
    PlayerDataService.save(id)
    saveData()

    sendMessage(id, "success", Lang.get(id, "market_gold_claimed") .. " " .. pending)
end

function MarketSystem.onPlayerLoad(id)
    local key = getPlayerKey(id)
    if not key then return end

    local pending = MarketSystem.PendingGold[key] or 0
    if pending > 0 then
        local data = getPlayerData(id)
        data.gold = (data.gold or 0) + pending
        MarketSystem.PendingGold[key] = nil
        PlayerDataService.save(id)
        saveData()
        sendMessage(id, "success", Lang.get(id, "market_gold_claimed") .. " " .. pending)
    end
end

addhook("menu", "MarketSystem.onMenuSelect")
function MarketSystem.onMenuSelect(id, title, button)
    local root = MarketSystem.ActiveMenus[id]
    if root and root.mode == "root" and title == root.title then
        if button == 0 then
            MarketSystem.ActiveMenus[id] = nil
            return
        end

        if button == 1 then
            MarketSystem.openBrowse(id, 1)
        elseif button == 2 then
            MarketSystem.openMyListings(id)
        elseif button == 3 then
            MarketSystem.claimPendingGold(id)
        else
            MarketSystem.ActiveMenus[id] = nil
        end
        return
    end

    local browse = MarketSystem.BrowseMenus[id]
    if browse and title == browse.title then
        if button == 0 then
            MarketSystem.BrowseMenus[id] = nil
            return
        end

        local map = browse.map[button]
        if not map then return end

        if map.action == "buy" then
            MarketSystem.buyListing(id, map.listingId)
        elseif map.action == "prev" or map.action == "next" then
            MarketSystem.openBrowse(id, map.page)
        elseif map.action == "back" then
            MarketSystem.BrowseMenus[id] = nil
            MarketSystem.openMenu(id)
        end
        return
    end

    local my = MarketSystem.MyMenus[id]
    if my and title == my.title then
        if button == 0 then
            MarketSystem.MyMenus[id] = nil
            return
        end

        local map = my.map[button]
        if not map then return end

        if map.action == "remove" then
            MarketSystem.removeListing(id, map.listingId)
        elseif map.action == "create" then
            MarketSystem.MyMenus[id] = nil
            MarketSystem.openInventorySelection(id)
        elseif map.action == "back" then
            MarketSystem.MyMenus[id] = nil
            MarketSystem.openMenu(id)
        end
        return
    end

    local menu = MarketSystem.ActiveMenus[id]
    if menu and menu.mode == "create" and title == menu.title then
        if button == 0 then
            MarketSystem.ActiveMenus[id] = nil
            resetCreateState(id)
            MarketSystem.openMyListings(id)
            return
        end

        local map = menu.map and menu.map[button]
        if not map then return end

        if map.action == "select_item" then
            if map.index then
                local data = getPlayerData(id)
                local item = data and data.inventory and data.inventory[map.index]
                if item then
                    local state = ensureCreateState(id)
                    state.index = map.index
                    state.item = {
                        itemId = item.itemId,
                        name = item.name,
                        type = item.type,
                        stackable = item.stackable,
                        bonuses = item.bonuses
                    }
                    MarketSystem.openQuantitySelection(id, map.index)
                end
            end
        elseif map.action == "select_quantity" then
            local state = ensureCreateState(id)
            state.quantity = map.quantity
            MarketSystem.openPriceSelection(id)
        elseif map.action == "select_price" then
            local state = ensureCreateState(id)
            state.price = map.price
            MarketSystem.createListing(id)
        elseif map.action == "back" then
            if menu.stage == "select_price" then
                local state = ensureCreateState(id)
                MarketSystem.openQuantitySelection(id, state.index)
            elseif menu.stage == "select_quantity" then
                MarketSystem.openInventorySelection(id)
            else
                MarketSystem.ActiveMenus[id] = nil
                resetCreateState(id)
                MarketSystem.openMyListings(id)
            end
        end
    end
end

return MarketSystem
