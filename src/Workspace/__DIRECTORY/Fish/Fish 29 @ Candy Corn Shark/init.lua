--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Candy Corn Shark",
    Icon = "rbxassetid://78218642922148",
    MutationIcons = {
        Bloodfish = "rbxassetid://78218642922148",
        Galaxy = "rbxassetid://78218642922148",
        Spooky = "rbxassetid://78218642922148",
    },
    Rarity = Rarity.Mythical,
    MoneyPerSecond = 440,
    BaseUpgradeCost = 10750,
    BillboardOffset = 7,
    PedestalOffset = -0.5,
    RarityWeight = 3,
    IndexOffset = -23,
    IndexPositionOffset = Vector3.new(-2, 0, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(90), 0),
}::FishTypes.raw_dir



