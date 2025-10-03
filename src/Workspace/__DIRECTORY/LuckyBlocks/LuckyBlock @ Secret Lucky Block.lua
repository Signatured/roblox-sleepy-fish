--!strict

local LuckyBlockTypes = require(game.ReplicatedStorage.Game.Library.Types.LuckyBlocks)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Secret",
    Rarity = Rarity.Secret,
    Loot = {
        ["Ancient Sea Dragon"] = 75,
        ["Luminite Shark"] = 21,
        ["Skeleton Shark"] = 3,
        ["Oblivion Sea Dragon"] = 5,
    },
}::LuckyBlockTypes.raw_dir
