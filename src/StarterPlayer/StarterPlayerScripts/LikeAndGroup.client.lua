--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Pad = require(ReplicatedStorage.Library.Client.Pad)
local TagHook = require(ReplicatedStorage.Library.Functions.TagHook)
local Save = require(ReplicatedStorage.Library.Client.Save)
local Message = require(ReplicatedStorage.Library.Client.Message)
local Network = require(ReplicatedStorage.Library.Client.Network)

local TAG = "LikePad"
local GROUP_ID = 535442508

-- Track whether the player has already stepped once (per-pad instance)
local primedPads: {[Instance]: boolean} = {}

local function isInGroup(player: Player): boolean
    local ok, res = pcall(function()
        return player:IsInGroup(GROUP_ID)
    end)
    return ok and res == true
end

TagHook(TAG, function(instance: Instance)
    if not instance:IsA("BasePart") and not instance:IsA("Model") then
        return function() end
    end

    local pad = Pad.new(instance)
    local conn = pad:AddEnterListener(function(player: Player)
        local function handle()
            local save = Save.Get()
            if not save then
                return
            end

            if save.GroupReward == true then
                return
            end

            if not isInGroup(Players.LocalPlayer) then
                Message.new("Like the game and join the group first!")
                return
            end

            if not primedPads[instance] then
                primedPads[instance] = true
                Message.new("Like the game first!")
                return
            end

            Network.Fire("LikeAndGroup_Claim")
        end

        if not Save.Get() then
            local once
            once = Save.SaveAdded:Connect(function()
                pcall(function() once:Disconnect() end)
                if pad:IsStandingOn(player) then
                    handle()
                end
            end)
        else
            handle()
        end
    end)

    return function()
        pcall(function() conn.Disconnect() end)
        pcall(function() pad:Destroy() end)
        primedPads[instance] = nil
    end
end)


