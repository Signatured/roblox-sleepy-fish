--!strict

local DirectoryTypes = require(game.ReplicatedStorage.Game.Library.Types.Directory)
local RarityTypes = require(game.ReplicatedStorage.Game.Library.Types.Rarity)
local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)

local module = {}

export type raw_dir = {
	DisplayName: string,
	Rarity: RarityTypes.dir_schema,
    Loot: {[string]: number},
}

export type lucky_block_visual_data = {
    FishId: string,
    Type: FishTypes.fish_type,
}

export type dir_schema = raw_dir & DirectoryTypes.dir_schema

return module
