Lang = {}

-- Tum kayitli diller burada tutulur
Lang.Packs = {}

-- Her oyuncunun secili dili burada tutulur
Lang.PlayerLang = {}

-- Bir dil paketi ekler (dil kodu, dil icerigi)
function Lang.addPack(langCode, pack)
    Lang.Packs[langCode] = pack
end

-- Bir oyuncunun dilini ayarlar
function Lang.setPlayerLang(id, langCode)
    Lang.PlayerLang[id] = langCode
    PLAYER_DATA[id].lang = langCode
end

-- Bir oyuncunun dil kodunu getirir (yoksa 'tr' default)
function Lang.getPlayerLang(id)
    return Lang.PlayerLang[id] or "tr"
end

-- Bir oyuncuya gore bir key'in string karsiligini getirir
function Lang.get(id, key)
    local langCode = Lang.getPlayerLang(id)
    local pack = Lang.Packs[langCode]
    return (pack and pack[key]) or "[MISSING: " .. key .. "]"
end

-- Direkt dil koduna gore string getirir (oyuncu id'siz)
function Lang.getByCode(langCode, key)
    local pack = Lang.Packs[langCode]
    return (pack and pack[key]) or "[MISSING: " .. key .. "]"
end

-- Oyuncu cikinca dil kaydini temizler (opsiyonel)
function Lang.removePlayer(id)
    Lang.PlayerLang[id] = nil
end
