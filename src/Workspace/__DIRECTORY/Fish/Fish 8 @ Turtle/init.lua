--!strict

local FishTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.GameLibrary.Directory.Rarity)

return {
    DisplayName = "Turtle",
    Rarity = Rarity.Common,
    MoneyPerSecond = 29,
    BaseUpgradeCost = 870
}::FishTypes.raw_dir



