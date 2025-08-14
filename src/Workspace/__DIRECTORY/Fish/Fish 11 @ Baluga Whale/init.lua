--!strict

local FishTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.GameLibrary.Directory.Rarity)

return {
    DisplayName = "Baluga Whale",
    Rarity = Rarity.Common,
    MoneyPerSecond = 123,
    BaseUpgradeCost = 3690,
    BillboardOffset = 7,
}::FishTypes.raw_dir



