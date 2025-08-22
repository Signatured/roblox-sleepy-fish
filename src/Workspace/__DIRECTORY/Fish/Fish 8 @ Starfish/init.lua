--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Starfish",
    Icon = "rbxassetid://134483109412863",
    Rarity = Rarity.Uncommon,
    MoneyPerSecond = 12,
    BaseUpgradeCost = 870,
    BillboardOffset = 7,
    RarityWeight = 10,
}::FishTypes.raw_dir



