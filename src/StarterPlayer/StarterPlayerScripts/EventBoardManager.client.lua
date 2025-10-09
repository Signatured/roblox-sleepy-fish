--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local TagHook = require(ReplicatedStorage.Library.Functions.TagHook)
local FFlags = require(ReplicatedStorage.Library.Client.FFlags)
local Network = require(ReplicatedStorage.Library.Client.Network)
local FormatTime = require(ReplicatedStorage.Library.Functions.FormatTime)
local NotificationCmds = require(ReplicatedStorage.Library.Client.NotificationCmds)
local WorldFX = require(ReplicatedStorage.Library.Client.WorldFX)

local TAG = "RobloxEventBoard"

type BoardData = {
	board: Model,
	main: BasePart,
	billboardGui: BillboardGui?,
	eventGui: SurfaceGui?,
	timerLabel: TextLabel?,
	eventImage: ImageLabel?,
	proximityPrompt: ProximityPrompt?,
	timerConnection: RBXScriptConnection?,
}

local function getAllDescendants(instance: Instance, instanceType: string): { Instance }
	local results = {}
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA(instanceType) then
			table.insert(results, descendant)
		end
	end
	return results
end

local function setVisibility(board: Model, visible: boolean)
	-- Handle all parts
	for _, part in ipairs(board:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = visible and 0 or 1
		elseif part:IsA("Decal") then
			(part :: Decal).Transparency = visible and 0 or 1
		elseif part:IsA("Texture") then
			(part :: Texture).Transparency = visible and 0 or 1
		end
	end

	-- Handle all GUIs
	for _, gui in ipairs(getAllDescendants(board, "BillboardGui")) do
		(gui :: BillboardGui).Enabled = visible
	end
	for _, gui in ipairs(getAllDescendants(board, "SurfaceGui")) do
		(gui :: SurfaceGui).Enabled = visible
	end
end

local function removeAllProximityPrompts(board: Model)
	for _, descendant in ipairs(board:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") then
			descendant:Destroy()
		end
	end
end

local function checkRsvpStatus(eventId: string): boolean
	if eventId == "" then
		return false
	end

	local success, currentRsvpStatus = pcall(function()
		return SocialService:GetEventRsvpStatusAsync(eventId)
	end)

	if not success or currentRsvpStatus == Enum.RsvpStatus.Going then
		return false
	end

	return true
end

local function setupProximityPrompt(data: BoardData)
	-- Remove any existing prompt
	if data.proximityPrompt then
		data.proximityPrompt:Destroy()
		data.proximityPrompt = nil
	end

	local eventId = FFlags.Get(FFlags.Keys.EventBoardEventId) :: string
	local shouldShowPrompt = checkRsvpStatus(eventId)

	if not shouldShowPrompt then
		return
	end

	-- Create new proximity prompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RobloxEventPrompt"
	prompt.ActionText = "Sign Up for Event"
	prompt.ObjectText = ""
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = data.main

	prompt.Triggered:Connect(function()
		local currentEventId = FFlags.Get(FFlags.Keys.EventBoardEventId) :: string
		if currentEventId ~= "" then
			pcall(function()
				SocialService:PromptRsvpToEventAsync(currentEventId)
			end)
			
			-- Wait a bit for the player to respond to the prompt
			task.wait(1)
			
			-- Check if they actually registered
			local success, newStatus = pcall(function()
				return SocialService:GetEventRsvpStatusAsync(currentEventId)
			end)
			
			if success and newStatus == Enum.RsvpStatus.Going then
				-- Remove the prompt after successful registration
				if prompt and prompt.Parent then
					prompt:Destroy()
				end
				if data.proximityPrompt == prompt then
					data.proximityPrompt = nil
				end

                -- Effects
                NotificationCmds.Message("You're now following the event! 🔥")

                WorldFX.Fireworks.FireworkShow(Players.LocalPlayer, 10, 12, 4)
			end
		end
	end)

	data.proximityPrompt = prompt
end

local function updateTimer(data: BoardData)
	if not data.timerLabel then
		return
	end

	local startTime = FFlags.Get(FFlags.Keys.EventBoardStartTime) :: number
	local currentTime = workspace:GetServerTimeNow()
	local timeRemaining = startTime - currentTime

	if timeRemaining <= 0 then
		data.timerLabel.Text = "Any moment now!"
	else
		data.timerLabel.Text = FormatTime(timeRemaining, true)
	end
end

local function setupBoard(board: Instance): () -> ()
	if not board:IsA("Model") then
		return function() end
	end

	local main = board:FindFirstChild("Main") :: BasePart?
	if not main or not main:IsA("BasePart") then
		warn("[EventBoardManager] Board missing Main part")
		return function() end
	end

	local billboardGui = main:FindFirstChild("BillboardGui") :: BillboardGui?
	local eventGui = main:FindFirstChild("EventGui") :: SurfaceGui?
	local timerLabel = billboardGui and billboardGui:FindFirstChild("Timer") :: TextLabel?
	local eventImage = eventGui and eventGui:FindFirstChild("EventImage") :: ImageLabel?

	local data: BoardData = {
		board = board,
		main = main,
		billboardGui = billboardGui,
		eventGui = eventGui,
		timerLabel = timerLabel,
		eventImage = eventImage,
		proximityPrompt = nil,
		timerConnection = nil,
	}

	local function applyFFlags()
		local isVisible = FFlags.Get(FFlags.Keys.EventBoardVisible) :: boolean

		if isVisible then
			-- Show the board
			setVisibility(board, true)

			-- Set event image
			if eventImage then
				local imageId = FFlags.Get(FFlags.Keys.EventBoardImage) :: string
				eventImage.Image = imageId
			end

			-- Setup proximity prompt
			setupProximityPrompt(data)

			-- Start timer updates
			if not data.timerConnection then
				updateTimer(data)
				data.timerConnection = RunService.Heartbeat:Connect(function()
					updateTimer(data)
				end)
			end
		else
			-- Hide the board
			setVisibility(board, false)
			removeAllProximityPrompts(board)

			-- Stop timer updates
			if data.timerConnection then
				data.timerConnection:Disconnect()
				data.timerConnection = nil
			end
		end
	end

	-- Initial setup
	applyFFlags()

	-- Listen for FFlag changes
	Network.Fired("FFlags Changed", function()
		applyFFlags()
	end)

	-- Cleanup function
	return function()
		if data.timerConnection then
			data.timerConnection:Disconnect()
			data.timerConnection = nil
		end

		if data.proximityPrompt then
			data.proximityPrompt:Destroy()
			data.proximityPrompt = nil
		end
	end
end

-- Hook into tagged boards
TagHook(TAG, setupBoard)

