--!strict

local FishTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.GameLibrary.Directory.Rarity)

return {
    DisplayName = "Mythical Megladon",
    Rarity = Rarity.Common,
    MoneyPerSecond = 100000,
    BaseUpgradeCost = 3000000
}::FishTypes.raw_dir



