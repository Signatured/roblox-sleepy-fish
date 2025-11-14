--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Bladewave Hammerhead",
    Icon = "rbxassetid://87490966672620",
    MutationIcons = {
        Bloodfish = "rbxassetid://87490966672620",
        Galaxy = "rbxassetid://87490966672620",
        Spooky = "rbxassetid://87490966672620",
        Haunted = "rbxassetid://87490966672620",
        YinYang = "rbxassetid://85257947158723",
    },
    Rarity = Rarity.God,
    MoneyPerSecond = 675,
    BaseUpgradeCost = 15500,
    BillboardOffset = 9,
    PedestalOffset = -3,
    RarityWeight = 1,
    IndexOffset = -12,
    IndexPositionOffset = Vector3.new(-5, 1, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(90), 0),
}::FishTypes.raw_dir




