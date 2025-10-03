--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Loch Ness Monster",
    Icon = "rbxassetid://87490966672620",
    MutationIcons = {
        Bloodfish = "rbxassetid://116052337277111",
        Galaxy = "rbxassetid://91677753341218",
    },
    Rarity = Rarity.God,
    MoneyPerSecond = 650,
    BaseUpgradeCost = 15000,
    BillboardOffset = 9,
    PedestalOffset = -3,
    RarityWeight = 5,
    IndexOffset = -1,
    IndexPositionOffset = Vector3.new(-0.5, 0, 0),
}::FishTypes.raw_dir




