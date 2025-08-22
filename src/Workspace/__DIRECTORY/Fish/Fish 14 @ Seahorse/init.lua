--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Seahorse",
    Icon = "rbxassetid://111756213553966",
    Rarity = Rarity.Epic,
    MoneyPerSecond = 42,
    BaseUpgradeCost = 15720,
    BillboardOffset = 7,
    RarityWeight = 30,
}::FishTypes.raw_dir



