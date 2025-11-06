--!strict

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Assets = game.ReplicatedStorage.Assets

local Functions = require(game.ReplicatedStorage.Library.Functions)
local ButtonFX = require(game.ReplicatedStorage.Library.Client.GUIFX.ButtonFX)
local ClientPlot = require(game.ReplicatedStorage.Plot.ClientPlot)
local NotificationCmds = require(game.ReplicatedStorage.Library.Client.NotificationCmds)
local FishCmds = require(game.ReplicatedStorage.Game.Library.Client.FishCmds)
local PlotTypes = require(game.ReplicatedStorage.Game.Library.Types.Plots)
local Directory = require(game.ReplicatedStorage.Game.Library.Directory)
local Network = require(game.ReplicatedStorage.Library.Client.Network)
local GameSettings = require(game.ReplicatedStorage.Game.Library.GameSettings)
local Save = require(game.ReplicatedStorage.Library.Client.Save)
local Marketplace = require(game.ReplicatedStorage.Library.Marketplace)
local ProductCmds = require(game.ReplicatedStorage.Library.Client.ProductCmds)
local Audio = require(game.ReplicatedStorage.Library.Audio)
local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
local LuckyBlockTypes = require(game.ReplicatedStorage.Game.Library.Types.LuckyBlocks)
local MutationCmds = require(game.ReplicatedStorage.Game.Library.Client.MutationCmds)
local TraitCmds = require(game.ReplicatedStorage.Game.Library.Client.TraitCmds)
local Message = require(game.ReplicatedStorage.Library.Client.Message)

-- Upgrade button images
local UPGRADE_IMAGE_GREEN = "rbxassetid://85004105467436"
local UPGRADE_IMAGE_GREY = "rbxassetid://95787790482910"

-- Configurable claim bounce tween settings
local CLAIM_TWEEN_TOTAL_TIME = 0.3 -- seconds for full down-and-up cycle
local CLAIM_TWEEN_DEPTH = 0.2 -- studs to move down

-- Configurable lucky block pre-animation settings
local LUCKY_BLOCK_SHRINK_DURATION = 0.85 -- seconds to shrink
local LUCKY_BLOCK_SHRINK_SCALE = 0.6 -- scale to shrink to (60%)
local LUCKY_BLOCK_GROW_DURATION = 0.25 -- seconds to grow and fade
local LUCKY_BLOCK_GROW_SCALE = 1.45 -- scale to grow to (120%)
local LUCKY_BLOCK_DECAL_TEXTURE = "rbxassetid://72606679736558" -- texture for decals during animation

-- Configurable audio pitch ramp when claiming repeatedly (local-only)
local CLAIM_PITCH_MAX_STREAK = 8 -- max consecutive steps to raise pitch
local CLAIM_PITCH_WINDOW_S = 1.5 -- time window to consider claims consecutive
local _claimPitchStreak = 0
local _lastClaimSoundTime = 0

local function nextClaimPlaybackSpeed(): number
	local now = time()
	if (now - _lastClaimSoundTime) <= CLAIM_PITCH_WINDOW_S then
		_claimPitchStreak = math.min(_claimPitchStreak + 1, CLAIM_PITCH_MAX_STREAK)
	else
		_claimPitchStreak = 0
	end
	_lastClaimSoundTime = now
	-- Raise by semitone per streak step: 2^(n/12)
	return 2 ^ (_claimPitchStreak / 12)
end

-- Boost pitch ramp (same timing/logic as claim)
local BOOST_PITCH_MAX_STREAK = 8
local BOOST_PITCH_WINDOW_S = 1.5
local _boostPitchStreak = 0
local _lastBoostSoundTime = 0

local function nextBoostPlaybackSpeed(): number
	local now = time()
	if (now - _lastBoostSoundTime) <= BOOST_PITCH_WINDOW_S then
		_boostPitchStreak = math.min(_boostPitchStreak + 1, BOOST_PITCH_MAX_STREAK)
	else
		_boostPitchStreak = 0
	end
	_lastBoostSoundTime = now
	return 2 ^ (_boostPitchStreak / 12)
end

local function playClaimBounce(claimPart: BasePart)
    if not claimPart or not claimPart.Parent then return end
    if claimPart:GetAttribute("_ClaimTweenActive") then return end
    claimPart:SetAttribute("_ClaimTweenActive", true)

    local startPosition = claimPart.Position
    local downPosition = startPosition - Vector3.new(0, CLAIM_TWEEN_DEPTH, 0)
    local halfDuration = CLAIM_TWEEN_TOTAL_TIME / 2
    local tweenInfo = TweenInfo.new(halfDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

    task.spawn(function()
        -- Down
        local t1 = Functions.Tween(claimPart, { Position = downPosition }, tweenInfo)
        if t1 and t1.Completed then t1.Completed:Wait() end
        -- Up
        if claimPart.Parent then
            local t2 = Functions.Tween(claimPart, { Position = startPosition }, tweenInfo)
            if t2 and t2.Completed then t2.Completed:Wait() end
        end
        claimPart:SetAttribute("_ClaimTweenActive", false)
    end)

end

-- Update the upgrade button image based on whether the player can afford the next level
local function UpdateUpgradeButtonImage(plot: ClientPlot.Type, model: Model)
    local pedestalId = tonumber(model.Name)
    if not pedestalId then return end

    local nameplate = model:FindFirstChild("Nameplate")
    if not nameplate or not nameplate:IsA("BasePart") then return end
    local surfaceGui = nameplate:FindFirstChild("SurfaceGui")
    if not surfaceGui or not surfaceGui:IsA("SurfaceGui") then return end
    local frame = surfaceGui:FindFirstChild("Frame")
    if not frame or not frame:IsA("Frame") then return end
    local upgradeFrame = frame:FindFirstChild("Upgrade")
    if not upgradeFrame or not upgradeFrame:IsA("Frame") then return end
    local upgradeButton = upgradeFrame:FindFirstChild("Button")
    if not upgradeButton or not upgradeButton:IsA("ImageButton") then return end

    local cost = plot:GetUpgradeCost(pedestalId)
    if not cost then return end -- Max level, leave as-is

    local targetImage = plot:CanAfford(cost) and UPGRADE_IMAGE_GREEN or UPGRADE_IMAGE_GREY
    if (upgradeButton :: ImageButton).Image ~= targetImage then
        (upgradeButton :: ImageButton).Image = targetImage
    end
end

type PedestalModel = {
    Model: Model,
    Billboard: BillboardGui,
    SellProximity: ProximityPrompt?,
    PickupProximity: ProximityPrompt?,
    BoostProximity: ProximityPrompt?,
    StealProximity: ProximityPrompt?,
}

local pedestalModels: {[ClientPlot.Type]: {[number]: PedestalModel}} = {}

-- Get the number of accessible pedestals based on ExtraFloors
local function GetAccessiblePedestalCount(plot: ClientPlot.Type): number
	local extraFloors = plot:Save("ExtraFloors")
	if not extraFloors or extraFloors == 0 then
		return GameSettings.DefaultPedestalCount
	end
	return GameSettings.ExtraFloorPedestalCounts[extraFloors] or GameSettings.DefaultPedestalCount
end

-- Store original parents for pedestals so we can restore them
local pedestalOriginalParents: {[ClientPlot.Type]: {[number]: Instance?}} = {}

-- Store references to all pedestal instances so we can access them even when parented to nil
local pedestalInstances: {[ClientPlot.Type]: {[number]: Model}} = {}

-- Update visibility of pedestals based on accessible count
local function UpdatePedestalVisibility(plot: ClientPlot.Type)
	local accessibleCount = GetAccessiblePedestalCount(plot)
	
	-- Initialize storage for this plot if needed
	if not pedestalOriginalParents[plot] then
		pedestalOriginalParents[plot] = {}
	end
	
	if not pedestalInstances[plot] then
		return -- No pedestals initialized yet
	end
	
	for pedestalId, child in pairs(pedestalInstances[plot]) do
		if pedestalId <= accessibleCount then
			-- Show this pedestal
			if child.Parent == nil and pedestalOriginalParents[plot][pedestalId] then
				child.Parent = pedestalOriginalParents[plot][pedestalId]
			end
		else
			-- Hide this pedestal
			if child.Parent ~= nil then
				pedestalOriginalParents[plot][pedestalId] = child.Parent
				child.Parent = nil
			end
		end
	end
end

local function getFishType(type: string): (string?, Color3?)
    if type == "Shiny" then
        return "Shiny", Color3.fromRGB(255, 255, 255)
    elseif type == "Gold" then
        return "Gold", Color3.fromRGB(255, 215, 0)
    elseif type == "Rainbow" then
        return "Rainbow"
    end
    return nil
end

local function getFishMutation(mutationId: string?): (string?, Color3?)
    if not mutationId then return nil end
    
    local dir = Directory.Mutations[mutationId]
    if dir then
        return dir.DisplayName, dir.Color
    end
    return nil
end

function SetupProximity(text: string, holdDuration: number, keyboardKeyCode: Enum.KeyCode, attachment: Attachment): ProximityPrompt
    local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = text
	prompt.HoldDuration = holdDuration
	prompt.MaxActivationDistance = 13
	prompt.KeyboardKeyCode = keyboardKeyCode
    prompt.RequiresLineOfSight = false
	prompt.Parent = attachment

    return prompt
end

function SetupBillboard(model: Model, fishData: PlotTypes.Fish): BillboardGui
    local primaryPart = assert(model.PrimaryPart)
    local dir = Directory.Fish[fishData.FishId]
    local billboardOffset = dir.BillboardOffset

    local billboard = Assets.FishPedestalGui:Clone()::BillboardGui
    billboard.StudsOffsetWorldSpace = Vector3.new(0, billboardOffset, 0)
    billboard.Parent = primaryPart

    return billboard
end

function UpdateBillboard(plot: ClientPlot.Type, index: number, billboard: BillboardGui)
    local fishData = plot:GetFish(index)
    if not fishData then
        return
    end

    local dir = Directory.Fish[fishData.FishId]
    local earnings = plot:GetFishEarnings(index)
    local offlineEarnings = plot:GetFishOfflineEarnings(index)

    local frame = billboard:WaitForChild("Frame")::Frame
    local displayName = frame:WaitForChild("DisplayName")::TextLabel
    local moneyPerSecond = frame:WaitForChild("MoneyPerSecond")::TextLabel
    local money = frame:WaitForChild("Money")::TextLabel
    local rarity = frame:WaitForChild("Rarity")::TextLabel
    local level = frame:WaitForChild("Level")::TextLabel
    local fishType = frame:WaitForChild("FishType")::TextLabel
    local mutation = frame:WaitForChild("Mutation")::TextLabel
    local offlineFrame = frame:WaitForChild("OfflineEarnings")::TextLabel
    local traitsFrame = frame:WaitForChild("Traits")::Frame

    -- Check if this is a lucky block
    local isLuckyBlock = dir.LuckyBlockId ~= nil
    local luckyBlockDir = nil
    if isLuckyBlock and dir.LuckyBlockId then
        luckyBlockDir = Directory.LuckyBlocks[dir.LuckyBlockId]
    end

    if isLuckyBlock and luckyBlockDir then
        -- Lucky block display
        displayName.Text = "Lucky Block"
        displayName.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        -- Hide money-related labels for lucky blocks
        moneyPerSecond.Visible = false
        money.Visible = false
        level.Visible = false
        
        -- Set mutation label to show lucky block display name
        mutation.Text = luckyBlockDir.DisplayName
        mutation.TextColor3 = Color3.fromRGB(255, 255, 255)
        mutation.Visible = true
        
        -- Use lucky block rarity
        rarity.Text = luckyBlockDir.Rarity.DisplayName
        rarity.TextColor3 = luckyBlockDir.Rarity.Color
        
        -- Hide fish type for lucky blocks
        fishType.Visible = false
        
        -- Hide offline earnings
        offlineFrame.Visible = false
        
        -- Hide traits for lucky blocks
        traitsFrame.Visible = false
    else
        -- Normal fish display
        local boosts = plot:Session("PlayerBoosts")::{[string]: number}
        local boostedTime = boosts[tostring(index)]
        local isBoosted = boostedTime and workspace:GetServerTimeNow() < boostedTime
        local multiplier = plot:GetMultiplier()
        local typeMultiplier = GameSettings.TypeMultipliers[fishData.FishData.Type] or 1
        local mutationMultiplier = MutationCmds.GetMutationMulti(fishData :: any)
        local traitMultiplier = TraitCmds.GetTraitMulti(fishData :: any)
        local fishMultiplier = (multiplier * typeMultiplier * mutationMultiplier * traitMultiplier) + (isBoosted and 0.5 or 0)

        displayName.Text = dir.DisplayName
        displayName.TextColor3 = Color3.fromRGB(255, 255, 255) -- Reset to default color
        rarity.Text = dir.Rarity.DisplayName
        rarity.TextColor3 = dir.Rarity.Color

        -- Show money-related labels for normal fish
        moneyPerSecond.Visible = true
        money.Visible = true
        level.Visible = true
        
        level.Text = `Level {fishData.FishData.Level}`
        moneyPerSecond.Text = `${Functions.NumberShorten(math.ceil((plot:GetMoneyPerSecond(index) or 0) * fishMultiplier))}/s`
        money.Text = `${Functions.NumberShorten(earnings + offlineEarnings)}`

        if offlineEarnings > 0 then
            offlineFrame.Visible = true
            offlineFrame.Text = `<font color="#FFFFFF">${Functions.NumberShorten(offlineEarnings)}</font> <font color="#a2a2a2">Made Offline</font>`
        else
            offlineFrame.Visible = false
        end

        local name, color = getFishType(fishData.FishData.Type)
        if color then
            fishType.TextColor3 = color
        end

        if name then
            fishType.Text = name
            fishType.Visible = true
        else
            fishType.Visible = false
        end

        local mutationName, mutationColor = getFishMutation(fishData.FishData.Mutation)
        if mutationColor then
            mutation.TextColor3 = mutationColor
        end

        if mutationName then
            mutation.Text = mutationName
            mutation.Visible = true
        else
            mutation.Visible = false
        end
        
        -- Update traits display
        local template = traitsFrame:FindFirstChild("Template")
        if template and template:IsA("ImageLabel") then
            -- Clear existing trait icons (except template)
            for _, child in ipairs(traitsFrame:GetChildren()) do
                if child:IsA("ImageLabel") and child ~= template then
                    child:Destroy()
                end
            end
            
            -- Get all traits for this fish
            local traitDataList = TraitCmds.GetTraitData(fishData.FishData)
            
            if #traitDataList > 0 then
                traitsFrame.Visible = true
                
                -- Sort traits alphabetically by ID
                table.sort(traitDataList, function(a, b)
                    return a._id < b._id
                end)
                
                -- Create trait icons
                for index, traitData in ipairs(traitDataList) do
                    local icon = template:Clone()
                    icon.Name = traitData._id
                    icon.Image = traitData.Icon
                    icon.Visible = true
                    icon.LayoutOrder = index
                    icon.Parent = traitsFrame
                end
            else
                traitsFrame.Visible = false
            end
        end
    end

    -- Mythical rarity rainbow gradient effect on rarity label
    local rarityToCheck = dir.Rarity
    if isLuckyBlock and luckyBlockDir then
        rarityToCheck = luckyBlockDir.Rarity
    end
    
    local rarityId = (rarityToCheck and (rarityToCheck :: any)._id) or nil
    if rarityId == "Mythical" or rarityId == "Exclusive" then
        local existing = rarity:FindFirstChild("RainbowGradientWrapped")
        if not existing or not existing:IsA("UIGradient") then
            local template = Assets:FindFirstChild("RainbowGradientWrapped")
            if template and template:IsA("UIGradient") then
                local gradient = template:Clone()
                gradient.Parent = rarity
                Functions.GradientScroll(gradient, 2.5)
            end
        end
    elseif rarityId == "God" then
        local existing = rarity:FindFirstChild("GodGradient")
        if not existing or not existing:IsA("UIGradient") then
            local template = Assets:FindFirstChild("GodGradient")
            if template and template:IsA("UIGradient") then
                local gradient = template:Clone()
                gradient.Parent = rarity
                Functions.GradientScroll(gradient, 2.5)
            end
        end
    elseif rarityId == "Secret" then
        local existing = rarity:FindFirstChild("SecretGradient")
        if not existing or not existing:IsA("UIGradient") then
            local template = Assets:FindFirstChild("SecretGradient")
            if template and template:IsA("UIGradient") then
                local gradient = template:Clone()
                gradient.Parent = rarity
                Functions.GradientScroll(gradient, 2.5)
            end
        end
    end
end

local function SetupButtons(plot: ClientPlot.Type, model: Model, upgradeFrame: Frame, placeFrame: Frame, boostFrame: Frame)
    if model:GetAttribute("_ButtonsInit") then
        return
    end
    model:SetAttribute("_ButtonsInit", true)
    local pedestalId = tonumber(model.Name)::number

    local upgradeButton = upgradeFrame:WaitForChild("Button")::GuiButton
    ButtonFX(upgradeButton)
    upgradeButton.Activated:Connect(function()
        local fish = plot:Save("Fish")::{[string]: PlotTypes.Fish}
        local fishData = fish[tostring(pedestalId)]

        if not fishData then
            return
        end

        local cost = plot:GetUpgradeCost(pedestalId)
        if not cost then
            NotificationCmds.Message("Fish is already at max level!", {
                Color = Color3.fromRGB(255, 0, 0),
            })
            return
        end

        if not plot:CanAfford(cost) then
            Network.Fire("LevelUp", plot:GetId(), pedestalId, fishData.UID)

            NotificationCmds.Message("Not enough money!", {
                Color = Color3.fromRGB(255, 0, 0),
            })
            return
        end

        Audio.Play("rbxassetid://124249358188422", script, 1, 0.6)

        plot:Invoke("UpgradeFish", pedestalId)
    end)

    local placeButton = placeFrame:WaitForChild("Button")::GuiButton
    ButtonFX(placeButton)
    placeButton.Activated:Connect(function()
        -- Check if there's a fish on this pedestal and if it's a lucky block
        local fish = plot:Save("Fish")::{[string]: PlotTypes.Fish}
        local fishData = fish[tostring(pedestalId)]
        
        if fishData then
            -- Fish exists - check if it's a lucky block
            local dir = Directory.Fish[fishData.FishId]
            if dir.LuckyBlockId then
                -- This is a lucky block - trigger opening
                plot:Invoke("OpenLuckyBlock", pedestalId)
                return
            end
        end
        
        -- No fish or not a lucky block - normal place behavior
        local currentFishData = FishCmds.GetCurrentFishData()
        if not currentFishData then
            NotificationCmds.Message("Equip a fish to place it!", {
                Color = Color3.fromRGB(255, 0, 0),
            })
            return
        end

        -- Check if this is a SpecialItemFish
        local fishSchema = Directory.Fish[currentFishData.FishId]
        if fishSchema and fishSchema.SpecialItemFish then
            -- local pumpkins = {
            --     ["Common Pumpkin"] = true,
            --     ["Epic Pumpkin"] = true,
            --     ["Mythical Pumpkin"] = true,
            -- }

            -- if pumpkins[fishSchema._id] then
            --     NotificationCmds.Message("You cannot place this, use it for Halloween Quests!", {
            --         Color = Color3.fromRGB(255, 0, 0),
            --     })
            --     return
            -- end

            NotificationCmds.Message("You cannot place this!", {
                Color = Color3.fromRGB(255, 0, 0),
            })
            return
        end

        -- playing here as verification from the server takes too long and sounds bad
        Audio.Play("rbxassetid://134182180985783", script, 1, 0.4)
        NotificationCmds.Message(`You placed down a {currentFishData.FishId}!`, {
            Color = Color3.fromRGB(11, 206, 255),
        })

        plot:Invoke("CreateFish", pedestalId, currentFishData.UID)
    end)

    local boostButton = boostFrame:WaitForChild("Button")::GuiButton
    ButtonFX(boostButton)
    boostButton.Activated:Connect(function()
        local success, msg = plot:Invoke("PlayerBoost", pedestalId)

        if not success then
            if msg then
                NotificationCmds.Message(msg, {
                    Color = Color3.fromRGB(255, 0, 0),
                })
            end
            return
        end

        -- Play boost sound (local-only)
        local boostSpeed = nextBoostPlaybackSpeed()
        Audio.Play("rbxassetid://133458542234750", script, boostSpeed, 0.3)
    end)
end

-- Track animation states to prevent multiple animations and disable prompts
local pedestalAnimationStates: {[ClientPlot.Type]: {[number]: boolean}} = {}

local function playLuckyBlockAnimation(plot: ClientPlot.Type, pedestalId: number, visualData: {LuckyBlockTypes.lucky_block_visual_data})
    -- Initialize animation tracking
    if not pedestalAnimationStates[plot] then
        pedestalAnimationStates[plot] = {}
    end
    
    -- Prevent multiple animations on the same pedestal
    if pedestalAnimationStates[plot][pedestalId] then
        return
    end
    
    pedestalAnimationStates[plot][pedestalId] = true
    
    -- Get the pedestal model and fish model
    local pedestalModel = pedestalModels[plot] and pedestalModels[plot][pedestalId]
    if not pedestalModel then
        pedestalAnimationStates[plot][pedestalId] = false
        return
    end
    
    -- Disable all proximity prompts during animation
    local originalProximityStates = {}
    if pedestalModel.SellProximity then
        originalProximityStates.SellProximity = pedestalModel.SellProximity.Enabled
        pedestalModel.SellProximity.Enabled = false
    end
    if pedestalModel.PickupProximity then
        originalProximityStates.PickupProximity = pedestalModel.PickupProximity.Enabled
        pedestalModel.PickupProximity.Enabled = false
    end
    if pedestalModel.BoostProximity then
        originalProximityStates.BoostProximity = pedestalModel.BoostProximity.Enabled
        pedestalModel.BoostProximity.Enabled = false
    end
    if pedestalModel.StealProximity then
        originalProximityStates.StealProximity = pedestalModel.StealProximity.Enabled
        pedestalModel.StealProximity.Enabled = false
    end
    
    -- Store original fish model and position
    local originalFishModel = pedestalModel.Model
    local _originalBillboard = pedestalModel.Billboard
    local originalPivot = originalFishModel:GetPivot()
    
    -- Get the nameplate and surface GUI for hiding during animation
    local model = plot:YieldModel()
    local pedestals = model:WaitForChild("Pedestals")::Model
    local pedestalModelInstance = pedestals:FindFirstChild(tostring(pedestalId))
    local nameplate = pedestalModelInstance and pedestalModelInstance:FindFirstChild("Nameplate") :: BasePart?
    local surfaceGui = nameplate and nameplate:FindFirstChild("SurfaceGui") :: SurfaceGui?
    
    -- Animation parameters with variable speed (fast to slow)
    local animationDuration = 5 -- seconds total
    
    -- Calculate variable intervals for each item (fast start, slow end)
    local intervals = {}
    local totalWeight = 0
    
    -- Create exponential curve for timing (starts fast, ends slow)
    for i = 1, #visualData do
        local progress = (i - 1) / (#visualData - 1) -- 0 to 1
        local weight = math.exp(progress * 3.5) -- Exponential curve: fast -> slow (more dramatic)
        intervals[i] = weight
        totalWeight = totalWeight + weight
    end
    
    -- Normalize intervals to fit total duration
    for i = 1, #visualData do
        intervals[i] = (intervals[i] / totalWeight) * animationDuration
    end
    
    task.spawn(function()
        -- Hide nameplate and surface GUI during animation
        if nameplate then
            nameplate.Transparency = 1
        end
        if surfaceGui then
            surfaceGui.Enabled = false
        end
        
        -- Attach pedestal particles to the Base part
        local basePart = pedestalModelInstance and pedestalModelInstance:FindFirstChild("Base") :: BasePart?
        local pedestalParticlesFolder = game.ReplicatedStorage.Assets.Particles.LuckyBlocks:FindFirstChild("Pedestal")
        local pedestalParticles = {}
        
        -- Pre-animation: Shrink and grow the lucky block before showing visual data
        if originalFishModel and originalFishModel.Parent then
            -- Get initial scale
            local initialScale = originalFishModel:GetScale()
            
            -- Attach shrink particles to the lucky block primary part
            local particleTemplate = game.ReplicatedStorage.Assets.Particles.LuckyBlocks:FindFirstChild("LuckyBlockShrinkParticles")
            local attachedParticles = {}
            local particleAttachment = nil
            if particleTemplate and originalFishModel.PrimaryPart then
                -- Create attachment at center of primary part
                particleAttachment = Instance.new("Attachment")
                particleAttachment.Position = Vector3.new(0, 0, 0)
                particleAttachment.Parent = originalFishModel.PrimaryPart
                
                -- Attach particle to the attachment
                local particleClone = particleTemplate:Clone()
                particleClone.Parent = particleAttachment
                table.insert(attachedParticles, particleClone)
            end
            
            -- Create decals on all sides of every BasePart
            local createdDecals = {}
            for _, descendant in ipairs(originalFishModel:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    local faces = {
                        Enum.NormalId.Front,
                        Enum.NormalId.Back,
                        Enum.NormalId.Left,
                        Enum.NormalId.Right,
                        Enum.NormalId.Top,
                        Enum.NormalId.Bottom
                    }
                    
                    for _, face in ipairs(faces) do
                        local decal = Instance.new("Decal")
                        decal.Texture = LUCKY_BLOCK_DECAL_TEXTURE
                        decal.Face = face
                        decal.Transparency = 1 -- Start invisible
                        decal.Parent = descendant
                        table.insert(createdDecals, decal)
                    end
                end
            end
            
            -- Phase 1: Shrink to configured scale while fading in decals
            local shrinkTweenInfo = TweenInfo.new(
                LUCKY_BLOCK_SHRINK_DURATION,
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.InOut
            )
            local shrinkTween = Functions.Tween(originalFishModel, {
                Scale = initialScale * LUCKY_BLOCK_SHRINK_SCALE
            }, shrinkTweenInfo)
            
            -- Fade in all decals during shrink
            for _, decal in ipairs(createdDecals) do
                Functions.Tween(decal, {
                    Transparency = 0
                }, shrinkTweenInfo)
            end

            -- Play grow sound when lucky block starts shrinking
            Audio.Play("rbxassetid://70646733921269", originalPivot.Position, 1, 0.5, 150)
            
            if shrinkTween and shrinkTween.Completed then
                shrinkTween.Completed:Wait()
            end
            
            -- After shrink completes: clean up textures and set to white
            for _, descendant in ipairs(originalFishModel:GetDescendants()) do
                if descendant:IsA("SurfaceAppearance") then
                    descendant:Destroy()
                elseif descendant:IsA("MeshPart") then
                    (descendant :: MeshPart).TextureID = ""
                    (descendant :: MeshPart).Color = Color3.fromRGB(255, 255, 255)
                elseif descendant:IsA("BasePart") then
                    (descendant :: BasePart).Color = Color3.fromRGB(255, 255, 255)
                end
            end
            
            -- Phase 2: Grow to larger scale and fade all parts to transparent
            local growTweenInfo = TweenInfo.new(
                LUCKY_BLOCK_GROW_DURATION,
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.Out
            )
            
            -- Play grow sound when lucky block starts growing
            Audio.Play("rbxassetid://130401084353873", originalPivot.Position, 1, 1, 150)
            
            -- Attach grow particles to the lucky block
            local growParticlesFolder = game.ReplicatedStorage.Assets.Particles.LuckyBlocks:FindFirstChild("Grow")
            local growAttachments = {}
            if growParticlesFolder and originalFishModel.PrimaryPart then
                for _, child in ipairs(growParticlesFolder:GetChildren()) do
                    if child:IsA("Attachment") then
                        local attachClone = child:Clone()
                        attachClone.Parent = originalFishModel.PrimaryPart
                        table.insert(growAttachments, attachClone)
                        
                        -- Emit all particles in this attachment
                        for _, particle in ipairs(attachClone:GetChildren()) do
                            if particle:IsA("ParticleEmitter") then
                                Functions.Emit(particle)
                            end
                        end
                    end
                end
            end
            
            -- Start the grow tween
            local growTween = Functions.Tween(originalFishModel, {
                Scale = initialScale * LUCKY_BLOCK_GROW_SCALE
            }, growTweenInfo)
            
            -- Simultaneously fade all parts and decals to transparency 1
            local fadeTweens = {}
            
            -- Fade out the created decals
            for _, decal in ipairs(createdDecals) do
                local fadeTween = Functions.Tween(decal, {
                    Transparency = 1
                }, growTweenInfo)
                table.insert(fadeTweens, fadeTween)
            end
            
            -- Disable attached particles before fading
            for _, particle in ipairs(attachedParticles) do
                if particle and particle:IsA("ParticleEmitter") then
                    particle:Destroy()
                end
            end
            
            -- Fade out all parts
            for _, descendant in ipairs(originalFishModel:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    local fadeTween = Functions.Tween(descendant, {
                        Transparency = 1
                    }, growTweenInfo)
                    table.insert(fadeTweens, fadeTween)
                elseif descendant:IsA("ParticleEmitter") then
                    -- Fade particle effects if present
                    (descendant :: ParticleEmitter).Enabled = false
                elseif descendant:IsA("Beam") then
                    (descendant :: Beam).Enabled = false
                elseif descendant:IsA("Trail") then
                    (descendant :: Trail).Enabled = false
                end
            end
            
            -- Wait for grow animation to complete
            if growTween and growTween.Completed then
                growTween.Completed:Wait()
            end

            if basePart and pedestalParticlesFolder then
                for _, child in ipairs(pedestalParticlesFolder:GetChildren()) do
                    if child:IsA("ParticleEmitter") then
                        local particleClone = child:Clone()
                        particleClone.Parent = basePart
                        table.insert(pedestalParticles, particleClone)
                    end
                end
            end
        end
        
        -- Hide original model after animation
        originalFishModel.Parent = nil
        
        -- Cycle through each visual data item with variable timing
        for i, visual in ipairs(visualData) do
            if not pedestalAnimationStates[plot][pedestalId] then
                break -- Animation was cancelled
            end
            
            -- Create temporary fish model for this visual
            local fishDir = Directory.Fish[visual.FishId]
            if fishDir and fishDir._script then
                local tempFishModel = fishDir._script:WaitForChild("Model"):Clone()::Model
                
                -- Apply fish type styling
                local plotFishFolder = workspace:WaitForChild("__THINGS"):WaitForChild("PlotFish")
                local parent = plotFishFolder
                
                if visual.Type == "Shiny" then
                    parent = plotFishFolder:WaitForChild("Shiny")
                elseif visual.Type == "Rainbow" then
                    parent = plotFishFolder:WaitForChild("Rainbow")
                elseif visual.Type == "Gold" then
                    parent = plotFishFolder:WaitForChild("Gold")
                end
                
                -- Apply mutation if present
                if visual.Mutation then
                    local mutationDir = Directory.Mutations[visual.Mutation]
                    if mutationDir then
                        mutationDir.ApplyToModel(tempFishModel)
                    end
                end
                
                -- Position the temporary model at the original position
                tempFishModel:PivotTo(originalPivot)
                tempFishModel:SetAttribute("PedestalFish", true)
                tempFishModel:SetAttribute("_PlotId", plot:GetId())
                tempFishModel:SetAttribute("_TempAnimation", true)
                tempFishModel:AddTag("SwimmingFish")
                tempFishModel.Parent = parent
                
                -- Play reveal sound for each fish (except the last one)
                if i <= #visualData then
                    Audio.Play("rbxassetid://73644741132942", originalPivot.Position, 1, 0.5, 150)
                end
                
                -- Create temporary billboard for this visual
                local tempFishData = {
                    UID = "temp-animation",
                    FishId = visual.FishId,
                    FishData = {
                        UID = "temp-animation",
                        FishId = visual.FishId,
                        Type = visual.Type,
                        Level = 1,
                        Mutation = visual.Mutation,
                        Shiny = false,
                        CreateTime = workspace:GetServerTimeNow(),
                        BaseTime = workspace:GetServerTimeNow(),
                    },
                    LastClaimTime = 0,
                    CreateTime = workspace:GetServerTimeNow(),
                    Earnings = 0,
                    OfflineEarnings = 0,
                }
                local tempBillboard = SetupBillboard(tempFishModel, tempFishData)
                
                -- Update the billboard with visual data
                local frame = tempBillboard:WaitForChild("Frame")::Frame
                local displayName = frame:WaitForChild("DisplayName")::TextLabel
                local rarity = frame:WaitForChild("Rarity")::TextLabel
                local level = frame:WaitForChild("Level")::TextLabel
                local fishType = frame:WaitForChild("FishType")::TextLabel
                local mutation = frame:WaitForChild("Mutation")::TextLabel
                
                -- Hide money and level info during animation
                frame:WaitForChild("MoneyPerSecond"):Destroy()
                frame:WaitForChild("Money"):Destroy()
                frame:WaitForChild("OfflineEarnings"):Destroy()
                level.Visible = false
                
                displayName.Text = fishDir.DisplayName
                rarity.Text = fishDir.Rarity.DisplayName
                rarity.TextColor3 = fishDir.Rarity.Color
                
                -- Show fish type
                local typeName, typeColor = getFishType(visual.Type)
                if typeName then
                    fishType.Text = typeName
                    fishType.TextColor3 = typeColor or Color3.fromRGB(255, 255, 255)
                    fishType.Visible = true
                else
                    fishType.Visible = false
                end
                
                -- Show mutation if present
                if visual.Mutation then
                    local mutationDir = Directory.Mutations[visual.Mutation]
                    if mutationDir then
                        mutation.Text = mutationDir.DisplayName
                        mutation.TextColor3 = mutationDir.Color
                        mutation.Visible = true
                    else
                        mutation.Visible = false
                    end
                else
                    mutation.Visible = false
                end
                
                -- Wait for the variable interval (fast at start, slow at end)
                task.wait(intervals[i])
                
                -- Play final reveal sound on the last fish
                if i == #visualData then-- Extra wait to let the final fish be visible longer
                    task.wait(0.25)

                    Audio.Play("rbxassetid://78632974820364", originalPivot.Position, 1, 1, 150)
                    Audio.Play("rbxassetid://81968496022483", originalPivot.Position, 1, 1, 150)
                    
                    -- Disable pedestal particles on final reveal
                    for _, particle in ipairs(pedestalParticles) do
                        if particle and particle:IsA("ParticleEmitter") then
                            particle.Enabled = false
                        end
                    end
                    
                    -- Delete pedestal particles after 3 seconds
                    task.delay(3, function()
                        for _, particle in ipairs(pedestalParticles) do
                            pcall(function() particle:Destroy() end)
                        end
                    end)
                end
                
                -- Clean up temporary model and billboard
                pcall(function() tempFishModel:Destroy() end)
                pcall(function() tempBillboard:Destroy() end)
            end
        end
        
        -- Animation complete - DON'T restore original model, let the system show the new fish
        if pedestalAnimationStates[plot][pedestalId] then
            -- Clean up the old tracked model since it's been replaced
            if originalFishModel then
                pcall(function() originalFishModel:Destroy() end)
            end
            
            -- Clear the tracked model so UpdatePedestal will create the new one
            if pedestalModels[plot] and pedestalModels[plot][pedestalId] then
                local tracked = pedestalModels[plot][pedestalId]
                -- Clean up old proximity prompts
                if tracked.SellProximity then pcall(function() tracked.SellProximity:Destroy() end) end
                if tracked.PickupProximity then pcall(function() tracked.PickupProximity:Destroy() end) end
                if tracked.BoostProximity then pcall(function() tracked.BoostProximity:Destroy() end) end
                if tracked.StealProximity then pcall(function() tracked.StealProximity:Destroy() end) end
                pedestalModels[plot][pedestalId] = nil
            end
            
            pedestalAnimationStates[plot][pedestalId] = false
            
            -- Restore nameplate and surface GUI after animation
            if nameplate then
                nameplate.Transparency = 0
            end
            if surfaceGui then
                surfaceGui.Enabled = true
            end
            
            -- Force update the pedestal to show the final result (will create new fish model)
            local model = plot:YieldModel()
            local pedestals = model:WaitForChild("Pedestals")::Model
            local pedestalModelInstance = pedestals:FindFirstChild(tostring(pedestalId))
            if pedestalModelInstance then
                UpdatePedestal(plot, pedestalModelInstance :: Model)
                
                -- Add reveal particle effect to the final fish model
                task.wait(0.1) -- Small wait to ensure model is created
                if pedestalModels[plot] and pedestalModels[plot][pedestalId] then
                    local baseVector = Vector3.new(3.32, 3.32, 1.66)
                    local finalFishModel = pedestalModels[plot][pedestalId].Model
                    local revealAttachment = game.ReplicatedStorage.Assets.Particles.LuckyBlocks:FindFirstChild("Reveal")
                    if revealAttachment and finalFishModel and finalFishModel.PrimaryPart then
                        local revealClone = revealAttachment:Clone()
                        local mainFishVFX = finalFishModel:FindFirstChild("VFX")::BasePart?
                        local revealCloneVectory = mainFishVFX and mainFishVFX.Size or finalFishModel.PrimaryPart.Size
                        local mult = revealCloneVectory.Magnitude / baseVector.Magnitude
                        
                        -- Scale the attachment using a temporary model and part
                        local tempModel = Instance.new("Model")
                        local tempPart = Instance.new("Part")
                        tempPart.Parent = tempModel
                        tempModel.PrimaryPart = tempPart
                        revealClone.Parent = tempPart
                        tempModel:ScaleTo(mult)
                        
                        -- Move the scaled attachment to the fish
                        revealClone.Parent = finalFishModel.PrimaryPart
                        tempModel:Destroy()
                        
                        -- Emit particles from all ParticleEmitters in the attachment
                        for _, child in ipairs(revealClone:GetChildren()) do
                            if child:IsA("ParticleEmitter") then
                                Functions.Emit(child)
                            end
                        end
                        
                        -- Destroy after 4 seconds
                        task.delay(4, function()
                            pcall(function() revealClone:Destroy() end)
                        end)
                    end
                end
            end
        end
    end)
end

function UpdatePedestal(plot: ClientPlot.Type, model: Model)
    local pedestalId = tonumber(model.Name)::number
    local fish = plot:Save("Fish")::{[string]: PlotTypes.Fish}

    local nameplate = model:WaitForChild("Nameplate")::BasePart
    local base = model:WaitForChild("Base")::BasePart
    local sellAttachment = base:WaitForChild("SellAttachment")::Attachment
    local pickupAttachment = base:WaitForChild("PickupAttachment")::Attachment
    local surfaceGui = nameplate:WaitForChild("SurfaceGui")::SurfaceGui

    -- Hook Claim part touch once per pedestal; print once per continuous contact by the local player
    if plot:IsLocal() then
        if not model:GetAttribute("_ClaimHooked") then
            local claim = model:FindFirstChild("Claim", true)
            local claimBase = model:FindFirstChild("ClaimBase", true)
            if claim and claim:IsA("BasePart") and claimBase and claimBase:IsA("BasePart") then
                model:SetAttribute("_ClaimHooked", true)
                local touchingParts: {[BasePart]: boolean} = {}
                
                claim.Touched:Connect(function(other: BasePart)
                    local character = LocalPlayer and LocalPlayer.Character
                    if not character or not other or not other:IsDescendantOf(character) then return end
                    
                    -- Don't allow parts from tools to trigger claims (check if descendant of Tool)
                    local parent = other.Parent
                    while parent do
                        if parent:IsA("Tool") then return end
                        parent = parent.Parent
                    end
                    
                    if not touchingParts[other] then
                        touchingParts[other] = true
                    end

                    if model:GetAttribute("_ClaimActive") ~= true then
                        -- Set active immediately to debounce before any yields
                        model:SetAttribute("_ClaimActive", true)
                        -- Play pedestal claim bounce animation only for unlocked pedestals
                        playClaimBounce(claim)
                        local success, amount = plot:Invoke("ClaimEarnings", pedestalId)
                        -- Play claim sound (coins collected)
                        if success and (amount or 0) > 0 then
                            local playbackSpeed = nextClaimPlaybackSpeed()
                            Audio.Play("rbxassetid://132697192191142", script, playbackSpeed, 0.6)
                            Functions.Emit(claimBase)
                        end
                    end
                end)
                claim.TouchEnded:Connect(function(other: BasePart)
                    local character = LocalPlayer and LocalPlayer.Character
                    if not character or not other or not other:IsDescendantOf(character) then return end
                    
                    -- Don't allow parts from tools to trigger claims (check if descendant of Tool)
                    local parent = other.Parent
                    while parent do
                        if parent:IsA("Tool") then return end
                        parent = parent.Parent
                    end
                    
                    touchingParts[other] = nil
                    -- If no more local parts are touching, reset active state
                    local any = false
                    for _ in pairs(touchingParts) do
                        any = true
                        break
                    end
                    if not any then
                        model:SetAttribute("_ClaimActive", false)
                    end
                end)
            end
        end
    end

    local frame = surfaceGui:WaitForChild("Frame")::Frame
    local upgradeFrame = frame:WaitForChild("Upgrade")::Frame
    local placeFrame = frame:WaitForChild("Place")::Frame
    local boostFrame = frame:WaitForChild("Boost")::Frame

    local boostTimer = boostFrame:WaitForChild("TextLabel")::TextLabel
    local boosts = plot:Session("PlayerBoosts")::{[string]: number}
    local boostedTime = boosts[tostring(pedestalId)]
    local isBoosted = boostedTime and workspace:GetServerTimeNow() < boostedTime

    SetupButtons(plot, model, upgradeFrame, placeFrame, boostFrame)

    if plot:IsLocal() then
        local fishData = fish[tostring(pedestalId)]
        if fishData then
            -- Check if this is a lucky block
            local dir = Directory.Fish[fishData.FishId]
            local isLuckyBlock = dir.LuckyBlockId ~= nil
            
            if isLuckyBlock then
                -- Show Place frame with "Open!" text for lucky blocks
                upgradeFrame.Visible = false
                placeFrame.Visible = true
                boostFrame.Visible = false
                
                -- Update the place button text to say "Open!"
                local placeButton = placeFrame:WaitForChild("Button")::GuiButton
                local placeTextLabel = placeButton:WaitForChild("TextLabel")::TextLabel
                placeTextLabel.Text = "Open!"
            else
                -- Normal fish upgrade display
                upgradeFrame.Visible = true
                placeFrame.Visible = false
                boostFrame.Visible = false

                local textLabel = upgradeFrame:WaitForChild("TextLabel")::TextLabel
                if fishData.FishData.Level == GameSettings.MaxLevel then
                    textLabel.Text = `Level {fishData.FishData.Level}`
                else
                    textLabel.Text = `Level {fishData.FishData.Level} -> Level {fishData.FishData.Level + 1}`
                end

                local upgradeButton = upgradeFrame:FindFirstChild("Button")::ImageButton
                local buttonText = upgradeButton:FindFirstChild("TextLabel")::TextLabel

                local cost = plot:GetUpgradeCost(pedestalId)
                if not cost then
                    buttonText.Text = "Max!"
                else
                    buttonText.Text = `${Functions.NumberShorten(cost)}`
                    -- Ensure button image reflects affordability on first render
                    UpdateUpgradeButtonImage(plot, model)
                end
            end

            -- Remove any existing place prompt since we're using GUI buttons
            local existingPlacePrompt = sellAttachment:FindFirstChild("PlacePrompt")
            if existingPlacePrompt and existingPlacePrompt:IsA("ProximityPrompt") then
                existingPlacePrompt:Destroy()
            end
        else
            upgradeFrame.Visible = false
            placeFrame.Visible = true
            boostFrame.Visible = false

            -- Reset place button text for empty pedestals
            local placeButton = placeFrame:WaitForChild("Button")::GuiButton
            local placeTextLabel = placeButton:WaitForChild("TextLabel")::TextLabel
            placeTextLabel.Text = "Place"

            -- Ensure a proximity prompt exists to allow placing via prompt too
            local placePromptAny = sellAttachment:FindFirstChild("PlacePrompt")
            local placePrompt: ProximityPrompt? = placePromptAny and placePromptAny:IsA("ProximityPrompt") and (placePromptAny :: ProximityPrompt) or nil
            if not placePrompt then
                local created = SetupProximity("Place", 0, Enum.KeyCode.E, sellAttachment)
                created.Name = "PlacePrompt"
                created.Triggered:Connect(function(_player: Player)
                    local fishData = FishCmds.GetCurrentFishData()
                    if not fishData then
                        NotificationCmds.Message("Equip a fish to place it!", {
                            Color = Color3.fromRGB(255, 0, 0),
                        })
                        return
                    end

                    -- Check if this is a SpecialItemFish
                    local fishSchema = Directory.Fish[fishData.FishId]
                    if fishSchema and fishSchema.SpecialItemFish then
                        local pumpkins = {
                            ["Common Pumpkin"] = true,
                            ["Epic Pumpkin"] = true,
                            ["Mythical Pumpkin"] = true,
                        }

                        if pumpkins[fishSchema._id] then
                            NotificationCmds.Message("You cannot place this, use it for Halloween Quests!", {
                                Color = Color3.fromRGB(255, 0, 0),
                            })
                            return
                        end

                        NotificationCmds.Message("You cannot place this!", {
                            Color = Color3.fromRGB(255, 0, 0),
                        })
                        return
                    end

                    -- playing here as verification from the server takes too long and sounds bad
                    Audio.Play("rbxassetid://134182180985783", script, 1, 0.4)
                    NotificationCmds.Message(`You placed down a {fishData.FishId}!`, {
                        Color = Color3.fromRGB(11, 206, 255),
                    })

                    plot:Invoke("CreateFish", pedestalId, fishData.UID)
                end)
                placePrompt = created
            end
        end 
    else
        upgradeFrame.Visible = false
        placeFrame.Visible = false
        boostFrame.Visible = true

        if isBoosted then
            boostTimer.Text = `{Functions.FormatTime(boostedTime - workspace:GetServerTimeNow())}`
            boostTimer.TextColor3 = Color3.fromRGB(255, 255, 0)
        else
            boostTimer.Text = "00:00"
            boostTimer.TextColor3 = Color3.fromRGB(255, 0, 0)
        end
    end

    local boostAttachment = nameplate:WaitForChild("BoostedAttachment")::Attachment
    local boostBillboard = boostAttachment:WaitForChild("BillboardGui")::BillboardGui
    boostBillboard.Enabled = isBoosted

    local fishData = fish[tostring(pedestalId)]
    if fishData and pedestalModels[plot] and not pedestalModels[plot][pedestalId] then
        local dir = Directory.Fish[fishData.FishId]
        local fishModel = dir._script:WaitForChild("Model"):Clone()::Model
        local plotFishFolder = workspace:WaitForChild("__THINGS"):WaitForChild("PlotFish")
        local plotFishShiny = plotFishFolder:WaitForChild("Shiny")::Model
        local plotFishRainbow = plotFishFolder:WaitForChild("Rainbow")::Model
        local plotFishGold = plotFishFolder:WaitForChild("Gold")::Model
        local parent = plotFishFolder

        if fishData.FishData.Type == "Shiny" then
            parent = plotFishShiny
        elseif fishData.FishData.Type == "Rainbow" then
            parent = plotFishRainbow
        elseif fishData.FishData.Type == "Gold" then
            parent = plotFishGold
        end

        if fishData.FishData.Mutation then
            local mutationDir = Directory.Mutations[fishData.FishData.Mutation]
            if mutationDir then
                mutationDir.ApplyToModel(fishModel)
            end
        end
        
        -- Apply trait visual effects to the model
        if fishData.FishData.Traits then
            for traitId, hasTrait in pairs(fishData.FishData.Traits) do
                if hasTrait then
                    local traitData = Directory.Traits[traitId]
                    if traitData and traitData.ApplyToModel then
                        traitData.ApplyToModel(fishModel)
                    end
                end
            end
        end

        local primaryPart = fishModel.PrimaryPart
        if primaryPart then
            primaryPart.Anchored = true
        end

        fishModel:PivotTo((base:GetPivot() + Vector3.new(0, base.Size.Y / 2, 0) + Vector3.new(0, fishModel:GetExtentsSize().Y / 2, 0) + Vector3.new(0, 2, 0) + Vector3.new(0, dir.PedestalOffset or 0, 0)) * CFrame.Angles(0, math.rad(180), 0))
        fishModel:SetAttribute("PedestalFish", true)
        -- Tie the fish model to this plot for reliable cleanup
        fishModel:SetAttribute("_PlotId", plot:GetId())
        fishModel:AddTag("SwimmingFish")
        fishModel.Parent = parent

        local sellProximity: ProximityPrompt?
        local pickupProximity: ProximityPrompt?
        local stealProximity: ProximityPrompt?
        local boostProximity: ProximityPrompt?

        if plot:IsLocal() then
            -- Check if this is a lucky block
            local fishDir = Directory.Fish[fishData.FishId]
            local isLuckyBlock = fishDir.LuckyBlockId ~= nil
            
            if isLuckyBlock then
                -- Create "Open" proximity prompt for lucky blocks
                sellProximity = SetupProximity("Open", 2, Enum.KeyCode.E, sellAttachment)
                
                assert(sellProximity).Triggered:Connect(function(player: Player)
                    -- Simply invoke the lucky block opening - server will handle broadcasting
                    plot:Invoke("OpenLuckyBlock", pedestalId)
                end)
            else
                -- Normal fish sell proximity
                local sellPrice = plot:GetSellPrice(pedestalId)
                local sellPriceString = sellPrice and `Sell: ${Functions.NumberShorten(sellPrice)}` or "Sell"
                sellProximity = SetupProximity(sellPriceString, 3, Enum.KeyCode.E, sellAttachment)
                
                assert(sellProximity).Triggered:Connect(function(player: Player)
                    local sellPrice = plot:GetSellPrice(pedestalId)
                    if not sellPrice then
                        return
                    end
                    
                    -- Check if fish is Mythical or above and prompt for confirmation
                    local schema = Directory.Fish[fishData.FishId]
                    if schema and schema.Rarity then
                        local rarityId = schema.Rarity._id
                        if rarityId == "Mythical" or rarityId == "Exclusive" or rarityId == "God" or rarityId == "Secret" then
                            local rarityName = schema.Rarity.DisplayName
                            local confirmed = Message.new(`Are you sure? This is a {rarityName} fish you're selling!`, true)
                            if not confirmed then
                                return
                            end
                        end
                    end
                    
                    local success = plot:Invoke("SellFish", pedestalId)
                    if success then
                        if not schema then
                            NotificationCmds.Message("Could not find fish data!", {
                                Color = Color3.fromRGB(255, 0, 0),
                            })
                            return
                        end

                        local displayName = (schema and schema.DisplayName) or fishData.FishId
                        Audio.Play("rbxassetid://132697192191142", script, 1, 0.6)
                        local textAmount = sellPrice and `You sold a {displayName} for ${Functions.NumberShorten(sellPrice)}!` or `You sold a {displayName}!`
                        NotificationCmds.Message(textAmount, {
                            Color = Color3.fromRGB(0, 255, 0),
                        })
                    else
                        NotificationCmds.Message("Something went wrong!", {
                            Color = Color3.fromRGB(255, 0, 0),
                        })
                    end
                end)
            end
            
            pickupProximity = SetupProximity("Pickup", 1, Enum.KeyCode.F, pickupAttachment)

            assert(pickupProximity).Triggered:Connect(function(player: Player)
                -- Inventory capacity check before attempting pickup
                local invLimit = plot:Save("InventorySize")::number?
                local saveData = Save.Get()
                if typeof(invLimit) == "number" and saveData and typeof(saveData.Inventory) == "table" then
                    local invCount = #(saveData.Inventory :: {any})
                    if invCount >= (invLimit :: number) then
                        NotificationCmds.Message("Your inventory is full!", { Color = Color3.fromRGB(255, 0, 0) })
                        local productId = ProductCmds.GetProductId("More Space")
                        if productId and invLimit < GameSettings.MaxInventoryUpgraded3 then
                            Marketplace.Prompt(Players.LocalPlayer, productId, true)
                        end
                        return
                    end
                end

                local success = plot:Invoke("PickupFish", pedestalId)
                if success then
                    Audio.Play("rbxassetid://128246360956937", script, 1, 0.1)
                end
            end)
        else
            stealProximity = SetupProximity("Steal", 3, Enum.KeyCode.E, sellAttachment)
            boostProximity = SetupProximity("Boost", 0, Enum.KeyCode.F, pickupAttachment)

            assert(stealProximity).Triggered:Connect(function(player: Player)
                Network.Fire("Steal", plot:GetId(), pedestalId, fishData.UID)
            end)

            assert(boostProximity).Triggered:Connect(function(player: Player)
                local success, msg = plot:Invoke("PlayerBoost", pedestalId)

                if not success then
                    if msg then
                        NotificationCmds.Message(msg, {
                            Color = Color3.fromRGB(255, 0, 0),
                        })
                    end
                    return
                end
        
                -- Play boost sound (local-only)
                local boostSpeed = nextBoostPlaybackSpeed()
                Audio.Play("rbxassetid://133458542234750", script, boostSpeed, 0.3)
            end)
        end
       
        local billboard = SetupBillboard(fishModel, fishData)
        UpdateBillboard(plot, pedestalId, billboard)

        pedestalModels[plot][pedestalId] = {
            Model = fishModel,
            Billboard = billboard,
            SellProximity = sellProximity,
            PickupProximity = pickupProximity,
            StealProximity = stealProximity,
            BoostProximity = boostProximity,
        }
    elseif not fishData and pedestalModels[plot] and pedestalModels[plot][pedestalId] then
        local fishModel = pedestalModels[plot][pedestalId]
        fishModel.Model:Destroy()
        if fishModel.SellProximity then
            fishModel.SellProximity:Destroy()
        end
        if fishModel.PickupProximity then
            fishModel.PickupProximity:Destroy()
        end
        if fishModel.StealProximity then
            fishModel.StealProximity:Destroy()
        end
        if fishModel.BoostProximity then
            fishModel.BoostProximity:Destroy()
        end
        pedestalModels[plot][pedestalId] = nil
    end

    -- If we have a tracked model, refresh billboard and sell prompt text
    if pedestalModels[plot][pedestalId] then
        -- Update the sell proximity prompt's ActionText to reflect the latest price
        local tracked = pedestalModels[plot][pedestalId]
        if plot:IsLocal() and tracked.SellProximity then
            local currentFishData = fish[tostring(pedestalId)]
            if currentFishData then
                local currentDir = Directory.Fish[currentFishData.FishId]
                local isLuckyBlock = currentDir.LuckyBlockId ~= nil
                
                if isLuckyBlock then
                    -- Keep "Open" text for lucky blocks
                    if tracked.SellProximity.ActionText ~= "Open" then
                        tracked.SellProximity.ActionText = "Open"
                    end
                else
                    -- Update sell price text for normal fish
                    local latestPrice = plot:GetSellPrice(pedestalId)
                    local latestText = latestPrice and `Sell: ${Functions.NumberShorten(latestPrice)}` or "Sell"
                    if tracked.SellProximity.ActionText ~= latestText then
                        tracked.SellProximity.ActionText = latestText
                    end
                end
            end
        end
        UpdateBillboard(plot, pedestalId, pedestalModels[plot][pedestalId].Billboard)
    end
end

function plotCreated(plot: ClientPlot.Type)
    pedestalModels[plot] = {}

    local model = plot:YieldModel()
    local pedestals = model:WaitForChild("Pedestals")::Model

    -- Store references to all pedestal instances
    pedestalInstances[plot] = {}
    for _, child in pedestals:GetChildren() do
        local pedestalId = tonumber(child.Name)
        if pedestalId then
            pedestalInstances[plot][pedestalId] = child::Model
        end
    end

    -- Initialize pedestal visibility based on ExtraFloors
    UpdatePedestalVisibility(plot)

    for _, child in pedestals:GetChildren() do
        UpdatePedestal(plot, child::Model)
    end

    plot:SaveUpdated("Fish"):Connect(function(newFish: {[string]: PlotTypes.Fish})
        if pedestalInstances[plot] then
            for _, child in pairs(pedestalInstances[plot]) do
                UpdatePedestal(plot, child)
            end
        end
    end)

    plot:SaveUpdated("PaidIndex"):Connect(function(newIndex: number)
        if pedestalInstances[plot] then
            for _, child in pairs(pedestalInstances[plot]) do
                UpdatePedestal(plot, child)
            end
        end
    end)

    -- Money changes: flip the upgrade button image when affordability changes
    plot:SaveUpdated("Money"):Connect(function(_value: number)
        if pedestalInstances[plot] then
            for _, child in pairs(pedestalInstances[plot]) do
                UpdateUpgradeButtonImage(plot, child)
            end
        end
    end)

    plot:SessionUpdated("PlayerBoosts"):Connect(function(newBoosts: {[string]: number})
        if pedestalInstances[plot] then
            for _, child in pairs(pedestalInstances[plot]) do
                UpdatePedestal(plot, child)
            end
        end
    end)

    -- Listen for ExtraFloors changes and update pedestal visibility
    plot:SaveUpdated("ExtraFloors"):Connect(function(_value: number?)
        UpdatePedestalVisibility(plot)
        -- Update all pedestals after visibility changes
        if pedestalInstances[plot] then
            for _, child in pairs(pedestalInstances[plot]) do
                UpdatePedestal(plot, child)
            end
        end
    end)
end

ClientPlot.OnAllAndCreated(function(plot: ClientPlot.Type)
    if pedestalModels[plot] then
        return
    end

    plotCreated(plot)
end)

ClientPlot.Destroying:Connect(function(plot: ClientPlot.Type)
    -- Clean up any pedestal models tracked for this plot
    if pedestalModels[plot] then
        for _, model in pairs(pedestalModels[plot]) do
            if model.Model then pcall(function() model.Model:Destroy() end) end
            if model.SellProximity then pcall(function() model.SellProximity:Destroy() end) end
            if model.PickupProximity then pcall(function() model.PickupProximity:Destroy() end) end
            if model.StealProximity then pcall(function() model.StealProximity:Destroy() end) end
            if model.BoostProximity then pcall(function() model.BoostProximity:Destroy() end) end
        end
        pedestalModels[plot] = nil
    end
    
    -- Clean up animation states
    if pedestalAnimationStates[plot] then
        for pedestalId, isAnimating in pairs(pedestalAnimationStates[plot]) do
            if isAnimating then
                pedestalAnimationStates[plot][pedestalId] = false -- Cancel any ongoing animations
            end
        end
        pedestalAnimationStates[plot] = nil
    end

    -- Clean up pedestal original parents
    if pedestalOriginalParents[plot] then
        pedestalOriginalParents[plot] = nil
    end

    -- Clean up pedestal instances
    if pedestalInstances[plot] then
        pedestalInstances[plot] = nil
    end

    -- Additionally, scan PlotFish folders and destroy any fish models that were tied to this plot
    local root = workspace:FindFirstChild("__THINGS")
    local folders = {
        root and root:FindFirstChild("PlotFish"),
        root and root:FindFirstChild("Shiny") and (root :: any).PlotFish and (root :: any).PlotFish:FindFirstChild("Shiny"),
        root and root:FindFirstChild("Rainbow") and (root :: any).PlotFish and (root :: any).PlotFish:FindFirstChild("Rainbow"),
        root and root:FindFirstChild("Gold") and (root :: any).PlotFish and (root :: any).PlotFish:FindFirstChild("Gold")
    }
    for _, folder in ipairs(folders) do
        if folder and folder:IsA("Instance") then
            for _, m in ipairs(folder:GetChildren()) do
                if m:IsA("Model") and m:GetAttribute("_PlotId") == plot:GetId() then
                    pcall(function() m:Destroy() end)
                end
            end
        end
    end
end)

-- Network listener for lucky block animations
Network.Fired("LuckyBlockAnimation", function(plotId: string, pedestalId: number, visualData: {LuckyBlockTypes.lucky_block_visual_data})
    -- Find the plot by ID
    local targetPlot = nil
    for plot in pairs(pedestalModels) do
        if tostring(plot:GetId()) == plotId then
            targetPlot = plot
            break
        end
    end
    
    if targetPlot then
        playLuckyBlockAnimation(targetPlot, pedestalId, visualData)
    end
end)

task.spawn(function()
    while true do
        for plot, models in pairs(pedestalModels) do
            for index, model in pairs(models) do
                UpdateBillboard(plot, index, model.Billboard)
            end
        end
        task.wait(1)
    end
end)