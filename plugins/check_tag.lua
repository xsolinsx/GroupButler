notified = { }

-- recursive to simplify code
local function check_tag(msg, user_id, user)
    if msg.entities then
        for k, v in pairs(msg.entities) do
            -- check if there's a text_mention
            if msg.entities[k].type == 'text_mention' and msg.entities[k].user then
                if tonumber(msg.entities[k].user.id) == tonumber(user_id) then
                    return true
                end
            end
        end
    end

    if user then
        if type(user) == 'table' then
            -- check if first name is in message
            if msg.text then
                if string.find(msg.text, user.first_name) then
                    return true
                end
            end
            if msg.media then
                if msg.caption then
                    if string.find(msg.caption, user.first_name) then
                        return true
                    end
                end
            end
            if user.username then
                -- check if username is in message
                if msg.text then
                    if string.find(msg.text:lower(), user.username:lower()) then
                        return true
                    end
                end
                if msg.media then
                    if msg.caption then
                        if string.find(msg.caption:lower(), user.username:lower()) then
                            return true
                        end
                    end
                end
            end
            return false
        else
            if msg.text then
                if string.find(msg.text:lower(), user:lower()) then
                    return true
                end
            end
            if msg.media then
                if msg.caption then
                    if string.find(msg.caption:lower(), user:lower()) then
                        return true
                    end
                end
            end
        end
    end
end

local function run(msg, matches)
    if msg.cb then
        if matches[2] == 'ALREADYREAD' then
            answerCallbackQuery(msg.cb_id, langs[msg.lang].markedAsRead, false)
            if not deleteMessage(msg.chat.id, msg.message_id, true) then
                editMessage(msg.chat.id, msg.message_id, langs[msg.lang].markedAsRead)
            end
        elseif matches[2] == 'REGISTER' then
            if not redis:hget('tagalert:usernames', msg.from.id) then
                answerCallbackQuery(msg.cb_id, langs[msg.lang].tagalertUserRegistered, true)
                if msg.from.username then
                    redis:hset('tagalert:usernames', msg.from.id, msg.from.username:lower())
                else
                    redis:hset('tagalert:usernames', msg.from.id, true)
                end
                mystat(matches[1] .. matches[2] .. msg.from.id)
            else
                answerCallbackQuery(msg.cb_id, langs[msg.lang].userAlreadyRegistered, true)
            end
            editMessage(msg.chat.id, msg.message_id, langs[msg.lang].startMessage .. '\n' .. langs[msg.lang].nowSetNickname)
            -- editMessage(msg.chat.id, msg.message_id, langs[msg.lang].startMessage .. '\n' .. langs[msg.lang].nowSetNickname, { inline_keyboard = { { { text = langs[msg.lang].tutorialWord, url = 'http://telegra.ph/TUTORIAL-AISASHABOT-09-15' } } } })
        else
            if matches[2] == 'DELETEUP' then
                if tonumber(matches[3]) == tonumber(msg.from.id) then
                    if deleteMessage(msg.chat.id, msg.message_id) then
                        answerCallbackQuery(msg.cb_id, langs[msg.lang].upMessageDeleted, false)
                    else
                        answerCallbackQuery(msg.cb_id, langs[msg.lang].cantDeleteMessage, false)
                        editMessage(msg.chat.id, msg.message_id, langs[msg.lang].stop)
                    end
                end
                mystat(matches[1] .. matches[2] .. matches[3] .. matches[4])
            elseif matches[2] == 'GOTO' then
                local link_in_keyboard = false
                if msg.from.username then
                    local res = sendKeyboard(matches[4], 'UP @' .. msg.from.username .. '\n#tag' .. msg.from.id, keyboard_tag(matches[4], matches[3], true, msg.from.id), false, matches[3], true)
                    if data[tostring(matches[4])] then
                        if is_mod2(msg.from.id, matches[4]) or(not data[tostring(matches[4])].lock_grouplink) then
                            if data[tostring(matches[4])].link then
                                link_in_keyboard = true
                                if res then
                                    editMessage(msg.chat.id, msg.message_id, langs[msg.lang].repliedToMessage, { inline_keyboard = { { { text = langs[msg.lang].alreadyRead, callback_data = 'check_tagALREADYREAD' } }, { { text = langs[msg.lang].gotoGroup, url = data[tostring(matches[4])].link } } } }, false, false, true)
                                else
                                    editMessage(msg.chat.id, msg.message_id, langs[msg.lang].cantFindMessage, { inline_keyboard = { { { text = langs[msg.lang].alreadyRead, callback_data = 'check_tagALREADYREAD' } }, { { text = langs[msg.lang].gotoGroup, url = data[tostring(matches[4])].link } } } }, false, false, true)
                                end
                            end
                        end
                    end
                    if not link_in_keyboard then
                        if res then
                            answerCallbackQuery(msg.cb_id, langs[msg.lang].repliedToMessage, true)
                        else
                            answerCallbackQuery(msg.cb_id, langs[msg.lang].cantFindMessage, true)
                        end
                        if not deleteMessage(msg.chat.id, msg.message_id, true) then
                            if sent then
                                editMessage(msg.chat.id, msg.message_id, langs[msg.lang].repliedToMessage)
                            else
                                editMessage(msg.chat.id, msg.message_id, langs[msg.lang].cantFindMessage)
                            end
                        end
                    end
                else
                    local sent = false
                    local res = sendKeyboard(matches[4], 'UP [' .. msg.from.first_name:mEscape_hard() .. '](tg://user?id=' .. msg.from.id .. ')\n#tag' .. msg.from.id, keyboard_tag(matches[4], matches[3], true, msg.from.id), 'markdown', matches[3], true)
                    if res then
                        sent = true
                    else
                        res = sendKeyboard(matches[4], 'UP <a href="tg://user?id=' .. msg.from.id .. '">' .. html_escape(msg.from.first_name) .. '</a>\n#tag' .. msg.from.id, keyboard_tag(matches[4], matches[3], true, msg.from.id), 'html', matches[3], true)
                        if res then
                            sent = true
                        else
                            res = sendKeyboard(matches[4], 'UP [' .. msg.from.first_name .. '](tg://user?id=' .. msg.from.id .. ')\n#tag' .. msg.from.id, keyboard_tag(matches[4], matches[3], true, msg.from.id), false, matches[3], true)
                            if res then
                                sent = true
                            end
                        end
                    end
                    if data[tostring(matches[4])] then
                        if is_mod2(msg.from.id, matches[4]) or(not data[tostring(matches[4])].lock_grouplink) then
                            if data[tostring(matches[4])].link then
                                link_in_keyboard = true
                                if sent then
                                    editMessage(msg.chat.id, msg.message_id, langs[msg.lang].repliedToMessage, { inline_keyboard = { { { text = langs[msg.lang].alreadyRead, callback_data = 'check_tagALREADYREAD' } }, { { text = langs[msg.lang].gotoGroup, url = data[tostring(matches[4])].link } } } }, false, false, true)
                                else
                                    editMessage(msg.chat.id, msg.message_id, langs[msg.lang].cantFindMessage, { inline_keyboard = { { { text = langs[msg.lang].alreadyRead, callback_data = 'check_tagALREADYREAD' } }, { { text = langs[msg.lang].gotoGroup, url = data[tostring(matches[4])].link } } } }, false, false, true)
                                end
                            end
                        end
                    end
                    if sent then
                        answerCallbackQuery(msg.cb_id, langs[msg.lang].repliedToMessage, true)
                    else
                        answerCallbackQuery(msg.cb_id, langs[msg.lang].cantFindMessage, true)
                    end
                    if not link_in_keyboard then
                        if not deleteMessage(msg.chat.id, msg.message_id, true) then
                            if sent then
                                editMessage(msg.chat.id, msg.message_id, langs[msg.lang].repliedToMessage)
                            else
                                editMessage(msg.chat.id, msg.message_id, langs[msg.lang].cantFindMessage)
                            end
                        end
                    end
                end
                mystat(matches[1] .. matches[2] .. matches[3] .. matches[4])
            end
        end
        return
    end

    if matches[1]:lower() == 'enablenotices' then
        if data[tostring(msg.chat.id)] and msg.from.is_owner then
            if not data[tostring(msg.chat.id)].pmnotices then
                mystat('/enablenotices')
                data[tostring(msg.chat.id)].pmnotices = true
                return langs[msg.lang].noticesGroupEnabled
            else
                return langs[msg.lang].noticesGroupAlreadyEnabled
            end
        else
            return langs[msg.lang].useYourGroups .. '\n' .. langs[msg.lang].require_owner
        end
    end

    if matches[1]:lower() == 'disablenotices' then
        if data[tostring(msg.chat.id)] and msg.from.is_owner then
            if data[tostring(msg.chat.id)].pmnotices then
                mystat('/disablenotices')
                data[tostring(msg.chat.id)].pmnotices = false
                return langs[msg.lang].noticesGroupDisabled
            else
                return langs[msg.lang].noticesGroupAlreadyDisabled
            end
        else
            return langs[msg.lang].useYourGroups .. '\n' .. langs[msg.lang].require_owner
        end
    end

    if matches[1]:lower() == 'registernotices' then
        if msg.chat.type == 'private' then
            if not redis:get('notice:' .. msg.from.id) then
                mystat('/registernotices')
                redis:set('notice:' .. msg.from.id, 1)
                return langs[msg.lang].noticesUserRegistered
            else
                return langs[msg.lang].userAlreadyRegistered
            end
        else
            return sendReply(msg, langs[msg.lang].require_private, 'html')
        end
    end

    if matches[1]:lower() == 'unregisternotices' then
        if msg.chat.type == 'private' then
            if redis:get('notice:' .. msg.from.id) then
                mystat('/unregisternotices')
                redis:del('notice:' .. msg.from.id)
                return langs[msg.lang].noticesUserUnregistered
            else
                return langs[msg.lang].userAlreadyUnregistered
            end
        else
            return sendReply(msg, langs[msg.lang].require_private, 'html')
        end
    end

    if matches[1]:lower() == 'enabletagalert' then
        if data[tostring(msg.chat.id)] and msg.from.is_owner then
            if not data[tostring(msg.chat.id)].tagalert then
                mystat('/enabletagalert')
                data[tostring(msg.chat.id)].tagalert = true
                return langs[msg.lang].tagalertGroupEnabled
            else
                return langs[msg.lang].tagalertGroupAlreadyEnabled
            end
        else
            return langs[msg.lang].useYourGroups .. '\n' .. langs[msg.lang].require_owner
        end
    end

    if matches[1]:lower() == 'disabletagalert' then
        if data[tostring(msg.chat.id)] and msg.from.is_owner then
            if data[tostring(msg.chat.id)].tagalert then
                mystat('/disabletagalert')
                data[tostring(msg.chat.id)].tagalert = false
                return langs[msg.lang].tagalertGroupDisabled
            else
                return langs[msg.lang].tagalertGroupAlreadyDisabled
            end
        else
            return langs[msg.lang].useYourGroups .. '\n' .. langs[msg.lang].require_owner
        end
    end

    if matches[1]:lower() == 'registertagalert' then
        if msg.chat.type == 'private' then
            if not redis:hget('tagalert:usernames', msg.from.id) then
                mystat('/registertagalert')
                if msg.from.username then
                    redis:hset('tagalert:usernames', msg.from.id, msg.from.username:lower())
                else
                    redis:hset('tagalert:usernames', msg.from.id, true)
                end
                return langs[msg.lang].tagalertUserRegistered
            else
                return langs[msg.lang].userAlreadyRegistered
            end
        else
            return sendReply(msg, langs[msg.lang].require_private, 'html')
        end
    end

    if matches[1]:lower() == 'unregistertagalert' then
        if redis:hget('tagalert:usernames', msg.from.id) then
            mystat('/unregistertagalert')
            redis:hdel('tagalert:usernames', msg.from.id)
            redis:hdel('tagalert:nicknames', msg.from.id)
            return langs[msg.lang].tagalertUserUnregistered
        else
            return langs[msg.lang].tagalertRegistrationNeeded
        end
    end

    if matches[1]:lower() == 'setnickname' and matches[2] then
        if redis:hget('tagalert:usernames', msg.from.id) then
            if string.len(matches[2]) >= 3 and matches[2]:match('%w+') then
                mystat('/setnickname')
                redis:hset('tagalert:nicknames', msg.from.id, matches[2]:lower())
                return langs[msg.lang].tagalertNicknameSet
            else
                return langs[msg.lang].tagalertNicknameTooShort
            end
        else
            return langs[msg.lang].tagalertRegistrationNeeded
        end
    end

    if matches[1]:lower() == 'unsetnickname' then
        if redis:hget('tagalert:usernames', msg.from.id) then
            mystat('/unsetnickname')
            redis:hdel('tagalert:nicknames', msg.from.id)
            return langs[msg.lang].tagalertNicknameUnset
        else
            return langs[msg.lang].tagalertRegistrationNeeded
        end
    end

    --[[if matches[1]:lower() == 'tagall' then
        if msg.from.is_owner then
            return langs[msg.lang].useAISasha
            local text = ''
            if matches[2] then
                mystat('/tagall <text>')
                text = matches[2] .. "\n"
            elseif msg.reply then
                mystat('/tagall <reply_text>')
                text = msg.reply_to_message.text .. "\n"
            end
            local participants = getChatParticipants(msg.chat.id)
            for k, v in pairs(participants) do
                if v.user then
                    v = v.user
                    if v.username then
                        text = text .. "@" .. v.username .. " "
                    else
                        local print_name =(v.first_name or '') ..(v.last_name or '')
                        if print_name ~= '' then
                            text = text .. print_name .. " "
                        end
                    end
                end
            end
            return text
        else
            return langs[msg.lang].require_owner
        end
    end]]
end

local function pre_process(msg)
    if msg then
        notified = { }
        -- update usernames
        if redis:hget('tagalert:usernames', msg.from.id) then
            if msg.from.username then
                if redis:hget('tagalert:usernames', msg.from.id) ~= msg.from.username:lower() then
                    redis:hset('tagalert:usernames', msg.from.id, msg.from.username:lower())
                end
            else
                redis:hset('tagalert:usernames', msg.from.id, true)
            end
        end
        if data[tostring(msg.chat.id)] then
            -- exclude private chats with bot
            for k, v in pairs(config.sudo_users) do
                if not notified[tostring(k)] then
                    -- exclude already notified
                    if tonumber(msg.from.id) ~= tonumber(k) and tonumber(msg.from.id) ~= tonumber(bot.userVersion.id) and tonumber(k) ~= tonumber(bot.userVersion.id) then
                        -- exclude autotags and tags from tg-cli version and tags of tg-cli version
                        if check_tag(msg, k, v) then
                            local lang = get_lang(k)
                            -- set user as notified to not send multiple notifications
                            notified[tostring(k)] = true
                            if msg.reply then
                                forwardMessage(k, msg.chat.id, msg.reply_to_message.message_id)
                            end
                            local text = langs[lang].receiver .. msg.chat.print_name:gsub("_", " ") .. ' [' .. msg.chat.id .. ']\n' .. langs[lang].sender
                            if msg.from.username then
                                text = text .. '@' .. msg.from.username .. ' [' .. msg.from.id .. ']\n'
                            else
                                text = text .. msg.from.print_name:gsub("_", " ") .. ' [' .. msg.from.id .. ']\n'
                            end
                            text = text .. langs[lang].msgText

                            if msg.text then
                                text = text .. msg.text
                            end
                            if msg.media then
                                if msg.caption then
                                    text = text .. msg.caption
                                end
                            end
                            text = text .. '\n#tag' .. k
                            sendMessage(k, text)
                            sendKeyboard(k, langs[lang].whatDoYouWantToDo, keyboard_tag(msg.chat.id, msg.message_id, false, k))
                        end
                    end
                end
            end
            if data[tostring(msg.chat.id)].tagalert then
                -- if group is enabled to tagalert notifications then
                local usernames = redis:hkeys('tagalert:usernames')
                for i = 1, #usernames do
                    if not notified[tostring(usernames[i])] then
                        -- exclude already notified
                        if tonumber(msg.from.id) ~= tonumber(usernames[i]) and tonumber(msg.from.id) ~= tonumber(bot.userVersion.id) and tonumber(usernames[i]) ~= tonumber(bot.userVersion.id) then
                            -- exclude autotags and tags from tg-cli version and tags of tg-cli version
                            local usr = redis:hget('tagalert:usernames', usernames[i])
                            if usr == 'true' then
                                usr = nil
                            end
                            if check_tag(msg, usernames[i], usr) then
                                print('username', usernames[i])
                                if not msg.command then
                                    local lang = get_lang(usernames[i])
                                    -- set user as notified to not send multiple notifications
                                    notified[tostring(usernames[i])] = true
                                    if msg.reply then
                                        forwardMessage(usernames[i], msg.chat.id, msg.reply_to_message.message_id)
                                    end
                                    local text = langs[lang].receiver .. msg.chat.print_name:gsub("_", " ") .. ' [' .. msg.chat.id .. ']\n' .. langs[lang].sender
                                    if msg.from.username then
                                        text = text .. '@' .. msg.from.username .. ' [' .. msg.from.id .. ']\n'
                                    else
                                        text = text .. msg.from.print_name:gsub("_", " ") .. ' [' .. msg.from.id .. ']\n'
                                    end
                                    text = text .. langs[lang].msgText

                                    if msg.text then
                                        text = text .. msg.text
                                    end
                                    if msg.media then
                                        if msg.caption then
                                            text = text .. msg.caption
                                        end
                                    end
                                    text = text .. '\n#tag' .. usernames[i]
                                    sendMessage(usernames[i], text)
                                    sendKeyboard(usernames[i], langs[lang].whatDoYouWantToDo, keyboard_tag(msg.chat.id, msg.message_id, false, usernames[i]))
                                else
                                    print("TAG FOUND BUT COMMAND")
                                end
                            end
                        end
                    end
                end
                local nicknames = redis:hkeys('tagalert:nicknames')
                for i = 1, #nicknames do
                    if not notified[tostring(nicknames[i])] then
                        -- exclude already notified
                        if tonumber(msg.from.id) ~= tonumber(nicknames[i]) and tonumber(msg.from.id) ~= tonumber(bot.userVersion.id) and tonumber(nicknames[i]) ~= tonumber(bot.userVersion.id) then
                            -- exclude autotags and tags from tg-cli version and tags of tg-cli version
                            if check_tag(msg, nicknames[i], redis:hget('tagalert:nicknames', nicknames[i])) then
                                print('nickname', nicknames[i])
                                if not msg.command then
                                    local obj = getChatMember(msg.chat.id, nicknames[i])
                                    if type(obj) == 'table' then
                                        if obj.ok and obj.result then
                                            obj = obj.result
                                            if obj.status == 'creator' or obj.status == 'administrator' or obj.status == 'member' or obj.status == 'restricted' then
                                                local lang = get_lang(nicknames[i])
                                                -- set user as notified to not send multiple notifications
                                                notified[tostring(nicknames[i])] = true
                                                if msg.reply then
                                                    forwardMessage(nicknames[i], msg.chat.id, msg.reply_to_message.message_id)
                                                end
                                                local text = langs[lang].receiver .. msg.chat.print_name:gsub("_", " ") .. ' [' .. msg.chat.id .. ']\n' .. langs[lang].sender
                                                if msg.from.username then
                                                    text = text .. '@' .. msg.from.username .. ' [' .. msg.from.id .. ']\n'
                                                else
                                                    text = text .. msg.from.print_name:gsub("_", " ") .. ' [' .. msg.from.id .. ']\n'
                                                end
                                                text = text .. langs[lang].msgText

                                                if msg.text then
                                                    text = text .. msg.text
                                                end
                                                if msg.media then
                                                    if msg.caption then
                                                        text = text .. msg.caption
                                                    end
                                                end
                                                text = text .. '\n#tag' .. nicknames[i]
                                                sendMessage(nicknames[i], text)
                                                sendKeyboard(nicknames[i], langs[lang].whatDoYouWantToDo, keyboard_tag(msg.chat.id, msg.message_id, false, nicknames[i]))
                                            end
                                        end
                                    end
                                else
                                    print("TAG FOUND BUT COMMAND")
                                end
                            end
                        end
                    end
                end
            end
        end
        return msg
    end
end

return {
    description = "CHECK_TAG",
    patterns =
    {
        "^(###cbcheck_tag)(ALREADYREAD)$",
        "^(###cbcheck_tag)(REGISTER)$",
        "^(###cbcheck_tag)(DELETEUP)(%d+)(%-%d+)$",
        "^(###cbcheck_tag)(GOTO)(%d+)(%-%d+)$",

        "^[#!/]([Ee][Nn][Aa][Bb][Ll][Ee][Tt][Aa][Gg][Aa][Ll][Ee][Rr][Tt])$",
        "^[#!/]([Dd][Ii][Ss][Aa][Bb][Ll][Ee][Tt][Aa][Gg][Aa][Ll][Ee][Rr][Tt])$",
        "^[#!/]([Rr][Ee][Gg][Ii][Ss][Tt][Ee][Rr][Tt][Aa][Gg][Aa][Ll][Ee][Rr][Tt])$",
        "^[#!/]([Uu][Nn][Rr][Ee][Gg][Ii][Ss][Tt][Ee][Rr][Tt][Aa][Gg][Aa][Ll][Ee][Rr][Tt])$",
        "^[#!/]([Ee][Nn][Aa][Bb][Ll][Ee][Nn][Oo][Tt][Ii][Cc][Ee][Ss])$",
        "^[#!/]([Dd][Ii][Ss][Aa][Bb][Ll][Ee][Nn][Oo][Tt][Ii][Cc][Ee][Ss])$",
        "^[#!/]([Rr][Ee][Gg][Ii][Ss][Tt][Ee][Rr][Nn][Oo][Tt][Ii][Cc][Ee][Ss])$",
        "^[#!/]([Uu][Nn][Rr][Ee][Gg][Ii][Ss][Tt][Ee][Rr][Nn][Oo][Tt][Ii][Cc][Ee][Ss])$",
        "^[#!/]([Ss][Ee][Tt][Nn][Ii][Cc][Kk][Nn][Aa][Mm][Ee]) (.*)$",
        "^[#!/]([Uu][Nn][Ss][Ee][Tt][Nn][Ii][Cc][Kk][Nn][Aa][Mm][Ee])$",
        "^[#!/]([Tt][Aa][Gg][Aa][Ll][Ll])$",
        "^[#!/]([Tt][Aa][Gg][Aa][Ll][Ll]) +(.+)$",
    },
    run = run,
    pre_process = pre_process,
    min_rank = 1,
    syntax =
    {
        "USER",
        "/registertagalert",
        "/unregistertagalert",
        "/registernotices",
        "/unregisternotices",
        "/setnickname {nickname}",
        "/unsetnickname",
        "OWNER",
        "/enabletagalert",
        "/disabletagalert",
        "/enablenotices",
        "/disablenotices",
        -- "/tagall {text}|{reply_text}",
    },
}