--!strict

-- Server-side Gift system: coordinates gift offers and transfers of fish/gadgets

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Network = require(ServerScriptService.Library.Network)
local Saving = require(ServerScriptService.Library.Saving)
local ServerPlot = require(ServerScriptService.Plot.ServerPlot)
local Fish = require(ServerScriptService.Game.Library.Fish)
local Gadgets = require(ServerScriptService.Game.Library.Gadgets)
local GadgetDirectory = require(ReplicatedStorage.Game.Library.Directory.Gadgets)

export type GiftRecord = {
    FromUserId: number,
    ToUserId: number,
    ItemType: "Fish" | "Gadget",
    FishData: any?,
    GadgetId: string?,
}

local GiftService = {}

-- Active gifts keyed by recipient user id
local activeByRecipient: {[number]: GiftRecord & { ExpiresAt: number }} = {}

-- Cooldowns for denied gifts: fromUserId -> toUserId -> expireTime (os.clock())
local denyCooldowns: {[number]: {[number]: number}} = {}

local function findPlayerByUserId(userId: number): Player?
    for _, p in ipairs(Players:GetPlayers()) do
        if p.UserId == userId then return p end
    end
    return nil
end

local function canReceiveFish(toPlayer: Player): boolean
    local plot = ServerPlot.GetByPlayer(toPlayer)
    if not plot then return false end
    local save = Saving.Get(toPlayer)
    if not save then return false end
    local inv = save.Inventory :: {any}
    local invLimit = plot:Save("InventorySize")
    local limitNum = (type(invLimit) == "number") and (invLimit :: number) or 0
    if limitNum <= 0 then return false end
    return #inv < limitNum
end

local function getDisplayName(userId: number): string
    local ok, name = pcall(function()
        return game.Players:GetNameFromUserIdAsync(userId)
    end)
    return (ok and name) and name or ("User " .. tostring(userId))
end

-- Request to offer a gift from player -> targetUserId, with client-provided descriptor
Network.Invoked("GiftRequest", function(player: Player, targetUserId: number, payload: {ItemType: string, UID: string?, GadgetId: string?})
    if type(targetUserId) ~= "number" then return false, "Invalid target" end
    local target = findPlayerByUserId(targetUserId)
    if not target or target == player then return false, "Invalid target" end

    if activeByRecipient[targetUserId] then
        return false, "That player is already being gifted something. Try again later."
    end

    -- Deny cooldown check
    local now = os.clock()
    local fromMap = denyCooldowns[player.UserId]
    local cooldownUntil = fromMap and fromMap[targetUserId] or 0
    if cooldownUntil and cooldownUntil > now then
        local remaining = math.max(0, math.ceil(cooldownUntil - now))
        return false, string.format("Please wait %ds before trying again!", remaining)
    end

    local saveFrom = Saving.Get(player)
    local saveTo = Saving.Get(target)
    if not saveFrom or not saveTo then return false, "Players not ready" end

    local itemType = payload and payload.ItemType
    if itemType ~= "Fish" and itemType ~= "Gadget" then
        return false, "Invalid gift type"
    end

    if itemType == "Fish" then
        local uid = payload and payload.UID
        if type(uid) ~= "string" or uid == "" then
            return false, "No fish selected"
        end
        -- verify gifter still has fish uid
        local has = false
        for _, entry in ipairs(saveFrom.Inventory :: {any}) do
            if entry and entry.UID == uid then has = true; break end
        end
        if not has then
            return false, "You no longer have that fish"
        end
        if not canReceiveFish(target) then
            return false, "Their inventory is full"
        end

        -- snapshot the fish data
        local fishData: any = nil
        for _, entry in ipairs(saveFrom.Inventory :: {any}) do
            if entry and entry.UID == uid then fishData = entry; break end
        end
        if not fishData then return false, "Fish not found" end

        activeByRecipient[targetUserId] = ({
            FromUserId = player.UserId,
            ToUserId = targetUserId,
            ItemType = "Fish",
            FishData = fishData,
            ExpiresAt = now + 60,
        } :: any)

        Network.Fire(target, "GiftOffered", {
            FromUserId = player.UserId,
            FromName = getDisplayName(player.UserId),
            ItemType = "Fish",
            ItemText = string.format("%s (Lvl %s)", fishData.FishId, tostring(fishData.Level or 1)),
        })
        -- inform gifter
        Network.Fire(player, "GiftResult", { Status = "Sent", Message = "You sent " .. getDisplayName(targetUserId) .. " a gift!" })
        -- schedule expiry
        task.delay(60, function()
            local rec = activeByRecipient[targetUserId]
            if rec and rec.FromUserId == player.UserId and rec.ExpiresAt <= os.clock() then
                local fromP = findPlayerByUserId(player.UserId)
                local toP = findPlayerByUserId(targetUserId)
                if fromP then
                    Network.Fire(fromP, "GiftResult", { Status = "Expired", Message = "Your gift to " .. getDisplayName(targetUserId) .. " expired.", Negative = true })
                end
                if toP then
                    Network.Fire(toP, "GiftResult", { Status = "Expired", Message = "The gift from " .. getDisplayName(player.UserId) .. " expired.", Negative = true })
                end
                activeByRecipient[targetUserId] = nil
            end
        end)
        return true

    else -- Gadget
        local gadgetId = payload and payload.GadgetId
        if type(gadgetId) ~= "string" or gadgetId == "" then
            return false, "No gadget selected"
        end
        local dir = GadgetDirectory[gadgetId]
        if not dir then return false, "Invalid gadget" end
        if not (saveFrom.Tools and saveFrom.Tools[gadgetId]) then
            return false, "You no longer have that gadget"
        end
        -- Recipient already owns gadget
        if saveTo.Tools and saveTo.Tools[gadgetId] then
            return false, getDisplayName(targetUserId) .. " already has that gadget!"
        end

        activeByRecipient[targetUserId] = ({
            FromUserId = player.UserId,
            ToUserId = targetUserId,
            ItemType = "Gadget",
            GadgetId = gadgetId,
            ExpiresAt = now + 60,
        } :: any)

        Network.Fire(target, "GiftOffered", {
            FromUserId = player.UserId,
            FromName = getDisplayName(player.UserId),
            ItemType = "Gadget",
            ItemText = dir.DisplayName,
        })
        -- inform gifter
        Network.Fire(player, "GiftResult", { Status = "Sent", Message = "You sent " .. getDisplayName(targetUserId) .. " a gift!" })
        -- schedule expiry
        task.delay(60, function()
            local rec = activeByRecipient[targetUserId]
            if rec and rec.FromUserId == player.UserId and rec.ExpiresAt <= os.clock() then
                local fromP = findPlayerByUserId(player.UserId)
                local toP = findPlayerByUserId(targetUserId)
                if fromP then
                    Network.Fire(fromP, "GiftResult", { Status = "Expired", Message = "Your gift to " .. getDisplayName(targetUserId) .. " expired.", Negative = true })
                end
                if toP then
                    Network.Fire(toP, "GiftResult", { Status = "Expired", Message = "The gift from " .. getDisplayName(player.UserId) .. " expired.", Negative = true })
                end
                activeByRecipient[targetUserId] = nil
            end
        end)
        return true
    end
end)

-- Recipient declined
Network.Invoked("GiftDecline", function(recipient: Player)
    local gift = activeByRecipient[recipient.UserId]
    if not gift then return false end
    local fromP = findPlayerByUserId(gift.FromUserId)
    if fromP then
        Network.Fire(fromP, "GiftResult", { Status = "Declined", Message = getDisplayName(recipient.UserId) .. " declined your gift.", Negative = true })
    end
    -- set deny cooldown
    local map = denyCooldowns[gift.FromUserId]
    if not map then map = {}; denyCooldowns[gift.FromUserId] = map end
    map[gift.ToUserId] = os.clock() + 120
    activeByRecipient[recipient.UserId] = nil
    return true
end)

-- Recipient accepted -> transfer
Network.Invoked("GiftAccept", function(recipient: Player)
    local gift = activeByRecipient[recipient.UserId]
    if not gift then return false, "No active gift" end
    local gifter = findPlayerByUserId(gift.FromUserId)
    if not gifter then
        Network.Fire(recipient, "GiftResult", { Status = "Missing", Message = getDisplayName(gift.FromUserId) .. " no longer has this item!", Negative = true })
        activeByRecipient[recipient.UserId] = nil
        return false
    end

    local saveFrom = Saving.Get(gifter)
    local saveTo = Saving.Get(recipient)
    if not saveFrom or not saveTo then return false end

    if gift.ItemType == "Fish" then
        local fishData = gift.FishData
        if not fishData then return false end
        -- ensure still owned
        local stillHas = false
        for _, entry in ipairs(saveFrom.Inventory :: {any}) do
            if entry and entry.UID == fishData.UID then stillHas = true; break end
        end
        if not stillHas then
            Network.Fire(recipient, "GiftResult", { Status = "Missing", Message = getDisplayName(gift.FromUserId) .. " no longer has this item!", Negative = true })
            activeByRecipient[recipient.UserId] = nil
            return false
        end
        if not canReceiveFish(recipient) then
            Network.Fire(gifter, "GiftResult", { Status = "Full", Message = getDisplayName(recipient.UserId) .. "'s inventory is full.", Negative = true })
            activeByRecipient[recipient.UserId] = nil
            return false
        end

        -- remove from gifter inventory and tools
        Fish.Take(gifter, fishData.UID)
        -- add to recipient preserving data (Fish.Give supports FishData via any cast)
        local added = Fish.Give(recipient, ({ FishData = fishData } :: any))
        if added then
            Fish.ForceHoldFish(recipient, fishData)
        end

    else -- Gadget
        local gadgetId = gift.GadgetId :: string
        if not (saveFrom.Tools and saveFrom.Tools[gadgetId]) then
            Network.Fire(recipient, "GiftResult", { Status = "Missing", Message = getDisplayName(gift.FromUserId) .. " no longer has this item!", Negative = true })
            activeByRecipient[recipient.UserId] = nil
            return false
        end
        -- remove from gifter
        saveFrom.Tools[gadgetId] = nil
        Gadgets.Take(gifter, gadgetId)
        -- give to recipient
        Gadgets.GiveAndInventory(recipient, gadgetId)
    end

    -- notify both
    Network.Fire(gifter, "GiftResult", { Status = "Accepted", Message = getDisplayName(recipient.UserId) .. " accepted your gift!" })
    Network.Fire(recipient, "GiftResult", { Status = "Accepted", Message = "You accepted " .. getDisplayName(gift.FromUserId) .. "'s gift!" })
    activeByRecipient[recipient.UserId] = nil
    return true
end)

-- Cleanup on player leaving
Players.PlayerRemoving:Connect(function(player)
    -- If player was recipient, clear state and notify gifter
    local recGift = activeByRecipient[player.UserId]
    if recGift then
        local g = findPlayerByUserId(recGift.FromUserId)
        if g then
            Network.Fire(g, "GiftResult", { Status = "Cancelled", Message = getDisplayName(player.UserId) .. " left the game.", Negative = true })
        end
        activeByRecipient[player.UserId] = nil
    end
    -- If player was gifter, notify recipient
    for toId, record in pairs(activeByRecipient) do
        if record.FromUserId == player.UserId then
            local toP = findPlayerByUserId(toId)
            if toP then
                Network.Fire(toP, "GiftResult", { Status = "Missing", Message = getDisplayName(player.UserId) .. " no longer has this item!", Negative = true })
            end
            activeByRecipient[toId] = nil
        end
    end
end)

return GiftService


