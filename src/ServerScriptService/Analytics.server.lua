--!strict

local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")

local Network = require(game.ServerScriptService.Library.Network)
local ProductsDirectory = require(game.ReplicatedStorage.Game.Library.Directory.Products)
local Products = require(game.ServerScriptService.Library.Products)

local debounce = {}

Network.Fired("ClickedProduct", function(player: Player, productName: string)
    local product = ProductsDirectory[productName]
    if not product then
        return
    end

    if debounce[player] and debounce[player][productName] then
        return
    end

    debounce[player][productName] = true
    pcall(function()
        AnalyticsService:LogCustomEvent(player, `Clicked_{productName}`)
    end)
    task.delay(2, function()
        if debounce[player] then
            debounce[player][productName] = nil
        end
    end)
end)

Products.ProductGranted:Connect(function(player: Player, productName: string)
    pcall(function()
        AnalyticsService:LogCustomEvent(player, `Purchased_{productName}`)
    end)
end)

Players.PlayerAdded:Connect(function(player: Player)
    debounce[player] = {}
end)

Players.PlayerRemoving:Connect(function(player: Player)
    debounce[player] = nil
end)