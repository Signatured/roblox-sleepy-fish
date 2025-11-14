--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Zilla Shark",
    Icon = "rbxassetid://102466648574486",
    MutationIcons = {
        Bloodfish = "rbxassetid://102466648574486",
        Galaxy = "rbxassetid://102466648574486",
        Spooky = "rbxassetid://102466648574486",
        Haunted = "rbxassetid://102466648574486",
        YinYang = "rbxassetid://134555790348557",
    },
    Rarity = Rarity.Secret,
    MoneyPerSecond = 1025,
    BaseUpgradeCost = 33500,
    BillboardOffset = 13,
    PedestalOffset = -2,
    RarityWeight = 3,
    IndexOffset = -17,
    IndexPositionOffset = Vector3.new(-6, 0, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(90), 0),
}::FishTypes.raw_dir



