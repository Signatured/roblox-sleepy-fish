--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Baluga Whale",
    Rarity = Rarity.Epic,
    MoneyPerSecond = 123,
    BaseUpgradeCost = 3690,
    BillboardOffset = 7,
}::FishTypes.raw_dir



