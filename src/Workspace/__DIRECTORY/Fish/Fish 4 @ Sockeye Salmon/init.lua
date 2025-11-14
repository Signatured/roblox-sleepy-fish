--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Sockeye Salmon",
    Icon = "rbxassetid://82855956090115",
    MutationIcons = {
        Bloodfish = "rbxassetid://125578700188369",
        Galaxy = "rbxassetid://98960008637270",
        Spooky = "rbxassetid://128422165388645",
        Haunted = "rbxassetid://124122973505185",
        YinYang = "rbxassetid://129562128689775",
    },
    Rarity = Rarity.Common,
    MoneyPerSecond = 4,
    BaseUpgradeCost = 80,
    BillboardOffset = 6,
    RarityWeight = 10,
    IndexOffset = 2.5,
    IndexPositionOffset = Vector3.new(-1, -0.5, 0),
}::FishTypes.raw_dir



