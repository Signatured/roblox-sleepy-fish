--!strict

local _MarketplaceService = game:GetService("MarketplaceService")

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

-- Privileged ranks that can use global commands
local PRIVILEGED_RANKS = {
	["Developer"] = true,
	["Owner"] = true,
	["Admin"] = true,
}

--[[
	Checks if a player has admin permissions
	@param player The player to check (can be nil for console)
	@return boolean Whether the player has admin permissions
]]
local function HasAdminPermission(player: Player?): boolean
	-- Console execution always has admin permissions
	if not player then
		return true
	end
	
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
	Checks if a player has privileged permissions for global commands
	@param player The player to check (can be nil for console)
	@return boolean Whether the player has privileged permissions
]]
local function HasPrivilegedPermission(player: Player?): boolean
	-- Console execution always has privileged permissions
	if not player then
		return true
	end
	
	-- Check rank attribute for privileged ranks only
	local rank = player:GetAttribute("Rank")
	return rank and PRIVILEGED_RANKS[rank] or false
end

--[[
	Checks if a player is on cooldown for a specific command
	@param player The player to check (can be nil for console)
	@param commandName The command to check cooldown for
	@return boolean Whether the player is on cooldown
]]
local function IsOnCooldown(player: Player?, commandName: string): boolean
	-- Console execution bypasses cooldowns
	if not player then
		return false
	end
	
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
	@param player The player to set cooldown for (can be nil for console)
	@param commandName The command to set cooldown for
	@param duration The cooldown duration in seconds
]]
local function SetCooldown(player: Player?, commandName: string, duration: number)
	-- Console execution doesn't set cooldowns
	if not player then
		return
	end
	
	if not playerCooldowns[player] then
		playerCooldowns[player] = {}
	end
	
	playerCooldowns[player][commandName] = workspace:GetServerTimeNow() + duration
end

--[[
	Executes an admin command
	@param executor The player executing the command (nil for console execution)
	@param commandName The name of the command to execute
	@param targetPlayer The target player (optional)
	@param isGlobal Whether this is a global command (optional)
]]
function AdminPanel.ExecuteCommand(executor: Player?, commandName: string, targetPlayer: Player?, isGlobal: boolean?)
	-- Check if executor has admin permissions
	if not HasAdminPermission(executor) then
		local executorName = executor and executor.Name or "Console"
		warn(`{executorName} attempted to use admin command without permission`)
		return
	end
	
	-- Check if executor has privileged permissions for global commands
	if isGlobal and not HasPrivilegedPermission(executor) then
		local executorName = executor and executor.Name or "Console"
		warn(`{executorName} attempted to use global admin command without privileged permission`)
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
		-- If executor is nil (console), make the target the executor (which will be nil)
		if not executor then
			warn(`Console command '{commandName}' requires a target player`)
			return
		else
			-- For player executors, use them as the target if no target specified
			targetPlayer = executor
		end
	end
	
	-- Check cooldown
	if IsOnCooldown(executor, commandName) then
		return
	end
	
	-- Handle global command execution
	if isGlobal then
		-- Disallow global if the command marks PreventGlobal
		if command.PreventGlobal then
			-- Fall back to local execution instead of global
			isGlobal = false
		else
		-- Broadcast global command via MessagingService
		local messagingService = game:GetService("MessagingService")
		local globalCommandData = {
			commandName = commandName,
			executorName = executor and executor.Name or "Console",
			executorUserId = executor and executor.UserId or 0,
			timestamp = workspace:GetServerTimeNow()
		}
		
		pcall(function()
			messagingService:PublishAsync("GlobalAdminCommand", globalCommandData)
		end)
		
		-- Execute locally on all players
		for _, player in ipairs(game.Players:GetPlayers()) do
			local success, result = command.OnExecute(executor, player)
			
			-- Handle finish function execution based on Duration
			if success and result and type(result) == "function" then
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
		return -- Don't continue with normal execution flow for global commands
		end
	end
	
	-- Execute the command normally
	local success, result = command.OnExecute(executor, targetPlayer)
	
	-- Check if command execution was successful
	if not success then
		-- Command failed, result should be an error message
		local errorMessage = result or "Command execution failed"
		local executorName = executor and executor.Name or "Console"
		warn(`Command '{commandName}' failed for {executorName}: {errorMessage}`)
		return
	end
	
	-- Command succeeded, set cooldown (privileged roles get reduced cooldown)
	local cooldownDuration = (HasPrivilegedPermission(executor) and 1) or command.Cooldown
	SetCooldown(executor, commandName, cooldownDuration)
	
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

--[[
	Executes an admin command from console (server-side)
	@param commandName The name of the command to execute
	@param targetPlayer The target player (required for console execution)
]]
function AdminPanel.ExecuteConsoleCommand(commandName: string, targetPlayer: Player?)
	AdminPanel.ExecuteCommand(nil, commandName, targetPlayer)
end

-- Network event handler for admin commands
Network.Fired("AdminPanel_ExecuteCommand", function(player: Player, commandName: string, targetPlayer: Player?, isGlobal: boolean?)
	AdminPanel.ExecuteCommand(player, commandName, targetPlayer, isGlobal)
end)

-- MessagingService listener for global commands
local messagingService = game:GetService("MessagingService")
pcall(function()
	messagingService:SubscribeAsync("GlobalAdminCommand", function(message)
		local data = message.Data
		if not data or not data.commandName then return end
		
		-- Get command from directory
		local command: AdminPanelTypes.AdminCommand? = AdminPanelDirectory[data.commandName]
		if not command then return end
		
		-- Execute the command on all players in this server
		for _, player in ipairs(game.Players:GetPlayers()) do
			local success, result = command.OnExecute(nil, player)
			
			-- Handle finish function execution based on Duration
			if success and result and type(result) == "function" then
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
		
		-- Log global command execution
		print(`[Global Admin Command] {data.executorName} executed '{data.commandName}' on all players`)
	end)
end)

return AdminPanel
