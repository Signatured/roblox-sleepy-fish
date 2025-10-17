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

local module = {}

-- Shared state for this event
local strikeCount = 0
local lastStrikeCheckTime = 0
local lightningCloud: Model? = nil

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
				if cloudTemplate then
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
		
		-- 15% chance of lightning strike
		if math.random() < 0.15 then
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
				
				local success = FishGenerator.AddTrait(targetUID, "Lightning")
				if success then
					strikeCount += 1
					print("[Lightning Server] Strike #" .. strikeCount .. " - Lightning trait applied to fish:", targetUID)
					
					-- Notify all clients about the lightning strike
					AdminAbuseEvents.Fire("Lightning", "Strike", {
						UID = targetUID,
						StrikeCount = strikeCount,
					})
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

