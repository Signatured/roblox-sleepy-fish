--!strict

--[[
	Client-side manager for the "Favorite Game" prompt.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AvatarEditorService = game:GetService("AvatarEditorService")

-- Framework Modules
local Library = ReplicatedStorage:WaitForChild("Library")
local Network = require(Library.Client.Network)

Network.Fired("PromptFavorite", function(delayInSeconds: number)
	task.wait(delayInSeconds)
	
    AvatarEditorService:PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true)
end)