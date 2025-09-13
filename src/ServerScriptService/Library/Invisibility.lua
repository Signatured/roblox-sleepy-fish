--!strict

local Players = game:GetService("Players")

export type TransparencyMap = {[Instance]: number}

type PlayerState = {
	IsInvisible: boolean,
	FadeId: number,
	OriginalTransparency: TransparencyMap,
	DescendantConn: RBXScriptConnection?,
}

local Invisibility = {}

-- Per-player state registry
local stateByPlayer: {[Player]: PlayerState} = {}

local FADE_DURATION = 0.5

local function ensureState(player: Player): PlayerState
	local s = stateByPlayer[player]
	if not s then
		s = {
			IsInvisible = false,
			FadeId = 0,
			OriginalTransparency = {},
			DescendantConn = nil,
		}
		stateByPlayer[player] = s
	end
	return s
end

local function getCharacter(player: Player): Model?
	local character = player.Character
	if character and character.Parent then
		return character
	end
	return nil
end

local function isFadable(inst: Instance): boolean
	return inst:IsA("BasePart") or inst:IsA("Decal") or inst:IsA("Texture")
end

local function collectTargets(character: Model): {Instance}
	local targets = {} :: {Instance}
	for _, descendant in character:GetDescendants() do
		if isFadable(descendant) then
			table.insert(targets, descendant)
		end
	end
	return targets
end

local function readTransparency(inst: Instance): number
	local ok, value = pcall(function()
		return (inst :: any).Transparency :: number
	end)
	if ok and typeof(value) == "number" then
		return value
	end
	return 0
end

local function writeTransparency(inst: Instance, value: number)
	pcall(function()
		(inst :: any).Transparency = value
	end)
end

local function connectForNewDescendants(player: Player, s: PlayerState, character: Model)
	if s.DescendantConn then
		s.DescendantConn:Disconnect()
		s.DescendantConn = nil
	end

	-- While invisible, immediately force new descendants to be transparent, capturing their original
	s.DescendantConn = character.DescendantAdded:Connect(function(desc: Instance)
		if not s.IsInvisible then return end
		if isFadable(desc) then
			if s.OriginalTransparency[desc] == nil then
				s.OriginalTransparency[desc] = readTransparency(desc)
			end
			writeTransparency(desc, 1)
		end
	end)
end

local function clearDescendantConn(s: PlayerState)
	if s.DescendantConn then
		s.DescendantConn:Disconnect()
		s.DescendantConn = nil
	end
end

local function fadeTo(player: Player, targets: {Instance}, startMap: TransparencyMap, targetMap: TransparencyMap, s: PlayerState)
	local myFadeId = s.FadeId
	local startTime = workspace:GetServerTimeNow()
	local endTime = startTime + FADE_DURATION
	while workspace:GetServerTimeNow() < endTime do
		if s.FadeId ~= myFadeId then
			return -- interrupted
		end
		local now = workspace:GetServerTimeNow()
		local alpha = math.clamp((now - startTime) / FADE_DURATION, 0, 1)
		for _, inst in targets do
			local a = startMap[inst]
			local b = targetMap[inst]
			if a ~= nil and b ~= nil then
				writeTransparency(inst, a + (b - a) * alpha)
			end
		end
		task.wait()
	end
	-- Finalize
	for _, inst in targets do
		local b = targetMap[inst]
		if b ~= nil then
			writeTransparency(inst, b)
		end
	end
end

local function captureOriginals(targets: {Instance}, map: TransparencyMap)
	for _, inst in targets do
		if map[inst] == nil then
			map[inst] = readTransparency(inst)
		end
	end
end

function Invisibility.MakeInvisible(player: Player)
	local s = ensureState(player)
	local character = getCharacter(player)
	if not character then return end

	s.FadeId += 1
	local currentFadeId = s.FadeId
	local targets = collectTargets(character)

	-- Save originals only when transitioning from visible -> invisible
	if not s.IsInvisible then
		captureOriginals(targets, s.OriginalTransparency)
	end

	-- Build fade maps
	local startMap: TransparencyMap = {}
	local targetMap: TransparencyMap = {}
	for _, inst in targets do
		startMap[inst] = readTransparency(inst)
		targetMap[inst] = 1
	end

	-- While invisible, keep new descendants hidden
	connectForNewDescendants(player, s, character)

	-- Run fade
	fadeTo(player, targets, startMap, targetMap, s)
	if s.FadeId == currentFadeId then -- still current fade
		s.IsInvisible = true
		player:SetAttribute("Invisible", true)
	end
end

function Invisibility.MakeVisible(player: Player)
	local s = ensureState(player)
	local character = getCharacter(player)
	if not character then
		-- Character gone; just reset state
		s.IsInvisible = false
		s.OriginalTransparency = {}
		clearDescendantConn(s)
		player:SetAttribute("Invisible", nil)
		return
	end

	s.FadeId += 1
	local currentFadeId = s.FadeId
	local targets = collectTargets(character)

	-- Build fade maps back to originals (default to current if missing)
	local startMap: TransparencyMap = {}
	local targetMap: TransparencyMap = {}
	for _, inst in targets do
		startMap[inst] = readTransparency(inst)
		targetMap[inst] = s.OriginalTransparency[inst] ~= nil and s.OriginalTransparency[inst] or readTransparency(inst)
	end

	-- Run fade
	fadeTo(player, targets, startMap, targetMap, s)
	if s.FadeId == currentFadeId then
		s.IsInvisible = false
		-- Restore exact originals and clear
		for inst, orig in s.OriginalTransparency do
			writeTransparency(inst, orig)
		end
		s.OriginalTransparency = {}
		clearDescendantConn(s)
		player:SetAttribute("Invisible", nil)
	end
end

function Invisibility.IsInvisible(player: Player): boolean
	local s = stateByPlayer[player]
	return s ~= nil and s.IsInvisible == true
end

-- Cleanup when players leave
Players.PlayerRemoving:Connect(function(player: Player)
	local s = stateByPlayer[player]
	if s then
		clearDescendantConn(s)
		stateByPlayer[player] = nil
	end
end)

return Invisibility


