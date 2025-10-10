--!strict

local LuckyBlockTypes = require(game.ReplicatedStorage.Game.Library.Types.LuckyBlocks)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Secret",
    Rarity = Rarity.Secret,
    Loot = {
        ["Skeleton Shark"] = 60,
        ["Oblivion Sea Dragon"] = 25,
        ["Void Whale"] = 10,
        ["Spineblade"] = 5,
    },
}::LuckyBlockTypes.raw_dir
