--!strict

local FishTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.GameLibrary.Directory.Rarity)

return {
    DisplayName = "Seahorse",
    Rarity = Rarity.Common,
    MoneyPerSecond = 524,
    BaseUpgradeCost = 15720
}::FishTypes.raw_dir


