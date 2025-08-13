--!strict

local FishTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.GameLibrary.Directory.Rarity)

return {
    DisplayName = "Starfish",
    Rarity = Rarity.Common,
    MoneyPerSecond = 7,
    BaseUpgradeCost = 210
}::FishTypes.raw_dir



