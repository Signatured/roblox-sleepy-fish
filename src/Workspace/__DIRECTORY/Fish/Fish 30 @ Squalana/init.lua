--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Squalana",
    Icon = "rbxassetid://121363521821478",
    MutationIcons = {
        Bloodfish = "rbxassetid://121363521821478",
        Galaxy = "rbxassetid://121363521821478",
    },
    Rarity = Rarity.God,
    MoneyPerSecond = 675,
    BaseUpgradeCost = 15500,
    BillboardOffset = 9,
    PedestalOffset = -3,
    RarityWeight = 2,
    IndexOffset = -1,
    IndexPositionOffset = Vector3.new(-0.5, 0, 0),
}::FishTypes.raw_dir




