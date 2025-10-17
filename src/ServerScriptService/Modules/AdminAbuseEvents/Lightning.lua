--!strict

--[[
	Server-side logic for Lightning event.
	Module-level variables are shared across all function calls.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local FishGenerator = require(ServerScriptService.Game.Library.FishGenerator)
local Traits = require(ServerScriptService.Game.Library.Traits)
local AdminAbuseEvents = require(ServerScriptService.Game.Library.AdminAbuseEvents)
local FFlags = require(ServerScriptService.Library.FFlags)

local module = {}

-- Shared state for this event
local strikeCount = 0
local lastStrikeCheckTime = 0
local lightningCloud: BasePart? = nil

function module.OnStart()
	print("[Lightning Server] Event started")
	strikeCount = 0
	lastStrikeCheckTime = 0
	
	-- Find the LightningCloud template
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if assets then
		local adminEvents = assets:FindFirstChild("AdminEvents")
		if adminEvents then
			local lightning = adminEvents:FindFirstChild("Lightning")
			if lightning then
				local cloudTemplate = lightning:FindFirstChild("LightningCloud")
				if cloudTemplate and cloudTemplate:IsA("BasePart") then
					-- Clone the cloud
					local cloned = cloudTemplate:Clone()
					
					-- Move it to workspace/__THINGS/AdminEvents
					local things = workspace:FindFirstChild("__THINGS")
					if not things then
						things = Instance.new("Folder")
						things.Name = "__THINGS"
						things.Parent = workspace
					end
					
					local adminEventsFolder = things:FindFirstChild("AdminEvents")
					if not adminEventsFolder then
						adminEventsFolder = Instance.new("Folder")
						adminEventsFolder.Name = "AdminEvents"
						adminEventsFolder.Parent = things
					end
					
					cloned.Parent = adminEventsFolder
					lightningCloud = cloned
					print("[Lightning Server] LightningCloud spawned in workspace")
				else
					warn("[Lightning Server] LightningCloud not found in template")
				end
			end
		end
	end
end

function module.Heartbeat(delta: number, time: number)
	-- Wait at least 3 seconds before first strike
	if time < 3 then
		return
	end
	
	-- Check every 1 second for potential lightning strike
	local secondsPassed = math.floor(time)
	local lastSecond = math.floor(lastStrikeCheckTime)
	
	if secondsPassed > lastSecond then
		lastStrikeCheckTime = time
		
		-- Check for lightning strike based on FFlag chance
		local lightningChance = FFlags.GetNumber(FFlags.Keys.LightningChance)
		if math.random() < lightningChance then
			-- Get all active fish
			local activeFish = {}
			for uid, fish in pairs(FishGenerator.GetAllActive()) do
				-- Check if fish doesn't have Lightning trait
				if not Traits.HasTrait(fish, "Lightning") then
					table.insert(activeFish, uid)
				end
			end
			
			-- Strike a random fish if any are available
			if #activeFish > 0 then
				local randomIndex = math.random(1, #activeFish)
				local targetUID = activeFish[randomIndex]
				
				-- Get the fish to find its position
				local allFish = FishGenerator.GetAllActive()
				local targetFish = allFish[targetUID]
				
				if targetFish and targetFish.Model and targetFish.Model.PrimaryPart then
					local success = FishGenerator.AddTrait(targetUID, "Lightning")
					if success then
						strikeCount += 1
						
						-- Calculate strike positions
						local fishPosition = targetFish.Model.PrimaryPart.Position
						local endPosition = fishPosition
						local startPosition = Vector3.new(fishPosition.X, fishPosition.Y, fishPosition.Z)
						
						-- Set start Y to lightning cloud's Y position if cloud exists
						if lightningCloud then
							startPosition = Vector3.new(fishPosition.X, lightningCloud.Position.Y, fishPosition.Z)
						else
							-- Default to 200 studs above if no cloud
							startPosition = Vector3.new(fishPosition.X, fishPosition.Y + 200, fishPosition.Z)
						end
						
						-- Notify all clients about the lightning strike
						AdminAbuseEvents.Fire("Lightning", "Strike", {
							UID = targetUID,
							StrikeCount = strikeCount,
							StartPosition = startPosition,
							EndPosition = endPosition,
						})
					end
				end
			end
		end
	end
end

function module.OnStop()
	print("[Lightning Server] Event stopped. Total strikes:", strikeCount)
	
	-- Destroy the lightning cloud
	if lightningCloud then
		local cachedCloud = lightningCloud
		lightningCloud = nil
		for _, child in cachedCloud:GetDescendants() do
			if child:IsA("ParticleEmitter") then
				child.Enabled = false
			end
		end
		task.delay(3, function()
			cachedCloud:Destroy()
		end)
		print("[Lightning Server] LightningCloud destroyed")
	end
	
	-- Reset state
	strikeCount = 0
	lastStrikeCheckTime = 0
end

return module

