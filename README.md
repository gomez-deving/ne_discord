# ne_discord
A powerful and optimized Discord API for FiveM, designed to integrate Discord functionality into your server with ease. This resource allows you to manage roles, nicknames, voice channels, and more, with enhanced performance and new features. It is a complete rewrite of the original Badger_Discord_API, with full credit to Badger for laying the groundwork.
Original Project: Badger_Discord_API by JaredScar
Features
•  Core Functionality:
	•  Retrieve Discord user info (username, email, avatar, roles, etc.).
	•  Manage guild details (icon, splash, name, description, member counts).
	•  Assign/remove roles, set nicknames, and move users to voice channels.
•  New Features:
	•  Async user info retrieval.
	•  Kick/ban members from the guild.
	•  Send messages or embeds to Discord channels.
	•  Fetch guild channels and member join dates.
	•  Manual cache refresh for performance.
•  Optimizations:
	•  Improved caching with TTL for roles, avatars, and member data.
	•  Async HTTP requests with timeouts to prevent server hangs.
	•  Robust rate limit handling with automatic retries.
	•  Enhanced error logging and multi-guild support.
•  Splash Screen: Customizable Adaptive Card displayed during player connection.
Installation
ne_discord is designed as a drag-and-drop resource for FiveM. Follow these steps to get it running on your server.
Prerequisites
•  A FiveM server running the cerulean fx_version.
•  A Discord bot with the following permissions:
	•  MANAGE_ROLES
	•  MANAGE_NICKNAMES
	•  KICK_MEMBERS
	•  BAN_MEMBERS
	•  SEND_MESSAGES
	•  VIEW_CHANNELS
	•  MOVE_MEMBERS
•  Developer Mode enabled in Discord to copy guild and channel IDs.
Steps
1.  Download the Resource:
	•  Download or clone this repository to your FiveM server’s resources directory.
	•  Ensure the folder is named ne_discord.
2.  Configure the Bot:
	•  Create a Discord bot in the Discord Developer Portal.
	•  Copy the bot token.
	•  Invite the bot to your Discord server with the required permissions (use the OAuth2 URL generator in the Developer Portal).
3.  Edit Config.lua:
	•  Open resources/ne_discord/Config.lua.
	•  Set the following fields:
		•  Bot_Token: Your Discord bot token.
		•  Guild_ID: Your primary Discord server ID (right-click server > Copy ID).
		•  Multiguild and Guilds: Enable and configure if using multiple guilds.
		•  Splash: Customize the connection screen (image, text, links).
	•  Example:
```Config = {
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
}```
4.  Add to server.cfg:
	•  Open your FiveM server’s server.cfg file.
```ensure ne_discord}```
5.  Start the Server:
	•  Start or restart your FiveM server.
	•  Join the server to see the splash screen (if Config.Splash.Enabled = true).
	•  Use the /ne_discord_test command in-game to test functionality.
Testing
•  Run /ne_discord_test in-game to verify exports (e.g., role checks, user info, channel messaging).
•  Check the server console for debug messages if Config.Debug = true.
•  Ensure the splash screen displays correctly with your configured image and links.
Troubleshooting
•  401 Errors: Verify Bot_Token is correct and the bot is in the guild.
•  403 Errors: Ensure the bot has the required permissions in Discord.
•  429 Errors: Rate limits are handled automatically, but increase CacheDiscordRolesTime to reduce API calls if needed.
•  No Splash Screen: Check Config.Splash.Enabled and ensure Header_IMG is a valid, publicly accessible URL.
•  Channel Messaging: For SendMessage, use a valid channel ID (right-click channel > Copy ID with Developer Mode enabled).
Exports
The resource provides the following exports for use in other scripts:
•  Original Exports (from Badger_Discord_API):
	•  GetRoleIdFromRoleName(name, guild): Get role ID by name.
	•  IsDiscordEmailVerified(user): Check if email is verified.
	•  GetDiscordEmail(user): Get user’s Discord email.
	•  GetDiscordName(user): Get user’s Discord username.
	•  GetGuildIcon(guild): Get guild icon URL.
	•  GetGuildSplash(guild): Get guild splash image URL.
	•  GetGuildName(guild): Get guild name.
	•  GetGuildDescription(guild): Get guild description.
	•  GetGuildMemberCount(guild): Get guild member count.
	•  GetGuildOnlineMemberCount(guild): Get online member count.
	•  GetDiscordAvatar(user): Get user’s avatar URL.
	•  GetGuildRoleList(guild): Get all guild roles (name to ID).
	•  GetDiscordRoles(user, guild): Get user’s roles in a guild.
	•  CheckEqual(role1, role2, guild): Check if two roles are equal.
	•  SetNickname(user, nickname, reason): Set user’s nickname.
	•  AddRole(user, roleId, reason): Add a role to a user.
	•  RemoveRole(user, roleId, reason): Remove a role from a user.
	•  SetRoles(user, roleList, reason): Set a user’s roles.
	•  ChangeDiscordVoice(user, voiceId, reason): Move user to a voice channel.
•  New Exports:
	•  GetUserInfo(user, callback): Async fetch of full user data.
	•  GetMemberJoinedAt(user, guild): Get member’s guild join date.
	•  KickMember(user, reason): Kick a member from the guild.
	•  BanMember(user, deleteMessageDays, reason): Ban a member.
	•  GetGuildChannels(guild): Get list of guild channels.
	•  SendMessage(channelId, content, embed, guild): Send a message/embed to a channel.
	•  RefreshCache(): Clear all caches.
Example usage in another script:
```-- Check if player has Admin role
local roleId = exports.ne_discord:GetRoleIdFromRoleName("Admin")
local roles = exports.ne_discord:GetDiscordRoles(source)
if roles and exports.ne_discord:CheckEqual(roleId, roles[1]) then
    print("Player has Admin role!")
end

-- Send a message to a Discord channel
exports.ne_discord:SendMessage("CHANNEL_ID", "Player joined the server!", nil)```
Credits
This resource is a rewrite and enhancement of Badger_Discord_API by JaredScar (Badger). Full credit to Badger for the original groundwork and inspiration. Join his Discord for support: discord.gg/WjB5VFz.
License
This project is open-source under the MIT License. Feel free to modify and distribute, but please retain credit to Badger for the original Badger_Discord_API.