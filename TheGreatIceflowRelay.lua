-- TheGreatIceflowRelay.lua
-- Turtle WoW Lia 5.0 compatible
-- Rectangle-based checkpoint detection

-- Rectangle checkpoints
local checkpoints = {
    { name = "Brewnall Village – Landing Stage", minX = 31.3, maxX = 31.6, minY = 44.2, maxY = 44.9 },
    { name = "The Tree", minX = 32.3, maxX = 32.8, minY = 39.1, maxY = 39.2 },
    { name = "Carcass Island", minX = 34.1, maxX = 34.4, minY = 41.8, maxY = 42.1 },
    { name = "Wet Log", minX = 36.0, maxX = 36.2, minY = 40.5, maxY = 40.8 },
    { name = "Behind the Branch", minX = 34.6, maxX = 34.7, minY = 45.7, maxY = 46.0 },
}

local DUN_MOROGH = 1
local currentCheckpoint = nil
local updateTimer = 0
local DEBUG = false

-- Slash command /iceflow pos
SLASH_ICEFLOW1 = "/iceflow"
SlashCmdList["ICEFLOW"] = function(msg)
    local m = string.lower(msg or "")
    if m == "pos" then
        SetMapZoom(0)
        SetMapToCurrentZone()
        local x, y = GetPlayerMapPosition("player")
        if x == 0 and y == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r Position unavailable. Make sure you are in a zone map.")
            return
        end
        x, y = x*100, y*100
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ffff[Iceflow Relay]|r Current Position: x=%.2f y=%.2f", x, y))
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r Usage: /iceflow pos")
    end
end

-- OnUpdate frame for checkpoint detection
local f = CreateFrame("Frame")
f:SetScript("OnUpdate", function(_, elapsed)
    elapsed = elapsed or 0
    updateTimer = updateTimer + elapsed
    if updateTimer < 0.5 then return end
    updateTimer = 0

    -- Force map internally
    SetMapZoom(0)
    SetMapToCurrentZone()

    -- Only track in Dun Morogh
    local continent = GetCurrentMapContinent()
    if continent ~= DUN_MOROGH then
        if currentCheckpoint then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ffff[Iceflow Relay]|r %s exits checkpoint: %s", UnitName("player"), currentCheckpoint))
            currentCheckpoint = nil
        end
        return
    end

    local x, y = GetPlayerMapPosition("player")
    if x == 0 and y == 0 then return end
    x, y = x*100, y*100

    if DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("DEBUG: x=%.2f y=%.2f", x, y))
    end

    local insideCheckpoint = nil
    for _, cp in ipairs(checkpoints) do
        if x >= cp.minX and x <= cp.maxX and y >= cp.minY and y <= cp.maxY then
            insideCheckpoint = cp.name
            break
        end
    end

    if insideCheckpoint then
        if currentCheckpoint ~= insideCheckpoint then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ffff[Iceflow Relay]|r %s enters checkpoint: %s", UnitName("player"), insideCheckpoint))
            currentCheckpoint = insideCheckpoint
        end
    else
        if currentCheckpoint then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ffff[Iceflow Relay]|r %s exits checkpoint: %s", UnitName("player"), currentCheckpoint))
            currentCheckpoint = nil
        end
    end
end)
