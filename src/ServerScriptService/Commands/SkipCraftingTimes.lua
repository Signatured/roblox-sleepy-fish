--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommandManager = require(ServerScriptService.CommandManager)
local Saving = require(ServerScriptService.Library.Saving)
local CommandType = require(ReplicatedStorage.Game.Library.Types.Commands)
local Notifications = require(ServerScriptService.Library.Notifications)

local Command = {
	Name = "SkipCraftingTimes",
	Aliases = {"skipcrafting"},
	Permissions = {"Admin", "Owner", "Developer"},
	Parameters = {
		{Type = "Player", Name = "TargetPlayer", Optional = true},
	} :: {CommandType.Parameter},

	Execute = function(player, args)
		local targetPlayers = args[1]

		for _, targetPlayer in ipairs(targetPlayers) do
			local saveData = Saving.Get(targetPlayer)
			if saveData then
				local currentTime = workspace:GetServerTimeNow()
				local skippedCount = 0
				
				-- Loop through all crafting machines and recipes
				for machineId, machineSlots in pairs(saveData.CraftingMachines) do
					for recipeKey, slot in pairs(machineSlots) do
						if slot and slot.CompletionTime then
							-- Set completion time to now
							slot.CompletionTime = currentTime
							skippedCount = skippedCount + 1
						end
					end
				end
				
				if skippedCount > 0 then
					print(`Skipped {skippedCount} crafting timer(s) for {targetPlayer.Name}`)
				end

                -- Notify all players
                Notifications.Message(targetPlayer,"Admin instantly finished all crafting times!", {
                    Rainbow = true,
                    Time = 8,
                })
			end
		end
	end,
} :: CommandType.Command

CommandManager.Register(Command)

return {}

