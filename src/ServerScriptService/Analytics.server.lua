--!strict

local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")

local Network = require(game.ServerScriptService.Library.Network)
local ProductsDirectory = require(game.ReplicatedStorage.Game.Library.Directory.Products)
local GamepassesDirectory = require(game.ReplicatedStorage.Game.Library.Directory.Gamepasses)
local Products = require(game.ServerScriptService.Library.Products)
local Signal = require(game.ReplicatedStorage.Library.Signal)

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

Network.Fired("ClickedGamepass", function(player: Player, gamepassName: string)
    local gamepass = GamepassesDirectory[gamepassName]
    if not gamepass then
        return
    end

    if debounce[player] and debounce[player][gamepassName] then
        return
    end

    debounce[player][gamepassName] = true
    pcall(function()
        AnalyticsService:LogCustomEvent(player, `Clicked_{gamepassName}`)
    end)
    task.delay(2, function()
        if debounce[player] then
            debounce[player][gamepassName] = nil
        end
    end)
end)

local dailyQuestDeboounce = {}
Network.Fired("DailyQuestPad", function(player: Player)
    if dailyQuestDeboounce[player] then
        return
    end
    dailyQuestDeboounce[player] = true
    task.delay(2, function()
        dailyQuestDeboounce[player] = nil
    end)
    pcall(function()
        AnalyticsService:LogCustomEvent(player, `DailyQuestPad_Opened`)
    end)
end)

Network.Fired("DailyQuestButton", function(player: Player)
    if dailyQuestDeboounce[player] then
        return
    end
    dailyQuestDeboounce[player] = true
    task.delay(2, function()
        dailyQuestDeboounce[player] = nil
    end)
    pcall(function()
        AnalyticsService:LogCustomEvent(player, `DailyQuestButton_Opened`)
    end)
end)

Products.ProductGranted:Connect(function(player: Player, productName: string)
    pcall(function()
        AnalyticsService:LogCustomEvent(player, `Purchased_{productName}`)
    end)
end)

Signal.Fired("GamepassPurchased"):Connect(function(player: Player, gamepassName: string)
    pcall(function()
        AnalyticsService:LogCustomEvent(player, `Purchased_{gamepassName}`)
    end)
end)

Players.PlayerAdded:Connect(function(player: Player)
    debounce[player] = {}
end)

Players.PlayerRemoving:Connect(function(player: Player)
    debounce[player] = nil
    dailyQuestDeboounce[player] = nil
end)