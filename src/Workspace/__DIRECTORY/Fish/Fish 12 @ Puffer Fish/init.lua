--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Puffer Fish",
    Icon = "rbxassetid://107649534762311",
    MutationIcons = {
        Bloodfish = "rbxassetid://77965100406749",
        Galaxy = "rbxassetid://122683647278559",
        Spooky = "rbxassetid://104472687217882",
        Haunted = "rbxassetid://102893434236149",
        YinYang = "rbxassetid://114430333683267",
    },
    Rarity = Rarity.Rare,
    MoneyPerSecond = 24,
    BaseUpgradeCost = 350,
    BillboardOffset = 6.5,
    RarityWeight = 20,
    IndexOffset = 1,
    IndexPositionOffset = Vector3.new(-0.5, 0, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(180), 0),
}::FishTypes.raw_dir



