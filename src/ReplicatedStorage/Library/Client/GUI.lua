--!strict

local RunService = game:GetService("RunService")

local WAIT_TIME = RunService:IsStudio() and 30 or 99999999
local PlayerGui: typeof(game.StarterGui) = game.Players.LocalPlayer:WaitForChild("PlayerGui", WAIT_TIME)

local module = {}

function module.Main() return PlayerGui:WaitForChild("Main", WAIT_TIME) end
function module.Notifications() return PlayerGui:WaitForChild("Notifications", WAIT_TIME) end
function module.Tools() return PlayerGui:WaitForChild("Tools", WAIT_TIME) end
function module.Message() return PlayerGui:WaitForChild("Message", WAIT_TIME) end
function module.Shop() return PlayerGui:WaitForChild("Shop", WAIT_TIME) end
function module.DropButton() return PlayerGui:WaitForChild("DropButton", WAIT_TIME) end
function module.Settings() return PlayerGui:WaitForChild("Settings", WAIT_TIME) end
function module.Tutorial() return PlayerGui:WaitForChild("Tutorial", WAIT_TIME) end
function module.FriendInvite() return PlayerGui:WaitForChild("FriendInvite", WAIT_TIME) end

return module
