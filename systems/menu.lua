addhook("serveraction", "onServerAction")
function onServerAction(id, action)
    if action == 1 then
        openMainMenu(id)
    end
end

-- Ana Menü Açıcı
function openMainMenu(id)
    MenuPager.show(id, "menu_main_title", {
        "menu_stats",
        "menu_empty",
        "menu_inventory",
        "menu_equipment",
        "menu_empty",
        "menu_quests",
        "menu_depot",
        "menu_market",
        "menu_empty",
        "menu_status",
        "menu_empty",
        "menu_language"
    }, onMainMenuSelect)
end

-- Ana Menüde Bir Şeye Tıklandıysa
function onMainMenuSelect(id, index)
    local optionKeys = {
        "menu_stats",
        "menu_empty",
        "menu_inventory",
        "menu_equipment",
        "menu_empty",
        "menu_quests",
        "menu_depot",
        "menu_market",
        "menu_empty",
        "menu_status",
        "menu_empty",
        "menu_language"
    }

    local key = optionKeys[index]
    if not key or key == "menu_empty" then
        return -- boş tuşa tıkladıysa hiçbir şey yapma
    end

    local messages = {
        menu_stats = "menu_char_coming_soon",
        menu_inventory = "menu_inventory_inactive",
        menu_equipment = "menu_equipment_coming_soon",
        menu_quests = "menu_quests_not_ready",
        menu_depot = "menu_depot_not_ready",
        menu_market = "menu_market_not_ready",
        menu_status = "menu_status_display"
    }

    if key == "menu_language" then
        openLanguageMenu(id)
    elseif key == "menu_stats" then
        openStatsMenu(id)
    elseif messages[key] then
        sendMessage(id, "info", Lang.get(id, messages[key]))
    end
end


-- Dil Seçim Menüsü
function openLanguageMenu(id)
    MenuPager[id] = nil -- Önce eski menü kaydını sil
    MenuPager.show(id, "menu_language", {
        "language_turkish",
        "language_english"
    }, onLanguageSelect)
end



-- Dil Menüsünde Seçim Yapıldıysa
function onLanguageSelect(id, index)
    if index == 1 then
        Lang.setPlayerLang(id, "tr")
        sendMessage(id, "success", Lang.get(id, "lang_set_tr"))
    elseif index == 2 then
        Lang.setPlayerLang(id, "en")
        sendMessage(id, "success", Lang.get(id, "lang_set_en"))
    end
end