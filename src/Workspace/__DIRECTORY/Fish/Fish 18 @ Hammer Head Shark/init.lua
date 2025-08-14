--!strict

local FishTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.GameLibrary.Directory.Rarity)

return {
    DisplayName = "Hammer Head Shark",
    Rarity = Rarity.Common,
    MoneyPerSecond = 3600,
    BaseUpgradeCost = 108000,
    BillboardOffset = 7,
}::FishTypes.raw_dir



