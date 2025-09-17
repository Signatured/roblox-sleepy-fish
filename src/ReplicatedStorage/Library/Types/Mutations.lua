--!strict

local DirectoryTypes = require(game.ReplicatedStorage.Game.Library.Types.Directory)
local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)

local module = {}

export type raw_dir = {
    DisplayName: string,
    Color: Color3,
    MutationId: FishTypes.fish_mutation_type,
    MutationEarningsMultiplier: number,
}

export type dir_schema = raw_dir & DirectoryTypes.dir_schema

return module




