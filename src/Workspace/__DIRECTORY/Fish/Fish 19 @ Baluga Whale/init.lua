--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Baluga Whale",
    Icon = "rbxassetid://129525720088267",
    Rarity = Rarity.Legendary,
    MoneyPerSecond = 70,
    BaseUpgradeCost = 1500,
    BillboardOffset = 6.5,
    RarityWeight = 30,
    IndexOffset = 3,
    IndexPositionOffset = Vector3.new(-3, 0, 0),
}::FishTypes.raw_dir



