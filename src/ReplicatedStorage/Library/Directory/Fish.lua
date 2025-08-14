--!strict

local FishTypes = require(game.ReplicatedStorage.Game.Library.Types.Fish)
export type dir_schema = FishTypes.dir_schema

local Children: typeof(workspace.__DIRECTORY.Fish) = require(game.ReplicatedStorage.DirectoryLoader):WaitForChild(script.Name)

local module: {[string]: FishTypes.dir_schema} = {}

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
            assert(type(dir.MoneyPerSecond) == "number")
            assert(type(dir.BaseUpgradeCost) == "number")

            -- Rarity schema validation
            assert(type(dir.Rarity) == "table")
            assert(typeof(dir.Rarity.Color) == "Color3")
            assert(type(dir.Rarity.Priority) == "number")

            -- Optional: verify Tool exists under the script for spawning tools
            local tool = dir._script:FindFirstChild("Tool")
            assert(tool == nil or tool:IsA("Tool"))
        end)
        if not success then
            warn("[Directory Validator]", script.Name, dir._script, tostring(reason))
        end
    end
end

return module


