--!strict

local Settings = {
	DefaultPedestalCount = 12,
    ExtraFloors = 2,
    
    -- Initial pedestal count when purchasing each floor (backwards compatible)
    ExtraFloorPedestalCounts = {
        [1] = 26,  -- Floor 2: grants access to all 26 pedestals (1-26)
        [2] = 28,  -- Floor 3: grants access to pedestals 1-28 initially (includes 27-28 from floor 3)
    },
    
    -- Purchasable pedestal groups for floors that support expansion
    -- Each group must be purchased in order and contains multiple pedestals
    PedestalGroups = {
        [2] = {  -- Floor 3 (ExtraFloors = 2) - pedestals 27-40
            -- Player gets 27-28 by default when buying floor
            { Pedestals = {29, 30}, Price = 15_000_000_000 },
            { Pedestals = {31, 32}, Price = 25_000_000_000 },
            { Pedestals = {33, 34}, Price = 50_000_000_000 },
            { Pedestals = {35, 36}, Price = 100_000_000_000 },
            { Pedestals = {37, 38}, Price = 150_000_000_000 },
            { Pedestals = {39, 40}, Price = 250_000_000_000 },
        },
        -- Floor 2 has no entry, so it doesn't support additional pedestal purchases (backwards compatible)
    },
    
    MaxLevel = 50,
    MaxInventory = 9,
    MaxInventoryUpgraded1 = 20,
    MaxInventoryUpgraded2 = 30,
    MaxInventoryUpgraded3 = 40,
    TypeMultipliers = {
        ["Normal"] = 1,
        ["Shiny"] = 1.5,
        ["Gold"] = 2,
        ["Rainbow"] = 3,
    },

    DespawnTime = 90,
}

return Settings