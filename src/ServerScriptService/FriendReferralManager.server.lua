--!strict

-- This script manages referral rewards for players who successfully invite their
-- friends to the game.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Framework Modules
local Network = require(ServerScriptService.Library.Network)
local Saving = require(ServerScriptService.Library.Saving)
local Notifications = require(ServerScriptService.Library.Notifications)
local Functions = require(ReplicatedStorage.Library.Functions)
local ServerPlot = require(ServerScriptService.Plot.ServerPlot)

-- Constants
local REWARD_AMOUNT = 1000

-- {[InvitingUserId]: {InvitedUserId}}
local pendingInvites: {[number]: {[number]: boolean}} = {}

---
-- Called when a player on the client reports that they've invited a friend.
-- @param player The player who sent the invitation.
-- @param invitedFriendId The UserId of the friend who was invited.
---
local function onPlayerInvitedFriend(player: Player, invitedFriendId: number)
	if not pendingInvites[player.UserId] then
		pendingInvites[player.UserId] = {}
	end
	
	pendingInvites[player.UserId][invitedFriendId] = true
	print(`[Referral] Player {player.Name} invited friend with UserId: {invitedFriendId}`)
end

---
-- Called when a new player joins the game, to check for a referral.
-- @param joiningPlayer The player who just joined.
---
local function onPlayerAdded(joiningPlayer: Player)
	-- Check all pending invites to see if this new player was one of them.
	for invitingPlayerId, invitedFriends in pairs(pendingInvites) do
		if invitedFriends[joiningPlayer.UserId] then
			local invitingPlayer = Players:GetPlayerByUserId(invitingPlayerId)
			
			if invitingPlayer and invitingPlayer.Parent then -- Make sure the inviting player is still in the game
				local success, areFriends = pcall(function()
					return invitingPlayer:IsFriendsWith(joiningPlayer.UserId)
				end)

				if success and areFriends then
                    local plot = ServerPlot.GetByPlayer(invitingPlayer)
					if plot then
                        plot:AddMoney(REWARD_AMOUNT)
						print(`[Referral] Awarded {REWARD_AMOUNT} coins to {invitingPlayer.Name} for referring {joiningPlayer.Name}.`)
						Notifications.Message(invitingPlayer, `You earned ${Functions.Commas(REWARD_AMOUNT)} for inviting a friend!`, {
                            Color = Color3.fromRGB(0, 255, 0),
                        })
					end
					
					-- Since a player can only be referred by one person, we can stop checking.
					invitedFriends[joiningPlayer.UserId] = nil
					break
				else
					if not success then
						warn(`[Referral] IsFriendsWith check failed for {invitingPlayer.Name} -> {joiningPlayer.Name}: {areFriends}`)
					end
					-- Not friends, so remove the pending invite to prevent repeated checks
					invitedFriends[joiningPlayer.UserId] = nil
				end
			end
		end
	end
end

---
-- Clears a player's pending invites when they leave the game.
---
local function onPlayerRemoving(player: Player)
	pendingInvites[player.UserId] = nil
end

-- Connect network and player events
Network.Fired("PlayerInvitedFriend", onPlayerInvitedFriend)
Saving.SaveAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)