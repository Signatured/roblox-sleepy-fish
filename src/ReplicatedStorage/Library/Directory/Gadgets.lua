--!strict

local GadgetTypes = require(game.ReplicatedStorage.Game.Library.Types.Gadgets)
export type dir_schema = GadgetTypes.dir_schema

local Children: typeof(workspace.__DIRECTORY.Gadgets) = require(game.ReplicatedStorage.DirectoryLoader):WaitForChild(script.Name)

local module: {[string]: GadgetTypes.dir_schema} = {
}

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
			assert(type(dir.Icon) == "string")
			assert(type(dir.Description) == "string")
			assert(not dir.Index or type(dir.Index) == "number")
			assert(not dir.Cost or type(dir.Cost) == "number")
			assert(dir.Gradient == nil or type(dir.Gradient) == "string")
		end)
		if not success then
			warn("[Directory Validator]", script.Name, dir._script, tostring(reason))
		end
	end
end

return module

