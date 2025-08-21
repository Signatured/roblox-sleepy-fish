--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Network = require(ServerScriptService.Library.Network)
local Saving = require(ServerScriptService.Library.Saving)

Network.Fired("SettingChanged", function(player, settingName, value)
	local saveData = Saving.Get(player)
	if not saveData or not saveData.Settings then return end
	
	saveData.Settings[settingName] = value
end) 

-- Tutorial completion toggle
Network.Fired("SetFinishedTutorial", function(player)
    local saveData = Saving.Get(player)
    if not saveData then return false end
    saveData.FinishedTutorial = true

    Network.Fire(player, "PromptFavorite", 5)

    return true
end)