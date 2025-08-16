--!strict

local Functions = require(game.ReplicatedStorage.Library.Functions)
local ClientPlot = require(game.ReplicatedStorage.Plot.ClientPlot)

ClientPlot.OnAllAndCreated(function(plot: ClientPlot.Type)
    local model = plot:WaitModel()
    local owner = plot:GetOwner()
    local billboard: BillboardGui = model:WaitForChild("PlayerBillboard"):WaitForChild("BillboardGui")::BillboardGui
   
    local frame = billboard:WaitForChild("Frame")::Frame
    local name = frame:WaitForChild("Name")::TextLabel
    local multi = frame:WaitForChild("Multi")::TextLabel
    local playerIcon = frame:WaitForChild("PlayerIcon")::ImageLabel

    task.spawn(function()
        local icon = Functions.GetAvatarFromUserIdAsync(owner.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        
        if icon then
            playerIcon.Image = icon

            local loading = playerIcon:WaitForChild("Loading")::ImageLabel
            loading.Visible = false
        end
    end)

    name.Text = owner.DisplayName
    multi.Text = "x1 Multi"

    billboard.Enabled = true
end)