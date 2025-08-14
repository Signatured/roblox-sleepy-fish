--!strict

local DirectoryTypes = require(game.ReplicatedStorage.Game.Library.Types.Directory)

local module = {}

export type raw_dir = {
	DisplayName: string,
	Location: number,
    FollowRange: number,
}

export type dir_schema = raw_dir & DirectoryTypes.dir_schema

return module


