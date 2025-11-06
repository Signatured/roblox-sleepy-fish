--!strict

local Settings = {
	DefaultPedestalCount = 12,
    ExtraFloors = 1,
    ExtraFloorPedestalCounts = {
        [1] = 26,
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