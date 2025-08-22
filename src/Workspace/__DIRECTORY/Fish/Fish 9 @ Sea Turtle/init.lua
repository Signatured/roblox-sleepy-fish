--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Sea Turtle",
    Icon = "rbxassetid://84059569528616",
    Rarity = Rarity.Rare,
    MoneyPerSecond = 15,
    BaseUpgradeCost = 250,
    BillboardOffset = 5.5,
    RarityWeight = 40,
    IndexOffset = -0.5,
    IndexPositionOffset = Vector3.new(0, 0, 0),
}::FishTypes.raw_dir



