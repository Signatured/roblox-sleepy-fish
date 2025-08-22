--!strict

local LeaderboardTypes = require(game.ReplicatedStorage.Game.Library.Types.Leaderboards)
export type dir_schema = LeaderboardTypes.dir_schema

local Children: typeof(workspace.__DIRECTORY.Leaderboards) = require(game.ReplicatedStorage.DirectoryLoader):WaitForChild(script.Name)

local module: {[string]: LeaderboardTypes.dir_schema} = {}

local function processModule(child: ModuleScript)
	local success, result = pcall(require, child)
	if success then
		local name = child.Name:match("@%s*(.+)")
		if not name then
			warn("Invalid module name format:", child.Name)
			return
		end
		result._id = name
		result._script = child
		module[name] = result
	else
		warn("Failed to require module:", child.Name, result)
	end
end

for _, child in pairs(Children:GetChildren()) do
	if child:IsA("ModuleScript") then
		processModule(child)
	elseif child:IsA("Folder") then
		for _, nestedChild in ipairs(child:GetChildren()) do
			if nestedChild:IsA("ModuleScript") then
				processModule(nestedChild)
			end
		end
	end
end

if game:GetService("RunService"):IsServer() and game:GetService("RunService"):IsStudio() then
	for _, dir in pairs(module) do
		local success, reason = pcall(function()
			assert(type(dir.DisplayName) == "string")
			assert(type(dir.Description) == "string")
			assert(type(dir.ScoreGetter) == "function")
			-- optional fields
			assert(dir.ScoreType == nil or type(dir.ScoreType) == "string")
			assert(dir.DisplayAmount == nil or type(dir.DisplayAmount) == "number")
		end)
		if not success then
			warn("[Directory Validator]", script.Name, tostring(reason))
		end
	end
end

return module


