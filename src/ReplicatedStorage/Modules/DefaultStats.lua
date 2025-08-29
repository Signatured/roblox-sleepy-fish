--!strict

local PlotTypes = require(game.ReplicatedStorage.Game.Library.Types.Plots)
local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)

local GameSettings = require(game.ReplicatedStorage.Game.Library.GameSettings)

--[[
	Defines the default stats for a new player.
	This is the master schema for all player data.
]]

export type PlotSave = {
	Money: number,
	Inventory: {FishTypes.data_schema},
	Fish: {[string]: PlotTypes.Fish},
	PaidIndex: number,
	InventorySize: number,
}

export type IndexData = {
	Normal: boolean?,
	Shiny: boolean?,
	Gold: boolean?,
	Rainbow: boolean?,
}

export type schema = {
	Inventory: {FishTypes.data_schema},
	Tools: {[string]: boolean},
	PlotSave: {
		Variables: PlotSave,
	},
	Settings: {[string]: boolean},
	LastLogout: number?,
	Gamepasses: {[string]: boolean},
	Products: {[string]: boolean},
	Joins: number,
	Playtime: number,
	TutorialClaim: boolean,
	FinishedTutorial: boolean,
	Index: {[string]: IndexData},
	GroupReward: boolean,
	PromptedNotifications: boolean,
	RobuxSpent: number,
}

local DefaultStats = {
	Inventory = {},
	Tools = {},
	PlotSave = {
		Variables = {
			Money = 0,
			Fish = {},
			PaidIndex = 0,
			InventorySize = GameSettings.MaxInventory,
		},
	},
	Settings = {
		Sound = true,
		Music = true,
	},
	Gamepasses = {},
	Products = {},
	Joins = 0,
	Playtime = 0,
	TutorialClaim = false,
	FinishedTutorial = true,
	Index = {},
	GroupReward = false,
	PromptedNotifications = false,
	RobuxSpent = 0,
}::schema

return DefaultStats
