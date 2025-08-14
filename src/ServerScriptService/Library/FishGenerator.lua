--!strict

local Assets = game.ReplicatedStorage.Assets

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Directory = require(ReplicatedStorage.Game.Library.Directory)
local FishTypes = require(ReplicatedStorage.Game.Library.Types.Fish)
local Functions = require(ReplicatedStorage.Library.Functions)
local Fish = require(ServerScriptService.Game.Library.Fish)
local Network = require(ServerScriptService.Library.Network)
local Enemies = require(ServerScriptService.Game.Library.Enemies)

local ROOT = workspace:WaitForChild("__THINGS")
local SPAWNS = ROOT:WaitForChild("FishSpawns")
local EASY = SPAWNS:WaitForChild("Easy")::BasePart
local HARD = SPAWNS:WaitForChild("Hard")::BasePart

local TOTAL_FISH = 80
local HARD_RATIO = 0.7
local HARD_COUNT = math.floor(TOTAL_FISH * HARD_RATIO)
local EASY_COUNT = TOTAL_FISH - HARD_COUNT

local DESPAWN_SECONDS = 60

local FishGen = {}

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
    model:PivotTo((torso :: BasePart).CFrame * CFrame.new(0, 0, 1))
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
    prompt.Parent = primary
    prompt.Triggered:Connect(function(player)
        -- Prevent multiple carriers and prevent a player from carrying more than one
        if fish.Carrier then return end
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
            mps.Text = `{schema.MoneyPerSecond}/s`
        end
        local timer = frame:FindFirstChild("Timer")
        if timer and timer:IsA("TextLabel") then
            timer.Text = "60s"
        end
    end
end

local function spawnOne(into: BasePart, backdate: number?)
    local rarityId = chooseRarityId()
    local schema = chooseFishByRarity(rarityId)
    if not schema then return end
    local fishModelTemplate = schema._script:WaitForChild("Model")
    if not fishModelTemplate or not fishModelTemplate:IsA("Model") then return end

    local uid = tostring(math.random(1, 1e9)) .. "-" .. tostring(os.clock())

    local fishData: FishTypes.data_schema = {
        UID = uid,
        FishId = schema._id,
        Type = "Normal",
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
    fishInstance.Model.Parent = ROOT
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

local function despawn(uid: string)
    local fish = uidToFish[uid]
    if not fish then return end
    -- Clear carrying link if any
    if fish.Carrier then
        playerCarry[fish.Carrier] = nil
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
    if fish.Gui then
        local dir = Directory.Fish[fish.FishData.FishId]
        fish.Gui.StudsOffsetWorldSpace = Vector3.new(0, 0, dir.BillboardOffset)
    end
    weldToBack(fish.Model, player)
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
            despawn(uid)
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
						Fish.Give(player, fish)
						despawn(uid)
					end
				end
			end
        end
    end
end)

-- Handle player lifecycle
local function onPlayerRemoving(player: Player)
    local uid = playerCarry[player]
    if uid then
        despawn(uid)
        playerCarry[player] = nil
    end
end
Players.PlayerRemoving:Connect(onPlayerRemoving)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid") :: Humanoid
        humanoid.Died:Connect(function()
            local uid = playerCarry[player]
            if uid then
                despawn(uid)
                playerCarry[player] = nil
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

return FishGen


