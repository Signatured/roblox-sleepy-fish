--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GadgetDirectory = require(ReplicatedStorage.Game.Library.Directory.Gadgets)
local GadgetTypes = require(ReplicatedStorage.Game.Library.Types.Gadgets)

local module = {}

local function getGadgetSchema(id: string | GadgetTypes.dir_schema): GadgetTypes.dir_schema?
	if typeof(id) == "table" then
		return id
	end
	return GadgetDirectory[id]
end

-- Returns true if the local player currently owns (has in Backpack or Character) the gadget.
function module.Has(id: string | GadgetTypes.dir_schema): boolean
	local schema = getGadgetSchema(id)
	if not schema then return false end

	local player = Players.LocalPlayer
	if not player then return false end

	local name = schema._id

	local character = player.Character
	if character and character:FindFirstChild(name) then
		return true
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack and backpack:FindFirstChild(name) then
		return true
	end

	return false
end

-- Unequips the Magic Carpet gadget if it is currently equipped. Returns true if unequipped.
function module.UnequipMagicCarpet(): boolean
	local player = Players.LocalPlayer
	if not player then return false end

	local character = player.Character
	if not character then return false end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end

	local currentTool = character:FindFirstChildOfClass("Tool")
	if currentTool and currentTool.Name == "Magic Carpet" then
		local ok = pcall(function()
			humanoid:UnequipTools()
		end)
		return ok
	end

	return false
end

-- Returns the directory schema of the currently equipped gadget (if any), otherwise nil
function module.GetCurrent(): GadgetTypes.dir_schema?
    local player = Players.LocalPlayer
    if not player then return nil end

    local character = player.Character
    local tool = character and character:FindFirstChildOfClass("Tool")
    if not tool then return nil end

    -- Tools are named with schema._id; map back to directory
    local dir = GadgetDirectory[tool.Name]
    return dir
end
-- Equips the best available coil gadget (highest SpeedMultiplier) if owned.
function module.EquipBestCoil(): boolean
    local player = Players.LocalPlayer
    if not player then return false end

    local character = player.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end

    local backpack = player:FindFirstChildOfClass("Backpack")

    local bestTool: Tool? = nil
    local bestSpeed = -math.huge

    local function considerTool(tool: Tool)
        local name = tool.Name
        if not string.find(name, "Coil", 1, true) then return end
        local dir = GadgetDirectory[name]
        local speed = (dir and dir.SpeedMultiplier) or 0
        if speed > bestSpeed then
            bestSpeed = speed
            bestTool = tool
        end
    end

    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            considerTool(child)
        end
    end
    if backpack then
        for _, child in ipairs(backpack:GetChildren()) do
            if child:IsA("Tool") then
                considerTool(child)
            end
        end
    end

    if not bestTool then return false end

    local ok = pcall(function()
        humanoid:EquipTool(bestTool :: Tool)
    end)
    return ok
end

return module

