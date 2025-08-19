local module = {}

-- Expose commonly used client modules through the root for convenience
local ok, srvLuck = pcall(function()
	return require(script:FindFirstChild("ServerLuckCmds"))
end)
if ok and srvLuck then
	module.ServerLuckCmds = srvLuck
end

return module
