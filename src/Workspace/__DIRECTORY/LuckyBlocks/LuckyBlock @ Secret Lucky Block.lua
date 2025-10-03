--!strict

local LuckyBlockTypes = require(game.ReplicatedStorage.Game.Library.Types.LuckyBlocks)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Secret",
    Rarity = Rarity.Secret,
    Loot = {
        ["Ancient Sea Dragon"] = 60,
        ["Luminite Shark"] = 25,
        ["Skeleton Shark"] = 10,
        ["Oblivion Sea Dragon"] = 5,
    },
}::LuckyBlockTypes.raw_dir
