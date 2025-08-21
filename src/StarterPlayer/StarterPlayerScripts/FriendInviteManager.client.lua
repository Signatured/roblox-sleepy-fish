--!strict

-- This script manages the friend invite feature, periodically prompting the player
-- to invite one of their online friends to the game.

local Players = game:GetService("Players")
local SocialService = game:GetService("SocialService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Framework Modules
local Library = ReplicatedStorage:WaitForChild("Library")
local GUI = require(game.ReplicatedStorage.Game.Library.Client.GUI)
local ButtonFX = require(Library.Client.GUIFX.ButtonFX)
local Network = require(Library.Client.Network)
local Save = require(Library.Client.Save)

-- to track button connections
local buttonConnections = {}

-- Stores a set of friend UserIds for whom an invite has already been shown in this session.
-- This prevents spamming the same friend repeatedly.

-- Constants
local BASE_INTERVAL = 60 * 15 -- 15 minutes
local EXTENSION_INTERVAL = 30 -- 30 seconds

-- Type Definition
type FriendOnlineInfo = {
    DisplayName: string,
	Username: string,
	Id: number,
	IsOnline: boolean,
}

-- State
local localPlayer = Players.LocalPlayer
local friendInviteGui: ScreenGui
local timer = 10 -- Start with a 60-second timer for the first prompt

local function canSendGameInvite(sendingPlayer, invitingUserId)
	local success, canSend = pcall(function()
		return SocialService:CanSendGameInviteAsync(sendingPlayer, invitingUserId)
	end)
	return success and canSend
end

---
-- Gets a list of a player's friends who are currently online.
-- @return A table of online friends, or nil if an error occurred.
---
local function getOnlineFriends(): {FriendOnlineInfo}?
	local success, result = pcall(function()
		return Players:GetFriendsAsync(localPlayer.UserId)
	end)

	if not success then
		warn(`[FriendInvite] Failed to get online friends: {result}`)
		return nil
	end

	local onlineFriends: {FriendOnlineInfo} = {}
    local limit = 10
    local counter = 1
	while true do
		for _, friendInfo in ipairs(result:GetCurrentPage()) do
  			table.insert(onlineFriends, friendInfo)
		end

		if result.IsFinished then
			break
		end

        if counter >= limit then
            break
        end

        counter += 1

		result:AdvanceToNextPageAsync()
	end
	
	return onlineFriends
end

---
-- Hides the FriendInvite GUI.
---
local function closeGui()
	if friendInviteGui then
		friendInviteGui.Enabled = false
	end
end

---
-- Selects a random online friend and shows the invite prompt.
---
local function showRandomFriendInvite()
	local onlineFriends = getOnlineFriends()
	
	if not onlineFriends or #onlineFriends == 0 then
		return
	end
	
	local randomFriend = onlineFriends[math.random(#onlineFriends)]

    if not canSendGameInvite(localPlayer, randomFriend.Id) then
        return
    end

	-- Get the GUI components using new structure
	friendInviteGui = GUI.FriendInvite()
	if not friendInviteGui then return end

	local rootFrame = friendInviteGui:FindFirstChild("Frame")
	if not rootFrame or not rootFrame:IsA("Frame") then return end

	local closeButton = rootFrame:FindFirstChild("Close")
	local mainImage = rootFrame:FindFirstChild("Main")
	local innerFrame = mainImage and mainImage:FindFirstChild("Frame")
	local inviteButton = innerFrame and innerFrame:FindFirstChild("Button")
	local inviteLabel = inviteButton and inviteButton:FindFirstChild("Label")
	local profileBox = mainImage and mainImage:FindFirstChild("ProfileBox")
	local profileIcon = profileBox and profileBox:FindFirstChild("PlayerIcon")
	local onlineLabel = mainImage and mainImage:FindFirstChild("OnlineLabel")

	if not (closeButton and closeButton:IsA("GuiButton")
		and inviteButton and inviteButton:IsA("GuiButton")
		and profileIcon and profileIcon:IsA("ImageLabel")
		and onlineLabel and onlineLabel:IsA("TextLabel")) then
		warn("[FriendInvite] FriendInvite UI missing or wrong types; check structure.")
		return
	end
	
	-- Update GUI with friend's info
	local success, thumb = pcall(function()
		return Players:GetUserThumbnailAsync(randomFriend.Id, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end)
	
	if success then
		(profileIcon :: ImageLabel).Image = thumb
	end
	(onlineLabel :: TextLabel).Text = `{randomFriend.DisplayName} is online! Invite for $1,000`
	if inviteLabel and inviteLabel:IsA("TextLabel") then
		inviteLabel.Text = "Invite"
	end
	
	-- Apply button effects and connect handlers
	ButtonFX(inviteButton :: GuiButton)
	ButtonFX(closeButton :: GuiButton)
	
	if buttonConnections[inviteButton] then
		buttonConnections[inviteButton]:Disconnect()
	end
	
	buttonConnections[inviteButton] = (inviteButton :: GuiButton).Activated:Connect(function()
		local success, canInvite = pcall(SocialService.CanSendGameInviteAsync, SocialService, localPlayer, randomFriend.Id)
		if success and canInvite then
			local inviteSuccess, _ = pcall(SocialService.PromptGameInvite, SocialService, localPlayer)
			if inviteSuccess then
				closeGui()
				Network.Fire("PlayerInvitedFriend", randomFriend.Id)
			else
				warn(`[FriendInvite] Failed to send game invite to {randomFriend.DisplayName}.`)
			end
		end
	end)

	if buttonConnections[closeButton] then
		buttonConnections[closeButton]:Disconnect()
	end
	
	buttonConnections[closeButton] = (closeButton :: GuiButton).Activated:Connect(closeGui)
	
	-- Show the GUI
	friendInviteGui.Enabled = true
end

-- Main timer loop
RunService.Heartbeat:Connect(function(deltaTime)
	timer -= deltaTime
	
	if timer <= 0 then
		-- Reset timer to the base interval
		timer = BASE_INTERVAL
		
		-- If the GUI is already open, add extension time and skip this cycle
		if friendInviteGui and friendInviteGui.Enabled then
			timer += EXTENSION_INTERVAL
			return
		end

		local save = Save.Get()
		if save and not save.FinishedTutorial then
			timer += EXTENSION_INTERVAL
			return
		end
		
		showRandomFriendInvite()
	end
end)