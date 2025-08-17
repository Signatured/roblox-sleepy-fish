--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GadgetDirectory = require(ReplicatedStorage.Game.Library.Directory.Gadgets)
local GadgetTypes = require(ReplicatedStorage.Game.Library.Types.Gadgets)

local module = {}

local function getGadgetSchema(id: string | GadgetTypes.dir_schema): GadgetTypes.dir_schema?
	if typeof(id) == "table" then
		return id
	end
	return GadgetDirectory[id]
end

-- Returns true if the local player currently owns (has in Backpack or Character) the gadget.
function module.Has(id: string | GadgetTypes.dir_schema): boolean
	local schema = getGadgetSchema(id)
	if not schema then return false end

	local player = Players.LocalPlayer
	if not player then return false end

	local name = schema._id

	local character = player.Character
	if character and character:FindFirstChild(name) then
		return true
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack and backpack:FindFirstChild(name) then
		return true
	end

	return false
end

return module


