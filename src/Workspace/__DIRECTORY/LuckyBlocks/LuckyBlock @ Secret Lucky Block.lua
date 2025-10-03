--!strict

local LuckyBlockTypes = require(game.ReplicatedStorage.Game.Library.Types.LuckyBlocks)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Secret",
    Rarity = Rarity.Secret,
    Loot = {
        ["Luminite Shark"] = 60,
        ["Skeleton Shark"] = 25,
        ["Oblivion Sea Dragon"] = 10,
        ["Void Whale"] = 5,
    },
}::LuckyBlockTypes.raw_dir
