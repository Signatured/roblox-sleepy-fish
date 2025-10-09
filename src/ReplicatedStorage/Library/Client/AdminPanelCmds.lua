--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Library = ReplicatedStorage:WaitForChild("Library")
local Network = require(Library.Client.Network)
local FFlags = require(game.ReplicatedStorage.Library.Client.FFlags)
local ProductCmds = require(ReplicatedStorage.Library.Client.ProductCmds)

local AdminPanelCmds = {}

local LocalPlayer = Players.LocalPlayer

-- Valid admin ranks
local ADMIN_RANKS = {
	["Admin"] = true,
	["Developer"] = true,
	["Owner"] = true,
}

--[[
	Checks if the local player has admin permissions
	@return boolean Whether the local player has admin permissions
]]
local function HasAdminPermission(): boolean
	-- Check rank attribute
	local rank = LocalPlayer:GetAttribute("Rank")
	if rank and ADMIN_RANKS[rank] then
		return true
	end

	-- Free admin via FFlag
	local ok, free = pcall(function()
		return FFlags.Get(FFlags.Keys.FreeAdminPanel)
	end)
	if ok and free == true then
		return true
	end
	
	-- Check developer product ownership (if product ID is set)
	if ProductCmds.Owns("Admin Panel") then
		return true
	end
	
	return false
end

--[[
	Executes an admin command on the server
	@param commandName The name of the command to execute
	@param targetPlayer The target player (optional)
	@param isGlobal Whether this is a global command (optional)
]]
function AdminPanelCmds.ExecuteCommand(commandName: string, targetPlayer: Player?, isGlobal: boolean?)
	-- Check if local player has admin permissions
	if not HasAdminPermission() then
		-- Silently fail - don't give feedback to non-admins
		return
	end
	
	-- Send command to server with global flag
	Network.Fire("AdminPanel_ExecuteCommand", commandName, targetPlayer, isGlobal or false)
end

return AdminPanelCmds
