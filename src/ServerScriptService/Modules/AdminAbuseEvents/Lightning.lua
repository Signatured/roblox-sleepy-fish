--!strict

--[[
	Server-side logic for Lightning event.
	Module-level variables are shared across all function calls.
]]

local module = {}

-- Shared state for this event
local strikeCount = 0
local lastStrikeTime = 0

function module.OnStart()
	print("[Lightning Server] Event started")
	strikeCount = 0
	lastStrikeTime = 0
end

function module.Heartbeat(delta: number, time: number)
	-- Example: Strike lightning every 5 seconds
	if time - lastStrikeTime >= 5 then
		strikeCount += 1
		lastStrikeTime = time
		print("[Lightning Server] Strike #" .. strikeCount .. " at time " .. math.floor(time))
	end
end

function module.OnStop()
	print("[Lightning Server] Event stopped. Total strikes:", strikeCount)
	-- Reset state
	strikeCount = 0
	lastStrikeTime = 0
end

return module

