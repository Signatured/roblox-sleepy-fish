--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Clown Fish",
    Icon = "rbxassetid://110984573735192",
    Rarity = Rarity.Common,
    MoneyPerSecond = 1,
    BaseUpgradeCost = 30,
    BillboardOffset = 5.5,
    RarityWeight = 60,
}::FishTypes.raw_dir



