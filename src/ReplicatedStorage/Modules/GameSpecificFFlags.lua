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
    LightningChance = { Default = 0.15, Type = "number" },

    -- Pumpkin Spawn System
    PumpkinSpawnChance = { Default = 0.01, Type = "number" },
    PumpkinCommonWeight = { Default = 80, Type = "number" },
    PumpkinEpicWeight = { Default = 15, Type = "number" },
    PumpkinMythicalWeight = { Default = 5, Type = "number" },

    -- Trick or Treat Houses Rarity Weights
    TrickOrTreatRareWeight = { Default = 50.7, Type = "number" },
    TrickOrTreatEpicWeight = { Default = 45, Type = "number" },
    TrickOrTreatLegendaryWeight = { Default = 3, Type = "number" },
    TrickOrTreatMythicalWeight = { Default = 1, Type = "number" },
    TrickOrTreatGodWeight = { Default = 0.25, Type = "number" },
    TrickOrTreatSecretWeight = { Default = 0.05, Type = "number" },
}

-- Optionally extend per-game admin access for the FFlags UI.
module.Admins = {
    -- [123456] = true,
}

return module


