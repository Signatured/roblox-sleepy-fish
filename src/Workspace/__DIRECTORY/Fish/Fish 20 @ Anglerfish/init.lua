--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Anglerfish",
    Icon = "rbxassetid://86840527641213",
    MutationIcons = {
        Bloodfish = "rbxassetid://104833757213119",
        Galaxy = "rbxassetid://87864836206724",
        Spooky = "rbxassetid://84691188404746",
    },
    Rarity = Rarity.Legendary,
    MoneyPerSecond = 85,
    BaseUpgradeCost = 1800,
    BillboardOffset = 7,
    RarityWeight = 19,
    IndexOffset = -1,
    IndexPositionOffset = Vector3.new(-0.5, 0, 0),
}::FishTypes.raw_dir



