--!strict

local PlotTypes = require(game.ReplicatedStorage.Game.Library.Types.Plots)
local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)

--[[
	Defines the default stats for a new player.
	This is the master schema for all player data.
]]

export type PlotSave = {
	Money: number,
	Pedestals: number,
	Inventory: {FishTypes.data_schema},
	Fish: {[string]: PlotTypes.Fish},
}

export type schema = {
	Inventory: {FishTypes.data_schema},
	PlotSave: {
		Variables: PlotSave,
	},
	Settings: {[string]: boolean},
}

local DefaultStats = {
	Inventory = {},
	PlotSave = {
		Variables = {
			Money = 0,
			Fish = {},
			Pedestals = 1
		},
	},
	Settings = {
		Sound = true,
	},
}::schema

return DefaultStats
