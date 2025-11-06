--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Pad = require(ReplicatedStorage.Library.Client.Pad)
local TabController = require(ReplicatedStorage.Library.Client.TabController)
local TagHook = require(ReplicatedStorage.Library.Functions.TagHook)
local Save = require(ReplicatedStorage.Library.Client.Save)
local NotificationCmds = require(ReplicatedStorage.Library.Client.NotificationCmds)

local TAG = "HalloweenCraftingPad"

TagHook(TAG, function(instance: Instance)
    if not instance:IsA("BasePart") and not instance:IsA("Model") then
        return function() end
    end
    local pad = Pad.new(instance)
    local conn = pad:AddEnterListener(function(_player)
        local save = Save.Get()
        if not save then
            return
        end

        if not save.TutorialClaim then
            NotificationCmds.Message("You need to complete the tutorial first!", {
                Color = Color3.fromRGB(255, 0, 0),
            })
            return
        end
        
        if TabController.GetCurrentTab() ~= "HalloweenCrafting" then
            TabController.OpenTab("HalloweenCrafting")
        end
    end)
    return function()
        pcall(function() conn.Disconnect() end)
        pcall(function() pad:Destroy() end)
    end
end)


