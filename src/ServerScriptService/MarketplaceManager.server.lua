--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Library = ServerScriptService:WaitForChild("Library")
local Network = require(Library.Network)
local Products = require(Library.Products)
local Gamepasses = require(Library.Gamepasses)

local PRIVILEGED_ROLES = { "Developer", "Admin", "Owner", "Tester" }

-- Listen for the client's request to grant an item
Network.Fired("Marketplace_GrantItem", function(player: Player, id: number, isProduct: boolean?)
	-- Double-check that the player is actually privileged before granting
	local playerRank = player:GetAttribute("Rank")
	local isPrivileged = false
	if typeof(playerRank) == "string" then
		isPrivileged = table.find(PRIVILEGED_ROLES, playerRank) ~= nil
	end
	
	if not isPrivileged then
		warn(`[MarketplaceManager] Player {player.Name} tried to grant an item without permission.`)
		return
	end
	
	-- Grant the item
	if isProduct then
		Products.Give(player, id)
	else
		Gamepasses.Give(player, id)
	end
end) 