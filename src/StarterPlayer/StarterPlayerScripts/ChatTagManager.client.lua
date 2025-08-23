--!strict

--[[
	Client-side manager for applying chat prefixes and random name colors.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")

local Library = ReplicatedStorage:WaitForChild("Library")

local ADMIN_PREFIX = "[🔧 OWNER] "
local PRIVILEGED_ROLES = { "Developer", "Admin", "Owner" }

-- A list of vibrant colors for player names
local NAME_COLORS = {
	Color3.fromRGB(255, 85, 85),   -- Red
	Color3.fromRGB(85, 170, 255),  -- Blue
	Color3.fromRGB(85, 255, 127),  -- Green
	Color3.fromRGB(255, 170, 0),   -- Orange
	Color3.fromRGB(255, 85, 255),  -- Magenta
	Color3.fromRGB(255, 255, 85),  -- Yellow
}

--// Gets a consistent color for a player based on their UserId
local function getPlayerColor(userId: number): Color3
	return NAME_COLORS[(userId % #NAME_COLORS) + 1]
end

--// Callback to modify chat messages
TextChatService.OnIncomingMessage = function(message: TextChatMessage): TextChatMessageProperties?
	local textSource = message.TextSource
	if not textSource then return nil end

	local player = Players:GetPlayerByUserId(textSource.UserId)
	if not player then return nil end

	local properties = Instance.new("TextChatMessageProperties")
	
	local playerRank = player:GetAttribute("Rank")
	
	local prefixTag = ""
	local nameColor: Color3
	
	-- Determine colors and tags based on player status
	if playerRank and table.find(PRIVILEGED_ROLES, playerRank) then
		nameColor = Color3.fromRGB(255, 85, 85) -- Red for name
		prefixTag = ("<font color='#960000'>%s</font>"):format(ADMIN_PREFIX) -- Dark Red for tag
    else
		nameColor = getPlayerColor(textSource.UserId)
	end
	
	-- Create the colored name tag, including the colon from the original behavior
	local playerNameWithColon = player.DisplayName .. ":"
	local coloredName = ("<font color='#%s'>%s</font>"):format(nameColor:ToHex(), playerNameWithColon)
	
	-- Construct the final prefix
	if prefixTag ~= "" then
		properties.PrefixText = prefixTag .. " " .. coloredName
	else
		properties.PrefixText = coloredName
	end
	
	return properties
end