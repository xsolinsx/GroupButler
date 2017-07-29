local chats = nil
local spam = false

local function run(msg, matches)
    if matches[1]:lower() == 'news' then
        return langs.news
    end
    if matches[1]:lower() == 'spamnews' then
        if is_sudo(msg) then
            chats = { }
            for k, v in pairs(data.groups) do
                if data[tostring(v)] then
                    chats[tostring(v)] = true
                end
            end
            for k, v in pairs(data.realms) do
                if data[tostring(v)] then
                    chats[tostring(v)] = true
                end
            end
            spam = true
        else
            return langs[msg.lang].require_sudo
        end
    end
    if matches[1]:lower() == 'stopnews' then
        if is_sudo(msg) then
            chats = nil
            spam = false
        else
            return langs[msg.lang].require_sudo
        end
    end
end

local function pre_process(msg)
    if msg then
        if spam and chats then
            if chats[tostring(msg.chat.id)] then
                sendMessage(msg.chat.id, langs.news)
                chats[tostring(msg.chat.id)] = false
            end
        end
        return msg
    end
end

return {
    description = "NEWS",
    patterns =
    {
        "^[#!/]([Nn][Ee][Ww][Ss])$",
        "^[#!/]([Ss][Pp][Aa][Mm][Nn][Ee][Ww][Ss])$",
        "^[#!/]([Ss][Tt][Oo][Pp][Nn][Ee][Ww][Ss])$",
    },
    run = run,
    pre_process = pre_process,
    min_rank = 0,
    syntax =
    {
        "USER",
        "#news",
        "SUDO",
        "#spamnews",
        "#stopnews",
    },
}