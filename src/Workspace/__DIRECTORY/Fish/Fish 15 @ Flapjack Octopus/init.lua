--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Flapjack Octopus",
    Icon = "rbxassetid://85984305169053",
    MutationIcons = {
        Bloodfish = "rbxassetid://127169742499786",
        Galaxy = "rbxassetid://80021108168670",
        Spooky = "rbxassetid://107093351195013",
        Haunted = "rbxassetid://91641391292797",
        YinYang = "rbxassetid://90891591361578",
    },
    Rarity = Rarity.Epic,
    MoneyPerSecond = 46,
    BaseUpgradeCost = 850,
    BillboardOffset = 7,
    RarityWeight = 20,
    -- IndexRotationOffset = Vector3.new(0, math.rad(180), 0),
    -- IndexOffset = 3.5,
}::FishTypes.raw_dir



