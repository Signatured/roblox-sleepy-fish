--!strict

local AdminPanelTypes = require(game.ReplicatedStorage.Game.Library.Types.AdminPanel)
export type dir_schema = AdminPanelTypes.AdminCommand

local Children: typeof(workspace.__DIRECTORY.AdminPanel) = require(game.ReplicatedStorage.DirectoryLoader):WaitForChild(script.Name)

local module: {[string]: AdminPanelTypes.AdminCommand} = {}

local function processModule(child: ModuleScript)
	local success, result = pcall(require, child)
	if success then
		module[child.Name] = result
	else
		warn("Failed to require AdminPanel module:", child.Name, result)
	end
end

for _, child in pairs(Children:GetChildren()) do
	if child:IsA("ModuleScript") then
		processModule(child)
	end
end

return module
