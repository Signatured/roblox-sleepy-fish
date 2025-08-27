--!strict

local DirectoryTypes = require(game.ReplicatedStorage.Game.Library.Types.Directory)

local module = {}

export type raw_dir = {
	DisplayName: string,
	Icon: string,
	Description: string,
	Index: number?,
	Cost: number?,
	SpeedMultiplier: number?,
	Gradient: string?,
	Exclusive: boolean?,
}

export type dir_schema = raw_dir & DirectoryTypes.dir_schema

return module
