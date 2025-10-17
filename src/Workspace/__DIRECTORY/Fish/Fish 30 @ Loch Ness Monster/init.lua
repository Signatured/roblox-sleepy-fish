--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Loch Ness Monster",
    Icon = "rbxassetid://87490966672620",
    MutationIcons = {
        Bloodfish = "rbxassetid://116052337277111",
        Galaxy = "rbxassetid://91677753341218",
        Spooky = "rbxassetid://94275974393084",
    },
    Rarity = Rarity.God,
    MoneyPerSecond = 650,
    BaseUpgradeCost = 15000,
    BillboardOffset = 9,
    PedestalOffset = -3,
    RarityWeight = 1,
    IndexOffset = -12,
    IndexPositionOffset = Vector3.new(-5, 1, 0),
    IndexRotationOffset = Vector3.new(0, math.rad(90), 0),
}::FishTypes.raw_dir




