--!strict

local FishTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.GameLibrary.Directory.Rarity)

return {
    DisplayName = "Puffer Fish",
    Rarity = Rarity.Common,
    MoneyPerSecond = 18,
    BaseUpgradeCost = 540,
    BillboardOffset = 7,
}::FishTypes.raw_dir



