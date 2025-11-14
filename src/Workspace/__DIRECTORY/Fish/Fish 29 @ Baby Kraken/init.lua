--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Baby Kraken", 
    Icon = "rbxassetid://97593230164895",
    MutationIcons = {
        Bloodfish = "rbxassetid://84571706066959",
        Galaxy = "rbxassetid://115088561413136",
        Spooky = "rbxassetid://86452600669836",
        Haunted = "rbxassetid://121010180693351",
        YinYang = "rbxassetid://89892540410947",
    },
    Rarity = Rarity.Mythical,
    MoneyPerSecond = 420,
    BaseUpgradeCost = 10500,
    BillboardOffset = 9.5,
    PedestalOffset = 0,
    RarityWeight = 5,
    IndexOffset = -4,
    IndexPositionOffset = Vector3.new(-3, 0, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(90), 0),
}::FishTypes.raw_dir



