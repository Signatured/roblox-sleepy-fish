--!strict

local ClientPlot = require(game.ReplicatedStorage.Plot.ClientPlot)
local FishCmds = require(game.ReplicatedStorage.Game.Library.Client.FishCmds)
local NotificationCmds = require(game.ReplicatedStorage.Library.Client.NotificationCmds)

ClientPlot.OnAllAndCreated(function(plot: ClientPlot.Type)
	local model = plot:WaitModel()
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

                if fish then
                    local success = plot:Invoke("DeleteFish", fish.UID)
                    if success then
                        NotificationCmds.Message("Fish deleted!", {
                            Color = Color3.fromRGB(0, 255, 0),
                        })
                    else
                        NotificationCmds.Message("You're not holding a fish!", {
                            Color = Color3.fromRGB(255, 0, 0),
                        })
                    end
                else
                    NotificationCmds.Message("You're not holding a fish!", {
                        Color = Color3.fromRGB(255, 0, 0),
                    })
                end
			end
		end)
	end
end)