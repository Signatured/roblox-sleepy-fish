--!strict

local LuckyBlockTypes = require(game.ReplicatedStorage.Game.Library.Types.LuckyBlocks)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Secret",
    Rarity = Rarity.Secret,
    Loot = {
        ["Vampire Sea Dragon"] = 60,
        ["Void Whale"] = 25,
        ["Spineblade"] = 10,
        ["The Seeker"] = 5,
    },
}::LuckyBlockTypes.raw_dir
