# ne_discord

A powerful and optimized Discord API for FiveM, designed to seamlessly integrate Discord functionality into your server. This resource enables role management, nickname changes, voice channel interactions, and more, with enhanced performance and new features. It is a complete rewrite of the original [Badger_Discord_API](https://github.com/JaredScar/Badger_Discord_API) by **JaredScar (Badger)**, with full credit to him for laying the groundwork.

## Features

- **Core Functionality**:
  - Retrieve Discord user details (username, email, avatar, roles, etc.).
  - Access guild information (icon, splash, name, description, member counts).
  - Manage roles, nicknames, and voice channel assignments.
- **New Features**:
  - Asynchronous user info retrieval.
  - Kick or ban members from the guild.
  - Send messages or embeds to Discord channels.
  - Fetch guild channels and member join dates.
  - Manual cache refresh for optimized performance.
- **Optimizations**:
  - Enhanced caching with TTL for roles, avatars, and member data.
  - Asynchronous HTTP requests with timeouts to prevent server hangs.
  - Robust rate limit handling with automatic retries.
  - Improved error logging and multi-guild support.
- **Splash Screen**: Customizable Adaptive Card displayed during player connection.

## Installation

`ne_discord` is a drag-and-drop resource for FiveM. Follow these steps to set it up.

### Prerequisites
- A FiveM server running the `cerulean` fx_version.
- A Discord bot with the following permissions:
  - `MANAGE_ROLES`
  - `MANAGE_NICKNAMES`
  - `KICK_MEMBERS`
  - `BAN_MEMBERS`
  - `SEND_MESSAGES`
  - `VIEW_CHANNELS`
  - `MOVE_MEMBERS`
- Discord Developer Mode enabled to copy guild and channel IDs.

### Steps
1. **Download the Resource**:
   - Clone or download this repository to your FiveM server's `resources` directory.
   - Ensure the folder is named `ne_discord`.

2. **Configure the Bot**:
   - Create a bot in the [Discord Developer Portal](https://discord.com/developers/applications).
   - Copy the bot token.
   - Invite the bot to your Discord server with the required permissions (use the OAuth2 URL generator).

3. **Edit Config.lua**:
   - Open `resources/ne_discord/Config.lua`.
   - Set the following fields:
     - `Bot_Token`: Your Discord bot token.
     - `Guild_ID`: Your primary Discord server ID (right-click server > Copy ID).
     - `Multiguild` and `Guilds`: Enable and configure for multiple guilds if needed.
     - `Splash`: Customize the connection screen (image, text, links).
   - Example configuration:
     ```lua
     Config = {
         API_Version = 'v10',
         Guild_ID = '123456789012345678',
         Multiguild = false,
         Guilds = {},
         Bot_Token = 'YOUR_BOT_TOKEN_HERE',
         RoleList = { Admin = '123456789012345678' },
         Debug = true,
         CacheDiscordRoles = true,
         CacheDiscordRolesTime = 60,
         CacheMemberDataTime = 300,
         UseRedisCache = false,
         Splash = {
             Enabled = true,
             Wait = 10,
             Header_IMG = 'https://example.com/your-image.png',
             Heading1 = "Welcome to My Server",
             Heading2 = "Join our Discord!",
             Discord_Link = 'https://discord.gg/your-invite',
             Website_Link = 'https://yourwebsite.com',
         },
     }
     ```

4. **Add to server.cfg**:
   - Open your FiveM server’s `server.cfg`.
   - Add:
     ```lua
     ensure ne_discord
     ```

5. **Start the Server**:
   - Start or restart your FiveM server.
   - Join to see the splash screen (if `Config.Splash.Enabled = true`).
   - Use the `/ne_discord_test` command to test functionality.

### Testing
- Run `/ne_discord_test` in-game to verify exports (e.g., role checks, user info, channel messaging).
- Check the server console for debug messages if `Config.Debug = true`.
- Ensure the splash screen displays with your configured image and links.

### Troubleshooting
- **401 Errors**: Verify `Bot_Token` is correct and the bot is in the guild.
- **403 Errors**: Ensure the bot has the required permissions in Discord.
- **429 Errors**: Rate limits are handled automatically; increase `CacheDiscordRolesTime` to reduce API calls if needed.
- **No Splash Screen**: Check `Config.Splash.Enabled` and ensure `Header_IMG` is a valid, publicly accessible URL.
- **Channel Messaging**: Use a valid channel ID for `SendMessage` (right-click channel > Copy ID with Developer Mode enabled).

## Exports

Use these exports in other scripts to interact with Discord:

### Original Exports (from Badger_Discord_API)
- `GetRoleIdFromRoleName(name, guild)`: Get role ID by name.
- `IsDiscordEmailVerified(user)`: Check if email is verified.
- `GetDiscordEmail(user)`: Get user’s Discord email.
- `GetDiscordName(user)`: Get user’s Discord username.
- `GetGuildIcon(guild)`: Get guild icon URL.
- `GetGuildSplash(guild)`: Get guild splash image URL.
- `GetGuildName(guild)`: Get guild name.
- `GetGuildDescription(guild)`: Get guild description.
- `GetGuildMemberCount(guild)`: Get guild member count.
- `GetGuildOnlineMemberCount(guild)`: Get online member count.
- `GetDiscordAvatar(user)`: Get user’s avatar URL.
- `GetGuildRoleList(guild)`: Get all guild roles (name to ID).
- `GetDiscordRoles(user, guild)`: Get user’s roles in a guild.
- `CheckEqual(role1, role2, guild)`: Check if two roles are equal.
- `SetNickname(user, nickname, reason)`: Set user’s nickname.
- `AddRole(user, roleId, reason)`: Add a role to a user.
- `RemoveRole(user, roleId, reason)`: Remove a role from a user.
- `SetRoles(user, roleList, reason)`: Set a user’s roles.
- `ChangeDiscordVoice(user, voiceId, reason)`: Move user to a voice channel.

### New Exports
- `GetUserInfo(user, callback)`: Async fetch of full user data.
- `GetMemberJoinedAt(user, guild)`: Get member’s guild join date.
- `KickMember(user, reason)`: Kick a member from the guild.
- `BanMember(user, deleteMessageDays, reason)`: Ban a member.
- `GetGuildChannels(guild)`: Get list of guild channels.
- `SendMessage(channelId, content, embed, guild)`: Send a message/embed to a channel.
- `RefreshCache()`: Clear all caches.

### Example Usage
```lua
-- Check if player has Admin role
local roleId = exports.ne_discord:GetRoleIdFromRoleName("Admin")
local roles = exports.ne_discord:GetDiscordRoles(source)
if roles and exports.ne_discord:CheckEqual(roleId, roles[1]) then
    print("Player has Admin role!")
end

-- Send a message to a Discord channel
exports.ne_discord:SendMessage("CHANNEL_ID", "Player joined the server!", nil)

-- Async user info
exports.ne_discord:GetUserInfo(source, function(userInfo)
    if userInfo then
        print("Username: " .. userInfo.username)
    end
end)

Credits
This resource is a rewrite and enhancement of Badger_Discord_API by JaredScar (Badger). Full credit to Badger for the original groundwork and inspiration. Join his Discord for support: discord.gg/WjB5VFz.
Support
Join our Discord Support Server for help, bug reports, or feature requests.
License
This project is licensed under the MIT License. Feel free to modify and distribute, but please retain credit to Badger for the original Badger_Discord_API.