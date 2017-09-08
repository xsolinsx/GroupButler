local delword_table = {
    -- chat_id = word|pattern
}

local function get_censorships_hash(msg)
    if msg.chat.type == 'group' then
        return 'group:' .. msg.chat.id .. ':censorships'
    end
    if msg.chat.type == 'supergroup' then
        return 'supergroup:' .. msg.chat.id .. ':censorships'
    end
    return false
end

local function setunset_delword(msg, var_name, time)
    local hash = get_censorships_hash(msg)
    if hash then
        if redis:hget(hash, var_name) then
            redis:hdel(hash, var_name)
            return langs[msg.lang].delwordRemoved .. var_name
        else
            if time then
                if tonumber(time) == 0 then
                    redis:hset(hash, var_name, true)
                else
                    redis:hset(hash, var_name, time)
                end
            else
                redis:hset(hash, var_name, true)
            end
            return langs[msg.lang].delwordAdded .. var_name
        end
    end
end

local function run(msg, matches)
    if msg.cb then
        if matches[1] then
            if matches[1] == '###cbdelword' then
                if matches[2] == 'DELETE' then
                    if not deleteMessage(msg.chat.id, msg.message_id, true) then
                        editMessageText(msg.chat.id, msg.message_id, langs[msg.lang].stop)
                    end
                elseif string.match(matches[2], '^%d+$') then
                    if delword_table[tostring(msg.from.id)] then
                        local time = tonumber(matches[2])
                        if matches[3] == 'BACK' then
                            editMessageText(msg.chat.id, msg.message_id, langs[msg.lang].delwordIntro:gsub('X', delword_table[tostring(msg.from.id)]), keyboard_scheduledelword(matches[4], time))
                            answerCallbackQuery(msg.cb_id, langs[msg.lang].keyboardUpdated, false)
                        elseif matches[3] == 'SECONDS' or matches[3] == 'MINUTES' or matches[3] == 'HOURS' then
                            mystat('###cbdelword' .. matches[2] .. matches[3] .. matches[4] .. matches[5])
                            local remainder, hours, minutes, seconds = 0
                            hours = math.floor(time / 3600)
                            remainder = time % 3600
                            minutes = math.floor(remainder / 60)
                            seconds = remainder % 60
                            if matches[3] == 'SECONDS' then
                                if tonumber(matches[4]) == 0 then
                                    time = time - seconds
                                    answerCallbackQuery(msg.cb_id, langs[msg.lang].secondsReset, false)
                                else
                                    if (time + tonumber(matches[4])) >= 0 and(time + tonumber(matches[4])) < 172800 then
                                        time = time + tonumber(matches[4])
                                    else
                                        answerCallbackQuery(msg.cb_id, langs[msg.lang].errorTempTimeRange, true)
                                    end
                                end
                            elseif matches[3] == 'MINUTES' then
                                if tonumber(matches[4]) == 0 then
                                    time = time -(minutes * 60)
                                    answerCallbackQuery(msg.cb_id, langs[msg.lang].minutesReset, false)
                                else
                                    if (time +(tonumber(matches[4]) * 60)) >= 0 and(time +(tonumber(matches[4]) * 60)) < 172800 then
                                        time = time +(tonumber(matches[4]) * 60)
                                    else
                                        answerCallbackQuery(msg.cb_id, langs[msg.lang].errorTempTimeRange, true)
                                    end
                                end
                            elseif matches[3] == 'HOURS' then
                                if tonumber(matches[4]) == 0 then
                                    time = time -(hours * 60 * 60)
                                    answerCallbackQuery(msg.cb_id, langs[msg.lang].hoursReset, false)
                                else
                                    if (time +(tonumber(matches[4]) * 60 * 60)) >= 0 and(time +(tonumber(matches[4]) * 60 * 60)) < 172800 then
                                        time = time +(tonumber(matches[4]) * 60 * 60)
                                    else
                                        answerCallbackQuery(msg.cb_id, langs[msg.lang].errorTempTimeRange, true)
                                    end
                                end
                            end
                            editMessageText(msg.chat.id, msg.message_id, langs[msg.lang].delwordIntro:gsub('X', delword_table[tostring(msg.from.id)]), keyboard_scheduledelword(matches[5], time))
                        elseif matches[3] == 'DONE' then
                            if is_mod2(msg.from.id, matches[4], false) then
                                mystat('###cbdelword' .. matches[2] .. matches[3] .. matches[4])
                                local tmp = { chat = { id = matches[4], type = '' }, lang = msg.lang }
                                if matches[4]:starts('-100') then
                                    tmp.chat.type = 'supergroup'
                                elseif matches[4]:starts('-') then
                                    tmp.chat.type = 'group'
                                end
                                local text = setunset_delword(tmp, delword_table[tostring(msg.from.id)], time)
                                delword_table[tostring(msg.from.id)] = nil
                                answerCallbackQuery(msg.cb_id, text, false)
                                sendMessage(matches[4], text)
                                if not deleteMessage(msg.chat.id, msg.message_id, true) then
                                    editMessageText(msg.chat.id, msg.message_id, langs[msg.lang].stop)
                                end
                            end
                        end
                    else
                        editMessageText(msg.chat.id, msg.message_id, langs[msg.lang].errorTryAgain)
                    end
                end
                return
            end
        end
    end
    if matches[1]:lower() == 'scheduledelword' then
        if msg.from.is_mod then
            if matches[2] and matches[3] and matches[4] and matches[5] then
                local hours = tonumber(matches[2])
                local minutes = tonumber(matches[3])
                local seconds = tonumber(matches[4])
                if hours >= 48 then
                    hours = 47
                    minutes = 59
                    seconds = 59
                end
                if minutes >= 60 then
                    minutes = 59
                    seconds = 59
                end
                if seconds >= 60 then
                    seconds = 59
                end
                local time = seconds +(minutes * 60) +(hours * 60 * 60)
                return setunset_delword(msg, matches[5]:lower(), time)
            else
                delword_table[tostring(msg.from.id)] = matches[2]:lower()
                local hash = get_censorships_hash(msg)
                if hash then
                    if redis:hget(hash, matches[2]:lower()) then
                        redis:hdel(hash, matches[2]:lower())
                        return langs[msg.lang].delwordRemoved .. matches[2]:lower()
                    else
                        if sendKeyboard(msg.from.id, langs[msg.lang].delwordIntro:gsub('X', matches[2]:lower()), keyboard_scheduledelword(msg.chat.id)) then
                            if msg.chat.type ~= 'private' then
                                local message_id = sendReply(msg, langs[msg.lang].sendTimeKeyboardPvt).result.message_id
                                io.popen('lua timework.lua "delete" "' .. msg.chat.id .. '" "60" "' .. message_id .. '"')
                                io.popen('lua timework.lua "delete" "' .. msg.chat.id .. '" "60" "' .. msg.message_id .. '"')
                                return
                            end
                        else
                            return sendKeyboard(msg.chat.id, langs[msg.lang].cantSendPvt, { inline_keyboard = { { { text = "/start", url = "t.me/AISashaBot" } } } }, false, msg.message_id)
                        end
                    end
                end
            end
        else
            return langs[msg.lang].require_mod
        end
    end
end

return {
    description = "SCHEDULED_COMMANDS",
    patterns =
    {
        "^(###cbdelword)(DELETE)$",
        "^(###cbdelword)(%d+)(BACK)(%-%d+)$",
        "^(###cbdelword)(%d+)(SECONDS)([%+%-]?%d+)(%-%d+)$",
        "^(###cbdelword)(%d+)(MINUTES)([%+%-]?%d+)(%-%d+)$",
        "^(###cbdelword)(%d+)(HOURS)([%+%-]?%d+)(%-%d+)$",
        "^(###cbdelword)(%d+)(DONE)(%-%d+)$",

        "^[#!/]([Ss][Cc][Hh][Ee][Dd][Uu][Ll][Ee][Dd][Ee][Ll][Ww][Oo][Rr][Dd]) (%d+) (%d+) (%d+) (.*)$",
        "^[#!/]([Ss][Cc][Hh][Ee][Dd][Uu][Ll][Ee][Dd][Ee][Ll][Ww][Oo][Rr][Dd]) (.*)$",
    },
    run = run,
    min_rank = 1,
    syntax =
    {
        "MOD",
        "#scheduledelword [<hours> <minutes> <seconds>] <word>|<pattern>",
    },
}