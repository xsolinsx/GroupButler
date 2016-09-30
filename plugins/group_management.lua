-- REFACTORING OF INPM.LUA INREALM.LUA INGROUP.LUA AND SUPERGROUP.LUA

group_type = ''

-- INPM
local function allChats(msg)
    i = 1
    local data = load_data(config.moderation.data)
    local groups = 'groups'
    if not data[tostring(groups)] then
        return langs[msg.lang].noGroups
    end
    local message = langs[msg.lang].groupsJoin
    for k, v in pairsByKeys(data[tostring(groups)]) do
        local group_id = v
        if data[tostring(group_id)] then
            settings = data[tostring(group_id)]['settings']
        end
        for m, n in pairsByKeys(settings) do
            if m == 'set_name' then
                name = n:gsub("", "")
                chat_name = name:gsub("?", "")
                group_name_id = name .. '\n(ID: ' .. group_id .. ')\n'
                if name:match("[\216-\219][\128-\191]") then
                    group_info = i .. '. \n' .. group_name_id
                else
                    group_info = i .. '. ' .. group_name_id
                end
                i = i + 1
            end
        end
        message = message .. group_info
    end

    i = 1
    local realms = 'realms'
    if not data[tostring(realms)] then
        return langs[msg.lang].noRealms
    end
    message = message .. '\n\n' .. langs[msg.lang].realmsJoin
    for k, v in pairsByKeys(data[tostring(realms)]) do
        local realm_id = v
        if data[tostring(realm_id)] then
            settings = data[tostring(realm_id)]['settings']
        end
        for m, n in pairsByKeys(settings) do
            if m == 'set_name' then
                name = n:gsub("", "")
                chat_name = name:gsub("?", "")
                realm_name_id = name .. '\n(ID: ' .. realm_id .. ')\n'
                if name:match("[\216-\219][\128-\191]") then
                    realm_info = i .. '. \n' .. realm_name_id
                else
                    realm_info = i .. '. ' .. realm_name_id
                end
                i = i + 1
            end
        end
        message = message .. realm_info
    end
    local file = io.open("./groups/lists/all_listed_groups.txt", "w")
    file:write(message)
    file:flush()
    file:close()
    return message
end

-- INREALM
local function groupsList(msg)
    local data = load_data(config.moderation.data)
    if not data.groups then
        return langs[msg.lang].noGroups
    end
    local message = langs[msg.lang].groupListStart
    for k, v in pairs(data.groups) do
        if data[tostring(v)] then
            if data[tostring(v)]['settings'] then
                local settings = data[tostring(v)]['settings']
                for m, n in pairs(settings) do
                    if m == 'set_name' then
                        name = n
                    end
                end
                local group_owner = "No owner"
                if data[tostring(v)]['set_owner'] then
                    group_owner = tostring(data[tostring(v)]['set_owner'])
                end
                local group_link = "No link"
                if data[tostring(v)]['settings']['set_link'] then
                    group_link = data[tostring(v)]['settings']['set_link']
                end
                message = message .. name .. ' ' .. v .. ' - ' .. group_owner .. '\n{' .. group_link .. "}\n"
            end
        end
    end
    local file = io.open("./groups/lists/groups.txt", "w")
    file:write(message)
    file:flush()
    file:close()
    return message
end

local function realmsList(msg)
    local data = load_data(config.moderation.data)
    if not data.realms then
        return langs[msg.lang].noRealms
    end
    local message = langs[msg.lang].realmListStart
    for k, v in pairs(data.realms) do
        local settings = data[tostring(v)]['settings']
        for m, n in pairs(settings) do
            if m == 'set_name' then
                name = n
            end
        end
        local group_owner = "No owner"
        if data[tostring(v)]['admins_in'] then
            group_owner = tostring(data[tostring(v)]['admins_in'])
        end
        local group_link = "No link"
        if data[tostring(v)]['settings']['set_link'] then
            group_link = data[tostring(v)]['settings']['set_link']
        end
        message = message .. name .. ' ' .. v .. ' - ' .. group_owner .. '\n{' .. group_link .. "}\n"
    end
    local file = io.open("./groups/lists/realms.txt", "w")
    file:write(message)
    file:flush()
    file:close()
    return message
end

-- begin ADD/REM GROUPS
local function addGroup(msg)
    if is_group(msg) then
        return langs[msg.lang].groupAlreadyAdded
    end
    local data = load_data(config.moderation.data)
    local list = getChatAdministrators(msg.chat.id)
    if list then
        for i, admin in pairs(list.result) do
            if admin.status == 'creator' then
                -- Group configuration
                data[tostring(msg.chat.id)] = {
                    goodbye = "",
                    group_type = 'Group',
                    moderators = { },
                    rules = "",
                    set_name = string.gsub(msg.chat.print_name,'_',' '),
                    set_owner = tostring(admin.user.id),
                    settings =
                    {
                        flood = true,
                        flood_max = 5,
                        lock_arabic = false,
                        lock_leave = false,
                        lock_link = false,
                        lock_member = false,
                        lock_rtl = false,
                        lock_spam = false,
                        mutes =
                        {
                            all = false,
                            audio = false,
                            contact = false,
                            document = false,
                            gif = false,
                            location = false,
                            photo = false,
                            sticker = false,
                            text = false,
                            tgservice = false,
                            video = false,
                            voice = false,
                        },
                        strict = false,
                        warn_max = 3,
                    },
                    welcome = "",
                    welcomemembers = 0,
                }
                save_data(config.moderation.data, data)
                if not data['groups'] then
                    data['groups'] = { }
                    save_data(config.moderation.data, data)
                end
                data['groups'][tostring(msg.chat.id)] = msg.chat.id
                save_data(config.moderation.data, data)
            end
        end
        if data[tostring(msg.chat.id)] then
            for i, admin in pairs(list.result) do
                if admin.status == 'administrator' then
                    table.insert(data[tostring(msg.chat.id)].moderators, admin.user.id .. admin.user.username or(admin.user.first_name ..(admin.user.last_name or '')))
                end
            end
        end
        return sendMessage(msg.chat.id, langs[msg.lang].groupAddedOwner)
    end
end

local function remGroup(msg)
    local data = load_data(config.moderation.data)
    if not is_group(msg) then
        return langs[msg.lang].groupNotAdded
    end
    -- Group configuration removal
    data[tostring(msg.chat.id)] = nil
    save_data(config.moderation.data, data)
    if not data['groups'] then
        data['groups'] = nil
        save_data(config.moderation.data, data)
    end
    data['groups'][tostring(msg.chat.id)] = nil
    save_data(config.moderation.data, data)
    return sendMessage(msg.chat.id, langs[msg.lang].groupRemoved)
end

local function addRealm(msg)
    local data = load_data(config.moderation.data)
    if is_realm(msg) then
        return langs[msg.lang].realmAlreadyAdded
    end
    local list = getChatAdministrators(msg.chat.id)
    if list then
        for i, admin in pairs(list.result) do
            if admin.status == 'creator' then
                -- Realm configuration
                data[tostring(msg.chat.id)] = {
                    goodbye = "",
                    group_type = 'Realm',
                    moderators = { },
                    rules = "",
                    set_name = string.gsub(msg.chat.print_name,'_',' '),
                    set_owner = tostring(admin.user.id),
                    settings =
                    {
                        flood = true,
                        flood_max = 5,
                        lock_arabic = false,
                        lock_leave = false,
                        lock_link = false,
                        lock_member = false,
                        lock_rtl = false,
                        lock_spam = false,
                        mutes =
                        {
                            all = false,
                            audio = false,
                            contact = false,
                            document = false,
                            gif = false,
                            location = false,
                            photo = false,
                            sticker = false,
                            text = false,
                            tgservice = false,
                            video = false,
                            voice = false,
                        },
                        strict = false,
                        warn_max = 3,
                    },
                    welcome = "",
                    welcomemembers = 0,
                }
                save_data(config.moderation.data, data)
                if not data['realms'] then
                    data['realms'] = { }
                    save_data(config.moderation.data, data)
                end
                data['realms'][tostring(msg.chat.id)] = msg.chat.id
                save_data(config.moderation.data, data)
                return sendMessage(msg.chat.id, langs[msg.lang].realmAdded)
            end
        end
    end
end

local function remRealm(msg)
    local data = load_data(config.moderation.data)
    if not is_realm(msg) then
        return langs[msg.lang].realmNotAdded
    end
    -- Realm configuration removal
    data[tostring(msg.chat.id)] = nil
    save_data(config.moderation.data, data)
    if not data['realms'] then
        data['realms'] = nil
        save_data(config.moderation.data, data)
    end
    data['realms'][tostring(msg.chat.id)] = nil
    save_data(config.moderation.data, data)
    return sendMessage(msg.chat.id, langs[msg.lang].realmRemoved)
end

local function addSuperGroup(msg)
    local data = load_data(config.moderation.data)
    if is_super_group(msg) then
        return langs[msg.lang].supergroupAlreadyAdded
    end
    local list = getChatAdministrators(msg.chat.id)
    if list then
        for i, admin in pairs(list.result) do
            if admin.status == 'creator' then
                -- SuperGroup configuration
                data[tostring(msg.chat.id)] = {
                    goodbye = "",
                    group_type = 'SuperGroup',
                    moderators = { },
                    rules = "",
                    set_name = string.gsub(msg.chat.print_name,'_',' '),
                    set_owner = tostring(admin.user.id),
                    settings =
                    {
                        flood = true,
                        flood_max = 5,
                        lock_arabic = false,
                        lock_leave = false,
                        lock_link = false,
                        lock_member = false,
                        lock_rtl = false,
                        lock_spam = false,
                        mutes =
                        {
                            all = false,
                            audio = false,
                            contact = false,
                            document = false,
                            gif = false,
                            location = false,
                            photo = false,
                            sticker = false,
                            text = false,
                            tgservice = false,
                            video = false,
                            voice = false,
                        },
                        strict = false,
                        warn_max = 3,
                    },
                    welcome = "",
                    welcomemembers = 0,
                }
                save_data(config.moderation.data, data)
                if not data['groups'] then
                    data['groups'] = { }
                    save_data(config.moderation.data, data)
                end
                data['groups'][tostring(msg.chat.id)] = msg.chat.id
                save_data(config.moderation.data, data)
            end
        end
        if data[tostring(msg.chat.id)] then
            for i, admin in pairs(list.result) do
                if admin.status == 'administrator' then
                    table.insert(data[tostring(msg.chat.id)].moderators, admin.user.id .. admin.user.username or(admin.user.first_name ..(admin.user.last_name or '')))
                end
            end
        end
        return sendMessage(msg.chat.id, langs[msg.lang].groupAddedOwner)
    end
end

local function remSuperGroup(msg)
    local data = load_data(config.moderation.data)
    if not is_super_group(msg) then
        return langs[msg.lang].groupNotAdded
    end
    -- Group configuration removal
    data[tostring(msg.chat.id)] = nil
    save_data(config.moderation.data, data)
    if not data['groups'] then
        data['groups'] = nil
        save_data(config.moderation.data, data)
    end
    data['groups'][tostring(msg.chat.id)] = nil
    save_data(config.moderation.data, data)
    return sendMessage(msg.chat.id, langs[msg.lang].supergroupRemoved)
end
-- end ADD/REM GROUPS

-- begin RANKS MANAGEMENT
local function promoteAdmin(user, chat_id)
    local lang = get_lang(chat_id)
    local data = load_data(config.moderation.data)
    if not data.admins then
        data.admins = { }
        save_data(config.moderation.data, data)
    end
    if data.admins[tostring(user.id)] then
        return sendMessage(chat_id,(user.username or user.print_name) .. langs[lang].alreadyAdmin)
    end
    data.admins[tostring(user.id)] =(user.username or user.print_name)
    save_data(config.moderation.data, data)
    return sendMessage(chat_id,(user.username or user.print_name) .. langs[lang].promoteAdmin)
end

local function demoteAdmin(user, chat_id)
    local lang = get_lang(chat_id)
    local data = load_data(config.moderation.data)
    if not data.admins then
        data.admins = { }
        save_data(config.moderation.data, data)
    end
    if not data.admins[tostring(user.id)] then
        return sendMessage(chat_id,(user.username or user.print_name) .. langs[lang].notAdmin)
    end
    data.admins[tostring(user.id)] = nil
    save_data(config.moderation.data, data)
    return sendMessage(chat_id,(user.username or user.print_name) .. langs[lang].demoteAdmin)
end

local function botAdminsList(chat_id)
    local lang = get_lang(chat_id)
    local data = load_data(config.moderation.data)
    if not data.admins then
        data.admins = { }
        save_data(config.moderation.data, data)
    end
    local message = langs[lang].adminListStart
    for k, v in pairs(data.admins) do
        message = message .. v .. ' - ' .. k .. '\n'
    end
    return sendMessage(chat_id, message)
end

local function setOwner(user, chat_id)
    local data = load_data(config.moderation.data)
    local lang = get_lang(chat_id)
    data[tostring(chat_id)]['set_owner'] = tostring(user.id)
    save_data(config.moderation.data, data)
    return(user.username or user.print_name) .. ' [' .. user.id .. ']' .. langs[lang].setOwner
end

local function getAdmins(chat_id)
    local list = getChatAdministrators(chat_id)
    if list then
        local text = ''
        for i, admin in pairs(list.result) do
            text = text ..(admin.user.username or admin.user.first_name) .. ' [' .. admin.user.id .. ']\n'
        end
        return text
    end
end

local function promoteMod(chat_id, user)
    local lang = get_lang(chat_id)
    local data = load_data(config.moderation.data)
    if not data[tostring(chat_id)] then
        return sendMessage(chat_id, langs[lang].groupNotAdded)
    end
    if data[tostring(chat_id)]['moderators'][tostring(user.id)] then
        return sendMessage(chat_id,(user.username or user.print_name) .. langs[lang].alreadyMod)
    end
    data[tostring(chat_id)]['moderators'][tostring(user.id)] =(user.username or user.print_name)
    save_data(config.moderation.data, data)
    return sendMessage(chat_id,(user.username or user.print_name) .. langs[lang].promoteMod)
end

local function demoteMod(chat_id, user)
    local lang = get_lang(chat_id)
    local data = load_data(config.moderation.data)
    if not data[tostring(chat_id)] then
        return sendMessage(chat_id, langs[lang].groupNotAdded)
    end
    if not data[tostring(chat_id)]['moderators'][tostring(user.id)] then
        return sendMessage(chat_id,(user.username or user.print_name) .. langs[lang].notMod)
    end
    data[tostring(chat_id)]['moderators'][tostring(user.id)] = nil
    save_data(config.moderation.data, data)
    return sendMessage(chat_id,(user.username or user.print_name) .. langs[lang].demoteMod)
end

local function modList(msg)
    local data = load_data(config.moderation.data)
    local groups = "groups"
    if not data[tostring(groups)][tostring(msg.chat.id)] then
        return langs[msg.lang].groupNotAdded
    end
    -- determine if table is empty
    if next(data[tostring(msg.chat.id)]['moderators']) == nil then
        -- fix way
        return langs[msg.lang].noGroupMods
    end
    local i = 1
    local message = langs[msg.lang].modListStart .. string.gsub(msg.chat.print_name, '_', ' ') .. ':\n'
    for k, v in pairs(data[tostring(msg.chat.id)]['moderators']) do
        message = message .. i .. '. ' .. v .. ' - ' .. k .. '\n'
        i = i + 1
    end
    return message
end

local function contactMods(msg)
    local text = langs[msg.lang].receiver .. msg.chat.print_name:gsub("_", " ") .. ' [' .. msg.chat.id .. ']\n' .. langs[msg.lang].sender
    if msg.from.username then
        text = text .. '@' .. msg.from.username .. ' [' .. msg.from.id .. ']\n'
    else
        text = text .. msg.from.print_name:gsub("_", " ") .. ' [' .. msg.from.id .. ']\n'
    end
    text = text .. langs[msg.lang].msgText ..(msg.text or msg.caption) .. '\n'
    if msg.reply then
        text = text .. langs[msg.lang].replyText ..(msg.reply_to_message.text or msg.reply_to_message.caption)
    end


    local already_contacted = { }
    local list = getChatAdministrators(msg.chat.id)
    if list then
        for i, admin in pairs(list.result) do
            already_contacted[tonumber(admin.user.id)] = admin.user.id
            sendMessage(admin.user.id, text)
        end
    end

    local data = load_data(config.moderation.data)

    -- owner
    local owner = data[tostring(msg.chat.id)]['set_owner']
    if owner then
        if not already_contacted[tonumber(owner)] then
            already_contacted[tonumber(owner)] = owner
            sendMessage(owner, text)
        end
    end

    -- determine if table is empty
    if next(data[tostring(msg.chat.id)]['moderators']) == nil then
        -- fix way
        return
    end
    for k, v in pairs(data[tostring(msg.chat.id)]['moderators']) do
        if not already_contacted[tonumber(k)] then
            already_contacted[tonumber(k)] = k
            sendMessage(k, text)
        end
    end
end
-- end RANKS MANAGEMENT

local function showSettings(target, lang)
    local data = load_data(config.moderation.data)
    if data[tostring(target)] then
        if data[tostring(target)]['settings'] then
            local settings = data[tostring(target)]['settings']
            local text = langs[lang].groupSettings ..
            langs[lang].arabicLock .. tostring(settings.lock_arabic) ..
            langs[lang].floodLock .. tostring(settings.flood) ..
            langs[lang].floodSensibility .. tostring(settings.flood_max) ..
            langs[lang].leaveLock .. tostring(settings.lock_leave) ..
            langs[lang].linksLock .. tostring(settings.lock_link) ..
            langs[lang].membersLock .. tostring(settings.lock_member) ..
            langs[lang].spamLock .. tostring(settings.lock_spam) ..
            langs[lang].strictrules .. tostring(settings.strict) ..
            langs[lang].warnSensibility .. tostring(settings.warn_max)
            return text
        end
    end
end

-- begin LOCK/UNLOCK FUNCTIONS
local function adjustSettingType(setting_type)
    if setting_type == 'arabic' then
        setting_type = 'lock_arabic'
    end
    if setting_type == 'flood' then
        setting_type = 'flood'
    end
    if setting_type == 'leave' then
        setting_type = 'lock_leave'
    end
    if setting_type == 'link' then
        setting_type = 'lock_link'
    end
    if setting_type == 'member' then
        setting_type = 'lock_member'
    end
    if setting_type == 'rtl' then
        setting_type = 'lock_rtl'
    end
    if setting_type == 'spam' then
        setting_type = 'lock_spam'
    end
    if setting_type == 'strict' then
        setting_type = 'strict'
    end
    return setting_type
end

function lockSetting(data, target, setting_type)
    local lang = get_lang(target)
    setting_type = adjustSettingType(setting_type)
    local setting = data[tostring(target)].settings[tostring(setting_type)]
    if setting ~= nil then
        if setting then
            return langs[lang].settingAlreadyLocked
        else
            data[tostring(target)].settings[tostring(setting_type)] = true
            save_data(config.moderation.data, data)
            return langs[lang].settingLocked
        end
    end
end

function unlockSetting(data, target, setting_type)
    local lang = get_lang(target)
    setting_type = adjustSettingType(setting_type)
    local setting = data[tostring(target)].settings[tostring(setting_type)]
    if setting ~= nil then
        if setting then
            data[tostring(target)].settings[tostring(setting_type)] = false
            save_data(config.moderation.data, data)
            return langs[lang].settingUnlocked
        else
            return langs[lang].settingAlreadyUnlocked
        end
    end
end
-- end LOCK/UNLOCK FUNCTIONS

local function run(msg, matches)
    local data = load_data(config.moderation.data)
    if matches[1]:lower() == 'type' then
        if is_mod(msg) then
            mystat('/type')
            if data[tostring(msg.chat.id)] then
                if not data[tostring(msg.chat.id)]['group_type'] then
                    if msg.chat.type == 'group' and not is_realm(msg) then
                        data[tostring(msg.chat.id)]['group_type'] = 'Group'
                        save_data(config.moderation.data, data)
                    elseif msg.chat.type == 'supergroup' then
                        data[tostring(msg.chat.id)]['group_type'] = 'SuperGroup'
                        save_data(config.moderation.data, data)
                    end
                end
                return data[tostring(msg.chat.id)]['group_type']
            else
                return langs[msg.lang].chatTypeNotFound
            end
        else
            return langs[msg.lang].require_mod
        end
    end
    if matches[1]:lower() == 'log' then
        if is_owner(msg) then
            mystat('/log')
            savelog(msg.chat.id, "log file created by owner/admin")
            return sendDocument(msg.chat.id, "./groups/logs/" .. msg.chat.id .. "log.txt")
        else
            return langs[msg.lang].require_owner
        end
    end
    if matches[1]:lower() == 'admins' then
        mystat('/admins')
        return contactMods(msg)
    end

    -- INPM
    if is_sudo(msg) or msg.chat.type == 'private' then
        if matches[1]:lower() == 'allchats' then
            if is_admin(msg) then
                mystat('/allchats')
                return allChats(msg)
            else
                return langs[msg.lang].require_admin
            end
        end

        if matches[1]:lower() == 'allchatslist' then
            if is_admin(msg) then
                mystat('/allchatslist')
                allChats(msg)
                return sendDocument(msg.chat.id, "./groups/lists/all_listed_groups.txt")
            else
                return langs[msg.lang].require_admin
            end
        end
    end

    -- INREALM
    if is_realm(msg) then
        if matches[1]:lower() == 'rem' and string.match(matches[2], '^%-?%d+$') then
            if is_admin(msg) then
                mystat('/rem <group_id>')
                -- Group configuration removal
                data[tostring(matches[2])] = nil
                save_data(config.moderation.data, data)
                if not data[tostring('groups')] then
                    data[tostring('groups')] = nil
                    save_data(config.moderation.data, data)
                end
                data[tostring('groups')][tostring(matches[2])] = nil
                save_data(config.moderation.data, data)
                return sendMessage(msg.chat.id, langs[msg.lang].chat .. matches[2] .. langs[msg.lang].removed)
            else
                return langs[msg.lang].require_admin
            end
        end
        if matches[1]:lower() == 'addadmin' then
            if is_sudo(msg) then
                mystat('/addadmin')
                if msg.reply then
                    return promoteAdmin(msg.reply_to_message.from, msg.chat.id)
                elseif string.match(matches[2], '^%d+$') then
                    local obj_user = getChat(matches[2])
                    if type(obj_user) == 'table' then
                        if obj_user.result then
                            obj_user = obj_user.result
                            if obj_user then
                                if obj_user.type == 'private' then
                                    return promoteAdmin(obj_user, msg.chat.id)
                                end
                            end
                        end
                    end
                else
                    local obj_user = resolveUsername(matches[2]:gsub('@', ''))
                    if obj_user then
                        if obj_user.type == 'private' then
                            return promoteAdmin(obj_user, msg.chat.id)
                        end
                    end
                end
                return
            else
                return langs[msg.lang].require_sudo
            end
        end
        if matches[1]:lower() == 'removeadmin' then
            if is_sudo(msg) then
                mystat('/removeadmin')
                if msg.reply then
                    return demoteAdmin(msg.reply_to_message.from, msg.chat.id)
                elseif string.match(matches[2], '^%d+$') then
                    local obj_user = getChat(matches[2])
                    if type(obj_user) == 'table' then
                        if obj_user.result then
                            obj_user = obj_user.result
                            if obj_user then
                                if obj_user.type == 'private' then
                                    return demoteAdmin(obj_user, msg.chat.id)
                                end
                            end
                        end
                    end
                else
                    local obj_user = resolveUsername(matches[2]:gsub('@', ''))
                    if obj_user then
                        if obj_user.type == 'private' then
                            return demoteAdmin(obj_user, msg.chat.id)
                        end
                    end
                end
                return
            else
                return langs[msg.lang].require_sudo
            end
        end
        if matches[1]:lower() == 'list' then
            if is_admin(msg) then
                if matches[2]:lower() == 'admins' then
                    mystat('/list admins')
                    return botAdminsList(msg.chat.id)
                elseif matches[2]:lower() == 'groups' then
                    mystat('/list groups')
                    if msg.chat.type == 'group' or msg.chat.type == 'supergroup' then
                        groupsList(msg)
                        sendDocument(msg.chat.id, "./groups/lists/groups.txt")
                        -- return group_list(msg)
                    elseif msg.chat.type == 'private' then
                        groupsList(msg)
                        sendDocument(msg.from.id, "./groups/lists/groups.txt")
                        -- return group_list(msg)
                    end
                    return langs[msg.lang].groupListCreated
                elseif matches[2]:lower() == 'realms' then
                    mystat('/list realms')
                    if msg.chat.type == 'group' or msg.chat.type == 'supergroup' then
                        realmsList(msg)
                        sendDocument(msg.chat.id, "./groups/lists/realms.txt")
                        -- return realmsList(msg)
                    elseif msg.chat.type == 'private' then
                        realmsList(msg)
                        sendDocument(msg.from.id, "./groups/lists/realms.txt")
                        -- return realmsList(msg)
                    end
                    return langs[msg.lang].realmListCreated
                end
            else
                return langs[msg.lang].require_admin
            end
        end
        if (matches[1]:lower() == 'lock' or matches[1]:lower() == 'sasha blocca' or matches[1]:lower() == 'blocca') and matches[2] and matches[3] then
            if is_admin(msg) then
                local flag = false
                if matches[3]:lower() == 'arabic' then
                    flag = true
                end
                if matches[3]:lower() == 'flood' then
                    flag = true
                end
                if matches[3]:lower() == 'leave' then
                    flag = true
                end
                if matches[3]:lower() == 'link' then
                    flag = true
                end
                if matches[3]:lower() == 'member' then
                    flag = true
                end
                if matches[3]:lower() == 'rtl' then
                    flag = true
                end
                if matches[3]:lower() == 'spam' then
                    flag = true
                end
                if matches[3]:lower() == 'strict' then
                    flag = true
                end
                if flag then
                    mystat('/lock <group_id> ' .. matches[3]:lower())
                    return lockSetting(data, matches[2], matches[3]:lower())
                end
            else
                return langs[msg.lang].require_admin
            end
        end
        if (matches[1]:lower() == 'unlock' or matches[1]:lower() == 'sasha sblocca' or matches[1]:lower() == 'sblocca') and matches[2] and matches[3] then
            if is_admin(msg) then
                local flag = false
                if matches[3]:lower() == 'arabic' then
                    flag = true
                end
                if matches[3]:lower() == 'flood' then
                    flag = true
                end
                if matches[3]:lower() == 'leave' then
                    flag = true
                end
                if matches[3]:lower() == 'link' then
                    flag = true
                end
                if matches[3]:lower() == 'member' then
                    flag = true
                end
                if matches[3]:lower() == 'rtl' then
                    flag = true
                end
                if matches[3]:lower() == 'spam' then
                    flag = true
                end
                if matches[3]:lower() == 'strict' then
                    flag = true
                end
                if flag then
                    mystat('/unlock <group_id> ' .. matches[3]:lower())
                    return unlockSetting(data, matches[2], matches[3]:lower())
                end
            else
                return langs[msg.lang].require_admin
            end
        end
        if matches[1]:lower() == 'settings' and data[tostring(matches[2])].settings then
            if is_admin(msg) then
                mystat('/settings <group_id>')
                return showSettings(matches[2], msg.lang)
            else
                return langs[msg.lang].require_admin
            end
        end
        if matches[1]:lower() == 'setgprules' and matches[2] and matches[3] then
            if is_admin(msg) then
                mystat('/setgprules <group_id>')
                data[tostring(matches[2])].rules = matches[3]
                save_data(config.moderation.data, data)
                return langs[msg.lang].newRules .. matches[3]
            else
                return langs[msg.lang].require_admin
            end
        end
        if matches[1]:lower() == 'setgpowner' and matches[2] and matches[3] then
            if is_admin(msg) then
                mystat('/setgpowner <group_id> <user_id>')
                data[tostring(matches[2])].set_owner = matches[3]
                save_data(config.moderation.data, data)
                sendMessage(matches[2], matches[3] .. langs[lang].setOwner)
                return sendMessage(msg.chat.id, matches[3] .. langs[lang].setOwner)
            else
                return langs[msg.lang].require_admin
            end
        end
    end

    -- INGROUP/SUPERGROUP
    if msg.chat.type == 'group' or msg.chat.type == 'supergroup' then
        if matches[1]:lower() == 'add' and not matches[2] then
            if is_admin(msg) then
                if is_realm(msg) then
                    return langs[msg.lang].errorAlreadyRealm
                end
                if msg.chat.type == 'group' then
                    mystat('/add')
                    if is_group(msg) then
                        return sendReply(msg, langs[msg.lang].groupAlreadyAdded)
                    end
                    savelog(msg.chat.id, msg.from.print_name .. " [" .. msg.from.id .. "] added group [ " .. msg.chat.id .. " ]")
                    print("group " .. msg.chat.print_name .. "(" .. msg.chat.id .. ") added")
                    return addGroup(msg)
                elseif msg.chat.type == 'supergroup' then
                    mystat('/add')
                    if is_super_group(msg) then
                        return sendReply(msg, langs[msg.lang].supergroupAlreadyAdded)
                    end
                    print("SuperGroup " .. msg.chat.print_name .. "(" .. msg.chat.id .. ") added")
                    savelog(msg.chat.id, msg.from.print_name .. " [" .. msg.from.id .. "] added SuperGroup")
                    return addSuperGroup(msg)
                end
            else
                savelog(msg.chat.id, msg.from.print_name .. " [" .. msg.from.id .. "] attempted to add group [ " .. msg.chat.id .. " ]")
                return langs[msg.lang].require_admin
            end
        end
        if matches[1]:lower() == 'add' and matches[2]:lower() == 'realm' then
            if is_sudo(msg) then
                if is_group(msg) then
                    return langs[msg.lang].errorAlreadyGroup
                end
                mystat('/add realm')
                if msg.chat.type == 'group' then
                    savelog(msg.chat.id, msg.from.print_name .. " [" .. msg.from.id .. "] added realm [ " .. msg.chat.id .. " ]")
                    print("group " .. msg.chat.print_name .. "(" .. msg.chat.id .. ") added as a realm")
                    return addRealm(msg)
                end
            else
                savelog(msg.chat.id, msg.from.print_name .. " [" .. msg.from.id .. "] attempted to add realm [ " .. msg.chat.id .. " ]")
                return langs[msg.lang].require_sudo
            end
        end
        if matches[1]:lower() == 'rem' and not matches[2] then
            if is_admin(msg) then
                if is_realm(msg) then
                    return langs[msg.lang].errorRealm
                end
                if msg.chat.type == 'group' then
                    if not is_group(msg) then
                        return sendReply(msg, langs[msg.lang].groupRemoved)
                    end
                    mystat('/rem')
                    savelog(msg.chat.id, msg.from.print_name .. " [" .. msg.from.id .. "] removed group [ " .. msg.chat.id .. " ]")
                    print("group " .. msg.chat.print_name .. "(" .. msg.chat.id .. ") removed")
                    return remGroup(msg)
                elseif msg.chat.type == 'supergroup' then
                    if not is_super_group(msg) then
                        return sendReply(msg, langs[msg.lang].supergroupRemoved)
                    end
                    mystat('/rem')
                    print("SuperGroup " .. msg.chat.print_name .. "(" .. msg.chat.id .. ") removed")
                    return remSuperGroup(msg)
                end
            else
                savelog(msg.chat.id, msg.from.print_name .. " [" .. msg.from.id .. "] attempted to remove group [ " .. msg.chat.id .. " ]")
                return langs[msg.lang].require_admin
            end
        end
        if matches[1]:lower() == 'rem' and matches[2]:lower() == 'realm' then
            if is_sudo(msg) then
                if not is_realm(msg) then
                    return langs[msg.lang].errorNotRealm
                end
                mystat('/rem realm')
                savelog(msg.chat.id, msg.from.print_name .. " [" .. msg.from.id .. "] removed realm [ " .. msg.chat.id .. " ]")
                print("group " .. msg.chat.print_name .. "(" .. msg.chat.id .. ") removed as a realm")
                return remRealm(msg)
            else
                savelog(msg.chat.id, msg.from.print_name .. " [" .. msg.from.id .. "] attempted to remove realm [ " .. msg.chat.id .. " ]")
                return langs[msg.lang].require_sudo
            end
        end
        if data[tostring(msg.chat.id)] then
            if matches[1]:lower() == 'rules' or matches[1]:lower() == 'sasha regole' then
                mystat('/rules')
                savelog(msg.chat.id, msg.from.print_name .. " [" .. msg.from.id .. "] requested group rules")
                if not data[tostring(msg.chat.id)].rules then
                    return langs[msg.lang].noRules
                end
                return langs[msg.lang].rules .. data[tostring(msg.chat.id)]['rules']
            end
            if matches[1]:lower() == 'setrules' or matches[1]:lower() == 'sasha imposta regole' then
                mystat('/setrules')
                if is_mod(msg) then
                    data[tostring(msg.chat.id)].rules = matches[2]
                    save_data(config.moderation.data, data)
                    savelog(msg.chat.id, msg.from.print_name .. " [" .. msg.from.id .. "] has changed group rules to [" .. matches[2] .. "]")
                    return langs[msg.lang].newRules .. matches[2]
                else
                    return langs[msg.lang].require_mod
                end
            end
            if matches[1]:lower() == 'setflood' then
                if is_mod(msg) then
                    if tonumber(matches[2]) < 3 or tonumber(matches[2]) > 200 then
                        return langs[msg.lang].errorFloodRange
                    end
                    mystat('/setflood')
                    data[tostring(msg.chat.id)].settings.flood_max = matches[2]
                    save_data(config.moderation.data, data)
                    savelog(msg.chat.id, msg.from.print_name .. " [" .. msg.from.id .. "] set flood to [" .. matches[2] .. "]")
                    return langs[msg.lang].floodSet .. matches[2]
                else
                    return langs[msg.lang].require_mod
                end
            end
            if matches[1]:lower() == 'getwarn' then
                mystat('/getwarn')
                return getWarn(msg.chat.id)
            end
            if matches[1]:lower() == 'setwarn' and matches[2] then
                if is_mod(msg) then
                    mystat('/setwarn')
                    local txt = setWarn(msg.from.id, msg.chat.id, matches[2])
                    if matches[2] == '0' then
                        return langs[msg.lang].neverWarn
                    else
                        return txt
                    end
                else
                    return langs[msg.lang].require_mod
                end
            end
            if matches[1]:lower() == 'lock' or matches[1]:lower() == 'sasha blocca' or matches[1]:lower() == 'blocca' then
                if is_mod(msg) then
                    local flag = false
                    if matches[2]:lower() == 'arabic' then
                        flag = true
                    end
                    if matches[2]:lower() == 'flood' then
                        flag = true
                    end
                    if matches[2]:lower() == 'leave' then
                        flag = true
                    end
                    if matches[2]:lower() == 'link' then
                        flag = true
                    end
                    if matches[2]:lower() == 'member' then
                        flag = true
                    end
                    if matches[2]:lower() == 'rtl' then
                        flag = true
                    end
                    if matches[2]:lower() == 'spam' then
                        flag = true
                    end
                    if matches[2]:lower() == 'strict' then
                        flag = true
                    end
                    if flag then
                        mystat('/lock ' .. matches[2]:lower())
                        return lockSetting(data, msg.chat.id, matches[2]:lower())
                    end
                else
                    return langs[msg.lang].require_mod
                end
            end
            if matches[1]:lower() == 'unlock' or matches[1]:lower() == 'sasha sblocca' or matches[1]:lower() == 'sblocca' then
                if is_mod(msg) then
                    local flag = false
                    if matches[2]:lower() == 'arabic' then
                        flag = true
                    end
                    if matches[2]:lower() == 'flood' then
                        flag = true
                    end
                    if matches[2]:lower() == 'leave' then
                        flag = true
                    end
                    if matches[2]:lower() == 'link' then
                        flag = true
                    end
                    if matches[2]:lower() == 'member' then
                        flag = true
                    end
                    if matches[2]:lower() == 'rtl' then
                        flag = true
                    end
                    if matches[2]:lower() == 'spam' then
                        flag = true
                    end
                    if matches[2]:lower() == 'strict' then
                        flag = true
                    end
                    if flag then
                        mystat('/unlock ' .. matches[2]:lower())
                        return unlockSetting(data, msg.chat.id, matches[2]:lower())
                    end
                else
                    return langs[msg.lang].require_mod
                end
            end
            if matches[1]:lower() == 'mute' or matches[1]:lower() == 'silenzia' then
                if is_owner(msg) then
                    local flag = false
                    if matches[2]:lower() == 'all' then
                        flag = true
                    end
                    if matches[2]:lower() == 'audio' then
                        flag = true
                    end
                    if matches[2]:lower() == 'contact' then
                        flag = true
                    end
                    if matches[2]:lower() == 'document' then
                        flag = true
                    end
                    if matches[2]:lower() == 'gif' then
                        flag = true
                    end
                    if matches[2]:lower() == 'location' then
                        flag = true
                    end
                    if matches[2]:lower() == 'photo' then
                        flag = true
                    end
                    if matches[2]:lower() == 'sticker' then
                        flag = true
                    end
                    if matches[2]:lower() == 'text' then
                        flag = true
                    end
                    if matches[2]:lower() == 'tgservice' then
                        flag = true
                    end
                    if matches[2]:lower() == 'video' then
                        flag = true
                    end
                    if matches[2]:lower() == 'voice' then
                        flag = true
                    end
                    if flag then
                        mystat('/mute ' .. matches[2]:lower())
                        return mute(msg.chat.id, matches[2]:lower())
                    end
                else
                    return langs[msg.lang].require_owner
                end
            end
            if matches[1]:lower() == 'unmute' or matches[1]:lower() == 'ripristina' then
                if is_owner(msg) then
                    local flag = false
                    if matches[2]:lower() == 'all' then
                        flag = true
                    end
                    if matches[2]:lower() == 'audio' then
                        flag = true
                    end
                    if matches[2]:lower() == 'contact' then
                        flag = true
                    end
                    if matches[2]:lower() == 'document' then
                        flag = true
                    end
                    if matches[2]:lower() == 'gif' then
                        flag = true
                    end
                    if matches[2]:lower() == 'location' then
                        flag = true
                    end
                    if matches[2]:lower() == 'photo' then
                        flag = true
                    end
                    if matches[2]:lower() == 'sticker' then
                        flag = true
                    end
                    if matches[2]:lower() == 'text' then
                        flag = true
                    end
                    if matches[2]:lower() == 'tgservice' then
                        flag = true
                    end
                    if matches[2]:lower() == 'video' then
                        flag = true
                    end
                    if matches[2]:lower() == 'voice' then
                        flag = true
                    end
                    if flag then
                        mystat('/unmute ' .. matches[2]:lower())
                        return unmute(msg.chat.id, matches[2]:lower())
                    end
                else
                    return langs[msg.lang].require_owner
                end
            end
            if matches[1]:lower() == "muteuser" or matches[1]:lower() == 'voce' then
                if is_mod(msg) then
                    mystat('/muteuser')
                    if msg.reply then
                        if matches[2] then
                            if matches[2]:lower() == 'from' then
                                if msg.reply_to_message.forward then
                                    if msg.reply_to_message.forward_from then
                                        -- ignore higher or same rank
                                        if compare_ranks(msg.from.id, msg.reply_to_message.forward_from.id, msg.chat.id) then
                                            if isMutedUser(msg.chat.id, msg.reply_to_message.forward_from.id) then
                                                unmuteUser(msg.chat.id, msg.reply_to_message.forward_from.id)
                                                savelog(msg.chat.id, name_log .. " [" .. msg.from.id .. "] removed [" .. msg.reply_to_message.forward_from.id .. "] from the muted users list")
                                                return matches[2] .. langs[msg.lang].muteUserRemove
                                            else
                                                muteUser(msg.chat.id, msg.reply_to_message.forward_from.id)
                                                savelog(msg.chat.id, name_log .. " [" .. msg.from.id .. "] added [" .. msg.reply_to_message.forward_from.id .. "] to the muted users list")
                                                return msg.reply_to_message.forward_from.id .. langs[msg.lang].muteUserAdd
                                            end
                                        else
                                            return langs[msg.lang].require_rank
                                        end
                                    else
                                        return langs[msg.lang].cantDoThisToChat
                                    end
                                else
                                    return langs[msg.lang].errorNoForward
                                end
                            end
                        else
                            -- ignore higher or same rank
                            if compare_ranks(msg.from.id, msg.reply_to_message.from.id, msg.chat.id) then
                                if isMutedUser(msg.chat.id, msg.reply_to_message.from.id) then
                                    unmuteUser(msg.chat.id, msg.reply_to_message.from.id)
                                    savelog(msg.chat.id, name_log .. " [" .. msg.from.id .. "] removed [" .. msg.reply_to_message.from.id .. "] from the muted users list")
                                    return matches[2] .. langs[msg.lang].muteUserRemove
                                else
                                    muteUser(msg.chat.id, msg.reply_to_message.from.id)
                                    savelog(msg.chat.id, name_log .. " [" .. msg.from.id .. "] added [" .. msg.reply_to_message.from.id .. "] to the muted users list")
                                    return msg.reply_to_message.from.id .. langs[msg.lang].muteUserAdd
                                end
                            else
                                return langs[msg.lang].require_rank
                            end
                        end
                    end
                    if string.match(matches[2], '^%d+$') then
                        -- ignore higher or same rank
                        if compare_ranks(msg.from.id, matches[2], msg.chat.id) then
                            if isMutedUser(msg.chat.id, matches[2]) then
                                unmuteUser(msg.chat.id, matches[2])
                                savelog(msg.chat.id, name_log .. " [" .. msg.from.id .. "] removed [" .. matches[2] .. "] from the muted users list")
                                return matches[2] .. langs[msg.lang].muteUserRemove
                            else
                                muteUser(msg.chat.id, matches[2])
                                savelog(msg.chat.id, name_log .. " [" .. msg.from.id .. "] added [" .. matches[2] .. "] to the muted users list")
                                return matches[2] .. langs[msg.lang].muteUserAdd
                            end
                        else
                            return langs[msg.lang].require_rank
                        end
                    else
                        local obj_user = resolveUsername(matches[2]:gsub('@', ''))
                        if obj_user then
                            if obj_user.type == 'private' then
                                -- ignore higher or same rank
                                if compare_ranks(msg.from.id, obj_user.id, msg.chat.id) then
                                    if isMutedUser(msg.chat.id, obj_user.id) then
                                        unmuteUser(msg.chat.id, obj_user.id)
                                        savelog(msg.chat.id, name_log .. " [" .. msg.from.id .. "] removed [" .. obj_user.id .. "] from the muted users list")
                                        --
                                        return matches[2] .. langs[msg.lang].muteUserRemove
                                    else
                                        muteUser(msg.chat.id, obj_user.id)
                                        savelog(msg.chat.id, name_log .. " [" .. msg.from.id .. "] added [" .. obj_user.id .. "] to the muted users list")
                                        --
                                        return obj_user.id .. langs[msg.lang].muteUserAdd
                                    end
                                else
                                    return langs[msg.lang].require_rank
                                end
                            end
                        end
                    end
                    return
                else
                    return langs[msg.lang].require_mod
                end
            end
            if matches[1]:lower() == "muteslist" or matches[1]:lower() == "lista muti" then
                if is_mod(msg) then
                    mystat('/muteslist')
                    savelog(msg.chat.id, name_log .. " [" .. msg.from.id .. "] requested SuperGroup muteslist")
                    return mutesList(msg.chat.id)
                else
                    return langs[msg.lang].require_mod
                end
            end
            if matches[1]:lower() == "mutelist" or matches[1]:lower() == "lista utenti muti" then
                if is_mod(msg) then
                    mystat('/mutelist')
                    savelog(msg.chat.id, name_log .. " [" .. msg.from.id .. "] requested SuperGroup mutelist")
                    return mutedUserList(msg.chat.id)
                else
                    return langs[msg.lang].require_mod
                end
            end
            if matches[1]:lower() == 'settings' then
                if is_mod(msg) then
                    mystat('/settings')
                    savelog(msg.chat.id, msg.from.print_name .. " [" .. msg.from.id .. "] requested group settings ")
                    return showSettings(msg.chat.id, msg.lang)
                else
                    return langs[msg.lang].require_mod
                end
            end
            if (matches[1]:lower() == 'setlink' or matches[1]:lower() == "sasha imposta link") and matches[2] then
                if is_owner(msg) then
                    mystat('/setlink')
                    data[tostring(msg.chat.id)].settings.set_link = matches[2]
                    save_data(config.moderation.data, data)
                    return langs[msg.lang].linkSaved
                else
                    return langs[msg.lang].require_owner
                end
            end
            if matches[1]:lower() == 'unsetlink' or matches[1]:lower() == "sasha elimina link" then
                if is_owner(msg) then
                    mystat('/unsetlink')
                    data[tostring(msg.chat.id)].settings.set_link = nil
                    save_data(config.moderation.data, data)
                    return langs[msg.lang].linkDeleted
                else
                    return langs[msg.lang].require_owner
                end
            end
            if matches[1]:lower() == 'link' or matches[1]:lower() == 'sasha link' then
                if is_mod(msg) then
                    mystat('/link')
                    local group_link = data[tostring(msg.chat.id)].settings.set_link
                    if not group_link then
                        return langs[msg.lang].sendMeLink
                    end
                    savelog(msg.chat.id, msg.from.print_name .. " [" .. msg.from.id .. "] requested group link [" .. group_link .. "]")
                    return msg.chat.title .. '\n' .. group_link
                else
                    return langs[msg.lang].require_mod
                end
            end
            if matches[1]:lower() == "getadmins" or matches[1]:lower() == "sasha lista admin" or matches[1]:lower() == "lista admin" then
                mystat('/getadmins')
                if is_owner(msg) then
                    savelog(msg.chat.id, msg.from.print_name .. " [" .. msg.from.id .. "] requested SuperGroup Admins list")
                    return getAdmins(msg.chat.id)
                else
                    return langs[msg.lang].require_owner
                end
            end
            if matches[1]:lower() == 'owner' then
                mystat('/owner')
                local group_owner = data[tostring(msg.chat.id)].set_owner
                if not group_owner then
                    return langs[msg.lang].noOwnerCallAdmin
                end
                savelog(msg.chat.id, msg.from.print_name .. " [" .. msg.from.id .. "] used /owner")
                return langs[msg.lang].ownerIs .. group_owner
            end
            if matches[1]:lower() == 'setowner' then
                if is_owner(msg) then
                    mystat('/setowner')
                    if msg.reply then
                        if matches[2] then
                            if matches[2]:lower() == 'from' then
                                if msg.reply_to_message.forward then
                                    if msg.reply_to_message.forward_from then
                                        return setOwner(msg.reply_to_message.forward_from, msg.chat.id)
                                    else
                                        return langs[msg.lang].cantDoThisToChat
                                    end
                                else
                                    return langs[msg.lang].errorNoForward
                                end
                            end
                        else
                            return setOwner(msg.reply_to_message.from, msg.chat.id)
                        end
                    end
                    if string.match(matches[2], '^%d+$') then
                        savelog(msg.chat.id, msg.from.print_name .. " [" .. msg.from.id .. "] set [" .. matches[2] .. "] as owner")
                        local obj_user = getChat(matches[2])
                        if type(obj_user) == 'table' then
                            if obj_user.result then
                                obj_user = obj_user.result
                                if obj_user then
                                    if obj_user.type == 'private' then
                                        return setOwner(obj_user, msg.chat.id)
                                    end
                                end
                            end
                        end
                    else
                        local obj_user = resolveUsername(matches[2]:gsub('@', ''))
                        if obj_user then
                            if obj_user.type == 'private' then
                                return setOwner(obj_user, msg.chat.id)
                            end
                        end
                    end
                    return
                else
                    return langs[msg.lang].require_owner
                end
            end
            if matches[1]:lower() == 'modlist' or matches[1]:lower() == 'sasha lista mod' or matches[1]:lower() == 'lista mod' then
                mystat('/modlist')
                savelog(msg.chat.id, msg.from.print_name .. " [" .. msg.from.id .. "] requested group modlist")
                return modList(msg)
            end
            if matches[1]:lower() == 'promote' or matches[1]:lower() == 'sasha promuovi' or matches[1]:lower() == 'promuovi' then
                if is_owner(msg) then
                    mystat('/promote')
                    if msg.reply then
                        if matches[2] then
                            if matches[2]:lower() == 'from' then
                                if msg.reply_to_message.forward then
                                    if msg.reply_to_message.forward_from then
                                        return promoteMod(msg.chat.id, msg.reply_to_message.forward_from)
                                    else
                                        return langs[msg.lang].cantDoThisToChat
                                    end
                                else
                                    return langs[msg.lang].errorNoForward
                                end
                            end
                        else
                            return promoteMod(msg.chat.id, msg.reply_to_message.from)
                        end
                    end
                    if string.match(matches[2], '^%d+$') then
                        local obj_user = getChat(matches[2])
                        if type(obj_user) == 'table' then
                            if obj_user.result then
                                obj_user = obj_user.result
                                if obj_user then
                                    if obj_user.type == 'private' then
                                        return promoteMod(msg.chat.id, obj_user)
                                    end
                                end
                            end
                        end
                    else
                        local obj_user = resolveUsername(matches[2]:gsub('@', ''))
                        if obj_user then
                            if obj_user.type == 'private' then
                                return promoteMod(msg.chat.id, obj_user)
                            end
                        end
                    end
                    return
                else
                    return langs[msg.lang].require_owner
                end
            end
            if matches[1]:lower() == 'demote' or matches[1]:lower() == 'sasha degrada' or matches[1]:lower() == 'degrada' then
                if is_owner(msg) then
                    mystat('/demote')
                    if msg.reply then
                        if matches[2] then
                            if matches[2]:lower() == 'from' then
                                if msg.reply_to_message.forward then
                                    if msg.reply_to_message.forward_from then
                                        return demoteMod(msg.chat.id, msg.reply_to_message.forward_from)
                                    else
                                        return langs[msg.lang].cantDoThisToChat
                                    end
                                else
                                    return langs[msg.lang].errorNoForward
                                end
                            end
                        else
                            return demoteMod(msg.chat.id, msg.reply_to_message.from)
                        end
                    end
                    if string.match(matches[2], '^%d+$') then
                        local obj_user = getChat(matches[2])
                        if type(obj_user) == 'table' then
                            if obj_user.result then
                                obj_user = obj_user.result
                                if obj_user then
                                    if obj_user.type == 'private' then
                                        return demoteMod(msg.chat.id, obj_user)
                                    end
                                end
                            end
                        end
                    else
                        local obj_user = resolveUsername(matches[2]:gsub('@', ''))
                        if obj_user then
                            if obj_user.type == 'private' then
                                return demoteMod(msg.chat.id, obj_user)
                            end
                        end
                    end
                    return
                else
                    return langs[msg.lang].require_owner
                end
            end
            if matches[1]:lower() == 'clean' then
                if is_owner(msg) then
                    if matches[2]:lower() == 'modlist' then
                        if next(data[tostring(msg.chat.id)].moderators) == nil then
                            -- fix way
                            return langs[msg.lang].noGroupMods
                        end
                        mystat('/clean modlist')
                        local message = langs[msg.lang].modListStart .. string.gsub(msg.chat.print_name, '_', ' ') .. ':\n'
                        for k, v in pairs(data[tostring(msg.chat.id)].moderators) do
                            data[tostring(msg.chat.id)].moderators[tostring(k)] = nil
                            save_data(config.moderation.data, data)
                        end
                        savelog(msg.chat.id, msg.from.print_name .. " [" .. msg.from.id .. "] cleaned modlist")
                    end
                    if matches[2]:lower() == 'rules' then
                        mystat('/clean rules')
                        data[tostring(msg.chat.id)].rules = nil
                        save_data(config.moderation.data, data)
                        savelog(msg.chat.id, msg.from.print_name .. " [" .. msg.from.id .. "] cleaned rules")
                    end
                else
                    return langs[msg.lang].require_owner
                end
            end
        end
    end
end

local function pre_process(msg)
    if msg.service then
        if is_realm(msg) then
            if msg.service_type == 'chat_add_user' or msg.service_type == 'chat_add_user_link' then
                if msg.added.id ~= bot.userVersion then
                    -- if not admin and not bot then
                    if not is_admin(msg) then
                        banUser(bot.id, msg.added.id, msg.chat.id)
                    end
                end
            end
        end
        if is_group(msg) then
            local settings = data[tostring(msg.chat.id)].settings
            if msg.service_type == 'chat_add_user' then
                if settings.lock_member and not is_owner2(msg.added.id, msg.chat.id) then
                    banUser(bot.id, msg.added.id, msg.chat.id)
                end
            end
            if msg.service_type == 'chat_del_user' then
                savelog(msg.chat.id, msg.from.print_name .. " [" .. msg.from.id .. "] deleted user  " .. 'user#id' .. msg.action.user.id)
            end
        end
    end
    return msg
end

return {
    description = "GROUP_MANAGEMENT",
    patterns =
    {
        -- INPM
        "^[#!/]([Aa][Ll][Ll][Cc][Hh][Aa][Tt][Ss])$",
        "^[#!/]([Aa][Ll][Ll][Cc][Hh][Aa][Tt][Ss][Ll][Ii][Ss][Tt])$",

        -- INREALM
        "^[#!/]([Rr][Ee][Mm]) (%-?%d+)$",
        "^[#!/]([Aa][Dd][Dd][Aa][Dd][Mm][Ii][Nn]) (.*)$",
        "^[#!/]([Rr][Ee][Mm][Oo][Vv][Ee][Aa][Dd][Mm][Ii][Nn]) (.*)$",
        "^[#!/]([Ss][Ee][Tt][Gg][Pp][Oo][Ww][Nn][Ee][Rr]) (%-?%d+) (%d+)$",-- (group id) (owner id)
        "^[#!/]([Ll][Ii][Ss][Tt]) (.*)$",
        "^[#!/]([Ll][Oo][Cc][Kk]) (%-?%d+) (.*)$",
        "^[#!/]([Uu][Nn][Ll][Oo][Cc][Kk]) (%-?%d+) (.*)$",
        "^[#!/]([Ss][Ee][Tt][Tt][Ii][Nn][Gg][Ss]) (%-?%d+)$",
        "^[#!/]([Ss][Uu][Pp][Ee][Rr][Ss][Ee][Tt][Tt][Ii][Nn][Gg][Ss]) (%-?%d+)$",
        "^[#!/]([Ss][Ee][Tt][Gg][Pp][Rr][Uu][Ll][Ee][Ss]) (%-?%d+) (.*)$",
        "^[#!/]([Ss][Ee][Tt][Gg][Pp][Aa][Bb][Oo][Uu][Tt]) (%-?%d+) (.*)$",
        -- lock
        "^([Ss][Aa][Ss][Hh][Aa] [Bb][Ll][Oo][Cc][Cc][Aa]) (%-?%d+) (.*)$",
        "^([Bb][Ll][Oo][Cc][Cc][Aa]) (%-?%d+) (.*)$",
        -- unlock
        "^([Ss][Aa][Ss][Hh][Aa] [Ss][Bb][Ll][Oo][Cc][Cc][Aa]) (%-?%d+) (.*)$",
        "^([Ss][Bb][Ll][Oo][Cc][Cc][Aa]) (%-?%d+) (.*)$",

        -- INGROUP
        "^[#!/]([Aa][Dd][Dd]) ([Rr][Ee][Aa][Ll][Mm])$",
        "^[#!/]([Rr][Ee][Mm]) ([Rr][Ee][Aa][Ll][Mm])$",

        -- SUPERGROUP
        "^[#!/]([Gg][Ee][Tt][Aa][Dd][Mm][Ii][Nn][Ss])$",
        -- getadmins
        "^([Ss][Aa][Ss][Hh][Aa] [Ll][Ii][Ss][Tt][Aa] [Aa][Dd][Mm][Ii][Nn])$",
        "^([Ll][Ii][Ss][Tt][Aa] [Aa][Dd][Mm][Ii][Nn])$",

        -- COMMON
        "^[#!/]([Tt][Yy][Pp][Ee])$",
        "^[#!/]([Ll][Oo][Gg])$",
        "^[#!/]([Aa][Dd][Mm][Ii][Nn][Ss])",
        "^[#!/]([Aa][Dd][Dd])$",
        "^[#!/]([Rr][Ee][Mm])$",
        "^[#!/]([Rr][Uu][Ll][Ee][Ss])$",
        "^[#!/]([Aa][Bb][Oo][Uu][Tt])$",
        "^[#!/]([Ss][Ee][Tt][Ff][Ll][Oo][Oo][Dd]) (%d+)$",
        "^[#!/]([Ss][Ee][Tt][Tt][Ii][Nn][Gg][Ss])$",
        "^[#!/]([Pp][Rr][Oo][Mm][Oo][Tt][Ee]) (.*)$",
        "^[#!/]([Pp][Rr][Oo][Mm][Oo][Tt][Ee])$",
        "^[#!/]([Dd][Ee][Mm][Oo][Tt][Ee]) (.*)$",
        "^[#!/]([Dd][Ee][Mm][Oo][Tt][Ee])$",
        "^[#!/]([Mm][Uu][Tt][Ee][Uu][Ss][Ee][Rr]) (.*)$",
        "^[#!/]([Mm][Uu][Tt][Ee][Uu][Ss][Ee][Rr])",
        "^[#!/]([Mm][Uu][Tt][Ee][Ll][Ii][Ss][Tt])",
        "^[#!/]([Mm][Uu][Tt][Ee][Ss][Ll][Ii][Ss][Tt])",
        "^[#!/]([Uu][Nn][Mm][Uu][Tt][Ee]) (.*)",
        "^[#!/]([Mm][Uu][Tt][Ee]) (.*)",
        "^[#!/]([Ss][Ee][Tt][Ll][Ii][Nn][Kk]) ([Hh][Tt][Tt][Pp][Ss]://[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]/[Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]/%S+)$",
        "^[#!/]([Ss][Ee][Tt][Ll][Ii][Nn][Kk]) ([Hh][Tt][Tt][Pp][Ss]://[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]/[Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]/%S+)$",
        "^[#!/]([Uu][Nn][Ss][Ee][Tt][Ll][Ii][Nn][Kk])$",
        "^[#!/]([Ll][Ii][Nn][Kk])$",
        "^[#!/]([Ss][Ee][Tt][Rr][Uu][Ll][Ee][Ss]) (.*)$",
        "^[#!/]([Ss][Ee][Tt][Aa][Bb][Oo][Uu][Tt]) (.*)$",
        "^[#!/]([Oo][Ww][Nn][Ee][Rr])$",
        "^[#!/]([Ll][Oo][Cc][Kk]) (.*)$",
        "^[#!/]([Uu][Nn][Ll][Oo][Cc][Kk]) (.*)$",
        "^[#!/]([Mm][Oo][Dd][Ll][Ii][Ss][Tt])$",
        "^[#!/]([Cc][Ll][Ee][Aa][Nn]) (.*)$",
        "^[#!/]([Ss][Ee][Tt][Oo][Ww][Nn][Ee][Rr]) (.*)$",
        "^[#!/]([Ss][Ee][Tt][Oo][Ww][Nn][Ee][Rr])$",
        "^[#!/]([Ss][Ee][Tt][Ww][Aa][Rr][Nn]) (%d+)$",
        "^[#!/]([Gg][Ee][Tt][Ww][Aa][Rr][Nn])$",
        -- rules
        "^([Ss][Aa][Ss][Hh][Aa] [Rr][Ee][Gg][Oo][Ll][Ee])$",
        -- promote
        "^([Ss][Aa][Ss][Hh][Aa] [Pp][Rr][Oo][Mm][Uu][Oo][Vv][Ii]) (.*)$",
        "^([Ss][Aa][Ss][Hh][Aa] [Pp][Rr][Oo][Mm][Uu][Oo][Vv][Ii])$",
        "^([Pp][Rr][Oo][Mm][Uu][Oo][Vv][Ii]) (.*)$",
        "^([Pp][Rr][Oo][Mm][Uu][Oo][Vv][Ii])$",
        -- demote
        "^([Ss][Aa][Ss][Hh][Aa] [Dd][Ee][Gg][Rr][Aa][Dd][Aa]) (.*)$",
        "^([Ss][Aa][Ss][Hh][Aa] [Dd][Ee][Gg][Rr][Aa][Dd][Aa])$",
        "^([Dd][Ee][Gg][Rr][Aa][Dd][Aa]) (.*)$",
        "^([Dd][Ee][Gg][Rr][Aa][Dd][Aa])$",
        -- setrules
        "^([Ss][Aa][Ss][Hh][Aa] [Ii][Mm][Pp][Oo][Ss][Tt][Aa] [Rr][Ee][Gg][Oo][Ll][Ee]) (.*)$",
        -- lock
        "^([Ss][Aa][Ss][Hh][Aa] [Bb][Ll][Oo][Cc][Cc][Aa]) (.*)$",
        "^([Bb][Ll][Oo][Cc][Cc][Aa]) (.*)$",
        -- unlock
        "^([Ss][Aa][Ss][Hh][Aa] [Ss][Bb][Ll][Oo][Cc][Cc][Aa]) (.*)$",
        "^([Ss][Bb][Ll][Oo][Cc][Cc][Aa]) (.*)$",
        -- modlist
        "^([Ss][Aa][Ss][Hh][Aa] [Ll][Ii][Ss][Tt][Aa] [Mm][Oo][Dd])$",
        "^([Ll][Ii][Ss][Tt][Aa] [Mm][Oo][Dd])$",
        -- link
        "^([Ss][Aa][Ss][Hh][Aa] [Ll][Ii][Nn][Kk])$",
        -- setlink
        "^([Ss][Aa][Ss][Hh][Aa] [Ii][Mm][Pp][Oo][Ss][Tt][Aa] [Ll][Ii][Nn][Kk]) ([Hh][Tt][Tt][Pp][Ss]://[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]/[Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]/%S+)$",
        "^([Ss][Aa][Ss][Hh][Aa] [Ii][Mm][Pp][Oo][Ss][Tt][Aa] [Ll][Ii][Nn][Kk]) ([Hh][Tt][Tt][Pp][Ss]://[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]/[Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]/%S+)$",
        -- unsetlink
        "^([Ss][Aa][Ss][Hh][Aa] [Ee][Ll][Ii][Mm][Ii][Nn][Aa] [Ll][Ii][Nn][Kk])$",
        -- mute
        "^([Ss][Ii][Ll][Ee][Nn][Zz][Ii][Aa]) ([^%s]+)$",
        -- unmute
        "^([Rr][Ii][Pp][Rr][Ii][Ss][Tt][Ii][Nn][Aa]) ([^%s]+)$",
        -- muteuser
        "^([Vv][Oo][Cc][Ee])$",
        "^([Vv][Oo][Cc][Ee]) (.*)$",
        -- muteslist
        "^([Ll][Ii][Ss][Tt][Aa] [Mm][Uu][Tt][Ii])$",
        -- mutelist
        "^([Ll][Ii][Ss][Tt][Aa] [Uu][Tt][Ee][Nn][Tt][Ii] [Mm][Uu][Tt][Ii])$",
    },
    pre_process = pre_process,
    run = run,
    min_rank = 0,
    syntax =
    {
        "USER",
        "#getwarn",
        "(#rules|sasha regole)",
        "(#modlist|[sasha] lista mod)",
        "#owner",
        "#admins [<reply>|<text>]",
        "MOD",
        "#type",
        "(#setrules|sasha imposta regole) <text>",
        "#setwarn <value>",
        "#setflood <value>",
        "#settings",
        "(#link|sasha link)",
        "#muteuser|voce <id>|<username>|<reply>|from",
        "(#muteslist|lista muti)",
        "(#mutelist|lista utenti muti)",
        "(#lock|[sasha] blocca) arabic|flood|leave|link|member|rtl|spam|strict",
        "(#unlock|[sasha] sblocca) arabic|flood|leave|link|member|rtl|spam|strict",
        "OWNER",
        "#log",
        "(#getadmins|[sasha] lista admin)",
        "(#setlink|sasha imposta link) <link>",
        "(#unsetlink|sasha elimina link)",
        "(#promote|[sasha] promuovi) <username>|<reply>",
        "(#demote|[sasha] degrada) <username>|<reply>",
        "#setowner <id>|<username>|<reply>",
        "#mute|silenzia all|audio|contact|document|gif|location|photo|sticker|text|tgservice|video|voice",
        "#unmute|ripristina all|audio|contact|document|gif|location|photo|sticker|text|tgservice|video|voice",
        "#clean modlist|rules",
        "ADMIN",
        "#add",
        "#rem",
        "ex INGROUP.LUA",
        "#add realm",
        "#rem realm",
        "ex INPM.LUA",
        "#allchats",
        "#allchatlist",
        "REALM",
        "#setgpowner <group_id> <user_id>",
        "#setgprules <group_id> <text>",
        "(#lock|[sasha] blocca) <group_id> arabic|flood|leave|link|member|rtl|spam|strict",
        "(#unlock|[sasha] sblocca) <group_id> arabic|flood|leave|link|member|rtl|spam|strict",
        "#settings <group_id>",
        "#type",
        "#rem <group_id>",
        "#list admins|groups|realms",
        "SUDO",
        "#addadmin <user_id>|<username>",
        "#removeadmin <user_id>|<username>",
    },
}