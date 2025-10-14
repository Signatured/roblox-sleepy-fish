--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

local GUI = require(ReplicatedStorage.Game.Library.Client.GUI)
local LimitedMythicalOffer = require(ReplicatedStorage.Game.Library.Client.LimitedMythicalOfferCmds)
local Marketplace = require(ReplicatedStorage.Library.Marketplace)
local Products = require(ReplicatedStorage.Game.Library.Directory.Products)
local ButtonFX = require(ReplicatedStorage.Library.Client.GUIFX.ButtonFX)
local Network = require(ReplicatedStorage.Library.Client.Network)
local Directory = require(ReplicatedStorage.Game.Library.Directory)

-- Mythical brainrot icons to rotate through (no repeats back-to-back)
-- Dynamically populated from Brainrot directory
local MYTHICAL_ICONS: {string} = {}
do
	for brainrotId, brainrot in pairs(Directory.Fish) do
		if brainrot.Rarity and brainrot.Rarity._id == "Mythical" then
			-- Only add icons that are not empty strings
			if brainrot.Icon and brainrot.Icon ~= "" then
				table.insert(MYTHICAL_ICONS, brainrot.Icon)
			end
		end
	end
end

local function preloadIcons()
	local instances = {}
	for _, id in ipairs(MYTHICAL_ICONS) do
		local img = Instance.new("ImageLabel")
		img.Size = UDim2.new(0, 0, 0, 0)
		img.BackgroundTransparency = 1
		img.Image = id
		img.Parent = script
		table.insert(instances, img)
	end
	pcall(function()
		ContentProvider:PreloadAsync(instances)
	end)
	for _, inst in ipairs(instances) do
		inst:Destroy()
	end
end

local function getMain()
	-- Assumes GUI.Main() returns the root gui containing 'MythicalOffer'
	return GUI.Main()
end

local function setVisible(frame: Frame?, visible: boolean)
	if frame then
		frame.Visible = visible
	end
end

local function pickNextIcon(exclude: string?): string
	local pool = {}
	for _, id in ipairs(MYTHICAL_ICONS) do
		if id ~= exclude then table.insert(pool, id) end
	end
	if #pool == 0 then return exclude or MYTHICAL_ICONS[1] end
	local idx = math.random(1, #pool)
	return pool[idx]
end

local function run()
	local main = getMain()
	if not main then return end

	local mythicalOffer = main:FindFirstChild("MythicalOffer")
	if not mythicalOffer or not mythicalOffer:IsA("Frame") then return end

	local frame = mythicalOffer:FindFirstChild("Frame")
	local imageButton = frame and frame:FindFirstChild("ImageButton")
	local timeLabel = mythicalOffer:FindFirstChild("Time")

	if not (imageButton and imageButton:IsA("ImageButton") and timeLabel and timeLabel:IsA("TextLabel")) then
		return
	end

	-- Add button feedback FX
	ButtonFX(imageButton)

	local lastIcon: string? = nil
	local iconConn: RBXScriptConnection? = nil

	-- Rotate icon every 5 seconds when visible
	local function startIconRotation()
		if iconConn then iconConn:Disconnect() end
		local elapsed = 0
		iconConn = game:GetService("RunService").Heartbeat:Connect(function(dt)
			elapsed += dt
			if elapsed >= 5 then
				elapsed = 0
				local nextIcon = pickNextIcon(lastIcon)
				lastIcon = nextIcon
				imageButton.Image = nextIcon
			end
		end)
	end

	local function stopIconRotation()
		if iconConn then iconConn:Disconnect() end
		iconConn = nil
	end

	-- Purchase
	imageButton.Activated:Connect(function()
		task.spawn(function()
			Network.Fire("ClickedProduct", "Spawn Mythical")
		end)
		local product = Products["Spawn Mythical"]
		if product then
			Marketplace.Prompt(game.Players.LocalPlayer, product.ProductId, true)
		end
	end)

	-- Preload mythical icons once
	task.spawn(preloadIcons)

	-- Main poll loop every 0.5s
	while main and main.Parent do
		local can = LimitedMythicalOffer.CanPurchase()
		if can then
			setVisible(mythicalOffer, true)
			local timeLeft = LimitedMythicalOffer.GetPurchaseTimeLeft()
			timeLabel.Text = `{math.ceil(timeLeft)}s`
			if not iconConn then
				startIconRotation()
			end
		else
			setVisible(mythicalOffer, false)
			stopIconRotation()
		end
		task.wait(0.5)
	end
end

task.spawn(run)

-- Owner-only mythical beam rendering
local function createLocalBeamFor(uid: string)
    -- Find fish model by UID attribute
    local things = workspace:FindFirstChild("__THINGS")
    if not things then return end
    local swimRoot = things:FindFirstChild("SwimmingFish")
    if not swimRoot then return end
    local model: Model? = nil
    for _, child in ipairs(swimRoot:GetDescendants()) do
        if child:IsA("Model") then
            local a = child:GetAttribute("UID")
            if a == uid then
                model = child
                break
            end
        end
    end
    if not model then return end

    local hrp = (game.Players.LocalPlayer.Character and (game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or game.Players.LocalPlayer.Character:FindFirstChild("Torso")))
    local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not hrp or not primary or not primary:IsA("BasePart") then return end

    local beamTemplate = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("MythicalBeam")
    local beamObj: Beam? = nil
    if beamTemplate then
        if beamTemplate:IsA("Beam") then
            beamObj = beamTemplate:Clone()
        else
            local inner = beamTemplate:FindFirstChildWhichIsA("Beam")
            if inner and inner:IsA("Beam") then
                beamObj = inner:Clone()
            end
        end
    end
    if not beamObj then return end

    local attach0 = hrp:FindFirstChild("_MythicalBeamAttachment")
    if not attach0 then
        attach0 = Instance.new("Attachment")
        attach0.Name = "_MythicalBeamAttachment"
        attach0.Parent = hrp
    end
    local attach1 = Instance.new("Attachment")
    attach1.Name = "_MythicalBeamAttachment"
    attach1.Parent = primary
    beamObj.Attachment0 = attach0 :: Attachment
    beamObj.Attachment1 = attach1
    beamObj.Enabled = true
    beamObj.Parent = primary

    -- Hide when carrying this fish
    local conn1
    conn1 = game:GetService("RunService").Heartbeat:Connect(function()
        if not model or not model.Parent then
            if conn1 then conn1:Disconnect() end
            if beamObj then beamObj:Destroy() end
            return
        end
        local carryingId = game.Players.LocalPlayer:GetAttribute("CarryingFishUID")
        if carryingId == uid then
            beamObj.Enabled = false
        else
            beamObj.Enabled = true
        end
    end)
end

Network.Fired("MythicalBeam_Create", function(uid: string)
    createLocalBeamFor(uid)
end)


