--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Vortex Barracuda",
    Icon = "rbxassetid://74379222733109",
    MutationIcons = {
        Bloodfish = "rbxassetid://74379222733109",
    },
    Rarity = Rarity.God,
    MoneyPerSecond = 625,
    BaseUpgradeCost = 14000,
    BillboardOffset = 9,
    PedestalOffset = -1,
    RarityWeight = 35,
    IndexOffset = -1,
    IndexPositionOffset = Vector3.new(-0.5, 0, 0),
}::FishTypes.raw_dir




