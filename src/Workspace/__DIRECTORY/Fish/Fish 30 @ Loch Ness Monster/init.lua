--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Loch Ness Monster",
    Icon = "rbxassetid://86840527641213",
    MutationIcons = {
        Bloodfish = "rbxassetid://104833757213119",
    },
    Rarity = Rarity.God,
    MoneyPerSecond = 625,
    BaseUpgradeCost = 14000,
    BillboardOffset = 7,
    RarityWeight = 35,
    IndexOffset = -1,
    IndexPositionOffset = Vector3.new(-0.5, 0, 0),
}::FishTypes.raw_dir




