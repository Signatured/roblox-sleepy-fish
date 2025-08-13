--!strict

local FishTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.GameLibrary.Directory.Rarity)

return {
    DisplayName = "Sockeye Salmon",
    Rarity = Rarity.Common,
    MoneyPerSecond = 3,
    BaseUpgradeCost = 90
}::FishTypes.raw_dir


