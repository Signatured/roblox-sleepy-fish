--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommandManager = require(ServerScriptService.CommandManager)
local CommandType = require(ReplicatedStorage.Game.Library.Types.Commands)
local BadgeManager = require(ServerScriptService.Game.Library.BadgeManager)

local LEGEND_BADGE_ID = 2611268647815735

local Command = {
	Name = "GrantLegendBadge",
	Aliases = {"grantlegendbadge", "legendbadge", "grantlegend"},
	Permissions = {"Admin", "Owner", "Developer"},
	Parameters = {
		{Type = "Player", Name = "TargetPlayer", Optional = true},
	} :: {CommandType.Parameter},

	Execute = function(player: Player, args: {any})
		local targetPlayers = args[1]

		for _, targetPlayer in ipairs(targetPlayers) do
			local success = BadgeManager.GiveBadge(targetPlayer, LEGEND_BADGE_ID)
			if success then
				print(`[GrantLegendBadge] Granted TheLegend badge to {targetPlayer.Name}`)
			else
				warn(`[GrantLegendBadge] Failed to grant TheLegend badge to {targetPlayer.Name}`)
			end
		end
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {}

