--!strict

--[[
	Initializes the AdminAbuseEventCmds library to listen for server events.
	The module will automatically request any active events from the server when loaded.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- This require initializes the network listeners and requests active events
local _AdminAbuseEventCmds = require(ReplicatedStorage.Game.Library.Client.AdminAbuseEventCmds)

print("[AdminAbuseEvents] Client initialized and requested active events")
