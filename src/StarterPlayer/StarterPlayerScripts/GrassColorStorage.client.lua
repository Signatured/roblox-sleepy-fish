--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TagHook = require(ReplicatedStorage.Library.Functions.TagHook)

local TAG = "Grass"

TagHook(TAG, function(instance: Instance)
	if not instance:IsA("BasePart") then
		return function() end
	end

	local part = instance :: BasePart
	
	-- Store the original color as an attribute
	part:SetAttribute("OriginalColor", part.Color)

	-- Return cleanup function (optional, but good practice)
	return function()
		-- Cleanup if needed when tag is removed
	end
end)


