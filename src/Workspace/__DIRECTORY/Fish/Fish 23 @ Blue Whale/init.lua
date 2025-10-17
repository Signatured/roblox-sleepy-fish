--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Blue Whale",
    Icon = "rbxassetid://80687870999907",
    MutationIcons = {
        Bloodfish = "rbxassetid://98021010685179",
        Galaxy = "rbxassetid://115507423164072",
        Spooky = "rbxassetid://112178215422567",
    },
    Rarity = Rarity.Legendary,
    MoneyPerSecond = 120,
    BaseUpgradeCost = 2400,
    BillboardOffset = 6.5,
    PedestalOffset = 1,
    RarityWeight = 10,
    IndexOffset = 5,
    IndexPositionOffset = Vector3.new(-5, -0.5, 0),
}::FishTypes.raw_dir



