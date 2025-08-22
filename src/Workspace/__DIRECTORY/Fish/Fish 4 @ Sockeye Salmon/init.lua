--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Sockeye Salmon",
    Icon = "rbxassetid://81444317161028",
    Rarity = Rarity.Common,
    MoneyPerSecond = 4,
    BaseUpgradeCost = 120,
    BillboardOffset = 6,
    RarityWeight = 10,
    IndexOffset = 2.5,
    IndexPositionOffset = Vector3.new(-1, -0.5, 0),
}::FishTypes.raw_dir



