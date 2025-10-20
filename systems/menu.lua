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

    if key == "menu_language" then
        openLanguageMenu(id)
    elseif key == "menu_stats" then
        openStatsMenu(id)
    elseif key == "menu_inventory" then
        InventorySystem.openMenu(id)
    elseif key == "menu_equipment" then
        EquipmentSystem.openMenu(id)
    elseif key == "menu_quests" then
        QuestSystem.openMenu(id)
    elseif key == "menu_market" then
        MarketSystem.openMenu(id)
    elseif key == "menu_status" then
        StatusSystem.openMenu(id)
    elseif key == "menu_depot" then
        sendMessage(id, "info", Lang.get(id, "menu_depot_not_ready"))
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