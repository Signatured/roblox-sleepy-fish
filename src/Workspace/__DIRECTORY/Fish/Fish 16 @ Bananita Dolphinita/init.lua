--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Bananita Dolphinita",
    Icon = "rbxassetid://140679803980962",
    Rarity = Rarity.Epic,
    MoneyPerSecond = 60,
    BaseUpgradeCost = 41190,
    BillboardOffset = 7,
    RarityWeight = 10,
    IndexOffset = 1,
    IndexPositionOffset = Vector3.new(-0.25, 0.25, 0),
}::FishTypes.raw_dir



