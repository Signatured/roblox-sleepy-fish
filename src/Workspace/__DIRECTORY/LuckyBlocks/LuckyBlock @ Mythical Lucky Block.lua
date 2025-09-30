--!strict

local LuckyBlockTypes = require(game.ReplicatedStorage.Game.Library.Types.LuckyBlocks)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Mythical",
    Rarity = Rarity.Mythical,
    Loot = {
        ["Blobfish"] = 100,
        ["Giant Jellyfish"] = 50,
        ["Blue Whale"] = 25,
    },
}::LuckyBlockTypes.raw_dir
