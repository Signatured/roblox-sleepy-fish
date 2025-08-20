--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Electric Eel",
    Rarity = Rarity.Epic,
    MoneyPerSecond = 47,
    BaseUpgradeCost = 1410,
    BillboardOffset = 7,
}::FishTypes.raw_dir



