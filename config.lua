Config = {
    API_Version = 'v10', -- Discord API version
    Guild_ID = '', -- Primary guild ID (replace with your guild ID)
    Multiguild = false, -- Enable multiple guilds
    Guilds = {
        -- ["guild_name"] = "guild_id",
    },
    Bot_Token = '', -- Your Discord bot token
    RoleList = {}, -- Optional: Static role ID mappings (name = id)
    Debug = false, -- Enable debug logging
    CacheDiscordRoles = true, -- Cache roles
    CacheDiscordRolesTime = 60, -- Cache TTL in seconds
    CacheMemberDataTime = 300, -- Member data cache TTL
    UseRedisCache = false, -- Set to true if using Redis (requires Redis resource)
    Splash = {
        Enabled = true,
        Wait = 10, -- Seconds to show splash (max 12)
        Header_IMG = 'https://example.com/header.png',
        Heading1 = "Welcome to [ServerName]",
        Heading2 = "Join our Discord and check out our website!",
        Discord_Link = 'https://discord.gg/example',
        Website_Link = 'https://example.com',
    },
}