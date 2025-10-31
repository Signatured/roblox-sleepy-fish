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
    RarityWeight = 3,
    IndexOffset = 0,
    IndexPositionOffset = Vector3.new(-4.5, -0.5, 0),
}::FishTypes.raw_dir



