--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Mythical Megladon",
    Rarity = Rarity.Secret,
    MoneyPerSecond = 100000,
    BaseUpgradeCost = 3000000,
    BillboardOffset = 7,
}::FishTypes.raw_dir



