--!strict

-- This module manages giving, taking, and tracking player-owned gadgets.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Framework Modules
local GadgetDirectory = require(ReplicatedStorage.Game.Library.Directory.Gadgets)
local GadgetTypes = require(ReplicatedStorage.Game.Library.Types.Gadgets)
local Saving = require(ServerScriptService.Library.Saving)
local ServerPlot = require(ServerScriptService.Plot.ServerPlot)
local Network = require(ServerScriptService.Library.Network)
local BadgeManager = require(ServerScriptService.Game.Library.BadgeManager)

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

-- Find an existing Tool instance for this schema in the player's Character or Backpack
local function findExistingToolInstance(player: Player, schema: GadgetTypes.dir_schema): Tool?
	local name = schema._id
	local character = player.Character
	if character then
		local toolInChar = character:FindFirstChild(name)
		if toolInChar and toolInChar:IsA("Tool") then
			return toolInChar
		end
	end
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		local toolInBackpack = backpack:FindFirstChild(name)
		if toolInBackpack and toolInBackpack:IsA("Tool") then
			return toolInBackpack
		end
	end
	return nil
end

--// Checks if a player currently has a specific gadget.
function Gadgets.Has(player: Player, id: string | GadgetTypes.dir_schema): boolean
	local schema = getGadgetSchema(id)
	if not schema then return false end
	
	-- Prefer authoritative check: actual instance in Character or Backpack
	local existing = findExistingToolInstance(player, schema)
	if existing then
		-- ensure tracking is synced
		local map = playerGadgets[player.UserId]
		if not map then
			playerGadgets[player.UserId] = {}
			map = playerGadgets[player.UserId]
		end
		map[schema._id] = existing
		return true
	end
	
	-- Clean up stale tracking if it exists without a corresponding instance
	local map = playerGadgets[player.UserId]
	if map and map[schema._id] then
		map[schema._id] = nil
	end
	return false
end

--// Gives a gadget to a player.
function Gadgets.Give(player: Player, id: string | GadgetTypes.dir_schema)
	local schema = getGadgetSchema(id)
	if not schema then
		warn(`[Gadgets] Attempted to give invalid gadget: {tostring(id)}`)
		return
	end
	
	-- If they already have a live instance of the tool, just sync tracking and return
	local existing = findExistingToolInstance(player, schema)
	if existing then
		local map = playerGadgets[player.UserId]
		if not map then
			playerGadgets[player.UserId] = {}
			map = playerGadgets[player.UserId]
		end
		map[schema._id] = existing
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
	newTool.ToolTip = schema.DisplayName
	newTool.Parent = backpack
	
	if schema.Icon and schema.Icon ~= "" then
		newTool.TextureId = schema.Icon
	end
	
	-- Track the given gadget
	if not playerGadgets[player.UserId] then
		playerGadgets[player.UserId] = {}
	end
	playerGadgets[player.UserId][schema._id] = newTool

	task.spawn(function()
		if schema.DisplayName:find("Coil") then
			BadgeManager.GiveBadgeByName(player, "NewCoil")
		end
	end)
	
	print(`[Gadgets] Gave '{schema.DisplayName}' to {player.Name}.`)
end

--// Takes a gadget from a player.
function Gadgets.Take(player: Player, id: string | GadgetTypes.dir_schema): boolean
	local schema = getGadgetSchema(id)
	if not schema then
		warn(`[Gadgets] Attempted to take invalid gadget: {tostring(id)}`)
		return false
	end
	
	-- Ensure tracking reflects the actual current instance
	local map = playerGadgets[player.UserId]
	if not map then return false end
	local toolInstance = map[schema._id]
	
	if not toolInstance then
		-- Try to discover it live
		local discovered = findExistingToolInstance(player, schema)
		if discovered then
			toolInstance = discovered :: Tool
		end
	end
	
	if toolInstance then
		toolInstance:Destroy()
		map[schema._id] = nil
		print(`[Gadgets] Took '{schema.DisplayName}' from {player.Name}.`)
		return true
	end
	return false
end

--// This function is called when a player's character spawns.
--// It gives them all the gadgets they are supposed to have.
local function onCharacterAdded(character: Model, player: Player)
	task.spawn(function()
		-- Grant owned gadgets from save on spawn (ensure Backpack exists)
		task.wait()
		local save = Saving.Get(player)
		-- Wait for backpack to exist; retry while player is still in game
		local backpack = player:FindFirstChildOfClass("Backpack")
		while player.Parent ~= nil and not backpack do
			task.wait(0.1)
			backpack = player:FindFirstChildOfClass("Backpack")
		end
		if save and save.Tools then
			for id, owned in pairs(save.Tools) do
				if owned == true then
					Gadgets.Give(player, id)
				end
			end
		end

		-- local userGadgets = playerGadgets[player.UserId]
		-- if not userGadgets then return end

		-- -- Use a task.wait() to ensure the Backpack has been created.
		-- task.wait()
		-- local backpack = player:FindFirstChildOfClass("Backpack")
		-- if not backpack then return end
		
		-- for gadgetName, _ in pairs(userGadgets) do
		-- 	local schema = getGadgetSchema(gadgetName)
		-- 	if schema then
		-- 		local toolTemplate = schema._script:FindFirstChild("Tool")
		-- 		if toolTemplate and toolTemplate:IsA("Tool") then
		-- 			-- Check if the player already has this tool in their backpack or character by its unique name
		-- 			if not backpack:FindFirstChild(gadgetName) and not character:FindFirstChild(gadgetName) then
		-- 				Gadgets.Give(player, gadgetName)
		-- 			end
		-- 		end
		-- 	end
		-- end
	end)
end

function Gadgets.GiveAndInventory(player: Player, id: string | GadgetTypes.dir_schema)
	local schema = getGadgetSchema(id)
    if not schema then
        warn("[Gadgets] Invalid gadget id provided to Buy")
        return false
    end

    local save = Saving.Get(player)
    if not save then return false end

    local plot = ServerPlot.GetByPlayer(player)
    if not plot then
        warn("[Gadgets] No plot found for", player.Name)
        return false
    end

    -- Already owned in save?
    if save.Tools[schema._id] then
        return false
    end

    -- Mark owned, and give the gadget
    save.Tools[schema._id] = true
    Gadgets.Give(player, schema)

    return true
end

--// Attempts to buy a gadget for the player. Returns true if purchased.
function Gadgets.Buy(player: Player, id: string | GadgetTypes.dir_schema): boolean
    local schema = getGadgetSchema(id)
    if not schema then
        warn("[Gadgets] Invalid gadget id provided to Buy")
        return false
    end

    local save = Saving.Get(player)
    if not save then return false end

    local plot = ServerPlot.GetByPlayer(player)
    if not plot then
        warn("[Gadgets] No plot found for", player.Name)
        return false
    end

    -- Already owned in save?
    if save.Tools[schema._id] then
        return false
    end

    local cost = schema.Cost or 0
    if not plot:CanAfford(cost) then
        return false
    end

    -- Deduct, mark owned, and give the gadget
    plot:AddMoney(-cost)
    save.Tools[schema._id] = true
    Gadgets.Give(player, schema)

    return true
end

--// Attempts to sell a gadget back. Returns true if sold and refunded.
function Gadgets.Sell(player: Player, id: string | GadgetTypes.dir_schema): boolean
    local schema = getGadgetSchema(id)
    if not schema then
        warn("[Gadgets] Invalid gadget id provided to Sell")
        return false
    end

    local save = Saving.Get(player)
    if not save then return false end

    local plot = ServerPlot.GetByPlayer(player)
    if not plot then
        warn("[Gadgets] No plot found for", player.Name)
        return false
    end

    if not save.Tools[schema._id] then
        return false
    end

    -- Remove ownership, take the tool, and refund half cost
    save.Tools[schema._id] = nil
    Gadgets.Take(player, schema)

    local refund = math.floor((schema.Cost or 0) * 0.5)
    if refund > 0 then
        plot:AddMoney(refund)
    end

    return true
end

--// This function is called when a player joins the game.
local function onPlayerAdded(player: Player)
	if not Saving.Get(player) then return end

	-- Initialize the gadget table for the player
	if not playerGadgets[player.UserId] then
		playerGadgets[player.UserId] = {}
	end

	-- Grant owned gadgets from save on join
	task.spawn(function()
		-- Ensure a short delay for Backpack creation
		task.wait()
		local save = Saving.Get(player)
		if save and save.Tools then
			for id, owned in pairs(save.Tools) do
				if owned == true then
					Gadgets.Give(player, id)
				end
			end
		end
	end)

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

Network.Invoked("BuyTool", function(player: Player, id: string)
	local success = Gadgets.Buy(player, id)
	return success
end)

Network.Invoked("SellTool", function(player: Player, id: string)
	local success = Gadgets.Sell(player, id)
	return success
end)

return Gadgets