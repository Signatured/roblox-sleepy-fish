--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Seahorse",
    Icon = "rbxassetid://99958304528048",
    MutationIcons = {
        Bloodfish = "rbxassetid://140470600532782",
        Galaxy = "rbxassetid://97521499005262",
        Spooky = "rbxassetid://126532269866132",
    },
    Rarity = Rarity.Epic,
    MoneyPerSecond = 42,
    BaseUpgradeCost = 700,
    BillboardOffset = 7,
    RarityWeight = 25,
    IndexRotationOffset = Vector3.new(0, math.rad(180), 0),
    IndexOffset = 3.5,
}::FishTypes.raw_dir



