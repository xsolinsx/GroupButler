local max_time = dateToUnix(0, 0, 48, 0, 0)

local schedule_table = {
    -- chat_id = command
}
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
        if redis_hget_something(hash, var_name) then
            redis_hdelsrem_something(hash, var_name)
            return langs[msg.lang].delwordRemoved .. var_name
        else
            if time then
                if tonumber(time) == 0 then
                    redis_hset_something(hash, var_name, true)
                else
                    redis_hset_something(hash, var_name, time)
                end
            else
                redis_hset_something(hash, var_name, true)
            end
            return langs[msg.lang].delwordAdded .. var_name
        end
    end
end

local function run(msg, matches)
    if msg.cb then
        if matches[1] == '###cbdelword' then
            if matches[2] == 'DELETE' then
                if not deleteMessage(msg.chat.id, msg.message_id, true) then
                    editMessageText(msg.chat.id, msg.message_id, langs[msg.lang].stop)
                end
            elseif string.match(matches[2], '^%d+$') then
                if delword_table[tostring(msg.from.id)] then
                    local time = tonumber(matches[2])
                    if matches[3] == 'BACK' then
                        answerCallbackQuery(msg.cb_id, langs[msg.lang].keyboardUpdated, false)
                        editMessageReplyMarkup(msg.chat.id, msg.message_id, keyboard_less_time('delword', matches[4], time))
                    elseif matches[3] == 'SECONDS' or matches[3] == 'MINUTES' or matches[3] == 'HOURS' then
                        local seconds, minutes, hours = unixToDate(time)
                        if matches[3] == 'SECONDS' then
                            if tonumber(matches[4]) == 0 then
                                answerCallbackQuery(msg.cb_id, langs[msg.lang].secondsReset, false)
                                time = time - dateToUnix(seconds, 0, 0, 0, 0)
                            else
                                if (time + dateToUnix(tonumber(matches[4]), 0, 0, 0, 0)) >= 0 and(time + dateToUnix(tonumber(matches[4]), 0, 0, 0, 0)) < 172800 then
                                    time = time + dateToUnix(tonumber(matches[4]), 0, 0, 0, 0)
                                else
                                    answerCallbackQuery(msg.cb_id, langs[msg.lang].errorTempTimeRange, true)
                                end
                            end
                        elseif matches[3] == 'MINUTES' then
                            if tonumber(matches[4]) == 0 then
                                answerCallbackQuery(msg.cb_id, langs[msg.lang].minutesReset, false)
                                time = time - dateToUnix(0, minutes, 0, 0, 0)
                            else
                                if (time + dateToUnix(0, tonumber(matches[4]), 0, 0, 0)) >= 0 and(time + dateToUnix(0, tonumber(matches[4]), 0, 0, 0)) < 172800 then
                                    time = time + dateToUnix(0, tonumber(matches[4]), 0, 0, 0)
                                else
                                    answerCallbackQuery(msg.cb_id, langs[msg.lang].errorTempTimeRange, true)
                                end
                            end
                        elseif matches[3] == 'HOURS' then
                            if tonumber(matches[4]) == 0 then
                                answerCallbackQuery(msg.cb_id, langs[msg.lang].hoursReset, false)
                                time = time - dateToUnix(0, 0, hours, 0, 0)
                            else
                                if (time + dateToUnix(0, 0, tonumber(matches[4]), 0, 0)) >= 0 and(time + dateToUnix(0, 0, tonumber(matches[4]), 0, 0)) < 172800 then
                                    time = time + dateToUnix(0, 0, tonumber(matches[4]), 0, 0)
                                else
                                    answerCallbackQuery(msg.cb_id, langs[msg.lang].errorTempTimeRange, true)
                                end
                            end
                        end
                        editMessageReplyMarkup(msg.chat.id, msg.message_id, keyboard_less_time('delword', matches[5], time))
                        mystat(matches[1] .. matches[2] .. matches[3] .. matches[4] .. matches[5])
                    elseif matches[3] == 'DONE' then
                        if is_mod2(msg.from.id, matches[4], false) then
                            local tmp = { chat = { id = matches[4], type = '' }, lang = msg.lang }
                            if matches[4]:starts('-100') then
                                tmp.chat.type = 'supergroup'
                            elseif matches[4]:starts('-') then
                                tmp.chat.type = 'group'
                            end
                            local text = ''
                            if pcall( function()
                                    string.match(delword_table[tostring(msg.from.id)], delword_table[tostring(msg.from.id)])
                                end ) then
                                text = setunset_delword(tmp, delword_table[tostring(msg.from.id)], time)
                            else
                                text = langs[msg.lang].errorTryAgain
                            end
                            answerCallbackQuery(msg.cb_id, text, false)
                            delword_table[tostring(msg.from.id)] = nil
                            sendMessage(matches[4], text)
                            if not deleteMessage(msg.chat.id, msg.message_id, true) then
                                editMessageText(msg.chat.id, msg.message_id, langs[msg.lang].stop)
                            end
                            mystat(matches[1] .. matches[2] .. matches[3] .. matches[4])
                        end
                    end
                else
                    editMessageText(msg.chat.id, msg.message_id, langs[msg.lang].errorTryAgain)
                end
            end
        elseif matches[1]:lower() == '###cbschedule' then
            if is_sudo(msg) then
                if matches[2] == 'DELETE' then
                    if not deleteMessage(msg.chat.id, msg.message_id, true) then
                        editMessageText(msg.chat.id, msg.message_id, langs[msg.lang].stop)
                    end
                elseif string.match(matches[2], '^%d+$') then
                    if schedule_table[tostring(msg.from.id)] then
                        local time = tonumber(matches[2])
                        if matches[3] == 'BACK' then
                            answerCallbackQuery(msg.cb_id, langs[msg.lang].keyboardUpdated, false)
                            editMessageReplyMarkup(msg.chat.id, msg.message_id, keyboard_less_time('schedule', matches[4], time))
                        elseif matches[3] == 'SECONDS' or matches[3] == 'MINUTES' or matches[3] == 'HOURS' then
                            local seconds, minutes, hours = unixToDate(time)
                            if matches[3] == 'SECONDS' then
                                if tonumber(matches[4]) == 0 then
                                    answerCallbackQuery(msg.cb_id, langs[msg.lang].secondsReset, false)
                                    time = time - dateToUnix(seconds, 0, 0, 0, 0)
                                else
                                    if (time + dateToUnix(tonumber(matches[4]), 0, 0, 0, 0)) >= 0 and(time + dateToUnix(tonumber(matches[4]), 0, 0, 0, 0)) < 172800 then
                                        time = time + dateToUnix(tonumber(matches[4]), 0, 0, 0, 0)
                                    else
                                        answerCallbackQuery(msg.cb_id, langs[msg.lang].errorTempTimeRange, true)
                                    end
                                end
                            elseif matches[3] == 'MINUTES' then
                                if tonumber(matches[4]) == 0 then
                                    answerCallbackQuery(msg.cb_id, langs[msg.lang].minutesReset, false)
                                    time = time - dateToUnix(0, minutes, 0, 0, 0)
                                else
                                    if (time + dateToUnix(0, tonumber(matches[4]), 0, 0, 0)) >= 0 and(time + dateToUnix(0, tonumber(matches[4]), 0, 0, 0)) < 172800 then
                                        time = time + dateToUnix(0, tonumber(matches[4]), 0, 0, 0)
                                    else
                                        answerCallbackQuery(msg.cb_id, langs[msg.lang].errorTempTimeRange, true)
                                    end
                                end
                            elseif matches[3] == 'HOURS' then
                                if tonumber(matches[4]) == 0 then
                                    answerCallbackQuery(msg.cb_id, langs[msg.lang].hoursReset, false)
                                    time = time - dateToUnix(0, 0, hours, 0, 0)
                                else
                                    if (time + dateToUnix(0, 0, tonumber(matches[4]), 0, 0)) >= 0 and(time + dateToUnix(0, 0, tonumber(matches[4]), 0, 0)) < 172800 then
                                        time = time + dateToUnix(0, 0, tonumber(matches[4]), 0, 0)
                                    else
                                        answerCallbackQuery(msg.cb_id, langs[msg.lang].errorTempTimeRange, true)
                                    end
                                end
                            end
                            editMessageReplyMarkup(msg.chat.id, msg.message_id, keyboard_less_time('schedule', matches[5], time))
                        elseif matches[3] == 'DONE' then
                            answerCallbackQuery(msg.cb_id, 'SCHEDULED', false)
                            io.popen('lua timework.lua "' .. schedule_table[tostring(msg.from.id)].method .. '" "' .. time .. '" "' .. schedule_table[tostring(msg.from.id)].chat_id .. '" "' .. schedule_table[tostring(msg.from.id)].text .. '"')
                            schedule_table[tostring(msg.from.id)] = nil
                            sendMessage(matches[4], 'SCHEDULED')
                            if not deleteMessage(msg.chat.id, msg.message_id, true) then
                                editMessageText(msg.chat.id, msg.message_id, langs[msg.lang].stop)
                            end
                        end
                    else
                        editMessageText(msg.chat.id, msg.message_id, langs[msg.lang].errorTryAgain)
                    end
                end
            end
        end
        return
    end
    if matches[1]:lower() == 'scheduledelword' then
        if msg.from.is_mod then
            if matches[2] and matches[3] and matches[4] and matches[5] then
                time = dateToUnix(matches[4], matches[3], matches[2])
                if time >= max_time then
                    time = max_time - 1
                end
                return setunset_delword(msg, matches[5]:lower(), time)
            else
                delword_table[tostring(msg.from.id)] = matches[2]:lower()
                local hash = get_censorships_hash(msg)
                if hash then
                    if redis_hget_something(hash, matches[2]:lower()) then
                        redis_hdelsrem_something(hash, matches[2]:lower())
                        return langs[msg.lang].delwordRemoved .. matches[2]:lower()
                    else
                        if sendKeyboard(msg.from.id, langs[msg.lang].delwordIntro:gsub('X', matches[2]:lower()), keyboard_less_time('delword', msg.chat.id)) then
                            if msg.chat.type ~= 'private' then
                                local message_id = getMessageId(sendReply(msg, langs[msg.lang].sendTimeKeyboardPvt, 'html'))
                                io.popen('lua timework.lua "deletemessage" "60" "' .. msg.chat.id .. '" "' .. msg.message_id .. ',' ..(message_id or '') .. '"')
                                return
                            end
                        else
                            return sendKeyboard(msg.chat.id, langs[msg.lang].cantSendPvt, { inline_keyboard = { { { text = "/start", url = bot.link } } } }, false, msg.message_id)
                        end
                    end
                end
            end
        else
            return langs[msg.lang].require_mod
        end
    end
    if matches[1]:lower() == 'schedule' then
        if is_sudo(msg) then
            if matches[2] and matches[3] and matches[4] and matches[5] and matches[6] and matches[7] and matches[8] then
                local time = dateToUnix(matches[4], matches[3], matches[2])
                if time >= max_time then
                    time = max_time - 1
                end
                io.popen('lua timework.lua "' .. matches[6]:lower() .. '" "' .. time .. '" "' .. matches[7]:lower() .. '" "' .. matches[8]:lower() .. '"')
                return 'SCHEDULED'
            else
                schedule_table[tostring(msg.from.id)] = { method = matches[2]:lower(), chat_id = matches[3], text = matches[4] }
                if sendKeyboard(msg.from.id, 'SCHEDULE', keyboard_less_time('schedule', msg.chat.id)) then
                    if msg.chat.type ~= 'private' then
                        local message_id = getMessageId(sendReply(msg, langs[msg.lang].sendTimeKeyboardPvt, 'html'))
                        io.popen('lua timework.lua "deletemessage" "60" "' .. msg.chat.id .. '" "' .. msg.message_id .. ',' ..(message_id or '') .. '"')
                        return
                    end
                else
                    return sendKeyboard(msg.chat.id, langs[msg.lang].cantSendPvt, { inline_keyboard = { { { text = "/start", url = bot.link } } } }, false, msg.message_id)
                end
            end
        else
            return langs[msg.lang].require_sudo
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
        "^(###cbschedule)(DELETE)$",
        "^(###cbschedule)(%d+)(BACK)(%-%d+)$",
        "^(###cbschedule)(%d+)(SECONDS)([%+%-]?%d+)(%-%d+)$",
        "^(###cbschedule)(%d+)(MINUTES)([%+%-]?%d+)(%-%d+)$",
        "^(###cbschedule)(%d+)(HOURS)([%+%-]?%d+)(%-%d+)$",
        "^(###cbschedule)(%d+)(DONE)(%-%d+)$",

        "^[#!/]([Ss][Cc][Hh][Ee][Dd][Uu][Ll][Ee][Dd][Ee][Ll][Ww][Oo][Rr][Dd]) (%d+) (%d+) (%d+) (.*)$",
        "^[#!/]([Ss][Cc][Hh][Ee][Dd][Uu][Ll][Ee][Dd][Ee][Ll][Ww][Oo][Rr][Dd]) (.*)$",
        "^[#!/]([Ss][Cc][Hh][Ee][Dd][Uu][Ll][Ee]) (%d+) (%d+) (%d+) ([^%s]+) (%-?%d+) (.*)$",
        "^[#!/]([Ss][Cc][Hh][Ee][Dd][Uu][Ll][Ee]) ([^%s]+) (%-?%d+) (.*)$",
    },
    run = run,
    min_rank = 2,
    syntax =
    {
        "MOD",
        "/scheduledelword [{hours} {minutes} {seconds}] {word}|{pattern}",
        "SUDO",
        "/schedule [{hours} {minutes} {seconds}] {method} {chat_id} {text}",
    },
}