--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Baby Kraken", 
    Icon = "rbxassetid://96361050680724",
    MutationIcons = {
        Bloodfish = "rbxassetid://103236754905383",
        Galaxy = "rbxassetid://102709209991376",
        Spooky = "rbxassetid://112344437927995",
        Haunted = "rbxassetid://127349470769652",
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



