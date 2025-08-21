--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Electric Eel",
    Rarity = Rarity.Epic,
    MoneyPerSecond = 50,
    BaseUpgradeCost = 25440,
    BillboardOffset = 5.5,
    RarityWeight = 20,
}::FishTypes.raw_dir



