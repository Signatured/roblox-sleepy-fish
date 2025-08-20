--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Electric Eel",
    Rarity = Rarity.Legendary,
    MoneyPerSecond = 848,
    BaseUpgradeCost = 25440,
    BillboardOffset = 5.5,
}::FishTypes.raw_dir



