--!strict

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Library = ReplicatedStorage:WaitForChild("Library")
local Network = require(Library.Client.Network)

local AdminPanelCmds = {}

local LocalPlayer = Players.LocalPlayer

-- Developer product ID for admin permissions (should match server-side)
local ADMIN_PRODUCT_ID = 0 -- Replace with your actual developer product ID

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
	
	-- Check developer product ownership (if product ID is set)
	if ADMIN_PRODUCT_ID > 0 then
		local success, hasProduct = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(LocalPlayer.UserId, ADMIN_PRODUCT_ID)
		end)
		
		if success and hasProduct then
			return true
		end
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
