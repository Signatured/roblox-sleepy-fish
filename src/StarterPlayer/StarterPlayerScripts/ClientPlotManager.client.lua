--!strict

local ClientPlot = require(game.ReplicatedStorage.Plot.ClientPlot)

ClientPlot.OnAllAndCreated(function(plot)
    if not plot:IsLocal() then
        local model = plot:YieldModel()

        local packOffers = model:WaitForChild("PackOffers")::Model
        local groupOffer = model:WaitForChild("GroupOffer")::BasePart

        packOffers:Destroy()
        groupOffer:Destroy()
    end
end)