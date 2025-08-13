--!strict

--[[
	This script is the main entry point for the server-side command system.
	It loads the manager, registers all commands, and then starts listening for player chat.
]]

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- 1. Load the CommandManager module
local CommandManager = require(ServerScriptService.CommandManager)

-- 2. Load all command modules, which will register themselves with the manager
require(ServerScriptService.Game.Commands)