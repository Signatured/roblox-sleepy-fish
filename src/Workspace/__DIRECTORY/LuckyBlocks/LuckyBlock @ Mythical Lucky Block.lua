--!strict

local LuckyBlockTypes = require(game.ReplicatedStorage.Game.Library.Types.LuckyBlocks)
local Rarity = require(game.ReplicatedStorage.Game.Library.Directory.Rarity)

return {
    DisplayName = "Mythical",
    Rarity = Rarity.Mythical,
    Loot = {
        ["Zombie Tralalero"] = 40,
        ["Haunted Prawn"] = 30,
        ["Narwhal"] = 20,
        ["Diamond Serpent"] = 10,
    },
}::LuckyBlockTypes.raw_dir
