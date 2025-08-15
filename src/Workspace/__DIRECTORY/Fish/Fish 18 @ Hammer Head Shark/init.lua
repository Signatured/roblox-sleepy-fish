--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Hammer Head Shark",
    Rarity = Rarity.Common,
    MoneyPerSecond = 3600,
    BaseUpgradeCost = 108000,
    BillboardOffset = 5.5,
}::FishTypes.raw_dir



