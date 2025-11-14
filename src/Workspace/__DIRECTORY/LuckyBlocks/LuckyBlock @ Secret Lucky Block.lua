--!strict

local LuckyBlockTypes = require(game.ReplicatedStorage.Game.Library.Types.LuckyBlocks)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Secret",
    Rarity = Rarity.Secret,
    Loot = {
        ["Void Whale"] = 60,
        ["Spineblade"] = 25,
        ["Zilla Shark"] = 10,
        ["The Seeker"] = 5,
    },
}::LuckyBlockTypes.raw_dir
