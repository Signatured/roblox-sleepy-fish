--!strict

local Assets = game.ReplicatedStorage.Assets

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Signal = require(ReplicatedStorage.Library.Signal)
local Directory = require(ReplicatedStorage.Game.Library.Directory)
local FishTypes = require(ReplicatedStorage.Game.Library.Types.Fish)
local Functions = require(ReplicatedStorage.Library.Functions)
local Fish = require(ServerScriptService.Game.Library.Fish)
local Network = require(ServerScriptService.Library.Network)
local Enemies = require(ServerScriptService.Game.Library.Enemies)
local Notifications = require(ServerScriptService.Library.Notifications)
local BadgeManager = require(ServerScriptService.Game.Library.BadgeManager)
local SharedGameSettings = require(ReplicatedStorage.Game.Library.GameSettings)

local THINGS = workspace:WaitForChild("__THINGS")
local ROOT = THINGS:WaitForChild("SwimmingFish")
local ROOT_SHINY = THINGS:WaitForChild("SwimmingFish"):WaitForChild("Shiny")
local ROOT_GOLD = THINGS:WaitForChild("SwimmingFish"):WaitForChild("Gold")
local ROOT_RAINBOW = THINGS:WaitForChild("SwimmingFish"):WaitForChild("Rainbow")
local SPAWNS = THINGS:WaitForChild("FishSpawns")
local EASY = SPAWNS:WaitForChild("Easy")::BasePart
local HARD = SPAWNS:WaitForChild("Hard")::BasePart

local TOTAL_FISH = 80
local HARD_RATIO = 0.7
local HARD_COUNT = math.floor(TOTAL_FISH * HARD_RATIO)
local EASY_COUNT = TOTAL_FISH - HARD_COUNT

local DESPAWN_SECONDS = 60

local typeChances = {
    ["Normal"] = 79,
    ["Shiny"] = 15,
    ["Gold"] = 5,
    ["Rainbow"] = 1,
}

local FishGen = {}
-- Internal scheduling state (real-time aligned)
FishGen._nextEpicAt = nil :: number?
FishGen._nextLegendaryAt = nil :: number?
FishGen._nextMythicalAt = nil :: number?

type Swimming = FishTypes.swimming_fish_schema & {
    UID: string,
    Model: Model,
    Gui: BillboardGui?,
}

local uidToFish: {[string]: Swimming} = {}
local playerCarry: {[Player]: string} = {}

local function chooseRarityId(): string
    local dir = Directory.Rarity
    local total = 0
    for _, r in pairs(dir) do
        total += (r.RarityWeight or 0)
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
        acc += (r.RarityWeight or 0)
        if roll <= acc then return id end
    end
    local ids = {}
    for id in pairs(dir) do table.insert(ids, id) end
    return ids[#ids]
end

local function chooseFishByRarity(rarityId: string): FishTypes.dir_schema?
    local candidates = {}
    for id, f in pairs(Directory.Fish) do
        if f.Rarity and f.Rarity._id == rarityId then
            table.insert(candidates, f)
        end
    end
    if #candidates == 0 then return nil end
    return candidates[math.random(1, #candidates)]
end

local function randomPointIn(part: BasePart): CFrame
    local size = part.Size
    local offset = Vector3.new(
        (math.random() - 0.5) * size.X,
        (math.random() - 0.5) * size.Y,
        (math.random() - 0.5) * size.Z
    )
    return part.CFrame * CFrame.new(offset)
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

local function makePrompt(fish: Swimming)
    local primary = fish.Model.PrimaryPart or fish.Model:FindFirstChildWhichIsA("BasePart")
    if not primary or not primary:IsA("BasePart") then return end
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Pick Up"
    prompt.ObjectText = fish.FishData.FishId
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.Parent = primary
    prompt.Triggered:Connect(function(player)
        -- Prevent multiple carriers and prevent a player from carrying more than one
        if fish.Carrier then return end

        if playerCarry[player] then
            Notifications.Message(player, "You're already carrying a fish!", {
                Color = Color3.fromRGB(255, 0, 0),
            })
            return
        end

        setModelAnchored(fish.Model, false)
        -- Alert sphere at pickup
        local dir = Directory.Fish[fish.FishData.FishId]
        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if dir and hrp and hrp:IsA("BasePart") then
            Network.FireAll("AlertPart", hrp.Position, dir.Rarity.AlertRange)
            -- Notify enemies server-side to begin tracking this alert
            Enemies.Alert(player, hrp.Position, dir.Rarity.AlertRange)
        end
        FishGen.SetCarrying(player, fish.UID)
        prompt.Enabled = false
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

    local frame = gui:FindFirstChild("Frame")
    if frame and frame:IsA("Frame") then
        local displayName = frame:FindFirstChild("DisplayName")
        if displayName and displayName:IsA("TextLabel") then
            displayName.Text = schema.DisplayName or schema._id
        end
        local rarity = frame:FindFirstChild("Rarity")
        if rarity and rarity:IsA("TextLabel") then
            local r = schema.Rarity
            local rarityName = r and ((r :: any).DisplayName or r._id) or "Rarity"
            rarity.Text = rarityName
            if r and (r :: any).Color then
                rarity.TextColor3 = (r :: any).Color
            end
        end
        local mps = frame:FindFirstChild("MoneyPerSecond")
        if mps and mps:IsA("TextLabel") then
            local typeMultiplier = SharedGameSettings.TypeMultipliers[fish.FishData.Type] or 1
            mps.Text = `${Functions.NumberShorten(math.ceil(schema.MoneyPerSecond * typeMultiplier))}/s`
        end
        local timer = frame:FindFirstChild("Timer")
        if timer and timer:IsA("TextLabel") then
            timer.Text = "60s"
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

-- Force-spawn a fish constrained to a given rarity id (e.g., "Epic", "Legendary", "Mythical").
local function spawnForcedByRarity(rarityId: string)
    local schema = chooseFishByRarity(rarityId)
    if not schema then return end
    local fishModelTemplate = schema._script:WaitForChild("Model")
    if not fishModelTemplate or not fishModelTemplate:IsA("Model") then return end

    local uid = Functions.GenerateUID()
    local fishType = Functions.Lottery(typeChances)

    local fishData: FishTypes.data_schema = {
        UID = uid,
        FishId = schema._id,
        Type = fishType,
        Shiny = false,
        Level = 1,
        CreateTime = os.clock(),
        BaseTime = os.clock(),
    }

    local fishInstance: Swimming = {
        UID = uid,
        FishData = fishData,
        SpawnTime = os.clock(),
        Carrier = nil,
        Model = fishModelTemplate:Clone(),
        Gui = nil,
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
    attachGui(fishInstance, schema)
    makePrompt(fishInstance)
end

local function spawnOne(into: BasePart, backdate: number?)
    local rarityId = chooseRarityId()
    local schema = chooseFishByRarity(rarityId)
    if not schema then return end
    local fishModelTemplate = schema._script:WaitForChild("Model")
    if not fishModelTemplate or not fishModelTemplate:IsA("Model") then return end

    local uid = Functions.GenerateUID()
    local fishType = Functions.Lottery(typeChances)

    local fishData: FishTypes.data_schema = {
        UID = uid,
        FishId = schema._id,
        Type = fishType,
        Shiny = false,
        Level = 1,
        CreateTime = os.clock(),
        BaseTime = os.clock(),
    }

    local fishInstance: Swimming = {
        UID = uid,
        FishData = fishData,
        SpawnTime = os.clock() - (backdate or 0),
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
    playerCarry[player] = uid
    fish.Carrier = player
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

-- Heartbeat: despawn and respawn
RunService.Heartbeat:Connect(function()
    local now = os.clock()
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
                    timer.Text = tostring(math.ceil(remaining)) .. "s"
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
                        end
						despawn(uid)
                        task.spawn(function()
                            local success = BadgeManager.GiveBadgeByName(player, "FirstCatch")
                            if success then
                                Network.Fire(player, "PromptFavorite", 3)
                            end
                        end)
					end
				end
			end
        end
    end
    -- Guaranteed spawns aligned to real-world clock
    -- Compute next targets lazily and step forward as crossed
    local unixNow = DateTime.now().UnixTimestamp

    -- Mythical: at top of every hour
    if not FishGen._nextMythicalAt then
        local base = math.floor(unixNow / 3600) * 3600
        FishGen._nextMythicalAt = base + 3600
    end
    -- Epic/Legendary: start at bottom of the hour (:30)
    if not FishGen._nextEpicAt or not FishGen._nextLegendaryAt then
        local hourStart = math.floor(unixNow / 3600) * 3600
        local bottom = hourStart + 1800
        FishGen._nextEpicAt = (unixNow <= bottom) and bottom or (bottom + math.ceil((unixNow - bottom) / (2*60)) * (2*60))
        FishGen._nextLegendaryAt = (unixNow <= bottom) and bottom or (bottom + math.ceil((unixNow - bottom) / (5*60)) * (5*60))
    end

    while unixNow >= (FishGen._nextEpicAt or 0) do
        spawnForcedByRarity("Epic")
        FishGen._nextEpicAt = (FishGen._nextEpicAt :: number) + 2*60
    end
    while unixNow >= (FishGen._nextLegendaryAt or 0) do
        spawnForcedByRarity("Legendary")
        FishGen._nextLegendaryAt = (FishGen._nextLegendaryAt :: number) + 5*60
    end
    while unixNow >= (FishGen._nextMythicalAt or 0) do
        spawnForcedByRarity("Mythical")
        FishGen._nextMythicalAt = (FishGen._nextMythicalAt :: number) + 60*60
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


