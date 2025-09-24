--!strict

local MarketplaceService = game:GetService("MarketplaceService")

local Network = require(game.ServerScriptService.Library.Network)
local AdminPanelDirectory = require(game.ReplicatedStorage.Game.Library.Directory.AdminPanel)
local AdminPanelTypes = require(game.ReplicatedStorage.Game.Library.Types.AdminPanel)
local Products = require(game.ServerScriptService.Library.Products)
local ProductDirectory = require(game.ReplicatedStorage.Game.Library.Directory.Products)

local AdminPanel = {}

-- Developer product ID for admin permissions (you'll need to set this to your actual product ID)

local ADMIN_PRODUCT_ID = ProductDirectory["Admin Panel"].ProductId

-- Cooldown tracking
local playerCooldowns: {[Player]: {[string]: number}} = {}

-- Valid admin ranks
local ADMIN_RANKS = {
	["Admin"] = true,
	["Developer"] = true,
	["Owner"] = true,
}

--[[
	Checks if a player has admin permissions
	@param player The player to check
	@return boolean Whether the player has admin permissions
]]
local function HasAdminPermission(player: Player): boolean
	-- Check rank attribute
	local rank = player:GetAttribute("Rank")
	if rank and ADMIN_RANKS[rank] then
		return true
	end
	
	-- Check developer product ownership (if product ID is set)
	local owns = Products.Owns(player, ADMIN_PRODUCT_ID)
	if owns then
		return true
	end
	
	return false
end

--[[
	Checks if a player is on cooldown for a specific command
	@param player The player to check
	@param commandName The command to check cooldown for
	@return boolean Whether the player is on cooldown
]]
local function IsOnCooldown(player: Player, commandName: string): boolean
	local playerCooldown = playerCooldowns[player]
	if not playerCooldown then
		return false
	end
	
	local cooldownEnd = playerCooldown[commandName]
	if not cooldownEnd then
		return false
	end
	
	return workspace:GetServerTimeNow() < cooldownEnd
end

--[[
	Sets a cooldown for a player and command
	@param player The player to set cooldown for
	@param commandName The command to set cooldown for
	@param duration The cooldown duration in seconds
]]
local function SetCooldown(player: Player, commandName: string, duration: number)
	if not playerCooldowns[player] then
		playerCooldowns[player] = {}
	end
	
	playerCooldowns[player][commandName] = workspace:GetServerTimeNow() + duration
end

--[[
	Executes an admin command
	@param executor The player executing the command
	@param commandName The name of the command to execute
	@param targetPlayer The target player (optional)
]]
function AdminPanel.ExecuteCommand(executor: Player, commandName: string, targetPlayer: Player?)
	-- Check if executor has admin permissions
	if not HasAdminPermission(executor) then
		warn(`Player {executor.Name} attempted to use admin command without permission`)
		return
	end
	
	-- Get command from directory
	local command: AdminPanelTypes.AdminCommand? = AdminPanelDirectory[commandName]
	if not command then
		warn(`Command '{commandName}' not found`)
		return
	end
	
	-- Check if command can target players and if target is provided when needed
	if command.CanTarget and not targetPlayer then
		warn(`Command '{commandName}' requires a target player`)
		return
	end
	
	-- Check cooldown
	if IsOnCooldown(executor, commandName) then
		return
	end
	
	-- Execute the command
	local success, result = command.OnExecute(executor, targetPlayer)
	
	-- Check if command execution was successful
	if not success then
		-- Command failed, result should be an error message
		local errorMessage = result or "Command execution failed"
		warn(`Command '{commandName}' failed for {executor.Name}: {errorMessage}`)
		return
	end
	
	-- Command succeeded, set cooldown
	SetCooldown(executor, commandName, command.Cooldown)
	
	-- Handle finish function execution based on Duration
	if result and type(result) == "function" then
		local onFinish = result :: () -> ()
		local duration = command.Duration
		if duration and duration > 0 then
			-- Delay the finish function execution in a separate thread
			task.spawn(function()
				task.wait(duration)
				onFinish()
			end)
		else
			-- Call immediately if no duration or duration is 0
			onFinish()
		end
	end
end

-- Clean up cooldowns when players leave
game.Players.PlayerRemoving:Connect(function(player)
	playerCooldowns[player] = nil
end)

-- Network event handler for admin commands
Network.Fired("AdminPanel_ExecuteCommand", function(player: Player, commandName: string, targetPlayer: Player?)
	AdminPanel.ExecuteCommand(player, commandName, targetPlayer)
end)

return AdminPanel
