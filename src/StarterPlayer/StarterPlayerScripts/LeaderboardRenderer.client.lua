--!strict

-- This client script uses CollectionService to find all leaderboard objects
-- and renders the player rankings based on data from the LeaderboardCmds library.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Framework Modules
local Library = ReplicatedStorage:WaitForChild("Library")
local Functions = require(Library.Functions)
local LeaderboardCmds = require(ReplicatedStorage.Game.Library.Client.LeaderboardCmds)
local LeaderboardDirectory = require(ReplicatedStorage.Game.Library.Directory.Leaderboards)
local Network = require(Library.Client.Network)

local TAG = "Leaderboard"
local localPlayer = Players.LocalPlayer

-- {[leaderboardInstance]: {templateName: GuiObject}}
local templateCache = {}

--// Clears all old player entries from the leaderboard UI.
local function clearLeaderboard(scrollingFrame: ScrollingFrame)
	for _, child in ipairs(scrollingFrame:GetChildren()) do
		-- A player entry's name is its UserId. If the name is a number, destroy it.
		if tonumber(child.Name) then
			child:Destroy()
		end
	end
end

--// Updates the "Your Stats" portion of the leaderboard.
local function updateYourStats(leaderboardPart: BasePart, leaderboardId: string)
	local surfaceGui = leaderboardPart:FindFirstChildOfClass("SurfaceGui")
	if not surfaceGui then return end
	
	local frame = surfaceGui:FindFirstChild("Frame")
	if not frame or not frame:IsA("Frame") then return end
	
	local bottomFrame = frame:FindFirstChild("Bottom")
	if not bottomFrame or not bottomFrame:IsA("Frame") then return end

	local yourStatsFrame = bottomFrame:FindFirstChild("YourStats")
	if not yourStatsFrame or not yourStatsFrame:IsA("Frame") then return end

	-- Asynchronously get the player's rank and score from the server
	task.spawn(function()
		local rank, score = Network.Invoke("GetPlayerRank", leaderboardId)
		
		-- Check if the UI elements still exist before updating them
		if not yourStatsFrame or not yourStatsFrame.Parent then return end
		
		local holder = yourStatsFrame:FindFirstChild("Holder")
		if not holder or not holder:IsA("Frame") then return end
		
		local numberLabel = holder:FindFirstChild("Number")
		if numberLabel and numberLabel:IsA("TextLabel") then
			numberLabel.Text = rank and "#" .. rank or "N/A"
		end
		
		local nameLabel = holder:FindFirstChild("PlayerName")
		if nameLabel and nameLabel:IsA("TextLabel") then
			nameLabel.Text = "@" .. localPlayer.Name
		end
		
		local descLabel = holder:FindFirstChild("Desc")
		if descLabel and descLabel:IsA("TextLabel") then
			descLabel.Text = score and Functions.NumberShorten(score) or "???"
		end
	end)
end


--// Updates a single leaderboard's UI with new data.
local function updateLeaderboardDisplay(leaderboardPart: BasePart, data: {[number]: number}, leaderboardSchema: any)
	local surfaceGui = leaderboardPart:FindFirstChildOfClass("SurfaceGui")
	if not surfaceGui then return end
	
	local frame = surfaceGui:FindFirstChild("Frame")
	if not frame or not frame:IsA("Frame") then return end
	
	local scrollingFrame = frame:FindFirstChild("ScrollingFrame")
	if not scrollingFrame or not scrollingFrame:IsA("ScrollingFrame") then return end
	
	-- Get UI templates from the cache
	local templates = templateCache[leaderboardPart]
	if not templates then
		warn(`[LeaderboardRenderer] No templates cached for leaderboard part '{leaderboardPart:GetFullName()}'.`)
		return
	end
	
	-- Clear old entries before rendering new ones
	clearLeaderboard(scrollingFrame)
	
	-- Create a sorted array from the data dictionary
	local sortedData = {}
	for userId, score in pairs(data) do
		table.insert(sortedData, {userId = userId, score = score})
	end
	table.sort(sortedData, function(a, b) return a.score > b.score end)
	
	-- Render new entries
	for i, entry in ipairs(sortedData) do
		local userId = entry.userId
		local score = entry.score
		
		local template
		local isTopThree = false
		if i == 1 then
			template = templates.FirstPlace
			isTopThree = true
		elseif i == 2 then
			template = templates.SecondPlace
			isTopThree = true
		elseif i == 3 then
			template = templates.ThirdPlace
			isTopThree = true
		else
			template = templates.OtherPlace
		end
		
		local newEntry = template:Clone()
		if not newEntry:IsA("GuiObject") then continue end
		
		newEntry.Name = tostring(userId)
		newEntry.Visible = true
		
		local placeText = newEntry:FindFirstChild("PlaceText")
		if placeText and placeText:IsA("TextLabel") then
			placeText.Text = "#" .. i
		end

		local nameLabel = newEntry:FindFirstChild("PlayerName")
		if nameLabel and nameLabel:IsA("TextLabel") then
			nameLabel.Text = "@???"
			task.spawn(function()
				local playerName = Functions.GetNameFromUserIdAsync(userId)
				if playerName and nameLabel and nameLabel.Parent then
					nameLabel.Text = "@" .. playerName
				end
			end)
		end

		local amountLabel = newEntry:FindFirstChild("Amount")
		if amountLabel and amountLabel:IsA("TextLabel") then
			local scoreText = Functions.NumberShorten(score)
			if isTopThree and leaderboardSchema.ScoreType then
				amountLabel.Text = scoreText .. " " .. (leaderboardSchema.ScoreType :: string)
			else
				amountLabel.Text = scoreText
			end
		end

		if isTopThree then
			local playerImage = newEntry:FindFirstChild("Player")
			if playerImage and playerImage:IsA("ImageLabel") then
				playerImage.Image = ""
				task.spawn(function()
					local imageUrl = Functions.GetAvatarFromUserIdAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
					if imageUrl and playerImage and playerImage.Parent then
						playerImage.Image = imageUrl
					end
				end)
			end
		end
		
		newEntry.LayoutOrder = i
		newEntry.Parent = scrollingFrame
	end
	
	-- Update the canvas size to fit the newly rendered content.
	task.delay(0.1, function()
		Functions.UpdateCanvasSize(scrollingFrame)
	end)
end

--// Sets up a new leaderboard instance when it's tagged.
local function setupLeaderboard(leaderboardPart: BasePart)
	local leaderboardId = leaderboardPart:GetAttribute("Id")
	if not leaderboardId then
		warn(`[LeaderboardRenderer] Leaderboard part '{leaderboardPart:GetFullName()}' is missing string attribute 'Id'.`)
		return
	end
	
	local surfaceGui = leaderboardPart:FindFirstChildOfClass("SurfaceGui")
	if not surfaceGui then return end
	
	local frame = surfaceGui:FindFirstChild("Frame")
	if not frame or not frame:IsA("Frame") then return end
	
	local scrollingFrame = frame:FindFirstChild("ScrollingFrame")
	if not scrollingFrame then return end
	
	-- Cache the templates from their correct location (all inside the ScrollingFrame) and hide them.
	local firstPlace = scrollingFrame:FindFirstChild("FirstPlace")
	local secondPlace = scrollingFrame:FindFirstChild("SecondPlace")
	local thirdPlace = scrollingFrame:FindFirstChild("ThirdPlace")
	local otherPlace = scrollingFrame:FindFirstChild("OtherPlace")

	if firstPlace and firstPlace:IsA("GuiObject") and 
		secondPlace and secondPlace:IsA("GuiObject") and
		thirdPlace and thirdPlace:IsA("GuiObject") and
		otherPlace and otherPlace:IsA("GuiObject") then
		
		templateCache[leaderboardPart] = {
			FirstPlace = firstPlace,
			SecondPlace = secondPlace,
			ThirdPlace = thirdPlace,
			OtherPlace = otherPlace,
		}
		firstPlace.Visible = false
		secondPlace.Visible = false
		thirdPlace.Visible = false
		otherPlace.Visible = false
	else
		warn(`[LeaderboardRenderer] Could not find all UI templates for '{leaderboardId}'.`)
		return
	end
	
	-- When the data is updated, re-render this leaderboard.
	LeaderboardCmds.LeaderboardUpdated:Connect(function(id, data)
		if id == leaderboardId then
			local leaderboardSchema = LeaderboardDirectory[id]
			if not leaderboardSchema then return end
			
			updateLeaderboardDisplay(leaderboardPart, data, leaderboardSchema)
			updateYourStats(leaderboardPart, id)
		end
	end)
	
	-- Request the latest data from the server for this specific leaderboard.
	Network.Fire("RequestLeaderboardUpdate", leaderboardId)
end


-- Main Setup
-- Find all objects that are already tagged.
for _, part in ipairs(CollectionService:GetTagged(TAG)) do
	if part:IsA("BasePart") then
		task.spawn(setupLeaderboard, part)
	end
end

-- Listen for any new objects that get tagged in the future.
CollectionService:GetInstanceAddedSignal(TAG):Connect(function(part)
	if part:IsA("BasePart") then
		task.spawn(setupLeaderboard, part)
	end
end)
