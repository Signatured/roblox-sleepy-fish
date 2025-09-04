--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Pad = require(ReplicatedStorage.Library.Client.Pad)
local TabController = require(ReplicatedStorage.Library.Client.TabController)
local TagHook = require(ReplicatedStorage.Library.Functions.TagHook)
local Network = require(ReplicatedStorage.Library.Client.Network)

local TAG = "DailyQuestsPad"

TagHook(TAG, function(instance: Instance)
    if not instance:IsA("BasePart") and not instance:IsA("Model") then
        return function() end
    end
    local pad = Pad.new(instance)
    local conn = pad:AddEnterListener(function(_player)
        if TabController.GetCurrentTab() ~= "DailyQuests" then
            TabController.OpenTab("DailyQuests")
            Network.Fire("DailyQuestPad")
        end
    end)
    return function()
        pcall(function() conn.Disconnect() end)
        pcall(function() pad:Destroy() end)
    end
end)


