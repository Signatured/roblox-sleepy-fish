--!strict

local RunService = game:GetService("RunService")

local WAIT_TIME = RunService:IsStudio() and 30 or 99999999
local PlayerGui: typeof(game.StarterGui) = game.Players.LocalPlayer:WaitForChild("PlayerGui", WAIT_TIME)

local module = {}

function module.Main() return PlayerGui:WaitForChild("Main", WAIT_TIME) end
function module.MainRight() return PlayerGui:WaitForChild("MainRight", WAIT_TIME) end
function module.Notifications() return PlayerGui:WaitForChild("Notifications", WAIT_TIME) end
function module.Tools() return PlayerGui:WaitForChild("Tools", WAIT_TIME) end
function module.Message() return PlayerGui:WaitForChild("Message", WAIT_TIME) end
function module.Shop() return PlayerGui:WaitForChild("Shop", WAIT_TIME) end
function module.DropButton() return PlayerGui:WaitForChild("DropButton", WAIT_TIME) end
function module.Settings() return PlayerGui:WaitForChild("Settings", WAIT_TIME) end
function module.Tutorial() return PlayerGui:WaitForChild("Tutorial", WAIT_TIME) end
function module.FriendInvite() return PlayerGui:WaitForChild("FriendInvite", WAIT_TIME) end
function module.Index() return PlayerGui:WaitForChild("Index", WAIT_TIME) end
function module.Gift() return PlayerGui:WaitForChild("Gift", WAIT_TIME) end
function module.DailyQuests() return PlayerGui:WaitForChild("DailyQuests", WAIT_TIME) end
function module.Sell() return PlayerGui:WaitForChild("Sell", WAIT_TIME) end
function module.GlobalMessage() return PlayerGui:WaitForChild("GlobalMessage", WAIT_TIME) end
function module.SpinnyWheel() return PlayerGui:WaitForChild("SpinnyWheel", WAIT_TIME) end

task.spawn(function()
    local images = {}

    for _, module in ipairs(module) do
        for _, inst in ipairs(module:GetDescendants()) do
            if inst:IsA("ImageLabel") then
                table.insert(images, inst)
            end
        end
    end

    game:GetService("ContentProvider"):PreloadAsync(images)
end)

return module
