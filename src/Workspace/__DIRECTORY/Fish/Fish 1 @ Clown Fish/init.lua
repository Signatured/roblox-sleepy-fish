--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Clown Fish",
    Icon = "rbxassetid://110984573735192",
    MutationIcons = {
        Bloodfish = "rbxassetid://89664796459386",
        Galaxy = "rbxassetid://122223189406804",
        Spooky = "rbxassetid://109268934648111",
    },
    Rarity = Rarity.Common,
    MoneyPerSecond = 1,
    BaseUpgradeCost = 50,
    BillboardOffset = 5.5,
    RarityWeight = 60,
    IndexRotationOffset = Vector3.new(0, math.rad(180), 0),
    IndexOffset = 2,
    IndexPositionOffset = Vector3.new(-0.5, 0, 0),
}::FishTypes.raw_dir



