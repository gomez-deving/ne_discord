local FormattedToken = "Bot " .. Config.Bot_Token
local API_BASE = "https://discord.com/api/" .. Config.API_Version .. "/"

local error_codes_defined = {
    [200] = 'OK - The request was completed successfully.',
    [201] = 'Created - The entity was created successfully.',
    [204] = 'OK - No Content.',
    [304] = 'Not Modified - There was no new data to return.',
    [400] = "Error - The request was improperly formatted, or the server couldn't understand it.",
    [401] = 'Error - The Authorization header was missing or invalid. Check your Discord Token.',
    [403] = 'Error - The Authorization token lacks permission. Check bot roles.',
    [404] = "Error - The resource doesn't exist.",
    [429] = 'Error - Rate limited. See https://discord.com/developers/docs/topics/rate-limits',
    [502] = 'Error - Discord API may be down.',
}

local Caches = {
    Avatars = {},
    RoleList = {},
    MemberData = {},
    GuildData = {},
}

local recent_role_cache = {}

function DebugPrint(msg)
    if Config.Debug then
        print("^1[^5ne_discord^1] ^3" .. msg)
    end
end

RegisterNetEvent('ne_discord:PlayerLoaded')
AddEventHandler('ne_discord:PlayerLoaded', function()
    local src = source
    local license = GetIdentifier(src, 'license')
    TriggerClientEvent('chatMessage', src, '^1[^5ne_discord^1] ^3Connected to Discord API.')
end)

local card = [[
{
    "type": "AdaptiveCard",
    "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
    "version": "1.6",
    "body": [
        {
            "type": "Image",
            "url": "]] .. Config.Splash.Header_IMG .. [[",
            "horizontalAlignment": "Center"
        },
        {
            "type": "TextBlock",
            "text": "]] .. Config.Splash.Heading1 .. [[",
            "wrap": true,
            "size": "ExtraLarge",
            "weight": "Bolder",
            "horizontalAlignment": "Center"
        },
        {
            "type": "TextBlock",
            "text": "]] .. Config.Splash.Heading2 .. [[",
            "wrap": true,
            "size": "Medium",
            "horizontalAlignment": "Center"
        },
        {
            "type": "ActionSet",
            "actions": [
                {
                    "type": "Action.OpenUrl",
                    "title": "Join Discord",
                    "url": "]] .. Config.Splash.Discord_Link .. [[",
                    "style": "positive"
                },
                {
                    "type": "Action.OpenUrl",
                    "title": "Visit Website",
                    "url": "]] .. Config.Splash.Website_Link .. [[",
                    "style": "positive"
                }
            ],
            "horizontalAlignment": "Center"
        }
    ]
}
]]

if Config.Splash.Enabled then
    AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
        deferrals.defer()
        local src = source
        local endTime = GetGameTimer() + (Config.Splash.Wait * 1000)
        while GetGameTimer() < endTime do
            deferrals.presentCard(card, function(data, rawData) end)
            Citizen.Wait(1000)
        end
        deferrals.done()
    end)
end

function GetIdentifier(source, id_type)
    for _, identifier in pairs(GetPlayerIdentifiers(source)) do
        if string.find(identifier, id_type) then
            return identifier
        end
    end
    return nil
end

function GetGuildId(guild)
    if guild and Config.Guilds[guild] then
        return Config.Guilds[guild]
    end
    return Config.Guild_ID
end

function DiscordRequest(method, endpoint, jsondata, reason, callback)
    local data = nil
    local headers = {
        ['Content-Type'] = 'application/json',
        ['Authorization'] = FormattedToken,
    }
    if reason then
        headers['X-Audit-Log-Reason'] = reason
    end

    PerformHttpRequest(API_BASE .. endpoint, function(errorCode, resultData, resultHeaders)
        if errorCode == 429 then
            local retryAfter = tonumber(resultHeaders['Retry-After']) or 1
            DebugPrint("Rate limit hit, retrying after " .. retryAfter .. " seconds")
            Citizen.Wait(retryAfter * 1000)
            DiscordRequest(method, endpoint, jsondata, reason, callback)
            return
        end
        if callback then
            callback({data = resultData, code = errorCode, headers = resultHeaders})
        else
            data = {data = resultData, code = errorCode, headers = resultHeaders}
        end
    end, method, #jsondata > 0 and jsondata or "", headers)

    if not callback then
        local start = GetGameTimer()
        while data == nil and GetGameTimer() - start < 5000 do
            Citizen.Wait(0)
        end
        if data == nil then
            DebugPrint("Request timed out for endpoint: " .. endpoint)
            return { code = 408, data = nil }
        end
        return data
    end
end

exports('GetRoleIdFromRoleName', function(name, guild)
    local guildId = GetGuildId(guild)
    local cacheKey = "rolelist_" .. guildId
    local roles = Caches.RoleList[cacheKey]
    if not roles then
        roles = exports.ne_discord:GetGuildRoleList(guild)
    end
    return roles and roles[name] or nil
end)

exports('IsDiscordEmailVerified', function(user)
    local discordId = GetDiscordId(user)
    if not discordId then return false end

    local cacheKey = "member_" .. discordId
    if Caches.MemberData[cacheKey] and Caches.MemberData[cacheKey].expires > GetGameTimer() then
        return Caches.MemberData[cacheKey].verified
    end

    local endpoint = "users/" .. discordId
    local res = DiscordRequest("GET", endpoint, "")
    if res.code == 200 then
        local data = json.decode(res.data)
        Caches.MemberData[cacheKey] = { verified = data.verified, expires = GetGameTimer() + (Config.CacheMemberDataTime * 1000) }
        return data.verified
    end
    DebugPrint("Error: " .. error_codes_defined[res.code] or res.code)
    return false
end)

exports('GetDiscordEmail', function(user)
    local discordId = GetDiscordId(user)
    if not discordId then return nil end

    local cacheKey = "member_" .. discordId
    if Caches.MemberData[cacheKey] and Caches.MemberData[cacheKey].expires > GetGameTimer() then
        return Caches.MemberData[cacheKey].email
    end

    local endpoint = "users/" .. discordId
    local res = DiscordRequest("GET", endpoint, "")
    if res.code == 200 then
        local data = json.decode(res.data)
        Caches.MemberData[cacheKey] = { email = data.email, expires = GetGameTimer() + (Config.CacheMemberDataTime * 1000) }
        return data.email
    end
    DebugPrint("Error: " .. error_codes_defined[res.code] or res.code)
    return nil
end)

exports('GetDiscordName', function(user)
    local discordId = GetDiscordId(user)
    if not discordId then return nil end

    local cacheKey = "member_" .. discordId
    if Caches.MemberData[cacheKey] and Caches.MemberData[cacheKey].expires > GetGameTimer() then
        return Caches.MemberData[cacheKey].username
    end

    local endpoint = "users/" .. discordId
    local res = DiscordRequest("GET", endpoint, "")
    if res.code == 200 then
        local data = json.decode(res.data)
        local username = data.global_name or data.username -- Support new Discord username format
        Caches.MemberData[cacheKey] = { username = username, expires = GetGameTimer() + (Config.CacheMemberDataTime * 1000) }
        return username
    end
    DebugPrint("Error: " .. error_codes_defined[res.code] or res.code)
    return nil
end)

exports('GetGuildIcon', function(guild)
    local guildId = GetGuildId(guild)
    local cacheKey = "guild_" .. guildId
    if Caches.GuildData[cacheKey] and Caches.GuildData[cacheKey].expires > GetGameTimer() then
        return Caches.GuildData[cacheKey].icon
    end

    local res = DiscordRequest("GET", "guilds/" .. guildId, "")
    if res.code == 200 then
        local data = json.decode(res.data)
        local icon = data.icon and ("https://cdn.discordapp.com/icons/" .. guildId .. "/" .. data.icon .. (data.icon:sub(1, 2) == "a_" and ".gif" or ".png")) or nil
        Caches.GuildData[cacheKey] = { icon = icon, expires = GetGameTimer() + (Config.CacheMemberDataTime * 1000) }
        return icon
    end
    DebugPrint("Error: " .. error_codes_defined[res.code] or res.code)
    return nil
end)

exports('GetGuildSplash', function(guild)
    local guildId = GetGuildId(guild)
    local cacheKey = "guild_" .. guildId
    if Caches.GuildData[cacheKey] and Caches.GuildData[cacheKey].expires > GetGameTimer() then
        return Caches.GuildData[cacheKey].splash
    end

    local res = DiscordRequest("GET", "guilds/" .. guildId, "")
    if res.code == 200 then
        local data = json.decode(res.data)
        local splash = data.splash and ("https://cdn.discordapp.com/splashes/" .. guildId .. "/" .. data.splash .. ".png") or nil
        Caches.GuildData[cacheKey] = { splash = splash, expires = GetGameTimer() + (Config.CacheMemberDataTime * 1000) }
        return splash
    end
    DebugPrint("Error: " .. error_codes_defined[res.code] or res.code)
    return nil
end)

exports('GetGuildName', function(guild)
    local guildId = GetGuildId(guild)
    local cacheKey = "guild_" .. guildId
    if Caches.GuildData[cacheKey] and Caches.GuildData[cacheKey].expires > GetGameTimer() then
        return Caches.GuildData[cacheKey].name
    end

    local res = DiscordRequest("GET", "guilds/" .. guildId, "")
    if res.code == 200 then
        local data = json.decode(res.data)
        Caches.GuildData[cacheKey] = { name = data.name, expires = GetGameTimer() + (Config.CacheMemberDataTime * 1000) }
        return data.name
    end
    DebugPrint("Error: " .. error_codes_defined[res.code] or res.code)
    return nil
end)

exports('GetGuildDescription', function(guild)
    local guildId = GetGuildId(guild)
    local cacheKey = "guild_" .. guildId
    if Caches.GuildData[cacheKey] and Caches.GuildData[cacheKey].expires > GetGameTimer() then
        return Caches.GuildData[cacheKey].description
    end

    local res = DiscordRequest("GET", "guilds/" .. guildId, "")
    if res.code == 200 then
        local data = json.decode(res.data)
        Caches.GuildData[cacheKey] = { description = data.description, expires = GetGameTimer() + (Config.CacheMemberDataTime * 1000) }
        return data.description
    end
    DebugPrint("Error: " .. error_codes_defined[res.code] or res.code)
    return nil
end)

exports('GetGuildMemberCount', function(guild)
    local guildId = GetGuildId(guild)
    local cacheKey = "guild_" .. guildId
    if Caches.GuildData[cacheKey] and Caches.GuildData[cacheKey].expires > GetGameTimer() then
        return Caches.GuildData[cacheKey].member_count
    end

    local res = DiscordRequest("GET", "guilds/" .. guildId .. "?with_counts=true", "")
    if res.code == 200 then
        local data = json.decode(res.data)
        Caches.GuildData[cacheKey] = { member_count = data.approximate_member_count, expires = GetGameTimer() + (Config.CacheMemberDataTime * 1000) }
        return data.approximate_member_count
    end
    DebugPrint("Error: " .. error_codes_defined[res.code] or res.code)
    return nil
end)

exports('GetGuildOnlineMemberCount', function(guild)
    local guildId = GetGuildId(guild)
    local cacheKey = "guild_" .. guildId
    if Caches.GuildData[cacheKey] and Caches.GuildData[cacheKey].expires > GetGameTimer() then
        return Caches.GuildData[cacheKey].online_count
    end

    local res = DiscordRequest("GET", "guilds/" .. guildId .. "?with_counts=true", "")
    if res.code == 200 then
        local data = json.decode(res.data)
        Caches.GuildData[cacheKey] = { online_count = data.approximate_presence_count, expires = GetGameTimer() + (Config.CacheMemberDataTime * 1000) }
        return data.approximate_presence_count
    end
    DebugPrint("Error: " .. error_codes_defined[res.code] or res.code)
    return nil
end)

exports('GetDiscordAvatar', function(user)
    local discordId = GetDiscordId(user)
    if not discordId then return nil end

    local cacheKey = "avatar_" .. discordId
    if Caches.Avatars[cacheKey] and Caches.Avatars[cacheKey].expires > GetGameTimer() then
        return Caches.Avatars[cacheKey].url
    end

    local endpoint = "users/" .. discordId
    local res = DiscordRequest("GET", endpoint, "")
    if res.code == 200 then
        local data = json.decode(res.data)
        local avatar = data.avatar and ("https://cdn.discordapp.com/avatars/" .. discordId .. "/" .. data.avatar .. (data.avatar:sub(1, 2) == "a_" and ".gif" or ".png")) or nil
        Caches.Avatars[cacheKey] = { url = avatar, expires = GetGameTimer() + (Config.CacheMemberDataTime * 1000) }
        return avatar
    end
    DebugPrint("Error: " .. error_codes_defined[res.code] or res.code)
    return nil
end)

exports('GetGuildRoleList', function(guild)
    local guildId = GetGuildId(guild)
    local cacheKey = "rolelist_" .. guildId
    if Caches.RoleList[cacheKey] and Caches.RoleList[cacheKey].expires > GetGameTimer() then
        return Caches.RoleList[cacheKey].roles
    end

    local res = DiscordRequest("GET", "guilds/" .. guildId .. "/roles", "")
    if res.code == 200 then
        local data = json.decode(res.data)
        local roleList = {}
        for _, role in ipairs(data) do
            roleList[role.name] = role.id
        end
        Caches.RoleList[cacheKey] = { roles = roleList, expires = GetGameTimer() + (Config.CacheDiscordRolesTime * 1000) }
        return roleList
    end
    DebugPrint("Error: " .. error_codes_defined[res.code] or res.code)
    return nil
end)

exports('GetDiscordRoles', function(user, guild)
    local discordId = GetDiscordId(user)
    if not discordId then
        DebugPrint("Error: Discord ID not found for user")
        return nil
    end

    local guildId = GetGuildId(guild)
    if Config.CacheDiscordRoles and recent_role_cache[discordId] and recent_role_cache[discordId][guildId] then
        return recent_role_cache[discordId][guildId].roles
    end

    local endpoint = "guilds/" .. guildId .. "/members/" .. discordId
    local res = DiscordRequest("GET", endpoint, "")
    if res.code == 200 then
        local data = json.decode(res.data)
        local roles = data.roles
        if Config.CacheDiscordRoles then
            recent_role_cache[discordId] = recent_role_cache[discordId] or {}
            recent_role_cache[discordId][guildId] = { roles = roles, expires = GetGameTimer() + (Config.CacheDiscordRolesTime * 1000) }
            Citizen.SetTimeout(Config.CacheDiscordRolesTime * 1000, function()
                recent_role_cache[discordId][guildId] = nil
            end)
        end
        return roles
    end
    DebugPrint("Error: " .. error_codes_defined[res.code] or res.code)
    return nil
end)

exports('CheckEqual', function(role1, role2, guild)
    local roleId1 = type(role1) == "string" and (tonumber(role1) or Config.RoleList[role1] or exports.ne_discord:GetRoleIdFromRoleName(role1, guild)) or role1
    local roleId2 = type(role2) == "string" and (tonumber(role2) or Config.RoleList[role2] or exports.ne_discord:GetRoleIdFromRoleName(role2, guild)) or role2
    return roleId1 and roleId2 and roleId1 == roleId2
end)

exports('SetNickname', function(user, nickname, reason)
    local discordId = GetDiscordId(user)
    if not discordId then return false end

    local endpoint = "guilds/" .. Config.Guild_ID .. "/members/" .. discordId
    local payload = json.encode({ nick = tostring(nickname or "") })
    local res = DiscordRequest("PATCH", endpoint, payload, reason)
    if res.code == 200 or res.code == 204 then
        return true
    end
    DebugPrint("Error: " .. error_codes_defined[res.code] or res.code)
    return false
end)

exports('AddRole', function(user, roleId, reason)
    local discordId = GetDiscordId(user)
    if not discordId then return false end

    local roles = exports.ne_discord:GetDiscordRoles(user) or {}
    table.insert(roles, tostring(roleId))
    local endpoint = "guilds/" .. Config.Guild_ID .. "/members/" .. discordId
    local payload = json.encode({ roles = roles })
    local res = DiscordRequest("PATCH", endpoint, payload, reason)
    if res.code == 200 or res.code == 204 then
        return true
    end
    DebugPrint("Error: " .. error_codes_defined[res.code] or res.code)
    return false
end)

exports('RemoveRole', function(user, roleId, reason)
    local discordId = GetDiscordId(user)
    if not discordId then return false end

    local roles = exports.ne_discord:GetDiscordRoles(user) or {}
    for i, v in ipairs(roles) do
        if v == tostring(roleId) then
            table.remove(roles, i)
            break
        end
    end
    local endpoint = "guilds/" .. Config.Guild_ID .. "/members/" .. discordId
    local payload = json.encode({ roles = roles })
    local res = DiscordRequest("PATCH", endpoint, payload, reason)
    if res.code == 200 or res.code == 204 then
        return true
    end
    DebugPrint("Error: " .. error_codes_defined[res.code] or res.code)
    return false
end)

exports('SetRoles', function(user, roleList, reason)
    local discordId = GetDiscordId(user)
    if not discordId then return false end

    local endpoint = "guilds/" .. Config.Guild_ID .. "/members/" .. discordId
    local payload = json.encode({ roles = roleList })
    local res = DiscordRequest("PATCH", endpoint, payload, reason)
    if res.code == 200 or res.code == 204 then
        return true
    end
    DebugPrint("Error: " .. error_codes_defined[res.code] or res.code)
    return false
end)

exports('ChangeDiscordVoice', function(user, voiceId, reason)
    local discordId = GetDiscordId(user)
    if not discordId then return false end

    local endpoint = "guilds/" .. Config.Guild_ID .. "/members/" .. discordId
    local payload = json.encode({ channel_id = tostring(voiceId) })
    local res = DiscordRequest("PATCH", endpoint, payload, reason)
    if res.code == 200 or res.code == 204 then
        return true
    end
    DebugPrint("Error: " .. error_codes_defined[res.code] or res.code)
    return false
end)

exports('GetUserInfo', function(user, callback)
    local discordId = GetDiscordId(user)
    if not discordId then return callback(nil) end

    local endpoint = "users/" .. discordId
    DiscordRequest("GET", endpoint, "", nil, function(res)
        if res.code == 200 then
            callback(json.decode(res.data))
        else
            DebugPrint("Error: " .. error_codes_defined[res.code] or res.code)
            callback(nil)
        end
    end)
end)

exports('GetMemberJoinedAt', function(user, guild)
    local discordId = GetDiscordId(user)
    if not discordId then return nil end

    local guildId = GetGuildId(guild)
    local endpoint = "guilds/" .. guildId .. "/members/" .. discordId
    local res = DiscordRequest("GET", endpoint, "")
    if res.code == 200 then
        local data = json.decode(res.data)
        return data.joined_at
    end
    DebugPrint("Error: " .. error_codes_defined[res.code] or res.code)
    return nil
end)

exports('KickMember', function(user, reason)
    local discordId = GetDiscordId(user)
    if not discordId then return false end

    local endpoint = "guilds/" .. Config.Guild_ID .. "/members/" .. discordId
    local res = DiscordRequest("DELETE", endpoint, "", reason)
    if res.code == 204 then
        return true
    end
    DebugPrint("Error: " .. error_codes_defined[res.code] or res.code)
    return false
end)

exports('BanMember', function(user, deleteMessageDays, reason)
    local discordId = GetDiscordId(user)
    if not discordId then return false end

    local deleteDays = deleteMessageDays or 0
    local endpoint = "guilds/" .. Config.Guild_ID .. "/bans/" .. discordId
    local payload = json.encode({ delete_message_days = deleteDays })
    local res = DiscordRequest("PUT", endpoint, payload, reason)
    if res.code == 204 then
        return true
    end
    DebugPrint("Error: " .. error_codes_defined[res.code] or res.code)
    return false
end)

exports('GetGuildChannels', function(guild)
    local guildId = GetGuildId(guild)
    local endpoint = "guilds/" .. guildId .. "/channels"
    local res = DiscordRequest("GET", endpoint, "")
    if res.code == 200 then
        return json.decode(res.data)
    end
    DebugPrint("Error: " .. error_codes_defined[res.code] or res.code)
    return nil
end)

exports('SendMessage', function(channelId, content, embed, guild)
    local guildId = GetGuildId(guild)
    local endpoint = "channels/" .. channelId .. "/messages"
    local payload = json.encode({ content = content, embeds = embed and { embed } or nil })
    local res = DiscordRequest("POST", endpoint, payload)
    if res.code == 200 then
        return true
    end
    DebugPrint("Error: " .. error_codes_defined[res.code] or res.code)
    return false
end)

exports('RefreshCache', function()
    Caches = { Avatars = {}, RoleList = {}, MemberData = {}, GuildData = {} }
    recent_role_cache = {}
    DebugPrint("Cache refreshed")
end)

function GetDiscordId(user)
    for _, id in ipairs(GetPlayerIdentifiers(user)) do
        if string.match(id, "discord:") then
            return string.gsub(id, "discord:", "")
        end
    end
    DebugPrint("Error: Discord ID not found for user")
    return nil
end

Citizen.CreateThread(function()
    local guild = DiscordRequest("GET", "guilds/" .. Config.Guild_ID, "")
    if guild.code == 200 then
        local data = json.decode(guild.data)
        DebugPrint("Connected to guild: " .. data.name .. " (" .. data.id .. ")")
    else
        DebugPrint("Connection error: " .. (guild.data or guild.code))
    end
    if Config.Multiguild then
        for guildName, guildId in pairs(Config.Guilds) do
            local guild = DiscordRequest("GET", "guilds/" .. guildId, "")
            if guild.code == 200 then
                local data = json.decode(guild.data)
                DebugPrint("Connected to guild: " .. data.name .. " (" .. data.id .. ")")
            else
                DebugPrint("Connection error for guild " .. guildName .. ": " .. (guild.data or guild.code))
            end
        end
    end
end)