-- TheGreatIceflowRelay.lua
-- Turtle WoW Lia 5.0 compatible
-- Rectangle-based checkpoint detection with 5-second countdown

-- Global frame
TheGreatIceflowRelayFrame = TheGreatIceflowRelayFrame or CreateFrame("Frame")
TheGreatIceflowRelayFrame:Hide()  -- hidden by default

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
local elapsedTotal = 0
local debugTick = false
local running = false

-- Countdown variables
local countdown = 5
local cdTimer = 0

-- Main checkpoint detection
local function CheckpointOnUpdate(elapsed)
    updateTimer = updateTimer + elapsed
    elapsedTotal = elapsedTotal + elapsed

    -- Auto stop after 3 hours
    if elapsedTotal >= 3*60*60 then
        running = false
        TheGreatIceflowRelayFrame:SetScript("OnUpdate", nil)
        TheGreatIceflowRelayFrame:Hide()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r Relay stopped automatically after 3 hours.")
        return
    end

    if updateTimer < 0.5 then return end
    updateTimer = 0

    -- Force map
    SetMapZoom(0)
    SetMapToCurrentZone()

    local x, y = GetPlayerMapPosition("player")
    if x == 0 and y == 0 then return end
    x, y = x*100, y*100

    if debugTick then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ffff[Iceflow Relay]|r Tick: x=%.3f y=%.3f", x, y))
    end

    -- Only track in Dun Morogh
    if GetCurrentMapContinent() ~= DUN_MOROGH then
        if currentCheckpoint then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ffff[Iceflow Relay]|r %s exits checkpoint: %s", UnitName("player"), currentCheckpoint))
            currentCheckpoint = nil
        end
        return
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
end

-- Countdown OnUpdate
local function CountdownOnUpdate(elapsed)
    cdTimer = cdTimer + elapsed
    if cdTimer >= 1 then
        if countdown > 0 then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ffff[Iceflow Relay]|r Starting in %d...", countdown))
            countdown = countdown - 1
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r START!")
            -- Start main detection
            updateTimer = 0
            elapsedTotal = 0
            running = true
            TheGreatIceflowRelayFrame:SetScript("OnUpdate", CheckpointOnUpdate)
        end
        cdTimer = 0
    end
end

-- Slash commands
SLASH_ICEFLOW1 = "/iceflow"
SlashCmdList["ICEFLOW"] = function(msg)
    local m = string.lower(msg or "")
    if m == "start" then
        if running then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r Already running!")
            return
        end
        countdown = 5
        cdTimer = 0
        currentCheckpoint = nil
        TheGreatIceflowRelayFrame:Show()
        TheGreatIceflowRelayFrame:SetScript("OnUpdate", CountdownOnUpdate)
    elseif m == "end" then
        if running then
            running = false
            TheGreatIceflowRelayFrame:SetScript("OnUpdate", nil)
            TheGreatIceflowRelayFrame:Hide()
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r Relay stopped.")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r Relay is not running.")
        end
    elseif m == "pos" then
        SetMapZoom(0)
        SetMapToCurrentZone()
        local x, y = GetPlayerMapPosition("player")
        if x == 0 and y == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r Position unavailable.")
            return
        end
        x, y = x*100, y*100
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ffff[Iceflow Relay]|r Current Position: x=%.2f y=%.2f", x, y))
    elseif m == "tick" then
        debugTick = not debugTick
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ffff[Iceflow Relay]|r Debug tick %s", debugTick and "ON" or "OFF"))
    elseif m == "checkpoints" then
        for _, cp in ipairs(checkpoints) do
            DEFAULT_CHAT_FRAME:AddMessage(string.format("%s: minX=%.2f maxX=%.2f minY=%.2f maxY=%.2f", cp.name, cp.minX, cp.maxX, cp.minY, cp.maxY))
        end
    elseif m == "check" then
        SetMapZoom(0)
        SetMapToCurrentZone()
        local x, y = GetPlayerMapPosition("player")
        if x == 0 and y == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r Position unavailable.")
            return
        end
        x, y = x*100, y*100
        local insideCheckpoint = nil
        for _, cp in ipairs(checkpoints) do
            if x >= cp.minX and x <= cp.maxX and y >= cp.minY and y <= cp.maxY then
                insideCheckpoint = cp.name
                break
            end
        end
        if insideCheckpoint then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ffff[Iceflow Relay]|r %s is in checkpoint: %s", UnitName("player"), insideCheckpoint))
        else
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ffff[Iceflow Relay]|r %s is not in any checkpoint", UnitName("player")))
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r Usage: /iceflow start | end | pos | tick | checkpoints | check")
    end
end
