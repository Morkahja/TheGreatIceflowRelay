-- TheGreatIceflowRelay.lua
-- Turtle WoW Lia 5.0 compatible
-- Event-driven checkpoint detection with jump-to-start

-- Global frame
TheGreatIceflowRelayFrame = TheGreatIceflowRelayFrame or CreateFrame("Frame")
TheGreatIceflowRelayFrame:Hide()  -- hidden by default

-- Rectangle checkpoints
local checkpoints = {
    { name = "Brewnall Village – Landing Stage", minX = 31.3, maxX = 31.6, minY = 44.2, maxY = 44.9 },
    { name = "The Tree", minX = 32.3, maxX = 32.8, minY = 39.1, maxY = 39.2 },
    { name = "Carcass Island", minX = 34.1, maxX = 34.4, minY = 41.8, maxY = 42.1 },
    { name = "Wet Log", minX = 36.0, maxX = 36.2, minY = 40.5, maxY = 40.8 },
    { name = "Behind the Branch", minX = 34.5, maxX = 35.0, minY = 45.5, maxY = 46.0 },
}

local DUN_MOROGH = 1
local currentCheckpoint = nil
local running = false
local tracking = false
local debugTick = false

-- Jump-to-start variables
local jumps = 0
local jumpsRequired = 5
local readyToStart = false

-- Helper: get player position
local function GetPlayerXY()
    SetMapZoom(0)
    SetMapToCurrentZone()
    local x, y = GetPlayerMapPosition("player")
    if x == 0 and y == 0 then return nil end
    return x*100, y*100
end

-- Check current position against checkpoints
local function CheckCheckpoint()
    local x, y = GetPlayerXY()
    if not x then return end

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

    if insideCheckpoint ~= currentCheckpoint then
        if currentCheckpoint then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ffff[Iceflow Relay]|r %s exits checkpoint: %s", UnitName("player"), currentCheckpoint))
        end
        if insideCheckpoint then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ffff[Iceflow Relay]|r %s enters checkpoint: %s", UnitName("player"), insideCheckpoint))
        end
        currentCheckpoint = insideCheckpoint
    end

    if debugTick then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ffff[Iceflow Relay]|r Tick: x=%.2f y=%.2f", x, y))
    end
end

-- Event handling
TheGreatIceflowRelayFrame:RegisterEvent("PLAYER_STARTED_MOVING")
TheGreatIceflowRelayFrame:RegisterEvent("PLAYER_STOPPED_MOVING")
TheGreatIceflowRelayFrame:RegisterEvent("UNIT_POSITION_CHANGED")
TheGreatIceflowRelayFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED") -- detect jumps

TheGreatIceflowRelayFrame:SetScript("OnEvent", function(self, event, unit, _, spellID)
    if not running then
        -- Jump-to-start logic
        if event == "UNIT_SPELLCAST_SUCCEEDED" and unit == "player" then
            -- spellID 522 is usually Jump; adjust if different in Turtle WoW
            if spellID == 522 then
                jumps = jumps + 1
                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ffff[Iceflow Relay]|r Jump %d/%d", jumps, jumpsRequired))
                if jumps > jumpsRequired then
                    running = true
                    tracking = IsPlayerMoving() or false
                    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r READY — GO!")
                end
            end
        end
        return
    end

    -- Normal event-driven tracking once running
    if event == "PLAYER_STARTED_MOVING" then
        tracking = true
    elseif event == "PLAYER_STOPPED_MOVING" then
        tracking = false
    elseif event == "UNIT_POSITION_CHANGED" and unit == "player" then
        if tracking then
            CheckCheckpoint()
        end
    end
end)

-- Slash commands
SLASH_ICEFLOW1 = "/iceflow"
SlashCmdList["ICEFLOW"] = function(msg)
    local m = string.lower(msg or "")
    if m == "start" then
        if running then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r Already running!")
            return
        end
        jumps = 0
        running = false
        tracking = false
        TheGreatIceflowRelayFrame:Show()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r Jump 5 times to start the relay.")
    elseif m == "end" then
        if running then
            running = false
            tracking = false
            currentCheckpoint = nil
            jumps = 0
            TheGreatIceflowRelayFrame:Hide()
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r Relay stopped.")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r Relay is not running.")
        end
    elseif m == "pos" then
        local x, y = GetPlayerXY()
        if not x then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r Position unavailable.")
        else
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ffff[Iceflow Relay]|r Current Position: x=%.2f y=%.2f", x, y))
        end
    elseif m == "tick" then
        debugTick = not debugTick
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ffff[Iceflow Relay]|r Debug tick %s", debugTick and "ON" or "OFF"))
    elseif m == "checkpoints" then
        for _, cp in ipairs(checkpoints) do
            DEFAULT_CHAT_FRAME:AddMessage(string.format("%s: minX=%.2f maxX=%.2f minY=%.2f maxY=%.2f", cp.name, cp.minX, cp.maxX, cp.minY, cp.maxY))
        end
    elseif m == "check" then
        local x, y = GetPlayerXY()
        if not x then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r Position unavailable.")
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
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ffff[Iceflow Relay]|r %s is in checkpoint: %s", UnitName("player"), insideCheckpoint))
        else
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ffff[Iceflow Relay]|r %s is not in any checkpoint", UnitName("player")))
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r Usage: /iceflow start | end | pos | tick | checkpoints | check")
    end
end
