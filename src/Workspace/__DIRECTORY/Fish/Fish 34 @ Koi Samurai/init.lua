--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Koi Samurai",
    Icon = "rbxassetid://81394421163062",
    MutationIcons = {
        Bloodfish = "rbxassetid://120104632306078",
        Galaxy = "rbxassetid://96810967015031",
        Spooky = "rbxassetid://85223897277664",
        Haunted = "rbxassetid://130698641740936",
    },
    Rarity = Rarity.Secret,
    MoneyPerSecond = 960,
    BaseUpgradeCost = 30500,
    BillboardOffset = 12,
    PedestalOffset = -1,
    RarityWeight = 8,
    IndexOffset = -17,
    IndexPositionOffset = Vector3.new(-6, 0, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(90), 0),
}::FishTypes.raw_dir



