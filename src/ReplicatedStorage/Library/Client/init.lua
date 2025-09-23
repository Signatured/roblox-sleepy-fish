local module = {}

-- Expose commonly used client modules through the root for convenience
local ok, srvLuck = pcall(function()
	return require(script:FindFirstChild("ServerLuckCmds"))
end)
if ok and srvLuck then
	module.ServerLuckCmds = srvLuck
end

local okAP, ap = pcall(function()
	return require(script:FindFirstChild("AdminPanelCmds"))
end)
if okAP and ap then
	module.AdminPanelCmds = ap
end

return module
