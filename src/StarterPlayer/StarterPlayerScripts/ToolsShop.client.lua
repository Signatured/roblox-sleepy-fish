--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GUI = require(ReplicatedStorage.Game.Library.Client.GUI)
local TabController = require(ReplicatedStorage.Library.Client.TabController)
local ButtonFX = require(ReplicatedStorage.Library.Client.GUIFX.ButtonFX)
local GadgetDirectory = require(ReplicatedStorage.Game.Library.Directory.Gadgets)
local Functions = require(ReplicatedStorage.Library.Functions)
local Network = require(ReplicatedStorage.Library.Client.Network)
local Signal = require(ReplicatedStorage.Library.Signal)
local Save = require(ReplicatedStorage.Library.Client.Save)
local NotificationCmds = require(ReplicatedStorage.Library.Client.NotificationCmds)
local ClientPlot = require(ReplicatedStorage.Plot.ClientPlot)

local function getContentContainer(): ScrollingFrame?
	local toolsGui = GUI.Tools()
	local frame = toolsGui:FindFirstChild("Frame")
	if not frame then return nil end
	local mainFrame = frame:FindFirstChild("MainFrame")
	if not mainFrame then return nil end
	local content = mainFrame:FindFirstChild("Content")
	if not content then return nil end
	local scrolling = content:FindFirstChild("ScrollingFrame")
	return scrolling and scrolling:IsA("ScrollingFrame") and scrolling or nil
end

local function hasGadget(dir: GadgetDirectory.dir_schema)
	local save = Save.Get()
	if not save then return false end

	local tools = save.Tools
	return tools[dir._id] ~= nil
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

		-- Simple icon image for tool preview
		local toolImage = clone:FindFirstChild("ToolImage")
		local imageLabel = toolImage and toolImage:FindFirstChild("ImageLabel")
		if imageLabel and imageLabel:IsA("ImageLabel") then
			imageLabel.Image = tostring(dir.Icon or "")
		end

		-- Button setup
		local buttons = clone:FindFirstChild("Buttons")
		local buyButton: ImageButton? = buttons and buttons:FindFirstChild("BuyButton") :: ImageButton?
		if buyButton and buyButton:IsA("GuiButton") then
			ButtonFX(buyButton)
			local label = buyButton:FindFirstChild("TextLabel")
			local owned = hasGadget(dir)
			if label and label:IsA("TextLabel") then
				label.Text = owned and "Sell" or "Buy"
				buyButton.Image = owned and "rbxassetid://73232367551124" or "rbxassetid://85004105467436"
			end

			local busy = false
			buyButton.Activated:Connect(function()
				if busy then return end
				busy = true

				local isOwned = hasGadget(dir)
				if not isOwned then
					local plot = ClientPlot.GetLocal()
					local money = plot and plot:Save("Money") or 0
					if typeof(money) ~= "number" then
						money = 0
					end
					local cost = tonumber(dir.Cost) or 0
					if (money :: number) < cost then
						NotificationCmds.Message("You cannot afford this!", { Color = Color3.fromRGB(255, 80, 80)})
						busy = false
						return
					end
				end
				local _ok, _
				if isOwned then
					_ok = pcall(function()
						return Network.Invoke("SellTool", dir._id)
					end)

					if _ok then
						NotificationCmds.Message(`You sold a {dir.DisplayName}!`, { Color = Color3.fromRGB(0, 255, 0) })
					end
				else
					_ok = pcall(function()
						return Network.Invoke("BuyTool", dir._id)
					end)
					-- Notify on successful buy
					if _ok then
						NotificationCmds.Message(`You bought a {dir.DisplayName}!`, { Color = Color3.fromRGB(0, 255, 0) })
					end
				end

				-- Re-evaluate ownership and update label
				local nowOwned = hasGadget(dir)
				if label and label:IsA("TextLabel") then
					label.Text = nowOwned and "Sell" or "Buy"
				end

				buyButton.Active = true
				buyButton.AutoButtonColor = true
				busy = false
			end)
		end

		clone.Parent = scrolling
	end

	task.spawn(function()
		while true do
			if TabController.GetCurrentTab() ~= "Tools" then break end
			Functions.UpdateCanvasSize(scrolling)
			task.wait(0.1)
		end
	end)
end

-- Rebuild when the Tools tab opens
TabController.Opened:Connect(function(tabId: string)
	if tabId == "Tools" then
		buildToolsList()
	end
end)

Signal.Fired("StatCacheUpdated"):Connect(function(key: string, value: any)
	if key == "Tools" then
		buildToolsList()
	end
end)