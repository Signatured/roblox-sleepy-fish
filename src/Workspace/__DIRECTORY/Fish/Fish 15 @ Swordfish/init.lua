--!strict

local FishTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.GameLibrary.Directory.Rarity)

return {
    DisplayName = "Swordfish",
    Rarity = Rarity.Common,
    MoneyPerSecond = 848,
    BaseUpgradeCost = 25440
}::FishTypes.raw_dir



