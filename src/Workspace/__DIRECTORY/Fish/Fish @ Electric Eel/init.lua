--!strict

local FishTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.GameLibrary.Directory.Rarity)

return {
    DisplayName = "Electric Eel",
    Rarity = Rarity.Common,
    MoneyPerSecond = 47,
    BaseUpgradeCost = 1410
}::FishTypes.raw_dir


