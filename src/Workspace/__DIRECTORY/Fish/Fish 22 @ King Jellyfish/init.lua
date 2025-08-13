--!strict

local FishTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.GameLibrary.Directory.Rarity)

return {
    DisplayName = "King Jellyfish",
    Rarity = Rarity.Common,
    MoneyPerSecond = 24825,
    BaseUpgradeCost = 744750
}::FishTypes.raw_dir



