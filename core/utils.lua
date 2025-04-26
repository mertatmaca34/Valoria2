-- Tek oyuncuya mesaj gönder
function sendMessage(id, msgType, text)
    local colorSet = COLORS[msgType] or COLORS.info
    local captionColor = "\169" .. colorSet.caption
    local textColor = "\169" .. colorSet.text
    local caption = Lang.get(id, "caption_" .. msgType) or ""
    msg2(id, captionColor .. caption .. textColor .. text)
end

-- Tüm oyunculara mesaj gönder
function sendMessageAll(msgType, langKey)
    for _, id in pairs(player(0, "table")) do
        local text = Lang.get(id, langKey)
        sendMessage(id, msgType, text)
    end
end

-- Dosya var mı kontrol eder
function fileExists(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    else
        return false
    end
end

-- Bir table'ın derin kopyasını oluşturur
function table.deepCopy(tbl)
    if type(tbl) ~= "table" then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            copy[k] = table.deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

-- Bir table'ı dosyaya kaydeder (Lua formatında)
function table.save(tbl, path)
    local f = io.open(path, "w+")
    if not f then
        print("[Valoria] ERROR: Cannot open file for writing: " .. path)
        return
    end
    f:write("return " .. table.serialize(tbl))
    f:close()
end

-- Bir table'ı Lua kodu gibi serialize eder (stringe çevirir)
function table.serialize(tbl, indent)
    indent = indent or ""
    local str = "{\n"
    for k, v in pairs(tbl) do
        local key
        if type(k) == "number" then
            key = "[" .. k .. "]"
        else
            key = "[" .. string.format("%q", k) .. "]"
        end
        local value
        if type(v) == "table" then
            value = table.serialize(v, indent .. "  ")
        elseif type(v) == "string" then
            value = string.format("%q", v)
        else
            value = tostring(v)
        end
        str = str .. indent .. "  " .. key .. " = " .. value .. ",\n"
    end
    return str .. indent .. "}"
end
