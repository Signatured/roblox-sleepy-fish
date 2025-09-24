--!strict

-- Game-specific Fast Flags configuration.
-- This module is automatically picked up by the shared FFlags loader at
-- `ReplicatedStorage.Game.Modules.GameSpecificFFlags`.

export type RawSchema = { [string]: { [string]: any } }

local module = {}

-- Define or override flags here. Matches the schema used by the shared FFlags raw table.
module.Raw = {
    FreeAdminPanel = { Default = false, Type = "boolean", Important = true },
}

-- Optionally extend per-game admin access for the FFlags UI.
module.Admins = {
    -- [123456] = true,
}

return module


