--!strict

local FishTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.GameLibrary.Directory.Rarity)

return {
    DisplayName = "Test Fish",
    Rarity = Rarity.Common,
    MoneyPerSecond = 4,
    BaseUpgradeCost = 10
}::FishTypes.raw_dir