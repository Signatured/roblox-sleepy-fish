--!strict

local StarterGui = game:GetService("StarterGui")

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)

local function disableReset()
    -- Disable the Reset Character button in the escape menu
    local ok = pcall(function()
        StarterGui:SetCore("ResetButtonCallback", false)
    end)
    
    if not ok then
        task.wait(1)
        task.defer(disableReset)
    else
        StarterGui:SetCore("ResetButtonCallback", false)
    end
end

disableReset()