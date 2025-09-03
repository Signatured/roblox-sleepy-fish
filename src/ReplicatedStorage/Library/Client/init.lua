local module = {}

-- Expose commonly used client modules through the root for convenience
local ok, srvLuck = pcall(function()
	return require(script:FindFirstChild("ServerLuckCmds"))
end)
if ok and srvLuck then
	module.ServerLuckCmds = srvLuck
end

local okDQ, dq = pcall(function()
	return require(script:FindFirstChild("DailyQuestsCmds"))
end)
if okDQ and dq then
	module.DailyQuestsCmds = dq
end

return module
