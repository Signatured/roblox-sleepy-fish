--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Functions = require(ReplicatedStorage.Library.Functions)

-- Track active tweens per enemy model
local activeTweens: {[Model]: Tween} = {}

local function setupEnemy(model: Model)
    -- Listen for Alerted attribute changes on the enemy model
    local function getBillboardBits(): (BillboardGui?, UIScale?)
        local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
        if not primary then return nil, nil end
        local billboard = primary:FindFirstChild("BillboardGui")
        if not (billboard and billboard:IsA("BillboardGui")) then return nil, nil end
        local img = billboard:FindFirstChildOfClass("ImageLabel")
        if not (img and img:IsA("ImageLabel")) then return billboard, nil end
        local scale = img:FindFirstChildOfClass("UIScale")
        if not (scale and scale:IsA("UIScale")) then return billboard, nil end
        return billboard, scale
    end

    local function onAlertChanged()
        local alerted = model:GetAttribute("Alerted") == true
        local billboard, scale = getBillboardBits()
        if not billboard then return end

        -- Cancel any prior tween
        local prior = activeTweens[model]
        if prior then
            pcall(function() prior:Cancel() end)
            activeTweens[model] = nil
        end

        if alerted then
            billboard.Enabled = true
            if scale then
                scale.Scale = 0.2
                local tween = TweenService:Create(scale, TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
                activeTweens[model] = tween
                tween:Play()
            end
        else
            billboard.Enabled = false
        end
    end

    -- Initial state and signal
    onAlertChanged()
    local conn = model:GetAttributeChangedSignal("Alerted"):Connect(onAlertChanged)

    -- Cleanup when tag removed
    return function()
        local prior = activeTweens[model]
        if prior then
            pcall(function() prior:Cancel() end)
            activeTweens[model] = nil
        end
        if conn then conn:Disconnect() end
        local billboard: BillboardGui? = (function(): BillboardGui?
            local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
            if not primary then return nil end
            local billboard = primary:FindFirstChild("BillboardGui")
            if not (billboard and billboard:IsA("BillboardGui")) then return nil end
            return billboard
        end)()
        if billboard then
            billboard.Enabled = false
        end
    end
end

Functions.TagHook("Enemy", function(inst: Instance)
    if inst and inst:IsA("Model") then
        return setupEnemy(inst)
    end
    return function() end
end)


