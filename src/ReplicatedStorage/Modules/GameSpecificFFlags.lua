--!strict

-- Game-specific Fast Flags configuration.
-- This module is automatically picked up by the shared FFlags loader at
-- `ReplicatedStorage.Game.Modules.GameSpecificFFlags`.

export type RawSchema = { [string]: { [string]: any } }

local module = {}

-- Define or override flags here. Matches the schema used by the shared FFlags raw table.
module.Raw = {
    FreeAdminPanel = { Default = false, Type = "boolean", Important = true },
    EventBoardVisible = { Default = false, Type = "boolean" },
    EventBoardEventId = { Default = "", Type = "string" },
    EventBoardImage = { Default = "rbxassetid://85949862684940", Type = "string" },
    EventBoardStartTime = { Default = 0, Type = "number" },

    -- Admin Abuse Events
    AdminAbuseEvent_Lightning = { Default = false, Type = "boolean" },
}

-- Optionally extend per-game admin access for the FFlags UI.
module.Admins = {
    -- [123456] = true,
}

return module


