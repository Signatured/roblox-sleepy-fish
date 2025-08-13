--!strict

local PlotTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Plots)
local FishTypes = require(game.ReplicatedStorage.Game.GameLibrary.Types.Fish)

--[[
	Defines the default stats for a new player.
	This is the master schema for all player data.
]]

export type PlotSave = {
	Pedestals: number,
	PedestalData: PedestalData,
	Inventory: {FishTypes.data_schema} 
}

export type PedestalData = {[string]: {
	Level: number,
}}

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
			Pedestals = 1,
			PedestalData = {}
		},
	},
	Settings = {
		Sound = true,
	},
}::schema

return DefaultStats
