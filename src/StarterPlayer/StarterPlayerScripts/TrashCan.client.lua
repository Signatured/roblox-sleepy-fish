--!strict

local ClientPlot = require(game.ReplicatedStorage.Plot.ClientPlot)
local FishCmds = require(game.ReplicatedStorage.Game.Library.Client.FishCmds)
local NotificationCmds = require(game.ReplicatedStorage.Library.Client.NotificationCmds)
local Directory = require(game.ReplicatedStorage.Game.Library.Directory)
local Message = require(game.ReplicatedStorage.Library.Client.Message)

ClientPlot.OnAllAndCreated(function(plot: ClientPlot.Type)
	local model = plot:YieldModel()
	local trashCan = model:FindFirstChild("TrashCan")::BasePart

	if trashCan and not trashCan:GetAttribute("_PromptInit") then
		trashCan:SetAttribute("_PromptInit", true)
		local attachment = trashCan:FindFirstChild("TrashPromptAttachment")
		local attach: Attachment
		if attachment and attachment:IsA("Attachment") then
			attach = attachment
		else
			local newAttachment = Instance.new("Attachment")
			newAttachment.Name = "TrashPromptAttachment"
			newAttachment.Parent = trashCan
			attach = newAttachment
		end
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "TrashCanPrompt"
		prompt.ActionText = "Use Trash Can"
		prompt.HoldDuration = 3
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.Parent = attach
		prompt.Triggered:Connect(function()
			local plot = ClientPlot.GetLocal()
			if plot then
                local fish = FishCmds.GetCurrentFishData()

                if not fish then
                    NotificationCmds.Message("You're not holding a fish!", {
                        Color = Color3.fromRGB(255, 0, 0),
                    })
                    return
                end
                
                -- Get fish directory info to check rarity
                local fishDir = Directory.Fish[fish.FishId]
                if not fishDir or not fishDir.Rarity then
                    return
                end
                
                local rarityId = fishDir.Rarity._id
                local rarityName = fishDir.Rarity.DisplayName or rarityId
                
                -- Check if it's an Exclusive fish - block deletion completely
                if rarityId == "Exclusive" then
                    NotificationCmds.Message("You cannot delete an Exclusive fish!", {
                        Color = Color3.fromRGB(255, 0, 0),
                    })
                    return
                end
                
                -- Check if it's Mythical or Secret - show confirmation
                if rarityId == "Mythical" or rarityId == "God" or rarityId == "Secret" then
                    local confirmed = Message.new(`Are you sure? You're deleting a {rarityName} fish!`, true)
                    if confirmed then
                        local success = plot:Invoke("DeleteFish", fish.UID)
                        if success then
                            NotificationCmds.Message("Fish deleted!", {
                                Color = Color3.fromRGB(0, 255, 0),
                            })
                        else
                            NotificationCmds.Message("Failed to delete fish!", {
                                Color = Color3.fromRGB(255, 0, 0),
                            })
                        end
                    end
                    return
                end
                
                -- For all other rarities, delete immediately
                local success = plot:Invoke("DeleteFish", fish.UID)
                if success then
                    NotificationCmds.Message("Fish deleted!", {
                        Color = Color3.fromRGB(0, 255, 0),
                    })
                else
                    NotificationCmds.Message("Failed to delete fish!", {
                        Color = Color3.fromRGB(255, 0, 0),
                    })
                end
			end
		end)
	end
end)