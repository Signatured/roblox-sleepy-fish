--!strict

local Assets = game:GetService("ReplicatedStorage"):WaitForChild("Assets")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GUI = require(ReplicatedStorage.Game.Library.Client.GUI)
local TabController = require(ReplicatedStorage.Library.Client.TabController)
local ButtonFX = require(ReplicatedStorage.Library.Client.GUIFX.ButtonFX)
local Directory = require(ReplicatedStorage.Game.Library.Directory)
local HalloweenDailyQuestsCmds = require(ReplicatedStorage.Game.Library.Client.HalloweenDailyQuestsCmds)
local Functions = require(ReplicatedStorage.Library.Functions)
local SwapGradient = require(ReplicatedStorage.Library.Client.GUIFX.SwapGradient)
local Save = require(ReplicatedStorage.Library.Client.Save)
local NotificationCmds = require(ReplicatedStorage.Library.Client.NotificationCmds)
local Signal = require(ReplicatedStorage.Library.Signal)

local gui = GUI.HalloweenDailyQuests()

local greenGradient = Assets:WaitForChild("GreenButtonGradient")
local greyGradient = Assets:WaitForChild("GreyButtonGradient")

-- Token to manage the timer update loop so only one runs at a time
local timerToken = 0

local function getPumpkinSellPrice(id: string): number
	if id == "Common Pumpkin" then
		return 10_000
	elseif id == "Epic Pumpkin" then
		return 25_000
	elseif id == "Mythical Pumpkin" then
		return 50_000
	end
	return 0
end

local function getContentContainer(): ScrollingFrame?
	local toolsGui = GUI.HalloweenDailyQuests()
	local frame = toolsGui:FindFirstChild("Frame")
	if not frame then return nil end
	local mainFrame = frame:FindFirstChild("MainFrame")
	if not mainFrame then return nil end
	local content = mainFrame:FindFirstChild("Content")
	if not content then return nil end
	local scrolling = content:FindFirstChild("ScrollingFrame")
	return scrolling and scrolling:IsA("ScrollingFrame") and scrolling or nil
end

local function setBar(frame: Frame, progress: number, amount: number)
	local bar = frame:FindFirstChild("Bar")
	if not bar or not bar:IsA("ImageLabel") then return end
	local container = bar:FindFirstChild("ProgressContainer")
	local prog = container and container:FindFirstChild("ProgressBar")
	local unit = bar:FindFirstChild("ProgressUnit")
	if prog and prog:IsA("Frame") then
		local pct = amount > 0 and math.clamp(progress / amount, 0, 1) or 0
		prog.Size = UDim2.new(pct, 0, 1, 0)
	end
	if unit and unit:IsA("TextLabel") then
		unit.Text = string.format("%d/%d", progress, amount)
	end
end

local function setQuest(frame: Frame, quest, isUnlocked: boolean, isActive: boolean)
	local overlay = frame:FindFirstChild("Overlay")
	if overlay and overlay:IsA("Frame") then
		overlay.Visible = not isUnlocked
	end

	local completedLabel = frame:FindFirstChild("Completed")
	if completedLabel and completedLabel:IsA("TextLabel") then
		completedLabel.Visible = quest.Completed == true
	end

	local claimButton = frame:FindFirstChild("Claim")
	local claimText = claimButton and claimButton:FindFirstChild("TextLabel")
	if claimButton and claimButton:IsA("GuiButton") then
		claimButton.Visible = isActive and quest.ReadyToClaim == true and not quest.Completed
		if not claimButton:GetAttribute("DQ_Wired") then
			ButtonFX(claimButton)
			claimButton.Activated:Connect(function()
				HalloweenDailyQuestsCmds.Claim()
			end)
			claimButton:SetAttribute("DQ_Wired", true)
		end
		if claimText and claimText:IsA("TextLabel") then claimText.Text = "Claim" end
	end

	local sellButton = frame:FindFirstChild("Sell")
	local sellLabel = sellButton and sellButton:FindFirstChild("TextLabel")
	local sellPriceLabel = frame:FindFirstChild("SellPrice")
	if sellButton and sellButton:IsA("GuiButton") then
		local showSell = isActive and not quest.Completed and not (quest.ReadyToClaim == true)
		sellButton.Visible = showSell
		if not sellButton:GetAttribute("DQ_Wired") then
			ButtonFX(sellButton)
			-- remember quest index on the button for fresh lookup during click
			sellButton:SetAttribute("DQ_Index", tonumber(frame.Name))
			sellButton.Activated:Connect(function()
				-- fetch current quest state at click time
				local data = HalloweenDailyQuestsCmds.Get()
				local idx = sellButton:GetAttribute("DQ_Index")
				local q = data and data.Quests and data.Quests[tonumber(idx) or 1]
				if not q then return end
				local haveOne = false
				local save = Save.Get()
				local inv = save and save.Inventory
				if type(inv) == "table" then
					for _, entry in ipairs(inv) do
						if entry and entry.FishId == q.FishId then
							haveOne = true
							break
						end
					end
				end
				if not haveOne then
					local schemaNow = Directory.Fish[q.FishId]
					local name = schemaNow and schemaNow.DisplayName or "fish"
					NotificationCmds.Message("You don't have a " .. tostring(name) .. "!", { Color = Color3.fromRGB(255, 80, 80) })
					return
				end
				HalloweenDailyQuestsCmds.Sell()
			end)
			sellButton:SetAttribute("DQ_Wired", true)
		end
		-- Apply gradient based on whether inventory has at least one of required fish
		local hasRequired = false
		local save = Save.Get()
		local inv = save and save.Inventory
		if type(inv) == "table" then
			for _, entry in ipairs(inv) do
				if entry and entry.FishId == quest.FishId then
					hasRequired = true
					break
				end
			end
		end
		SwapGradient(sellButton, (showSell and hasRequired) and greenGradient or greyGradient)
		if sellLabel and sellLabel:IsA("TextLabel") then sellLabel.Text = "Sell" end
	end
	if sellPriceLabel and sellPriceLabel:IsA("TextLabel") then
		local pricePerSale = getPumpkinSellPrice(quest.FishId)
		sellPriceLabel.Visible = isActive and not quest.Completed and not (quest.ReadyToClaim == true)
		sellPriceLabel.Text = `${Functions.NumberShorten(pricePerSale)}`
	end

	-- Selected fish image preview
	local imgFrame = frame:FindFirstChild("ImageFrame")
	local selectedFish = imgFrame and imgFrame:FindFirstChild("SelectedFish")
	local schema = Directory.Fish[quest.FishId]
	if selectedFish and selectedFish:IsA("ImageLabel") and schema then
		selectedFish.Image = tostring(schema.Icon or "")
	end

	-- Description text under quest frame
	local description = frame:FindFirstChild("Description")
	if description and description:IsA("TextLabel") and schema then
		description.Text = string.format("Sell me %d %ss!", quest.Amount or 0, tostring(schema.DisplayName))
	end

	local rewardText = frame:FindFirstChild("RewardText")
	if rewardText and rewardText:IsA("TextLabel") then
		rewardText.Text = string.format("Sell %d %s", quest.Amount, Directory.Fish[quest.FishId].DisplayName)
	end

	setBar(frame, quest.Progress or 0, quest.Amount or 1)
end


local function refresh()
	if not gui then return end
	local root = gui:FindFirstChild("Frame")
	if not root or not root:IsA("Frame") then return end
	local mainFrame = root:FindFirstChild("MainFrame")
	if not mainFrame or not mainFrame:IsA("Frame") then return end
	local contentHolder = mainFrame:FindFirstChild("Content")
	if not contentHolder or not contentHolder:IsA("Frame") then return end
	local content = contentHolder:FindFirstChild("ScrollingFrame")
	if not content or not content:IsA("ScrollingFrame") then return end

	-- Start/refresh the countdown timer label under Content (TextLabel named 'Timer')
	local timerLabel = contentHolder:FindFirstChild("Timer")
	if timerLabel and timerLabel:IsA("TextLabel") then
		timerToken += 1
		local myToken = timerToken
		task.spawn(function()
			while myToken == timerToken and TabController.GetCurrentTab and TabController.GetCurrentTab() == "HalloweenDailyQuests" and timerLabel and timerLabel.Parent do
				local utc = workspace:GetServerTimeNow()
				local est = utc - (5 * 3600)
				local remain = 86400 - (est % 86400)
				if remain < 0 then remain = 0 end
				timerLabel.Text = string.format("New Halloween Quests In: %s", Functions.FormatTime(remain))
				task.wait(1)
			end
		end)
	end

	if not HalloweenDailyQuestsCmds then return end
	local data = HalloweenDailyQuestsCmds.Get()
	if not data or not data.Quests then return end

	for i = 1, 3 do
		local frame = content:FindFirstChild(tostring(i))
		if frame and frame:IsA("Frame") then
			local quest = data.Quests[i]
			local isUnlocked = (i == 1) or (data.Current and i <= data.Current)
			local isActive = data.Current == i
			setQuest(frame, quest, isUnlocked, isActive)
		end
	end
end

TabController.Opened:Connect(function(tabId: string)
	if tabId == "HalloweenDailyQuests" then
		refresh()

        -- task.spawn(function()
        --     while true do
		
        --         local scrolling = getContentContainer()
		-- 		if scrolling then
		-- 			Functions.UpdateCanvasSize(scrolling)
		-- 		end
        --         task.wait(0.1)
        --     end
        -- end)
	end
end)

HalloweenDailyQuestsCmds.Updated:Connect(function()
    refresh()
end)

Signal.Fired("StatCacheUpdated"):Connect(function(stat)
    if stat == "Inventory" then
        refresh()
    end
end)