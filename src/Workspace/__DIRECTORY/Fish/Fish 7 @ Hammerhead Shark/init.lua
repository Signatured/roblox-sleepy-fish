--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Hammerhead Shark",
    Icon = "rbxassetid://89376900524787",
    Rarity = Rarity.Uncommon,
    MoneyPerSecond = 10,
    BaseUpgradeCost = 540,
    BillboardOffset = 7,
    RarityWeight = 20,
}::FishTypes.raw_dir



