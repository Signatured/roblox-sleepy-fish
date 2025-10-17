--!strict

--[[
	Client-side logic for Lightning event.
	Module-level variables are shared across all function calls.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NotificationCmds = require(ReplicatedStorage.Library.Client.NotificationCmds)
local AdminAbuseEventCmds = require(ReplicatedStorage.Game.Library.Client.AdminAbuseEventCmds)

local module = {}

-- Shared state for this event
local flashCount = 0
local _intensity = 0

function module.OnStart()
	print("[Lightning Client] Event started")
	flashCount = 0
	_intensity = 0
	
	NotificationCmds.Message("A storm is brewing...", {
		Color = Color3.fromRGB(100, 193, 255),
		Time = 8,
	})
	
	-- Register handler for lightning strikes
	AdminAbuseEventCmds.Fired("Lightning", "Strike", function(data: any?)
		if typeof(data) == "table" then
			local strikeData = data :: {UID: string?, StrikeCount: number?}
			print("[Lightning Client] Lightning struck fish:", strikeData.UID, "Strike #" .. tostring(strikeData.StrikeCount or 0))
			
			-- Could add visual/audio effects here
			-- For example: flash the screen, play thunder sound, etc.
		end
	end)
end

function module.RenderStepped(delta: number, time: number)
	-- Example: Gradually increase intensity over time
	_intensity = math.min(1, time / 30) -- Ramps up over 30 seconds
	
	-- Example: Flash effect every few seconds
	local currentFlash = math.floor(time / 3)
	if currentFlash > flashCount then
		flashCount = currentFlash
		-- Could trigger visual effects here
		-- print("[Lightning Client] Flash! Intensity:", _intensity)
	end
end

function module.OnStop()
	print("[Lightning Client] Event stopped. Total flashes:", flashCount)
	
	NotificationCmds.Message("The storm has passed...", {
		Color = Color3.fromRGB(100, 193, 255),
		Time = 8,
	})
	
	-- Reset state
	flashCount = 0
	_intensity = 0
end

return module

