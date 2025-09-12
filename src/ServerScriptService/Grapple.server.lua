--!strict

local _Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local _ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ServerScriptService.Library.Network)
local Gadgets = require(ServerScriptService.Game.Library.Gadgets)
local FishGen = require(ServerScriptService.Game.Library.FishGenerator)

-- Client reports a grapple hit with a fish UID
Network.Invoked("Grapple_HitFish", function(player: Player, uid: string)
    if type(uid) ~= "string" or uid == "" then return end

    -- Verify the player currently has Grappling Hook equipped
    local hasHook = Gadgets.Has(player, "Grappling Hook")
    if not hasHook then return false end

    -- Find the fish model by UID attribute
    local hitModel: Model? = nil
    local things = workspace:FindFirstChild("__THINGS")
    local swimmingRoot = things and things:FindFirstChild("SwimmingFish")
    if swimmingRoot then
        for _, m in ipairs(swimmingRoot:GetDescendants()) do
            if m:IsA("Model") and m:GetAttribute("UID") == uid then
                hitModel = m
                break
            end
        end
    end
    if not hitModel then return false end

    -- Mark grappling and unanchor all parts so physics can move it
    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp or not hrp:IsA("BasePart") then return end

    local primary = hitModel.PrimaryPart or hitModel:FindFirstChildWhichIsA("BasePart")
    if not primary then return false end

    if not FishGen.CanPickup(player, uid) then
        return false
    end

    -- Mark as grappling
    hitModel:SetAttribute("Grappling", player.UserId)

    -- Unanchor the entire model so LV can move it
    for _, inst in ipairs(hitModel:GetDescendants()) do
        if inst:IsA("BasePart") then
            (inst :: BasePart).Anchored = false
        end
    end

    local att = Instance.new("Attachment")
    att.Parent = primary

    local lv = Instance.new("LinearVelocity")
    lv.Attachment0 = att
    lv.MaxForce = math.huge
    lv.Parent = primary

    local connection
    connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        if not player.Parent or not hitModel or not hitModel.Parent then
            if connection then connection:Disconnect() end
            if lv then lv:Destroy() end
            if att then att:Destroy() end
            pcall(function()
                if hitModel then hitModel:SetAttribute("Grappling", nil) end
            end)
            return
        end
        local toPlayer = (hrp.Position - primary.Position)
        local dist = toPlayer.Magnitude
        if dist < 6 then
            -- close enough: make the player carry the fish
            if connection then connection:Disconnect() end
            if lv then lv:Destroy() end
            if att then att:Destroy() end

            FishGen.AttemptPickupByUID(player, uid)
            hitModel:SetAttribute("Grappling", nil)
            return
        end
        local dir = toPlayer.Unit
        lv.VectorVelocity = dir * 40
    end)
    return true
end)


