--!strict

local FishTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.GameLibrary.Directory.Rarity)

return {
    DisplayName = "Whale Shark",
    Rarity = Rarity.Common,
    MoneyPerSecond = 5832,
    BaseUpgradeCost = 174960
}::FishTypes.raw_dir



