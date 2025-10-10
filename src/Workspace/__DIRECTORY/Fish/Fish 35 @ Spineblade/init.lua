--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Spineblade",
    Icon = "rbxassetid://102466648574486",
    MutationIcons = {
        Bloodfish = "rbxassetid://134560255470912",
        Galaxy = "rbxassetid://99255448903907",
    },
    Rarity = Rarity.Secret,
    MoneyPerSecond = 1000,
    BaseUpgradeCost = 33000,
    BillboardOffset = 13,
    PedestalOffset = -2,
    RarityWeight = 1,
    IndexOffset = -17,
    IndexPositionOffset = Vector3.new(-6, 0, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(90), 0),
}::FishTypes.raw_dir



