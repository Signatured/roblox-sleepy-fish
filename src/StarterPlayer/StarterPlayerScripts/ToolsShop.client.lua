--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GUI = require(ReplicatedStorage.Game.Library.Client.GUI)
local TabController = require(ReplicatedStorage.Library.Client.TabController)
local ButtonFX = require(ReplicatedStorage.Library.Client.GUIFX.ButtonFX)
local GadgetDirectory = require(ReplicatedStorage.Game.Library.Directory.Gadgets)
local GadgetCmds = require(ReplicatedStorage.Game.Library.Client.GadgetCmds)
local Functions = require(ReplicatedStorage.Library.Functions)

local function getContentContainer(): ScrollingFrame?
	local toolsGui = GUI.Tools()
	local frame = toolsGui:FindFirstChild("Frame")
	if not frame then return nil end
	local container = frame:FindFirstChild("Container")
	if not container then return nil end
	local mainFrame = container:FindFirstChild("MainFrame")
	if not mainFrame then return nil end
	local content = mainFrame:FindFirstChild("Content")
	if not content then return nil end
	local scrolling = content:FindFirstChild("ScrollingFrame")
	return scrolling and scrolling:IsA("ScrollingFrame") and scrolling or nil
end

local function buildToolsList()
	local scrolling = getContentContainer()
	if not scrolling then return end

	local template = scrolling:FindFirstChild("Tool")
	if not template or not template:IsA("Frame") then
		warn("ToolsShop: Template 'Tool' not found under ScrollingFrame")
		return
	end

	-- Remove existing clones
	for _, child in ipairs(scrolling:GetChildren()) do
		if child ~= template and child:IsA("Frame") and child.Name == "Tool" then
			child:Destroy()
		end
	end

	-- Prepare a sorted list by Index
	local items = {}
	for id, dir in pairs(GadgetDirectory) do
		if type(dir) == "table" and dir._id and dir.DisplayName then
			items[#items+1] = dir
		end
	end
	table.sort(items, function(a, b)
		local ai = tonumber(a.Index) or 0
		local bi = tonumber(b.Index) or 0
		return ai < bi
	end)

	-- Hide template
	template.Visible = false

	for _, dir in ipairs(items) do
		local clone = template:Clone()
		clone.Visible = true
		clone.LayoutOrder = (tonumber(dir.Index) or 0)
		clone.Name = "Tool"

		-- Title, Price, Description
		local title = clone:FindFirstChild("Title")
		if title and title:IsA("TextLabel") then
			title.Text = tostring(dir.DisplayName)
		end
		local price = clone:FindFirstChild("Price")
		if price and price:IsA("TextLabel") then
			price.Text = `${Functions.NumberShorten(dir.Cost)}`
		end
		local description = clone:FindFirstChild("Description")
		if description and description:IsA("TextLabel") then
			description.Text = tostring(dir.Description or "")
		end

		-- Button setup
		local buttons = clone:FindFirstChild("Buttons")
		local buyButton: GuiButton? = buttons and buttons:FindFirstChild("BuyButton") :: GuiButton?
		if buyButton and buyButton:IsA("GuiButton") then
			ButtonFX(buyButton)
			local label = buyButton:FindFirstChild("TextLabel")
			local owned = GadgetCmds.Has(dir)
			if label and label:IsA("TextLabel") then
				label.Text = owned and "Owned" or "Buy"
			end
		end

		clone.Parent = scrolling
	end
end

-- Rebuild when the Tools tab opens
TabController.Opened:Connect(function(tabId: string)
	if tabId == "Tools" then
		buildToolsList()
	end
end)


