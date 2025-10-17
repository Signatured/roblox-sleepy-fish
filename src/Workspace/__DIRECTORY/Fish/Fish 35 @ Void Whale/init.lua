--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Void Whale",
    Icon = "rbxassetid://131196286718082",
    MutationIcons = {
        Bloodfish = "rbxassetid://111956604842913",
        Galaxy = "rbxassetid://80574189877839",
        Spooky = "rbxassetid://85761224831114",
    },
    Rarity = Rarity.Secret,
    MoneyPerSecond = 975,
    BaseUpgradeCost = 32000,
    BillboardOffset = 13,
    PedestalOffset = -2,
    RarityWeight = 3,
    IndexOffset = -17,
    IndexPositionOffset = Vector3.new(-6, 0, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(90), 0),
}::FishTypes.raw_dir



