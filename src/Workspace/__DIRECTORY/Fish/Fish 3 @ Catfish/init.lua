--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Catfish",
    Icon = "rbxassetid://140404428926862",
    Rarity = Rarity.Common,
    MoneyPerSecond = 3,
    BaseUpgradeCost = 90,
    BillboardOffset = 5.5,
    RarityWeight = 15,
}::FishTypes.raw_dir



