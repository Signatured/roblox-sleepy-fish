--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Audio = require(ReplicatedStorage.Library.Audio)
local NotificationCmds = require(ReplicatedStorage.Library.Client.NotificationCmds)
local Network = require(ReplicatedStorage.Library.Client.Network)

-- Listen for server event when a fish is successfully banked
Network.Fired("Fish_Caught", function(displayName: string)
	Audio.Play("rbxassetid://94238694593476", script, 1, 0.3)
	if typeof(displayName) == "string" and #displayName > 0 then
		NotificationCmds.Message(`You caught a {displayName}!`, {
			Color = Color3.fromRGB(0, 255, 0),
			Time = 3,
		})
	end
end)


