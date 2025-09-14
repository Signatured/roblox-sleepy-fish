--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Marketplace = require(ReplicatedStorage.Library.Marketplace)
local Products = require(ReplicatedStorage.Game.Library.Directory.Products)

local LOCAL_PLAYER = Players.LocalPlayer

local PRODUCT_KEY = "Abyssal Hydra"
local productSchema = Products[PRODUCT_KEY]
local PRODUCT_ID: number? = productSchema and productSchema.ProductId or nil

local TAG_NAME = "ExclusivePrompt"

local function setupPromptFor(instance: Instance)
	if not PRODUCT_ID then return end
	if instance:IsA("BasePart") or instance:IsA("Model") then
		local attachParent: Instance = instance
		if instance:IsA("Model") then
			local primary = instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart")
			if primary then attachParent = primary end
		end

		-- Prefer an attachment named "ExclusiveAttachment" if present
		local attachTarget: Instance = attachParent
		local exclusiveAttachment: Instance? = nil
		if attachParent:IsA("BasePart") then
			exclusiveAttachment = attachParent:FindFirstChild("ExclusiveAttachment")
		elseif attachParent:IsA("Model") then
			exclusiveAttachment = attachParent:FindFirstChild("ExclusiveAttachment", true)
		end
		if exclusiveAttachment and exclusiveAttachment:IsA("Attachment") then
			attachTarget = exclusiveAttachment
		end

        print("setup")
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "ExclusivePurchasePrompt"
		prompt.ActionText = "Buy Abyssal Hydra!"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0
		prompt.RequiresLineOfSight = false
		prompt.MaxActivationDistance = 15
		prompt.Parent = attachTarget

		prompt.Triggered:Connect(function(player)
			if player ~= LOCAL_PLAYER then return end
			if PRODUCT_ID then
				Marketplace.Prompt(player, PRODUCT_ID :: number, true)
			end
		end)
	end
end

for _, inst in ipairs(CollectionService:GetTagged(TAG_NAME)) do
	setupPromptFor(inst)
end

CollectionService:GetInstanceAddedSignal(TAG_NAME):Connect(setupPromptFor)
