--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Megalodon Shark",
    Icon = "rbxassetid://88710987072085",
    MutationIcons = {
        Bloodfish = "rbxassetid://101658843624617",
        Galaxy = "rbxassetid://139487831896572",
        Spooky = "rbxassetid://84902031871558",
        Haunted = "rbxassetid://77182336355899",
        YinYang = "rbxassetid://138822159685887",
    },
    Rarity = Rarity.Mythical,
    MoneyPerSecond = 250,
    BaseUpgradeCost = 6500,
    BillboardOffset = 7,
    RarityWeight = 11,
    IndexOffset = 0,
    IndexPositionOffset = Vector3.new(-4.5, -0.5, 0),
}::FishTypes.raw_dir



