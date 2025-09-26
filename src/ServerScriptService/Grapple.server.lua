--!strict

local _Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local _ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ServerScriptService.Library.Network)
local Gadgets = require(ServerScriptService.Game.Library.Gadgets)
local FishGen = require(ServerScriptService.Game.Library.FishGenerator)

-- Broadcast to all clients when a player shoots their grapple (for visuals only)
Network.Fired("Grapple_Shoot", function(player: Player, origin: Vector3, direction: Vector3)
	-- Optional: validate the player still has the gadget
	if not Gadgets.Has(player, "Grappling Hook") then return end
	Network.FireAll("Grapple_PlayShot", player.UserId, origin, direction)
end)

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

	if player:GetAttribute("Dead") then return false end

	-- Mark grappling and unanchor all parts so physics can move it
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then return end

	local primary = hitModel.PrimaryPart or hitModel:FindFirstChildWhichIsA("BasePart")
	if not primary then return false end

	if not FishGen.CanPickup(player, uid) then
		return false
	end

	-- Check if already being grappled by someone else
	local currentGrappler = hitModel:GetAttribute("Grappling")
	if currentGrappler and currentGrappler ~= player.UserId then
		return false -- Already being grappled by another player
	end
	
	-- Mark as grappling
	hitModel:SetAttribute("Grappling", player.UserId)
	-- Tell all clients to visually attach this player's hook to the fish
	Network.FireAll("Grapple_Attach", player.UserId, uid)

	-- Unanchor the entire model so LV can move it
	for _, inst in ipairs(hitModel:GetDescendants()) do
		if inst:IsA("BasePart") then
			(inst :: BasePart).Anchored = false
		end
	end

	-- Clean up any existing LinearVelocity from previous grapples
	for _, child in ipairs(primary:GetChildren()) do
		if child:IsA("LinearVelocity") or child:IsA("Attachment") and child.Name == "GrappleAttachment" then
			child:Destroy()
		end
	end

	local att = Instance.new("Attachment")
	att.Name = "GrappleAttachment"
	att.Parent = primary

	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att
	lv.MaxForce = math.huge
	lv.Parent = primary

	local connection
	connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
		-- Get fresh references to avoid stale position data
		local character = player.Character
		local currentHrp = character and character:FindFirstChild("HumanoidRootPart")
		
		if not player.Parent or not hitModel or not hitModel.Parent or player:GetAttribute("Dead") or not currentHrp then
			for _, inst in ipairs(hitModel:GetDescendants()) do
				if inst:IsA("BasePart") then
					(inst :: BasePart).Anchored = true
				end
			end

			if connection then connection:Disconnect() end
			if lv then lv:Destroy() end
			if att then att:Destroy() end
			if hitModel then hitModel:SetAttribute("Grappling", nil) end
			-- End the visual on all clients
			Network.FireAll("Grapple_End", player.UserId)
			return
		end
		
		-- Verify we still own this grapple (prevent race conditions)
		if hitModel:GetAttribute("Grappling") ~= player.UserId then
			if connection then connection:Disconnect() end
			if lv then lv:Destroy() end
			if att then att:Destroy() end
			-- End the visual on all clients
			Network.FireAll("Grapple_End", player.UserId)
			return
		end
		
		local toPlayer = ((currentHrp :: BasePart).Position - primary.Position)
		local dist = toPlayer.Magnitude
		if dist < 6 then
			-- close enough: make the player carry the fish
			if connection then connection:Disconnect() end
			if lv then lv:Destroy() end
			if att then att:Destroy() end

			hitModel:SetAttribute("Grappling", nil)

			local pickedUp = FishGen.AttemptPickupByUID(player, uid)
			if not pickedUp and hitModel and hitModel.Parent and not hitModel:GetAttribute("Carrying") then
				for _, inst in ipairs(hitModel:GetDescendants()) do
					if inst:IsA("BasePart") then
						(inst :: BasePart).Anchored = true
					end
				end
			end
			-- End the visual on all clients
			Network.FireAll("Grapple_End", player.UserId)
			return
		end
		local dir = toPlayer.Unit
		lv.VectorVelocity = dir * 25
	end)
	return true
end)

-- Client signals a full cycle return (no fish attached): broadcast end to others
Network.Fired("Grapple_Returned", function(player: Player)
	Network.FireAll("Grapple_End", player.UserId)
end)


