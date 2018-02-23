-- Empty tables for solving multiple problems(thanks to @topkecleon)
local cronTable = {
    -- temp table to warn users if they are spamming too much the keyboards
    cbWarns =
    {
        -- user_id
    },
    -- temp table to avoid kicking an already kicked user
    floodKicks =
    {
        -- chat_id = counter
    },
    -- temp table to avoid flooding mods^
    modsContacted =
    {
        -- chat_id = false/true
    },
    -- temp table for messages hashes to prevent shitstorms
    msgsHashes =
    {
        -- chat_id = { msgHash = counter }
    },
    -- temp table for commands hashes to avoid api limitations
    commandsHashes =
    {
        -- chat_id = { user_id = { commandHash = counter } }
    },
    -- temp table to avoid restricting an already restricted user
    restrictedUsers =
    {
        -- chat_id = { user_id = false/true }
    }
}

local TIME_CHECK = 2
-- seconds
-- Save stats, ban user
local function pre_process(msg)
    if msg then
        cronTable.msgsHashes[tostring(msg.chat.id)] = cronTable.msgsHashes[tostring(msg.chat.id)] or { }
        cronTable.commandsHashes[tostring(msg.chat.id)] = cronTable.commandsHashes[tostring(msg.chat.id)] or { }
        cronTable.commandsHashes[tostring(msg.chat.id)][tostring(msg.from.id)] = cronTable.commandsHashes[tostring(msg.chat.id)][tostring(msg.from.id)] or { }
        cronTable.commandsHashes[tostring(msg.chat.id)][tostring(msg.from.id)].restricted = cronTable.commandsHashes[tostring(msg.chat.id)][tostring(msg.from.id)].restricted or false
        cronTable.restrictedUsers[tostring(msg.chat.id)] = cronTable.restrictedUsers[tostring(msg.chat.id)] or { }

        -- Ignore service msg
        if msg.service then
            return msg
        end

        -- Save chat's total messages
        local totalhash = 'chatmsgs:' .. msg.chat.id
        if not redis:get(totalhash) then
            redis:set(totalhash, 0)
        end
        redis:incr(totalhash)

        -- Save user on Redis
        if msg.from.type == 'user' then
            local savehash = 'user:' .. msg.from.id
            print('Saving user', savehash)
            if msg.from.print_name then
                redis:hset(savehash, 'print_name', msg.from.print_name)
            end
            if msg.from.first_name then
                redis:hset(savehash, 'first_name', msg.from.first_name)
            end
            if msg.from.last_name then
                redis:hset(savehash, 'last_name', msg.from.last_name)
            end
        end

        -- Save stats on Redis
        local statshash = 'chat:' .. msg.chat.id .. ':users'
        if msg.chat.type == 'private' then
            statshash = 'chat:' .. msg.from.id
        end
        redis:sadd(statshash, msg.from.id)

        -- Total user msgs in TIME_CHECK seconds
        local userhash = 'api:user:' .. msg.from.id .. ':msgs'
        local usermsgs = tonumber(redis:get(userhash) or 0)
        redis:setex(userhash, TIME_CHECK, usermsgs + 1)
        print('messages: ' .. usermsgs)

        if msg.cb then
            if not cronTable.cbWarns[tostring(msg.from.id)] then
                if usermsgs >= 4 then
                    cronTable.cbWarns[tostring(msg.from.id)] = true
                    answerCallbackQuery(msg.cb_id, langs[msg.lang].dontFloodKeyboard, true)
                end
            else
                cronTable.cbWarns[tostring(msg.from.id)] = false
            end
        else
            -- Total user msgs in that chat excluding keyboard interactions
            local msgshash = 'msgs:' .. msg.from.id .. ':' .. msg.chat.id
            redis:incr(msgshash)
        end

        if not msg.edited then
            -- Ignore admins
            if is_admin(msg) then
                return msg
            end

            -- Check for a distributed flood in one minute
            local hash
            if msg.media then
                local file_id = ''
                if msg.media_type == 'photo' then
                    local bigger_pic_id = ''
                    local size = 0
                    for k, v in pairsByKeys(msg.photo) do
                        if v.file_size > size then
                            size = v.file_size
                            bigger_pic_id = v.file_id
                        end
                    end
                    file_id = bigger_pic_id
                elseif msg.media_type == 'video' then
                    file_id = msg.video.file_id
                elseif msg.media_type == 'video_note' then
                    file_id = msg.video_note.file_id
                elseif msg.media_type == 'audio' then
                    file_id = msg.audio.file_id
                elseif msg.media_type == 'voice_note' then
                    file_id = msg.voice.file_id
                elseif msg.media_type == 'gif' then
                    file_id = msg.document.file_id
                elseif msg.media_type == 'document' then
                    file_id = msg.document.file_id
                elseif msg.media_type == 'sticker' then
                    file_id = msg.sticker.file_id
                end
                hash = file_id
            else
                hash = sha2.hash256(msg.text)
            end

            -- Check flood
            if msg.chat.type == 'private' then
                cronTable.msgsHashes[tostring(msg.chat.id)][tostring(hash)] =(cronTable.msgsHashes[tostring(msg.chat.id)][tostring(hash)] or 0) + 1
                if cronTable.msgsHashes[tostring(msg.chat.id)][tostring(hash)] > 10 or usermsgs >= 7 then
                    print("user blocked")
                    -- Block user if spammed in private
                    blockUser(msg.from.id)
                    sendMessage(msg.from.id, langs[msg.lang].user .. "[" .. msg.from.id .. "]" .. langs[msg.lang].blockedForSpam)
                    sendLog(langs[msg.lang].user .. "[" .. msg.from.id .. "]" .. langs[msg.lang].blockedForSpam, false, true)
                    savelog(msg.from.id .. " PM", "User [" .. msg.from.id .. "] blocked for spam.")
                    return nil
                end
            elseif data[tostring(msg.chat.id)] then
                -- Ignore mods^
                -- Check if flood is on or off
                -- Ignore whitelisted
                if msg.from.is_mod or not data[tostring(msg.chat.id)].settings.locks.flood or isWhitelisted(msg.chat.id, msg.from.id) then
                    return msg
                end
                cronTable.msgsHashes[tostring(msg.chat.id)][tostring(hash)] =(cronTable.msgsHashes[tostring(msg.chat.id)][tostring(hash)] or 0) + 1
                local NUM_MSG_MAX = 5
                if data[tostring(msg.chat.id)] then
                    if data[tostring(msg.chat.id)].settings then
                        if data[tostring(msg.chat.id)].settings.max_flood then
                            NUM_MSG_MAX = tonumber(data[tostring(msg.chat.id)].settings.max_flood)
                            -- Obtain group flood sensitivity
                        end
                    end
                end
                cronTable.floodKicks[tostring(msg.chat.id)] = cronTable.floodKicks[tostring(msg.chat.id)] or 0
                -- ANTI FLOOD
                if usermsgs >= NUM_MSG_MAX and not globalCronTable.punishedTable[tostring(msg.chat.id)][tostring(msg.from.id)] then
                    local text = punishmentAction(bot.id, msg.from.id, msg.chat.id, data[tostring(msg.chat.id)].settings.locks.flood, langs[msg.lang].reasonFlood, msg.message_id)
                    if text == '' then
                        return msg
                    end
                    local username = msg.from.username or 'USERNAME'
                    if msg.chat.type == 'group' or msg.chat.type == 'supergroup' then
                        if msg.from.username then
                            savelog(msg.chat.id, msg.from.print_name .. " @" .. username .. " [" .. msg.from.id .. "] punished for #flood punishment=" .. tostring(data[tostring(msg.chat.id)].settings.locks.flood))
                            sendMessage(msg.chat.id, text)
                        else
                            savelog(msg.chat.id, msg.from.print_name .. " [" .. msg.from.id .. "] punished for #flood punishment=" .. tostring(data[tostring(msg.chat.id)].settings.locks.flood))
                            sendMessage(msg.chat.id, text)
                        end
                    end
                    -- incr it on redis
                    local gbanspam = 'gban:spam' .. msg.from.id
                    redis:incr(gbanspam)
                    local gbanspam = 'gban:spam' .. msg.from.id
                    local gbanspamonredis = redis:get(gbanspam)
                    -- Check if user has spammed is group more than 4 times
                    if gbanspamonredis then
                        if tonumber(gbanspamonredis) == 4 and not msg.from.is_owner then
                            -- Global ban that user
                            gbanUser(msg.from.id)
                            local gbanspam = 'gban:spam' .. msg.from.id
                            -- reset the counter
                            redis:set(gbanspam, 0)
                            -- Send this to that chat
                            sendMessage(msg.chat.id, langs[msg.lang].user .. " [ " .. profileLink(msg.from.id, msg.from.print_name) .. " ] " .. msg.from.id .. langs[msg.lang].gbanned .. " (SPAM)", 'html')
                            gban_text = langs[msg.lang].user .. " [ " .. profileLink(msg.from.id, msg.from.print_name) .. " ] ( @" .. username .. " ) " .. msg.from.id .. langs[msg.lang].gbannedFrom .. " ( " .. msg.chat.print_name .. " ) [ " .. msg.chat.id .. " ] (SPAM)"
                            -- send it to log group/channel
                            sendLog(gban_text, 'html', true)
                        end
                    end
                    cronTable.floodKicks[tostring(msg.chat.id)] = cronTable.floodKicks[tostring(msg.chat.id)] + 1
                end
                -- ANTI SHITSTORM
                local shitstormAlarm = false
                if cronTable.floodKicks[tostring(msg.chat.id)] >= 4 or cronTable.msgsHashes[tostring(msg.chat.id)][tostring(hash)] > 10 then
                    -- check if there's a possible ongoing shitstorm (if flooders are more than 4 or more than 10 messages all equals in 1 minute)
                    shitstormAlarm = true
                    if string.match(getWarn(msg.chat.id), "%d+") then
                        local restrictedFlag = false
                        if not cronTable.restrictedUsers[tostring(msg.chat.id)][tostring(msg.from.id)] then
                            io.popen('lua timework.lua "restrictuser" "1" "' .. msg.chat.id .. '" "' .. msg.from.id .. '"')
                            savelog(msg.chat.id, msg.from.print_name .. " [" .. msg.from.id .. "] restricted for possible shitstorm")
                            cronTable.restrictedUsers[tostring(msg.chat.id)][tostring(msg.from.id)] = true
                            restrictedFlag = true
                        end
                        local text = ''
                        if not globalCronTable.punishedTable[tostring(msg.chat.id)][tostring(msg.from.id)] then
                            text = text .. tostring(warnUser(bot.id, msg.from.id, msg.chat.id, langs[msg.lang].reasonFlood))
                            if restrictedFlag then
                                sendMessage(msg.chat.id, text .. ' #kick #restrict\n' .. langs[msg.lang].scheduledKick:gsub('X', '300') .. '\n' .. langs[msg.lang].allRestrictionsApplied)
                                io.popen('lua timework.lua "kickuser" "' .. math.random(120, 300) .. '" "' .. msg.chat.id .. '" "' .. msg.from.id .. '"')
                                globalCronTable.punishedTable[tostring(msg.chat.id)][tostring(msg.from.id)] = true
                            else
                                sendMessage(msg.chat.id, text .. ' #kick\n' .. langs[msg.lang].scheduledKick:gsub('X', '10'))
                                io.popen('lua timework.lua "kickuser" "' .. math.random(1, 10) .. '" "' .. msg.chat.id .. '" "' .. msg.from.id .. '"')
                                globalCronTable.punishedTable[tostring(msg.chat.id)][tostring(msg.from.id)] = true
                            end
                            savelog(msg.chat.id, msg.from.print_name .. " [" .. msg.from.id .. "] will be kicked in 300 seconds at most for possible shitstorm")
                        elseif restrictedFlag then
                            sendMessage(msg.chat.id, langs[msg.lang].allRestrictionsApplied .. ' #restrict')
                        end
                    elseif not strict then
                        sendMessage(msg.chat.id, kickUser(bot.id, msg.from.id, msg.chat.id, langs[msg.lang].reasonFlood))
                    else
                        sendMessage(msg.chat.id, banUser(bot.id, msg.from.id, msg.chat.id, langs[msg.lang].reasonFlood))
                    end
                end
                -- ANTI COMMANDSFLOOD
                if not msg.cb and msg.command then
                    cronTable.commandsHashes[tostring(msg.chat.id)][tostring(msg.from.id)][tostring(hash)] =(cronTable.commandsHashes[tostring(msg.chat.id)][tostring(msg.from.id)][tostring(hash)] or 0) + 1
                    if cronTable.commandsHashes[tostring(msg.chat.id)][tostring(msg.from.id)][tostring(hash)] > 4 and not cronTable.commandsHashes[tostring(msg.chat.id)][tostring(msg.from.id)].restricted and not cronTable.restrictedUsers[tostring(msg.chat.id)][tostring(msg.from.id)] then
                        -- user spammed more than 4 equal commands in one minute (it has no sense, so restrict that user for 10 minutes) and not restricted
                        cronTable.commandsHashes[tostring(msg.chat.id)][tostring(msg.from.id)].restricted = true
                        sendReply(msg, langs[msg.lang].commandsFlooderRestricted)
                        -- restrict for 10 minutes
                        io.popen('lua timework.lua "restrictuser" "10" "' .. msg.chat.id .. '" "' .. msg.from.id .. '" "600"')
                        savelog(msg.chat.id, msg.from.print_name .. " [" .. msg.from.id .. "] restricted for flooding commands")
                    end
                end
                -- CONTACT ADMINS
                if shitstormAlarm and not cronTable.modsContacted[tostring(msg.chat.id)] then
                    cronTable.modsContacted[tostring(msg.chat.id)] = true
                    local hashtag = '#alarm' .. tostring(msg.message_id)
                    local chat_name = msg.chat.print_name:gsub("_", " ") .. ' [' .. msg.chat.id .. ']'
                    local group_link = data[tostring(msg.chat.id)].link
                    if group_link then
                        chat_name = "<a href=\"" .. group_link .. "\">" .. html_escape(chat_name) .. "</a>"
                    end
                    local attentionText = langs[msg.lang].possibleShitstorm .. chat_name .. '\n' ..
                    'HASHTAG: ' .. hashtag
                    attentionText = attentionText:gsub('"', '\\"')
                    io.popen('lua timework.lua "contactadmins" "0.5" "' .. msg.chat.id .. '" "true" "' .. hashtag .. '" "' .. attentionText .. '"')
                    data[tostring(msg.chat.id)].settings.locks.spam = 3
                end
                if usermsgs >= NUM_MSG_MAX then
                    return nil
                end
            end
        end
        return msg
    end
end

local function cron()
    -- clear those tables on the top of the plugin
    cronTable = {
        cbWarns = { },
        floodKicks = { },
        modsContacted = { },
        msgsHashes = { },
        commandsHashes = { },
        restrictedUsers = { }
    }
end

return {
    description = "ANTI_SPAM",
    cron = cron,
    patterns = { },
    pre_process = pre_process,
    min_rank = 6,
}