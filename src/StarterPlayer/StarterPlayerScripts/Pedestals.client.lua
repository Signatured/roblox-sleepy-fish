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
local MutationCmds = require(game.ReplicatedStorage.Game.Library.Client.MutationCmds)

-- Upgrade button images
local UPGRADE_IMAGE_GREEN = "rbxassetid://85004105467436"
local UPGRADE_IMAGE_GREY = "rbxassetid://95787790482910"

-- Configurable claim bounce tween settings
local CLAIM_TWEEN_TOTAL_TIME = 0.3 -- seconds for full down-and-up cycle
local CLAIM_TWEEN_DEPTH = 0.2 -- studs to move down

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

    local boosts = plot:Session("PlayerBoosts")::{[string]: number}
    local boostedTime = boosts[tostring(index)]
	local isBoosted = boostedTime and workspace:GetServerTimeNow() < boostedTime
    local multiplier = plot:GetMultiplier()
    local typeMultiplier = GameSettings.TypeMultipliers[fishData.FishData.Type] or 1
    local mutationMultiplier = MutationCmds.GetMutationMulti(fishData :: any)
    local fishMultiplier = (multiplier * typeMultiplier * mutationMultiplier) + (isBoosted and 0.5 or 0)

    displayName.Text = dir.DisplayName
    rarity.Text = dir.Rarity.DisplayName
    rarity.TextColor3 = dir.Rarity.Color

    -- Mythical rarity rainbow gradient effect on rarity label
    local rarityId = (dir.Rarity and (dir.Rarity :: any)._id) or nil
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
    else
        fishType.Visible = false
    end

    local mutationName, mutationColor = getFishMutation(fishData.FishData.Mutation)
    if mutationColor then
        mutation.TextColor3 = mutationColor
    end

    if mutationName then
        mutation.Text = mutationName
    else
        mutation.Visible = false
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
        local fishData = FishCmds.GetCurrentFishData()
        if not fishData then
            NotificationCmds.Message("Equip a fish to place it!", {
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
            if claim and claim:IsA("BasePart") then
                model:SetAttribute("_ClaimHooked", true)
                local touchingParts: {[BasePart]: boolean} = {}
                claim.Touched:Connect(function(other: BasePart)
                    local character = LocalPlayer and LocalPlayer.Character
                    if not character or not other or not other:IsDescendantOf(character) then return end
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
                        end
                    end
                end)
                claim.TouchEnded:Connect(function(other: BasePart)
                    local character = LocalPlayer and LocalPlayer.Character
                    if not character or not other or not other:IsDescendantOf(character) then return end
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
            upgradeFrame.Visible = true
            placeFrame.Visible = false
            boostFrame.Visible = false

            -- If a place prompt exists from previous state, remove it
            local existingPlacePrompt = sellAttachment:FindFirstChild("PlacePrompt")
            if existingPlacePrompt and existingPlacePrompt:IsA("ProximityPrompt") then
                existingPlacePrompt:Destroy()
            end

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
                return
            end

            buttonText.Text = `${Functions.NumberShorten(cost)}`

            -- Ensure button image reflects affordability on first render
            UpdateUpgradeButtonImage(plot, model)
        else
            upgradeFrame.Visible = false
            placeFrame.Visible = true
            boostFrame.Visible = false

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

        if fishData.FishData.Mutation == "Bloodfish" then
            FishTypes.MakeBloodfishModel(fishModel)
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
            local sellPrice = plot:GetSellPrice(pedestalId)
            local sellPriceString = sellPrice and `Sell: ${Functions.NumberShorten(sellPrice)}` or "Sell"
            sellProximity = SetupProximity(sellPriceString, 3, Enum.KeyCode.E, sellAttachment)
            pickupProximity = SetupProximity("Pickup", 1, Enum.KeyCode.F, pickupAttachment)

            assert(sellProximity).Triggered:Connect(function(player: Player)
                local sellPrice = plot:GetSellPrice(pedestalId)
                if not sellPrice then
                    return
                end
                local success = plot:Invoke("SellFish", pedestalId)
                if success then
                    local schema = Directory.Fish[fishData.FishId]
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
            local latestPrice = plot:GetSellPrice(pedestalId)
            local latestText = latestPrice and `Sell: ${Functions.NumberShorten(latestPrice)}` or "Sell"
            if tracked.SellProximity.ActionText ~= latestText then
                tracked.SellProximity.ActionText = latestText
            end
        end
        UpdateBillboard(plot, pedestalId, pedestalModels[plot][pedestalId].Billboard)
    end
end

function plotCreated(plot: ClientPlot.Type)
    pedestalModels[plot] = {}

    local model = plot:YieldModel()
    local pedestals = model:WaitForChild("Pedestals")::Model

    for _, child in pedestals:GetChildren() do
        UpdatePedestal(plot, child::Model)
    end

    plot:SaveUpdated("Fish"):Connect(function(newFish: {[string]: PlotTypes.Fish})
        for _, child in pedestals:GetChildren() do
            UpdatePedestal(plot, child::Model)
        end
    end)

    plot:SaveUpdated("PaidIndex"):Connect(function(newIndex: number)
        for _, child in pedestals:GetChildren() do
            UpdatePedestal(plot, child::Model)
        end
    end)

    -- Money changes: flip the upgrade button image when affordability changes
    plot:SaveUpdated("Money"):Connect(function(_value: number)
        for _, child in pedestals:GetChildren() do
            UpdateUpgradeButtonImage(plot, child::Model)
        end
    end)

    plot:SessionUpdated("PlayerBoosts"):Connect(function(newBoosts: {[string]: number})
        for _, child in pedestals:GetChildren() do
            UpdatePedestal(plot, child::Model)
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