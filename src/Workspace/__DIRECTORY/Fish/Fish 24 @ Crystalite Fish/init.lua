--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Crystalite Fish",
    Icon = "rbxassetid://129164143486030",
    Rarity = Rarity.Mythical,
    MoneyPerSecond = 350,
    BaseUpgradeCost = 8500,
    BillboardOffset = 6,
    RarityWeight = 10,
}::FishTypes.raw_dir



