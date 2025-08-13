--!strict

local FishTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.GameLibrary.Directory.Rarity)

return {
    DisplayName = "Blue Whale",
    Rarity = Rarity.Common,
    MoneyPerSecond = 9447,
    BaseUpgradeCost = 283410
}::FishTypes.raw_dir



