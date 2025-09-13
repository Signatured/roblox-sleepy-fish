--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Orca",
    Icon = "rbxassetid://80571201044562",
    Rarity = Rarity.Legendary,
    MoneyPerSecond = 90,
    BaseUpgradeCost = 1900,
    BillboardOffset = 7,
    PedestalOffset = -3.5,
    RarityWeight = 20,
    -- IndexOffset = -1,
    -- IndexPositionOffset = Vector3.new(-0.5, 0, 0),
}::FishTypes.raw_dir



