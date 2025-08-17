--!strict

-- This module manages giving, taking, and tracking player-owned gadgets.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Framework Modules
local GadgetDirectory = require(ReplicatedStorage.Game.Library.Directory.Gadgets)
local GadgetTypes = require(ReplicatedStorage.Game.Library.Types.Gadgets)
local Saving = require(ServerScriptService.Library.Saving)

local Gadgets = {}

-- {[UserId]: {[GadgetName]: Tool}}
local playerGadgets: {[number]: {[string]: Tool}} = {}

--// Helper to get a gadget's schema by its ID string or the schema itself.
local function getGadgetSchema(id: string | GadgetTypes.dir_schema): GadgetTypes.dir_schema?
	if typeof(id) == "table" then
		return id
	end
	return GadgetDirectory[id]
end

--// Checks if a player currently has a specific gadget.
function Gadgets.Has(player: Player, id: string | GadgetTypes.dir_schema): boolean
	local schema = getGadgetSchema(id)
	if not schema then return false end
	
	local userGadgets = playerGadgets[player.UserId]
	return not not (userGadgets and userGadgets[schema._id])
end

--// Gives a gadget to a player.
function Gadgets.Give(player: Player, id: string | GadgetTypes.dir_schema)
	local schema = getGadgetSchema(id)
	if not schema then
		warn(`[Gadgets] Attempted to give invalid gadget: {tostring(id)}`)
		return
	end
	
	if Gadgets.Has(player, schema) then
		warn(`[Gadgets] Player {player.Name} already has gadget '{schema.DisplayName}'.`)
		return
	end
	
	local tool = schema._script:FindFirstChild("Tool")
	if not tool or not tool:IsA("Tool") then
		warn(`[Gadgets] Could not find a valid Tool instance for gadget '{schema.DisplayName}'.`)
		return
	end
	
	local backpack = player:FindFirstChildOfClass("Backpack")
	
	if not backpack then
		warn(`[Gadgets] Could not find backpack for player {player.Name}.`)
		return
	end
	
	local newTool = tool:Clone()
	newTool.Name = schema._id
	newTool.Parent = backpack
	
	if schema.Icon and schema.Icon ~= "" then
		newTool.TextureId = schema.Icon
	end
	
	-- Track the given gadget
	if not playerGadgets[player.UserId] then
		playerGadgets[player.UserId] = {}
	end
	playerGadgets[player.UserId][schema._id] = newTool
	
	print(`[Gadgets] Gave '{schema.DisplayName}' to {player.Name}.`)
end

--// Takes a gadget from a player.
function Gadgets.Take(player: Player, id: string | GadgetTypes.dir_schema)
	local schema = getGadgetSchema(id)
	if not schema then
		warn(`[Gadgets] Attempted to take invalid gadget: {tostring(id)}`)
		return
	end
	
	if not Gadgets.Has(player, schema) then return end
	
	local userGadgets = playerGadgets[player.UserId]
	local toolInstance = userGadgets[schema._id]
	
	if toolInstance then
		toolInstance:Destroy()
		userGadgets[schema._id] = nil
		print(`[Gadgets] Took '{schema.DisplayName}' from {player.Name}.`)
	end
end

--// This function is called when a player's character spawns.
--// It gives them all the gadgets they are supposed to have.
local function onCharacterAdded(character: Model, player: Player)
	task.spawn(function()
		local userGadgets = playerGadgets[player.UserId]
		if not userGadgets then return end

		-- Use a task.wait() to ensure the Backpack has been created.
		task.wait()
		local backpack = player:FindFirstChildOfClass("Backpack")
		if not backpack then return end
		
		for gadgetName, _ in pairs(userGadgets) do
			local schema = getGadgetSchema(gadgetName)
			if schema then
				local toolTemplate = schema._script:FindFirstChild("Tool")
				if toolTemplate and toolTemplate:IsA("Tool") then
					-- Check if the player already has this tool in their backpack or character by its unique name
					if not backpack:FindFirstChild(gadgetName) and not character:FindFirstChild(gadgetName) then
						local newTool = toolTemplate:Clone()
						newTool.Name = gadgetName
						newTool.Parent = backpack
					end
				end
			end
		end
	end)
end

--// This function is called when a player joins the game.
local function onPlayerAdded(player: Player)
	-- Initialize the gadget table for the player
	if not playerGadgets[player.UserId] then
		playerGadgets[player.UserId] = {}
	end

	-- If the character already exists, grant the gadgets
	if player.Character then
		onCharacterAdded(player.Character, player)
	end
	
	-- Listen for when the character respawns
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(character, player)
	end)
end

--// Set up the listener for all current and future players.
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
Saving.SaveAdded:Connect(onPlayerAdded)

--// Cleans up a player's gadget data when they leave.
Players.PlayerRemoving:Connect(function(player)
	playerGadgets[player.UserId] = nil
end)

return Gadgets 