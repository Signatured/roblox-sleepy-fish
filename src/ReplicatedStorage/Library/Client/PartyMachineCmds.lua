--!strict

--[[
	Client-side PartyMachine commands.
	Handles UI interaction and communication with the server for Party Machine.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Directory = require(ReplicatedStorage.Game.Library.Directory)
local Network = require(ReplicatedStorage.Library.Client.Network)
local NotificationCmds = require(ReplicatedStorage.Library.Client.NotificationCmds)
local Message = require(ReplicatedStorage.Library.Client.Message)
local Save = require(ReplicatedStorage.Library.Client.Save)
local FFlags = require(ReplicatedStorage.Library.Client.FFlags)

local PartyMachineCmds = {}

-- Module state
local currentPoints = 0
local isEventActive = false
local pointGoal = 1000

-- Update state from server
local function updateState()
	local state = Network.Invoke("PartyMachine_GetState")
	if state then
		currentPoints = state.Points
		isEventActive = state.IsEventActive
		pointGoal = state.PointGoal
	end
end

-- Initialize by fetching current state
task.spawn(updateState)

-- Listen for server updates
Network.Fired("PartyMachine_PointsUpdated", function(newPoints: number)
	currentPoints = newPoints
end)

Network.Fired("PartyMachine_EventStarted", function()
	isEventActive = true
	NotificationCmds.Message("The party has started! 🎉", {
		Color = Color3.fromRGB(255, 200, 0),
		Time = 5
	})
end)

Network.Fired("PartyMachine_EventEnded", function()
	isEventActive = false
	currentPoints = 0
	NotificationCmds.Message("The party has ended!", {
		Color = Color3.fromRGB(255, 150, 0),
		Time = 5
	})
end)

-- Get rarity priority (higher = rarer)
local function getRarityPriority(rarityId: string): number
	local raritySchema = Directory.Rarity[rarityId]
	if raritySchema then
		return raritySchema.Priority
	end
	return 0
end

-- Submit fish for points
function PartyMachineCmds.SubmitPoints(fishUids: {string})
	if #fishUids == 0 then
		NotificationCmds.Message("No fish selected!", {
			Color = Color3.fromRGB(255, 0, 0)
		})
		return
	end
	
	-- Check for Mythical or higher rarity fish and confirm with player
	local needsConfirmation = false
	local highestRarityId = nil
	local highestPriority = -1
	local highestPoints = 0
	
	-- We need to check the player's save to get fish data
	local saveData = Save.Get()
	
	if saveData and saveData.Inventory then
		for _, uid in ipairs(fishUids) do
			-- Find the fish in inventory
			for _, fishData in ipairs(saveData.Inventory) do
				if fishData.UID == uid then
					local fishSchema = Directory.Fish[fishData.FishId]
					if fishSchema then
						local rarityId = fishSchema.Rarity._id
						local priority = getRarityPriority(rarityId)
						
						-- Check if this is Mythical or higher (priority >= 6)
						-- Mythical, God, Secret are typically priority 6+
						if priority >= 6 then
							needsConfirmation = true
							if priority > highestPriority then
								highestPriority = priority
								highestRarityId = rarityId
								
								-- Calculate points for this rarity
								local flagKey = `PartyPoints_{rarityId}`
								if FFlags.Keys[flagKey] then
									local points = FFlags.Get(FFlags.Keys[flagKey])
									if typeof(points) == "number" then
										highestPoints = points
									end
								end
							end
						end
					end
					break
				end
			end
		end
	end
	
	-- If needs confirmation, show message dialog
	if needsConfirmation and highestRarityId then
		local confirmed = Message.new(
			`You're giving a {highestRarityId} for {highestPoints} Party Points, are you sure?`,
			true
		)
		
		if not confirmed then
			return -- Player said no
		end
	end
	
	-- Invoke server to submit points
	local success, errorMessage, pointsAdded = Network.Invoke("PartyMachine_SubmitPoints", fishUids)
	
	if not success then
		if errorMessage then
			NotificationCmds.Message(errorMessage, {
				Color = Color3.fromRGB(255, 0, 0)
			})
		end
	else
		if pointsAdded then
			NotificationCmds.Message(`You added {pointsAdded} points to the party machine!`, {
				Color = Color3.fromRGB(0, 255, 0)
			})
		end
	end
end

-- Get current points
function PartyMachineCmds.GetCurrentPoints(): number
	return currentPoints
end

-- Check if event is active
function PartyMachineCmds.IsEventActive(): boolean
	return isEventActive
end

-- Get point goal
function PartyMachineCmds.GetPointGoal(): number
	return pointGoal
end

return PartyMachineCmds

