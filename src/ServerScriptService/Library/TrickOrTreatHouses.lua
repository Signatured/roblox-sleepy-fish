--!strict

local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ServerScriptService.Library.Network)
local Saving = require(ServerScriptService.Library.Saving)
local FishGenerator = require(ServerScriptService.Game.Library.FishGenerator)
local Functions = require(ReplicatedStorage.Library.Functions)
local Notifications = require(ServerScriptService.Library.Notifications)
local Directory = require(ReplicatedStorage.Game.Library.Directory)

local TrickOrTreatHouses = {}

-- Track used spawn points per house {[houseId] = {1, 2, 3, ...}}
local usedSpawnPoints: {[number]: {number}} = {}

local COOLDOWN_DURATION = 300 -- 5 minutes in seconds
local NUM_SPAWN_POINTS = 6

--[[
	Finds a house model by its ID attribute.
]]
local function findHouseById(houseId: number): Model?
	for _, instance in ipairs(CollectionService:GetTagged("HalloweenHouse")) do
		if instance:IsA("Model") and instance:GetAttribute("Id") == houseId then
			return instance
		end
	end
	return nil
end

--[[
	Chooses a spawn point for a house, exhausting all before repeating.
]]
local function chooseSpawnPoint(houseId: number): number
	if not usedSpawnPoints[houseId] then
		usedSpawnPoints[houseId] = {}
	end
	
	local used = usedSpawnPoints[houseId]
	
	-- If all spawn points have been used, reset
	if #used >= NUM_SPAWN_POINTS then
		used = {}
		usedSpawnPoints[houseId] = used
	end
	
	-- Find an unused spawn point
	local available = {}
	for i = 1, NUM_SPAWN_POINTS do
		if not table.find(used, i) then
			table.insert(available, i)
		end
	end
	
	if #available == 0 then
		-- Shouldn't happen but fallback
		return math.random(1, NUM_SPAWN_POINTS)
	end
	
	local chosen = available[math.random(1, #available)]
	table.insert(used, chosen)
	return chosen
end


--[[
	Checks if a house is currently on cooldown for a player.
	
	@param player The player to check
	@param houseId The house ID (number)
	@return boolean Whether the house is on cooldown
]]
function TrickOrTreatHouses.IsOnCooldown(player: Player, houseId: number): boolean
	local save = Saving.Get(player)
	if not save then return false end
	
	save.TrickOrTreatHouses = save.TrickOrTreatHouses or {}
	
	local cooldownEnd = save.TrickOrTreatHouses[tostring(houseId)]
	if not cooldownEnd then
		return false
	end
	
	return workspace:GetServerTimeNow() <= cooldownEnd
end

--[[
	Gets the remaining cooldown time for a house.
	
	@param player The player to check
	@param houseId The house ID (number)
	@return number Seconds remaining on cooldown (or 0 if not on cooldown)
]]
function TrickOrTreatHouses.GetHouseCooldown(player: Player, houseId: number): number
	local save = Saving.Get(player)
	if not save then return 0 end
	
	save.TrickOrTreatHouses = save.TrickOrTreatHouses or {}
	
	local cooldownEnd = save.TrickOrTreatHouses[tostring(houseId)]
	if not cooldownEnd then
		return 0
	end
	
	local remaining = cooldownEnd - workspace:GetServerTimeNow()
	return math.max(0, remaining)
end

--[[
	Requests to trick or treat at a house.
	
	@param player The player making the request
	@param houseId The house ID (number)
	@return boolean Whether the request was successful
]]
function TrickOrTreatHouses.RequestTrickOrTreat(player: Player, houseId: number): boolean
	local save = Saving.Get(player)
	if not save then return false end
	
	save.TrickOrTreatHouses = save.TrickOrTreatHouses or {}
	
	-- Check if the house is on cooldown
	if TrickOrTreatHouses.IsOnCooldown(player, houseId) then
		return false
	end
	
	-- Find the house model
	local houseModel = findHouseById(houseId)
	if not houseModel then
		warn(`[TrickOrTreatHouses] Could not find house with ID {houseId}`)
		return false
	end
	
	local primaryPart = houseModel.PrimaryPart
	if not primaryPart then
		warn(`[TrickOrTreatHouses] House {houseId} has no PrimaryPart`)
		return false
	end
	
	-- Choose a spawn point
	local spawnIndex = chooseSpawnPoint(houseId)
	local spawnAttachment = primaryPart:FindFirstChild(`FishSpawn{spawnIndex}`)
	if not spawnAttachment or not spawnAttachment:IsA("Attachment") then
		warn(`[TrickOrTreatHouses] Could not find FishSpawn{spawnIndex} in house {houseId}`)
		return false
	end
	
	-- Pick a rarity from the lottery
	local rarityLottery = {
		["Rare"] = 50.7,
		["Epic"] = 45,
		["Legendary"] = 3,
		["Mythical"] = 1,
		["God"] = 0.25,
		["Secret"] = 0.05,
	}
	local rarityId = Functions.Lottery(rarityLottery)
	
	-- Spawn the fish at the attachment's world position
	local spawnCFrame = spawnAttachment.WorldCFrame
	local yaw = math.rad(math.random(0, 359))
	spawnCFrame = CFrame.new(spawnCFrame.Position) * CFrame.Angles(0, yaw, 0)
	
	-- Use FishGenerator to spawn the fish with position override, owner, and rarity
	local fish = FishGenerator.SpawnAtPosition(spawnCFrame, player, rarityId)

    if fish then
        local schema = Directory.Fish[fish.FishData.FishId]
        local rarity = schema.Rarity

        fish.Model:SetAttribute("TrickOrTreat", true)

        Notifications.Message(player, "Trick or Treat! 👻", {
            Color = Color3.fromRGB(255, 136, 0),
            Time = 8,
        })

        if rarity._id == "Mythical" then
            Notifications.Message(player, `A Mythical {schema.DisplayName} answered the door!`, {
                Rainbow = true,
                Time = 8,
            })
        elseif rarity._id == "God" then
            Notifications.Message(player, `A GOD {schema.DisplayName} answered the door!`, {
                Rainbow = true,
                Time = 8,
            })
        elseif rarity._id == "Secret" then
            Notifications.Message(player, `A SECRET {schema.DisplayName} answered the door!`, {
                Rainbow = true,
                Time = 8,
            })
        else
            Notifications.Message(player, `A {rarity.DisplayName} {schema.DisplayName} answered the door!`, {
                Time = 8,
            })
        end
    end
	
	-- Set cooldown (current time + 5 minutes)
	local cooldownEnd = workspace:GetServerTimeNow() + COOLDOWN_DURATION
	save.TrickOrTreatHouses[tostring(houseId)] = cooldownEnd
	
	return true
end

-- Network handler for client requests
Network.Fired("TrickOrTreatHouses_Request", function(player: Player, houseId: number)
	if typeof(houseId) ~= "number" then return end
	if houseId < 1 or houseId > 5 then return end
	
	TrickOrTreatHouses.RequestTrickOrTreat(player, houseId)
end)

return TrickOrTreatHouses

