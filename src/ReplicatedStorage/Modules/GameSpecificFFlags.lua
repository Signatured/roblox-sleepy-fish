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
    AdminAbuseEvent_Party = { Default = false, Type = "boolean" },
    PartyCannonChance = { Default = 0.25, Type = "number" },

    -- Party Fish Spawn System
    PartyFishSpawn_Enabled = { Default = true, Type = "boolean" },
    PartyFishSpawn_Interval = { Default = 20, Type = "number" }, -- Spawn fish every 20 seconds
    PartyFishSpawn_InitialDelay = { Default = 5, Type = "number" }, -- Wait 5 seconds before first spawn
    PartyFishSpawn_ServerSpawnDelay = { Default = 12, Type = "number" }, -- Server spawns fish 12 seconds after client notification
    PartyFishSpawn_RareWeight = { Default = 50.7, Type = "number" },
    PartyFishSpawn_EpicWeight = { Default = 45, Type = "number" },
    PartyFishSpawn_LegendaryWeight = { Default = 3, Type = "number" },
    PartyFishSpawn_MythicalWeight = { Default = 1, Type = "number" },
    PartyFishSpawn_GodWeight = { Default = 0.25, Type = "number" },
    PartyFishSpawn_SecretWeight = { Default = 0.05, Type = "number" },

    -- Party Machine
    PartyPointGoal = { Default = 1000, Type = "number" },
    PartyEventDuration = { Default = 300, Type = "number" }, -- 5 minutes in seconds
    PartyPoints_Common = { Default = 3, Type = "number" },
    PartyPoints_Uncommon = { Default = 5, Type = "number" },
    PartyPoints_Rare = { Default = 15, Type = "number" },
    PartyPoints_Epic = { Default = 25, Type = "number" },
    PartyPoints_Legendary = { Default = 40, Type = "number" },
    PartyPoints_Mythical = { Default = 125, Type = "number" },
    PartyPoints_God = { Default = 750, Type = "number" },
    PartyPoints_Secret = { Default = 1_000, Type = "number" },

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

    -- Mutation Event
    MutationEvent_EnableOverride = { Default = true, Type = "boolean" },
    MutationEvent_DurationOverride = { Default = 60 * 15, Type = "number" },

    -- Halloween Crafting Machine
    HalloweenCrafting_AllowCrafting = { Default = true, Type = "boolean" },
    HalloweenCrafting_AllowClaiming = { Default = true, Type = "boolean" },
}

-- Optionally extend per-game admin access for the FFlags UI.
module.Admins = {
    -- [123456] = true,
}

return module


