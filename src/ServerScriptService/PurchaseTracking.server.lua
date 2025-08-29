--!strict

local Signal = require(game.ReplicatedStorage.Library.Signal)
local Products = require(game.ServerScriptService.Library.Products)
local Saving = require(game.ServerScriptService.Library.Saving)
local Functions = require(game.ReplicatedStorage.Library.Functions)
local ProductDirectory = require(game.ReplicatedStorage.Game.Library.Directory.Products)
local GamepassDirectory = require(game.ReplicatedStorage.Game.Library.Directory.Gamepasses)

Products.ProductGranted:Connect(function(player, productId)
    local schema = ProductDirectory[productId]
    if not schema then return end

    local saveData = Saving.Get(player)
    if saveData then
        local price = Functions.GetRobuxPrice(schema.ProductId, true) or 0
        saveData.RobuxSpent += price
    end
end)

Signal.Fired("GamepassPurchased"):Connect(function(player, gamepassId)
    local schema = GamepassDirectory[gamepassId]
    if not schema then return end

    local saveData = Saving.Get(player)
    if saveData then
        local price = Functions.GetRobuxPrice(schema.GamepassId) or 0
        saveData.RobuxSpent += price
    end
end)