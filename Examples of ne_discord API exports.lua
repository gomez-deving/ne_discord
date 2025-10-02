-- Examples of ne_discord API exports

-- Register a test command to showcase ne_discord exports
RegisterCommand('ne_discord_test', function(source, args, rawCommand)
    local user = source
    print("[ne_discord Example] Running tests for player: " .. GetPlayerName(user))

    -- Helper function to print results
    local function logResult(label, result)
        print("[ne_discord Example] " .. label .. ": " .. tostring(result))
    end

    -- 1. Get Role ID from Role Name (Synchronous)
    local roleName = "Admin" -- Replace with a role in your Discord server
    local roleId = exports.ne_discord:GetRoleIdFromRoleName(roleName)
    logResult("Role ID for " .. roleName, roleId or "Not found")

    -- 2. Check if Discord Email is Verified (Synchronous)
    local isVerified = exports.ne_discord:IsDiscordEmailVerified(user)
    logResult("Is " .. GetPlayerName(user) .. "'s email verified?", isVerified)

    -- 3. Get Discord Email (Synchronous)
    local email = exports.ne_discord:GetDiscordEmail(user)
    logResult("Email for " .. GetPlayerName(user), email or "Not found")

    -- 4. Get Discord Name (Synchronous, handles new username format)
    local discordName = exports.ne_discord:GetDiscordName(user)
    logResult("Discord name for " .. GetPlayerName(user), discordName or "Not found")

    -- 5. Get Guild Icon (Synchronous)
    local guildIcon = exports.ne_discord:GetGuildIcon()
    logResult("Guild icon URL", guildIcon or "Not found")

    -- 6. Get Guild Member Count (Synchronous)
    local memberCount = exports.ne_discord:GetGuildMemberCount()
    logResult("Guild member count", memberCount or "Not found")

    -- 7. Get Discord Roles (Synchronous)
    local roles = exports.ne_discord:GetDiscordRoles(user)
    if roles then
        print("[ne_discord Example] Roles for " .. GetPlayerName(user) .. ":")
        for _, roleId in ipairs(roles) do
            print("  - Role ID: " .. roleId)
        end
    else
        logResult("Roles for " .. GetPlayerName(user), "None or error")
    end

    -- 8. Async Get User Info (New Feature)
    exports.ne_discord:GetUserInfo(user, function(userInfo)
        if userInfo then
            logResult("User Info - Username", userInfo.username)
            logResult("User Info - Premium Type", userInfo.premium_type or "None")
        else
            logResult("User Info", "Failed to fetch")
        end
    end)

    -- 9. Get Member Join Date (New Feature)
    local joinedAt = exports.ne_discord:GetMemberJoinedAt(user)
    logResult("Joined guild at", joinedAt or "Not found")

    -- 10. Add Role to User
    if roleId then
        local success = exports.ne_discord:AddRole(user, roleId, "Test command addition")
        logResult("Add role " .. roleName .. " to user", success and "Success" or "Failed")
    end

    -- 11. Send Message to Channel (New Feature)
    local channelId = "YOUR_CHANNEL_ID" -- Replace with a valid channel ID
    local success = exports.ne_discord:SendMessage(channelId, "Hello from ne_discord!", nil)
    logResult("Send message to channel " .. channelId, success and "Success" or "Failed")

    -- 12. Kick Member (New Feature, use with caution)
    -- exports.ne_discord:KickMember(user, "Test kick")
    -- logResult("Kick user", "Commented out for safety")

    -- 13. Refresh Cache (New Feature)
    exports.ne_discord:RefreshCache()
    logResult("Cache refresh", "Completed")
end, false)

-- Example Event Handler for Role-Based Permissions
RegisterServerEvent('ne_discord:CheckRolePermission')
AddEventHandler('ne_discord:CheckRolePermission', function(roleName)
    local user = source
    local roleId = exports.ne_discord:GetRoleIdFromRoleName(roleName)
    if not roleId then
        TriggerClientEvent('chatMessage', user, '^1[ne_discord]^3 Role ' .. roleName .. ' not found.')
        return
    end

    local roles = exports.ne_discord:GetDiscordRoles(user)
    local hasRole = false
    if roles then
        for _, id in ipairs(roles) do
            if exports.ne_discord:CheckEqual(id, roleId) then
                hasRole = true
                break
            end
        end
    end

    if hasRole then
        TriggerClientEvent('chatMessage', user, '^2[ne_discord]^3 You have the ' .. roleName .. ' role!')
    else
        TriggerClientEvent('chatMessage', user, '^1[ne_discord]^3 You do not have the ' .. roleName .. ' role.')
    end
end)

-- Example Usage in Another Resource
-- In another script, you can use:
-- exports.ne_discord:GetUserInfo(source, function(data) print(data.username) end)
-- exports.ne_discord:AddRole(source, "ROLE_ID", "Reason")