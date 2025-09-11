--!strict

local Functions = require(game.ReplicatedStorage.Library.Functions)
local ClientPlot = require(game.ReplicatedStorage.Plot.ClientPlot)
local Save = require(game.ReplicatedStorage.Library.Client.Save)

local paidIndexMap = {
    [0] = 0,
    [1] = 0.5,
    [2] = 1,
    [3] = 1.5,
}
local doubleMoneyGamepassId = 1407961498

function OwnsDoubleMoney()
    local save = Save.Get()
    if not save then return false end
    local ownsGamepass = save.Gamepasses and save.Gamepasses[tostring(doubleMoneyGamepassId)] or false
    return ownsGamepass
end

ClientPlot.OnAllAndCreated(function(plot: ClientPlot.Type)
    local model = plot:YieldModel()
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

    local function calculateMultiplier()
        local paidIndex = plot:Save("PaidIndex")::number
        local indexMap = paidIndexMap[paidIndex]
        local totalMulti = indexMap + 1
        local questMultiplier = 0
        local questExpireTime = plot:Session("DailyQuests_Multiplied")
        if questExpireTime and workspace:GetServerTimeNow() < questExpireTime then
            questMultiplier = 1
        end

        if OwnsDoubleMoney() then
            totalMulti = totalMulti + 1
        end
    
        totalMulti = totalMulti + questMultiplier
        return totalMulti
    end

    name.Text = owner.DisplayName
    multi.Text = `x{calculateMultiplier()} Multi`

    billboard.Enabled = true

    plot:SaveUpdated("PaidIndex"):Connect(function(paidIndex: number)
        multi.Text = `x{calculateMultiplier()} Multi`
    end)

    plot:SessionUpdated("DailyQuests_Multiplied"):Connect(function(expireTime: number)
        multi.Text = `x{calculateMultiplier()} Multi`
    end)
end)

Save.Fired(function(key: string, value: any)
    if key == "Gamepasses" then
        local plot = ClientPlot.GetLocal()
        if not plot then return end

        local model = plot:YieldModel()
        local owner = plot:GetOwner()
        local billboard: BillboardGui = model:WaitForChild("PlayerBillboard"):WaitForChild("BillboardGui")::BillboardGui
    
        local frame = billboard:WaitForChild("Frame")::Frame
        local name = frame:WaitForChild("Name")::TextLabel
        local multi = frame:WaitForChild("Multi")::TextLabel

        local paidIndex = plot:Save("PaidIndex")::number
        local indexMap = paidIndexMap[paidIndex]
        local totalMulti = indexMap + 1

        if OwnsDoubleMoney() then
            totalMulti = totalMulti + 1
        end
    
        name.Text = owner.DisplayName
        multi.Text = `x{totalMulti} Multi`
    end
end)