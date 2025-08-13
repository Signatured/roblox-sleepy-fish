--!strict

local FishTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.GameLibrary.Directory.Rarity)

return {
    DisplayName = "Catfish",
    Rarity = Rarity.Common,
    MoneyPerSecond = 2,
    BaseUpgradeCost = 60
}::FishTypes.raw_dir


