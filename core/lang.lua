Lang = {}

-- Tüm kayıtlı diller burada tutulur
Lang.Packs = {}

-- Her oyuncunun seçili dili burada tutulur
Lang.PlayerLang = {}

-- Bir dil paketi ekler (dil kodu, dil içeriği)
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

-- Bir oyuncuya göre bir key'in string karşılığını getirir
function Lang.get(id, key)
    local langCode = Lang.getPlayerLang(id)
    local pack = Lang.Packs[langCode]
    return (pack and pack[key]) or "[MISSING: " .. key .. "]"
end

-- Direkt dil koduna göre string getirir (oyuncu id'siz)
function Lang.getByCode(langCode, key)
    local pack = Lang.Packs[langCode]
    return (pack and pack[key]) or "[MISSING: " .. key .. "]"
end

-- Oyuncu çıkınca dil kaydını temizler (opsiyonel)
function Lang.removePlayer(id)
    Lang.PlayerLang[id] = nil
end
