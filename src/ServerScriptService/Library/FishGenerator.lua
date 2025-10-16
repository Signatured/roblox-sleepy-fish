--!strict

local Assets = game.ReplicatedStorage.Assets

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Signal = require(ReplicatedStorage.Library.Signal)
local ProductDirectory = require(ReplicatedStorage.Game.Library.Directory.Products)
local Marketplace = require(ReplicatedStorage.Library.Marketplace)
local Directory = require(ReplicatedStorage.Game.Library.Directory)
local FishTypes = require(ReplicatedStorage.Game.Library.Types.Fish)
local Functions = require(ReplicatedStorage.Library.Functions)
local Fish = require(ServerScriptService.Game.Library.Fish)
local ServerPlot = require(game.ServerScriptService.Plot.ServerPlot)
local Network = require(ServerScriptService.Library.Network)
local Enemies = require(ServerScriptService.Game.Library.Enemies)
local Notifications = require(ServerScriptService.Library.Notifications)
local BadgeManager = require(ServerScriptService.Game.Library.BadgeManager)
local SharedGameSettings = require(ReplicatedStorage.Game.Library.GameSettings)
local Saving = require(ServerScriptService.Library.Saving)
local ExistCount = require(ServerScriptService.Game.Library.ExistCount)
local Index = require(ServerScriptService.Game.Library.Index)
local ServerLuck = require(ServerScriptService.Game.Library.ServerLuck)
local Invisibility = require(ServerScriptService.Game.Library.Invisibility)
local MutationEvent = require(ServerScriptService.Game.Library.MutationEvent)
local Mutations = require(ServerScriptService.Game.Library.Mutations)
local Traits = require(ServerScriptService.Game.Library.Traits)

local THINGS = workspace:WaitForChild("__THINGS")
local ROOT = THINGS:WaitForChild("SwimmingFish")
local ROOT_SHINY = THINGS:WaitForChild("SwimmingFish"):WaitForChild("Shiny")
local ROOT_GOLD = THINGS:WaitForChild("SwimmingFish"):WaitForChild("Gold")
local ROOT_RAINBOW = THINGS:WaitForChild("SwimmingFish"):WaitForChild("Rainbow")
local TARGET_ZONE = THINGS:WaitForChild("TargetZone")::BasePart
local SPAWNS = THINGS:WaitForChild("FishSpawns")
local EASY = SPAWNS:WaitForChild("Easy")::BasePart
local HARD = SPAWNS:WaitForChild("Hard")::BasePart

local TOTAL_FISH = 80
local HARD_RATIO = 0.6
local HARD_COUNT = math.floor(TOTAL_FISH * HARD_RATIO)
local EASY_COUNT = TOTAL_FISH - HARD_COUNT

local DESPAWN_SECONDS = 90

local typeChances = {
    ["Normal"] = 79,
    ["Shiny"] = 15,
    ["Gold"] = 5,
    ["Rainbow"] = 1,
}

local FishGen = {}
-- Internal scheduling state (real-time aligned)
FishGen._nextLegendaryAt = nil :: number?
FishGen._nextMythicalAt = nil :: number?

export type Swimming = FishTypes.swimming_fish_schema & {
    UID: string,
    Model: Model,
    Gui: BillboardGui?,
    Beam: Beam?,
}

local uidToFish: {[string]: Swimming} = {}
local playerCarry: {[Player]: string} = {}

local function canPickupFish(player: Player): boolean
    local plot = ServerPlot.GetByPlayer(player)
    if not plot then return true end
    local invSize = plot:Save("InventorySize")
    if typeof(invSize) ~= "number" then return true end
    local save = Saving.Get(player)
    if not save or typeof(save.Inventory) ~= "table" then return true end
    local invCount = #((save.Inventory) :: {any})
    if invCount >= invSize then
        Notifications.Message(player, "Your inventory is full!", { Color = Color3.fromRGB(255, 0, 0) })
        local product = ProductDirectory["More Space"]
        local productId = product and product.ProductId
        if typeof(productId) == "number" and invSize < SharedGameSettings.MaxInventoryUpgraded3 then
            Marketplace.Prompt(player, productId, true)
        end
        return false
    end
    return true
end

local function chooseRarityId(): string
    local dir = Directory.Rarity
    -- Apply luck multiplier to Epic/Legendary/Mythical weights
    local luck = 1
    local ok, mult = pcall(function()
        return ServerLuck.GetServerLuck()
    end)
    if ok and typeof(mult) == "number" and mult > 1 then
        luck = mult
    end

    local function weighted(rarityId: string, weight: number): number
        if rarityId == "Epic" or rarityId == "Legendary" or rarityId == "Mythical" or rarityId == "Secret" then
            return weight * luck
        end
        return weight
    end

    local total = 0
    for id, r in pairs(dir) do
        total += weighted(id, (r.RarityWeight or 0))
    end
    if total <= 0 then
        -- fallback: pick any
        local ids = {}
        for id in pairs(dir) do table.insert(ids, id) end
        return ids[math.random(1, #ids)]
    end
    local roll = math.random() * total
    local acc = 0
    for id, r in pairs(dir) do
        acc += weighted(id, (r.RarityWeight or 0))
        if roll <= acc then return id end
    end
    local ids = {}
    for id in pairs(dir) do table.insert(ids, id) end
    return ids[#ids]
end

local function chooseFishByRarity(rarityId: string): FishTypes.dir_schema?
    local candidates = {}
    local totalWeight = 0
    for _, f in pairs(Directory.Fish) do
        if f.Rarity and f.Rarity._id == rarityId and not f.Rarity.PreventSpawning then
            table.insert(candidates, f)
            totalWeight += (f.RarityWeight or 0)
        end
    end
    if #candidates == 0 then return nil end
    if totalWeight <= 0 then
        return candidates[math.random(1, #candidates)]
    end
    local roll = math.random() * totalWeight
    local acc = 0
    for _, f in ipairs(candidates) do
        acc += (f.RarityWeight or 0)
        if roll <= acc then return f end
    end
    return candidates[#candidates]
end

local function randomPointIn(part: BasePart): CFrame
    local size = part.Size
    local lastCF = part.CFrame
    for attempt = 1, 5 do
        local offset = Vector3.new(
            (math.random() - 0.5) * size.X,
            (math.random() - 0.5) * size.Y,
            (math.random() - 0.5) * size.Z
        )
        local cf = part.CFrame * CFrame.new(offset)
        lastCF = cf

        -- Check against NoFishZones
        local inter = workspace:FindFirstChild("Interact")
        local zonesFolder = inter and inter:FindFirstChild("NoFishZones")
        local blocked = false
        if zonesFolder then
            for _, inst in ipairs(zonesFolder:GetDescendants()) do
                if inst:IsA("BasePart") then
                    if Functions.IsPositionInPart(cf.Position, inst :: BasePart) then
                        blocked = true
                        break
                    end
                end
            end
        end
        if not blocked then
            return cf
        end
    end
    -- Give up and use the last attempted point
    return lastCF
end

local function weldToBack(model: Model, player: Player)
    local character = player.Character
    if not character then return end
    local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    if not torso or not torso:IsA("BasePart") then return end
    local size = model:GetExtentsSize()
    model:PivotTo((torso :: BasePart).CFrame * CFrame.new(0, 0, (size.Y / 2)) * CFrame.Angles(math.rad(90), 0, 0))
    local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not primary or not primary:IsA("BasePart") then return end
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = primary
    weld.Part1 = torso :: BasePart
    weld.Parent = primary
end

local function setModelAnchored(model: Model, anchored: boolean)
    for _, inst in ipairs(model:GetDescendants()) do
        if inst:IsA("BasePart") then
            inst.Anchored = anchored
        end
    end
end

local function hasHadFishBefore(player: Player): boolean
    local save = Saving.Get(player)
    if not save then return false end
    if not save.Index then return false end
    return Functions.DictionarySize(save.Index) > 0
end

function FishGen.CanPickup(player: Player, fishUID: string): boolean
    local fish = uidToFish[fishUID]
    if not fish then return false end
    
    if not hasHadFishBefore(player) then
        local fishId = fish.FishData.FishId

        if fishId ~= "Clown Fish" then
        Notifications.Message(player, "You need to catch a Clown Fish first!", {
                Color = Color3.fromRGB(255, 0, 0),
            })
            return false
        end
    end
    -- Inventory capacity gate
    local ownerUserId = fish.Model:GetAttribute("OwnerUserId")
    if typeof(ownerUserId) == "number" and ownerUserId ~= player.UserId then
        local owner = Players:GetPlayerByUserId(ownerUserId)
        local message = owner and `Only {owner.DisplayName} can pick up this fish!` or "You cannot pickup this fish!"
        Notifications.Message(player, message, {
            Color = Color3.fromRGB(255, 0, 0),
        })
        return false
    end
    if not canPickupFish(player) then
        return false
    end
    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")::BasePart
    if not hrp or not Functions.IsPositionInPart(hrp.Position, TARGET_ZONE) then
        Notifications.Message(player, "You have to be in the water to pick up a fish!", {
            Color = Color3.fromRGB(255, 0, 0),
        })
        return false
    end

    -- Prevent multiple carriers and prevent a player from carrying more than one
    if fish.Carrier then return false end

    if playerCarry[player] then
        Notifications.Message(player, "You're already carrying a fish!", {
            Color = Color3.fromRGB(255, 0, 0),
        })
        return false
    end

    if fish.Model:GetAttribute("Grappling") and fish.Model:GetAttribute("Grappling") ~= player.UserId then
        return false
    end

    return true
end

function FishGen.AttemptPickupByUID(player: Player, fishUID: string): boolean
	local fish = uidToFish[fishUID]
	if not fish then return false end
	-- Find the prompt attached in makePrompt (on the primary part)
	local primary = fish.Model.PrimaryPart or fish.Model:FindFirstChildWhichIsA("BasePart")
	local prompt: ProximityPrompt? = nil
	if primary then
		prompt = primary:FindFirstChildOfClass("ProximityPrompt")
	end
	if not prompt then
		for _, inst in ipairs(fish.Model:GetDescendants()) do
			if inst:IsA("ProximityPrompt") then
				prompt = inst
				break
			end
		end
	end
	return FishGen.AttemptPickup(player, fish, (prompt :: any))
end


function FishGen.AttemptPickup(player: Player, fish: Swimming, prompt: ProximityPrompt): boolean
    local canPickup = FishGen.CanPickup(player, fish.UID)
    if not canPickup then
        return false
    end

    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")::BasePart

    setModelAnchored(fish.Model, false)
    -- Alert sphere at pickup
    local dir = Directory.Fish[fish.FishData.FishId]
    if dir and hrp and hrp:IsA("BasePart") then
        Network.FireAll("AlertPart", hrp.Position, dir.Rarity.AlertRange)
        -- Notify enemies server-side to begin tracking this alert
        Enemies.Alert(player, hrp.Position, dir.Rarity.AlertRange)
    end

    Network.Fire(player, "Fish_Grabbed_In_Water", fish.FishData.FishId)
    FishGen.SetCarrying(player, fish.UID)
    prompt.Enabled = false

    return true
end

local function makePrompt(fish: Swimming)
    local primary = fish.Model.PrimaryPart or fish.Model:FindFirstChildWhichIsA("BasePart")
    if not primary or not primary:IsA("BasePart") then return end
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Pick Up"
    prompt.ObjectText = fish.FishData.FishId
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.HoldDuration = 1.5
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.Parent = primary
    prompt.Triggered:Connect(function(player)
        FishGen.AttemptPickup(player, fish, prompt)
    end)
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

local function updateTraitsDisplay(gui: BillboardGui?, fish: Swimming)
    if not gui then return end
    
    local frame = gui:FindFirstChild("Frame")
    if not frame or not frame:IsA("Frame") then return end
    
    local traitsFrame = frame:FindFirstChild("Traits")
    if not traitsFrame or not traitsFrame:IsA("Frame") then return end
    
    local template = traitsFrame:FindFirstChild("Template")
    if not template or not template:IsA("ImageLabel") then return end
    
    -- Clear existing trait icons (except template)
    for _, child in ipairs(traitsFrame:GetChildren()) do
        if child:IsA("ImageLabel") and child ~= template then
            child:Destroy()
        end
    end
    
    -- Get all traits for this fish
    local traitDataList = Traits.GetTraitData(fish)
    
    if #traitDataList == 0 then
        traitsFrame.Visible = false
        return -- No traits to display
    end
    
    -- Show traits frame when there are traits
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
end

--[[
    Adds a trait to a swimming fish by UID.
    Updates the billboard display and money per second calculation.
    
    @param uid - The unique ID of the swimming fish
    @param traitId - The trait ID to add (must exist in Directory.Traits)
    @return boolean - Whether the trait was successfully added
]]
function FishGen.AddTrait(uid: string, traitId: string): boolean
    if type(uid) ~= "string" or uid == "" then return false end
    if type(traitId) ~= "string" or traitId == "" then return false end
    
    -- Validate trait exists
    local traitData = Directory.Traits[traitId]
    if not traitData then 
        warn("AddTrait: Trait not found:", traitId)
        return false 
    end
    
    -- Get the fish
    local fish = uidToFish[uid]
    if not fish then
        warn("AddTrait: Fish not found:", uid)
        return false
    end
    
    -- Initialize Traits table if it doesn't exist
    if not fish.FishData.Traits then
        fish.FishData.Traits = {}
    end

    assert(fish.FishData.Traits)
    
    -- Check if fish already has this trait
    if fish.FishData.Traits[traitId] then
        return false -- Already has this trait
    end
    
    -- Add the trait
    fish.FishData.Traits[traitId] = true
    
    -- Apply visual effects to the model if the trait has ApplyToModel
    if traitData.ApplyToModel then
        traitData.ApplyToModel(fish.Model)
    end
    
    -- Update the billboard display
    if fish.Gui then
        -- Update traits icons
        updateTraitsDisplay(fish.Gui, fish)
        
        -- Update money per second display with new trait multiplier
        local frame = fish.Gui:FindFirstChild("Frame")
        if frame and frame:IsA("Frame") then
            local mps = frame:FindFirstChild("MoneyPerSecond")
            if mps and mps:IsA("TextLabel") then
                local schema = Directory.Fish[fish.FishData.FishId]
                if schema then
                    local typeMultiplier = SharedGameSettings.TypeMultipliers[fish.FishData.Type] or 1
                    local mutationMultiplier = Mutations.GetMutationMulti(fish)
                    local traitMultiplier = Traits.GetTraitMulti(fish)
                    mps.Text = `${Functions.NumberShorten(math.ceil(schema.MoneyPerSecond * typeMultiplier * mutationMultiplier * traitMultiplier))}/s`
                end
            end
        end
    end
    
    return true
end

local function attachGui(fish: Swimming, schema: FishTypes.dir_schema)
    local primary = fish.Model.PrimaryPart or fish.Model:FindFirstChildWhichIsA("BasePart")
    if not primary or not primary:IsA("BasePart") then return end
    local template = Assets:FindFirstChild("FishSwimmingGui")
    if not template or not template:IsA("BillboardGui") then return end
    local gui = template:Clone()
    gui.Name = "FishSwimmingGui"
    gui.StudsOffsetWorldSpace = Vector3.new(0, schema.BillboardOffset, 0)
    gui.Adornee = primary
    gui.Parent = primary
    fish.Gui = gui

    -- Check if this is a lucky block
    local isLuckyBlock = schema.LuckyBlockId ~= nil
    local luckyBlockDir = nil
    if isLuckyBlock and schema.LuckyBlockId then
        luckyBlockDir = Directory.LuckyBlocks[schema.LuckyBlockId]
    end

    local frame = gui:FindFirstChild("Frame")
    if frame and frame:IsA("Frame") then
        local displayName = frame:FindFirstChild("DisplayName")
        if displayName and displayName:IsA("TextLabel") then
            if isLuckyBlock and luckyBlockDir then
                displayName.Text = "Lucky Block"
                displayName.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                displayName.Text = schema.DisplayName or schema._id
            end
        end
        local rarity = frame:FindFirstChild("Rarity")
        if rarity and rarity:IsA("TextLabel") then
            if isLuckyBlock and luckyBlockDir then
                rarity.Text = luckyBlockDir.Rarity.DisplayName
                rarity.TextColor3 = luckyBlockDir.Rarity.Color
            else
                local r = schema.Rarity
                local rarityName = r and ((r :: any).DisplayName or r._id) or "Rarity"
                rarity.Text = rarityName
                if r and (r :: any).Color then
                    rarity.TextColor3 = (r :: any).Color
                end
            end
        end
        local mps = frame:FindFirstChild("MoneyPerSecond")
        if mps and mps:IsA("TextLabel") then
            if isLuckyBlock and luckyBlockDir then
                mps.Visible = false
            else
                local typeMultiplier = SharedGameSettings.TypeMultipliers[fish.FishData.Type] or 1
                local mutationMultiplier = Mutations.GetMutationMulti(fish)
                local traitMultiplier = Traits.GetTraitMulti(fish)
                mps.Text = `${Functions.NumberShorten(math.ceil(schema.MoneyPerSecond * typeMultiplier * mutationMultiplier * traitMultiplier))}/s`
            end
        end
        local timer = frame:FindFirstChild("Timer")
        if timer and timer:IsA("TextLabel") then
            timer.Text = "90s"
        end
        local fishType = frame:FindFirstChild("FishType")
        if fishType and fishType:IsA("TextLabel") then
            local name, color = getFishType(fish.FishData.Type)
            if color then
                fishType.TextColor3 = color
            end

            if name then
                fishType.Text = name
                fishType.Visible = true
            else
                fishType.Visible = false
            end
        end
        local mutation = frame:FindFirstChild("Mutation")
        if mutation and mutation:IsA("TextLabel") then
            if isLuckyBlock and luckyBlockDir then
                mutation.Text = luckyBlockDir.DisplayName
                mutation.TextColor3 = Color3.fromRGB(255, 255, 255)
                mutation.Visible = true
            else
                local name, color = getFishMutation(fish.FishData.Mutation)
                if color then
                    mutation.TextColor3 = color
                end

                if name then
                    mutation.Text = name
                    mutation.Visible = true
                else
                    mutation.Visible = false
                end
            end
        end
        local private = frame:FindFirstChild("Private")
        if private and private:IsA("TextLabel") then
            private.Visible = false
        end
        
        -- Update traits display
        updateTraitsDisplay(gui, fish)
    end
end

local function getRoot(type: string): Model
    if type == "Shiny" then
        return ROOT_SHINY
    elseif type == "Gold" then
        return ROOT_GOLD
    elseif type == "Rainbow" then
        return ROOT_RAINBOW
    end
    return ROOT
end

local function chooseSpawnPart(): BasePart
    if math.random() < HARD_RATIO then
        return HARD
    end
    return EASY
end

-- owner: if provided, marks the fish as private to this player
local function spawnForcedByRarity(rarityId: string, owner: Player?, _fishType: string?)
    local schema = chooseFishByRarity(rarityId)
    if not schema then return end
    local fishModelTemplate = schema._script:WaitForChild("Model")
    if not fishModelTemplate or not fishModelTemplate:IsA("Model") then return end

    local uid = Functions.GenerateUID()
    local fishType = Functions.Lottery(typeChances)
    if typeof(_fishType) == "string" then
        if _fishType == "Normal" or _fishType == "Shiny" or _fishType == "Gold" or _fishType == "Rainbow" then
            fishType = _fishType
        end
    end

    -- Lucky Block fish always have Normal type and no mutation
    if schema.LuckyBlockId then
        fishType = "Normal"
    end

    -- Check if Galaxy event is active and apply Galaxy mutation
    local mutation: FishTypes.fish_mutation_type? = nil
    if not schema.LuckyBlockId then -- Lucky Block fish never have mutations
        local isEventActive, eventId = MutationEvent.GetCurrentStatus()
        if isEventActive and eventId == "Galaxy" then
            mutation = "Galaxy"
        end
    end

    local fishData: FishTypes.data_schema = {
        UID = uid,
        FishId = schema._id,
        Type = fishType,
        Mutation = mutation,
        Shiny = false,
        Level = 1,
        CreateTime = workspace:GetServerTimeNow(),
        BaseTime = workspace:GetServerTimeNow(),
    }

    local fishInstance: Swimming = {
        UID = uid,
        FishData = fishData,
        SpawnTime = workspace:GetServerTimeNow(),
        Carrier = nil,
        Model = fishModelTemplate:Clone(),
        Gui = nil,
        Beam = nil,
    }
    uidToFish[uid] = fishInstance

    local into = chooseSpawnPart()
    local cf = randomPointIn(into)
    local yaw = math.rad(math.random(0, 359))
    local spawnCFrame = CFrame.new(cf.Position) * CFrame.Angles(0, yaw, 0)
    fishInstance.Model:PivotTo(spawnCFrame)
    setModelAnchored(fishInstance.Model, true)
    fishInstance.Model.Name = fishData.FishId
    fishInstance.Model.Parent = getRoot(fishType)
    fishInstance.Model:AddTag("SwimmingFish")
    fishInstance.Model:SetAttribute("UID", uid)
    fishInstance.Model:SetAttribute("CFrame", spawnCFrame)
    if owner then
        fishInstance.Model:SetAttribute("OwnerUserId", owner.UserId)
    end
    
    -- Apply Bloodfish visual effect if mutation is present
    if mutation == "Bloodfish" then
        FishTypes.MakeBloodfishModel(fishInstance.Model)
    elseif mutation == "Galaxy" then
        FishTypes.MakeGalaxyModel(fishInstance.Model)
    end
    
    attachGui(fishInstance, schema)
    -- If owned, mark GUI as private with owner name
    if owner and fishInstance.Gui then
        local frame = fishInstance.Gui:FindFirstChild("Frame")
        local private = frame and frame:FindFirstChild("Private")
        if private and private:IsA("TextLabel") then
            private.Visible = true
            private.Text = `{owner.DisplayName}'s Fish!`
        end
    end
    makePrompt(fishInstance)
    -- Notify owner client to create a local-only mythical beam
    if rarityId == "Mythical" and owner then
        Network.Fire(owner, "MythicalBeam_Create", uid)
    end
    -- Broadcast notification to all players about the forced spawn
    local displayName = schema.DisplayName or schema._id
    local rarity = schema.Rarity

    local luckyBlockId = schema.LuckyBlockId
    if luckyBlockId then
        local luckyBlockDir = Directory.LuckyBlocks[luckyBlockId]
        rarity = luckyBlockDir.Rarity
    end

    if owner then
        Notifications.Message(owner, `You spawned a private Mythical {displayName}!`, {
            Rainbow = true,
            Time = 8,
        })
    else
        if rarity._id == "Mythical" then
            Notifications.MessageAll(`A Mythical {displayName} has spawned!`, {
                Rainbow = true,
                Time = 8,
            })
        elseif rarity._id == "Secret" then
                Notifications.MessageAll(`A SECRET {displayName} has spawned!`, {
                    Rainbow = true,
                    Time = 8,
                })
        else
            Notifications.MessageAll(`A {rarity.DisplayName} {displayName} has spawned!`, {
                Time = 8,
            })
        end
    end
end

local function spawnOne(into: BasePart, backdate: number?)
    local rarityId = chooseRarityId()
    local schema = chooseFishByRarity(rarityId)
    if not schema then return end
    local fishModelTemplate = schema._script:WaitForChild("Model")
    if not fishModelTemplate or not fishModelTemplate:IsA("Model") then return end

    local uid = Functions.GenerateUID()
    local fishType = Functions.Lottery(typeChances)

    -- Lucky Block fish always have Normal type and no mutation
    if schema.LuckyBlockId then
        fishType = "Normal"
    end

    -- Check if Galaxy event is active and apply Bloodfish mutation
    local mutation: FishTypes.fish_mutation_type? = nil
    if not schema.LuckyBlockId then -- Lucky Block fish never have mutations
        local isBloodMoonActive, eventId = MutationEvent.GetCurrentStatus()
        if isBloodMoonActive and eventId == "Galaxy" then
            mutation = "Galaxy"
        end
    end

    local fishData: FishTypes.data_schema = {
        UID = uid,
        FishId = schema._id,
        Type = fishType,
        Mutation = mutation,
        Shiny = false,
        Level = 1,
        CreateTime = workspace:GetServerTimeNow(),
        BaseTime = workspace:GetServerTimeNow(),
    }

    local fishInstance: Swimming = {
        UID = uid,
        FishData = fishData,
        SpawnTime = workspace:GetServerTimeNow() - (backdate or 0),
        Carrier = nil,
        Model = fishModelTemplate:Clone(),
        Gui = nil,
    }
    uidToFish[uid] = fishInstance

    local cf = randomPointIn(into)
    local yaw = math.rad(math.random(0, 359))
    local spawnCFrame = CFrame.new(cf.Position) * CFrame.Angles(0, yaw, 0)
    fishInstance.Model:PivotTo(spawnCFrame)
    setModelAnchored(fishInstance.Model, true)
    fishInstance.Model.Name = fishData.FishId
    fishInstance.Model.Parent = getRoot(fishType)
    fishInstance.Model:AddTag("SwimmingFish")
    fishInstance.Model:SetAttribute("UID", uid)
    fishInstance.Model:SetAttribute("CFrame", spawnCFrame)
    fishInstance.Model:SetAttribute("OceanFish", true)
    
    -- Apply Bloodfish visual effect if mutation is present
    if mutation == "Bloodfish" then
        FishTypes.MakeBloodfishModel(fishInstance.Model)
    elseif mutation == "Galaxy" then
        FishTypes.MakeGalaxyModel(fishInstance.Model)
    end
    
    attachGui(fishInstance, schema)
    makePrompt(fishInstance)
end

local function respawnReplacement()
    -- keep counts balanced roughly by ratio
    local current = 0
    for _ in pairs(uidToFish) do current += 1 end
    if current >= TOTAL_FISH then return end
    if math.random() < HARD_RATIO then
        spawnOne(HARD)
    else
        spawnOne(EASY)
    end
end

local function despawn(uid: string, sendCarrierMessage: boolean?)
    local fish = uidToFish[uid]
    if not fish then return end
    -- Clear carrying link if any
    if fish.Carrier then
        if sendCarrierMessage then
            Notifications.Message(fish.Carrier, "Your fish timed out!", {
                Color = Color3.fromRGB(255, 0, 0),
            })
        end
        local carrier = fish.Carrier
        playerCarry[carrier] = nil
        pcall(function()
            carrier:SetAttribute("CarryingFishId", nil)
            carrier:SetAttribute("CarryingFishUID", nil)
        end)
        fish.Carrier = nil
    end
    if fish.Beam then
        pcall(function()
            fish.Beam:Destroy()
        end)
        fish.Beam = nil
    end
    if fish.Model then fish.Model:Destroy() end
    uidToFish[uid] = nil
    respawnReplacement()
end

function FishGen.GetCarrying(player: Player): Swimming?
    local uid = playerCarry[player]
    if not uid then return nil end
    return uidToFish[uid]
end

function FishGen.SetCarrying(player: Player, uid: string): boolean
    if playerCarry[player] then return false end
    local fish = uidToFish[uid]
    if not fish then return false end

    local save = Saving.Get(player)
    if save and not save.FinishedTutorial and fish.FishData.FishId == "Clown Fish" then
        local timeAlive = workspace:GetServerTimeNow() - fish.SpawnTime
        if timeAlive > 30 then
            fish.SpawnTime = workspace:GetServerTimeNow() - 30
        end
    end

    pcall(function()
        if Invisibility.IsInvisible(player) then
            Invisibility.MakeVisible(player)
        end
    end)

    playerCarry[player] = uid
    fish.Carrier = player
    -- Hide beam while carrying
    if fish.Beam then
        fish.Beam.Enabled = false
    end
    -- Set attribute with the directory FishId while carrying
    pcall(function()
        player:SetAttribute("CarryingFishId", fish.FishData.FishId)
        player:SetAttribute("CarryingFishUID", uid)
        fish.Model:SetAttribute("Carrying", true)
    end)
    -- if fish.Gui then
    --     local dir = Directory.Fish[fish.FishData.FishId]
    --     fish.Gui.StudsOffsetWorldSpace = Vector3.new(0, 0, dir.BillboardOffset)
    -- end
    weldToBack(fish.Model, player)
    return true
end

function FishGen.Drop(player: Player): boolean
    local uid = playerCarry[player]
    if not uid then return false end
    local fish = uidToFish[uid]
    if not fish then return false end
    if not playerCarry[player] then return false end

    -- Clear carrying record and attribute
    playerCarry[player] = nil
    pcall(function()
        player:SetAttribute("CarryingFishId", nil)
        player:SetAttribute("CarryingFishUID", nil)
        fish.Model:SetAttribute("Carrying", nil)
    end)

    -- Remove weld constraints that attached the fish to the player
    local character = player.Character
    for _, inst in ipairs(fish.Model:GetDescendants()) do
        if inst:IsA("WeldConstraint") then
            local part0 = (inst :: any).Part0
            local part1 = (inst :: any).Part1
            if (typeof(part0) == "Instance" and character and (part0 :: Instance):IsDescendantOf(character))
                or (typeof(part1) == "Instance" and character and (part1 :: Instance):IsDescendantOf(character)) then
                inst:Destroy()
            end
        end
    end

    -- Re-anchor the fish and place it at the player's current position
    setModelAnchored(fish.Model, true)
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then
        local hrpPart: BasePart = hrp :: BasePart
        local _, ry, _ = hrpPart.CFrame:ToOrientation()
        local uprightCFrame = CFrame.new(hrpPart.Position) * CFrame.Angles(0, ry, 0)
        fish.Model:PivotTo(uprightCFrame)
        fish.Model:SetAttribute("CFrame", uprightCFrame)
    end

    -- Re-enable pickup prompt(s)
    for _, inst in ipairs(fish.Model:GetDescendants()) do
        if inst:IsA("ProximityPrompt") then
            (inst :: ProximityPrompt).Enabled = true
        end
    end

    fish.Carrier = nil
    return true
end

function FishGen.Destroy(uid: string)
    despawn(uid)
end

function FishGen.ForceSpawnRandomType(rarityId: string, player: Player?, fishTypeOverride: string?)
    spawnForcedByRarity(rarityId, player, fishTypeOverride)
end

function FishGen.ForceSpawnSpecificFish(fishId: string, fishType: string?, mutation: string?, adminSpawned: boolean?)
    local schema = Directory.Fish[fishId]
    if not schema then return end
    local fishModelTemplate = schema._script:WaitForChild("Model")
    if not fishModelTemplate or not fishModelTemplate:IsA("Model") then return end

    local uid = Functions.GenerateUID()
    local selectedFishType: FishTypes.fish_type = "Normal"
    
    -- Lucky Block fish always have Normal type and no mutation
    if schema.LuckyBlockId then
        selectedFishType = "Normal"
    else
        -- Validate fish type
        if fishType == "Normal" or fishType == "Shiny" or fishType == "Gold" or fishType == "Rainbow" then
            selectedFishType = fishType :: FishTypes.fish_type
        end
    end

    -- Validate mutation
    local validatedMutation: FishTypes.fish_mutation_type? = nil
    if not schema.LuckyBlockId then -- Lucky Block fish never have mutations
        if mutation == "Bloodfish" then
            validatedMutation = "Bloodfish"
        elseif mutation == "Galaxy" then
            validatedMutation = "Galaxy"
        end
    end

    local fishData: FishTypes.data_schema = {
        UID = uid,
        FishId = schema._id,
        Type = selectedFishType,
        Mutation = validatedMutation,
        Shiny = false,
        Level = 1,
        CreateTime = workspace:GetServerTimeNow(),
        BaseTime = workspace:GetServerTimeNow(),
    }

    local fishInstance: Swimming = {
        UID = uid,
        FishData = fishData,
        SpawnTime = workspace:GetServerTimeNow(),
        Carrier = nil,
        Model = fishModelTemplate:Clone(),
        Gui = nil,
        Beam = nil,
    }
    uidToFish[uid] = fishInstance

    local into = chooseSpawnPart()
    local cf = randomPointIn(into)
    local yaw = math.rad(math.random(0, 359))
    local spawnCFrame = CFrame.new(cf.Position) * CFrame.Angles(0, yaw, 0)
    fishInstance.Model:PivotTo(spawnCFrame)
    setModelAnchored(fishInstance.Model, true)
    fishInstance.Model.Name = fishData.FishId
    fishInstance.Model.Parent = getRoot(selectedFishType)
    fishInstance.Model:AddTag("SwimmingFish")
    fishInstance.Model:SetAttribute("UID", uid)
    fishInstance.Model:SetAttribute("CFrame", spawnCFrame)
    fishInstance.Model:SetAttribute("OceanFish", true)
    
    -- Apply Bloodfish visual effect if mutation is present
    if validatedMutation == "Bloodfish" then
        FishTypes.MakeBloodfishModel(fishInstance.Model)
    elseif validatedMutation == "Galaxy" then
        FishTypes.MakeGalaxyModel(fishInstance.Model)
    end
    
    attachGui(fishInstance, schema)
    makePrompt(fishInstance)
    
    -- Broadcast notification to all players about the forced spawn
    local displayName = schema.DisplayName or schema._id
    local rarity = schema.Rarity
    local luckyBlockId = schema.LuckyBlockId

    if luckyBlockId then
        local luckyBlockDir = Directory.LuckyBlocks[luckyBlockId]
        rarity = luckyBlockDir.Rarity
    end

	-- Include fish type in message if not Normal, and allow admin prefix override
	local typeText = (selectedFishType ~= "Normal") and (selectedFishType .. " ") or ""
	local prefix = adminSpawned and "Admin spawned a" or "A"
    local suffix = adminSpawned and "!" or " has spawned!"

	if rarity._id == "Mythical" then
        local rarityText = luckyBlockId and "" or "Mythical "
		Notifications.MessageAll(`{prefix} {rarityText}{typeText}{displayName}{suffix}`, {
			Rainbow = true,
			Time = 8,
		})
    elseif rarity._id == "God" then
        local rarityText = luckyBlockId and "" or "God "
		Notifications.MessageAll(`{prefix} {rarityText}{typeText}{displayName}{suffix}`, {
			Rainbow = true,
			Time = 8,
		})
	elseif rarity._id == "Secret" then
        local rarityText = luckyBlockId and "" or "SECRET "
		Notifications.MessageAll(`{prefix} {rarityText}{typeText}{displayName}{suffix}`, {
			Rainbow = true,
			Time = 8,
		})
	else
		Notifications.MessageAll(`{prefix} {rarity.DisplayName} {typeText}{displayName}{suffix}`, {
			Time = 8,
		})
	end
end

-- Heartbeat: despawn and respawn
RunService.Heartbeat:Connect(function()
    local now = workspace:GetServerTimeNow()
    local homeBase = workspace:WaitForChild("__THINGS"):WaitForChild("HomeBase")::BasePart
    for uid, fish in pairs(uidToFish) do
        if (now - fish.SpawnTime) >= DESPAWN_SECONDS then
            -- Despawn if timer expired; if carried, also remove
            despawn(uid, true)
        else
            -- Update timer label
            local gui = fish.Gui
            if gui then
                local frame = gui:FindFirstChild("Frame")
                local timer = frame and frame:FindFirstChild("Timer")
                if timer and timer:IsA("TextLabel") then
                    local remaining = math.max(0, DESPAWN_SECONDS - (now - fish.SpawnTime))
                    timer.Text = "⏰ " .. tostring(math.ceil(remaining)) .. "s"
                end
            end

			-- Bank carried fish at HomeBase
			if fish.Carrier and homeBase then
				local player = fish.Carrier
				local character = player.Character
				local hrp = character and character:FindFirstChild("HumanoidRootPart")
				if hrp and hrp:IsA("BasePart") then
					if Functions.IsPositionInPart(hrp.Position, homeBase) then
						-- Award fish to player inventory and despawn world fish
						local data = Fish.Give(player, fish)
						if data then
							Fish.ForceHoldFish(player, data)
							-- Notify client of fish caught for local UI/SFX sync
							local schema = Directory.Fish[data.FishId]
							local displayName = (schema and schema.DisplayName) or data.FishId
							Network.Fire(player, "Fish_Caught", displayName)
						end
						despawn(uid)
						task.spawn(function()
                            ExistCount.IncrementCount(fish.FishData.FishId, fish.FishData.Type)
                            if fish.FishData.Mutation == "Bloodfish" then
                                ExistCount.IncrementBloodfishCount(fish.FishData.FishId)
                            end
                            if fish.FishData.Mutation == "Galaxy" then
                                ExistCount.IncrementGalaxyCount(fish.FishData.FishId)
                            end
                            Index.Add(player, fish.FishData.FishId, fish.FishData.Type, fish.FishData.Mutation)
							BadgeManager.GiveBadgeByName(player, "FirstCatch")
						end)
					end
				end
			end
        end
    end
    -- Guaranteed spawns aligned to real-world clock
    -- Compute next targets lazily and step forward as crossed
    local unixNow = DateTime.now().UnixTimestamp

    -- Mythical: every 15 minutes (quarter-hour aligned)
    if not FishGen._nextMythicalAt then
        local quarter = 15 * 60
        FishGen._nextMythicalAt = (math.floor(unixNow / quarter) + 1) * quarter
    end
    -- Epic/Legendary: start at bottom of the hour (:30)
    if not FishGen._nextLegendaryAt then
        local hourStart = math.floor(unixNow / 3600) * 3600
        local bottom = hourStart + 1800
        FishGen._nextLegendaryAt = (unixNow <= bottom) and bottom or (bottom + math.ceil((unixNow - bottom) / (5*60)) * (5*60))
    end
    while unixNow >= (FishGen._nextLegendaryAt or 0) do
        spawnForcedByRarity("Legendary")
        FishGen._nextLegendaryAt = (FishGen._nextLegendaryAt :: number) + 5*60
    end
    while unixNow >= (FishGen._nextMythicalAt or 0) do
        spawnForcedByRarity("Mythical")
        FishGen._nextMythicalAt = (FishGen._nextMythicalAt :: number) + 15*60
    end
end)

-- Handle player lifecycle
local function onPlayerRemoving(player: Player)
    local uid = playerCarry[player]
    if uid then
        FishGen.Drop(player)
    end
    pcall(function()
        player:SetAttribute("CarryingFishId", nil)
        player:SetAttribute("CarryingFishUID", nil)
    end)
end
Players.PlayerRemoving:Connect(onPlayerRemoving)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid") :: Humanoid
        humanoid.Died:Connect(function()
            local uid = playerCarry[player]
            if uid then
                FishGen.Drop(player)
            end
        end)
    end)
end)

-- Initial population
for i = 1, HARD_COUNT do
    spawnOne(HARD, Functions.RandomDouble(0, 50))
end
for i = 1, EASY_COUNT do
    spawnOne(EASY, Functions.RandomDouble(0, 50))
end

Signal.Fired("Death"):Connect(function(player: Player)
    FishGen.Drop(player)
end)

Network.Fired("DropFish", function(player: Player)
    FishGen.Drop(player)
end)

return FishGen


