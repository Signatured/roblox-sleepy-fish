--!strict

local Functions = require(game.ReplicatedStorage.Library.Functions)
local ClientPlot = require(game.ReplicatedStorage.Plot.ClientPlot)

local paidIndexMap = {
    [0] = 0,
    [1] = 0.5,
    [2] = 1,
    [3] = 1.5,
}

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

    local paidIndex = plot:Save("PaidIndex")::number
    local indexMap = paidIndexMap[paidIndex]
    local totalMulti = indexMap + 1

    name.Text = owner.DisplayName
    multi.Text = `x{totalMulti} Multi`

    billboard.Enabled = true

    plot:SaveChanged("PaidIndex"):Connect(function(paidIndex: number)
        local newIndexMap = paidIndexMap[paidIndex]
        local newTotalMulti = newIndexMap + 1
        multi.Text = `x{newTotalMulti} Multi`
    end)
end)