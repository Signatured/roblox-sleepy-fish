--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Pad = require(ReplicatedStorage.Library.Client.Pad)
local Marketplace = require(ReplicatedStorage.Library.Marketplace)
local TagHook = require(ReplicatedStorage.Library.Functions.TagHook)
local Directory = require(ReplicatedStorage.Game.Library.Directory)

local TAG = "ExclusivePad"

TagHook(TAG, function(instance: Instance)
    if not instance:IsA("BasePart") and not instance:IsA("Model") then
        return function() end
    end
    local pad = Pad.new(instance)
    local conn = pad:AddEnterListener(function(_player)
        local productId = Directory.Products["Imperium Whale"].ProductId
        Marketplace.Prompt(Players.LocalPlayer, productId, true)
    end)
    return function()
        pcall(function() conn.Disconnect() end)
        pcall(function() pad:Destroy() end)
    end
end)


