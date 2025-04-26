MenuPager = {}

function MenuPager.show(id, titleKey, optionKeys, callback)
    local page = MenuPager[id] and MenuPager[id].page or 1
    local perPage = 9
    local totalPages = math.ceil(#optionKeys / perPage)

    MenuPager[id] = {
        titleKey = titleKey,
        options = optionKeys,
        callback = callback,
        page = page,
        totalPages = totalPages
    }

    MenuPager.update(id)
end

function MenuPager.update(id)
    local data = MenuPager[id]
    if not data then return end

    local title = Lang.get(id, data.titleKey) .. " [" .. data.page .. "/" .. data.totalPages .. "]"
    local start = (data.page - 1) * 9 + 1
    local options = {}

    for i = start, math.min(start + 8, #data.options) do
        table.insert(options, Lang.get(id, data.options[i]))
    end

    MenuPager.menuFromTable(id, title, options)
end

function MenuPager.changePage(id, dir)
    local data = MenuPager[id]
    if not data then return end

    local newPage = data.page + dir
    if newPage >= 1 and newPage <= data.totalPages then
        data.page = newPage
        MenuPager.update(id)
    end
end

function MenuPager.handleClick(id, title, button)
    local data = MenuPager[id]
    if not data then return end

    -- Menü başlığı uyuşuyorsa
    if not string.find(title, Lang.get(id, data.titleKey)) then return end

    local index = (data.page - 1) * 9 + button
    if data.options[index] then
        data.callback(id, index)
    end
end

-- CS2D Menu Formatına dönüştürür
function MenuPager.menuFromTable(id, title, options)
    local arg = title
    for i = 1, math.min(#options, 9) do
        arg = arg .. "," .. options[i]
    end
    menu(id, arg)
end

-- Scroll tuşlarını bind edelim
addbind("mwheelup")
addbind("mwheeldown")

-- Scroll ile sayfa değiştirme
addhook("key", "onMenuPagerScroll")
function onMenuPagerScroll(id, key)
    if not MenuPager[id] then return end

    if key == "mwheelup" then
        MenuPager.changePage(id, -1)
    elseif key == "mwheeldown" then
        MenuPager.changePage(id, 1)
    end
end
