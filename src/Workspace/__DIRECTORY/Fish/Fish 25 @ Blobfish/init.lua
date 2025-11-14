--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Blobfish",
    Icon = "rbxassetid://138082211172333",
    MutationIcons = {
        Bloodfish = "rbxassetid://138465378317929",
        Galaxy = "rbxassetid://128548695169324",
        Spooky = "rbxassetid://118108984505347",
        Haunted = "rbxassetid://99701967535624",
        YinYang = "",
    },
    Rarity = Rarity.Mythical,
    MoneyPerSecond = 200,
    BaseUpgradeCost = 5100,
    BillboardOffset = 6,
    RarityWeight = 15,
    IndexRotationOffset = Vector3.new(0, math.rad(-180), 0),
    IndexOffset = 0.5,
    IndexPositionOffset = Vector3.new(0.5, -0.2, 0),
}::FishTypes.raw_dir



