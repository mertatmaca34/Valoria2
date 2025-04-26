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
