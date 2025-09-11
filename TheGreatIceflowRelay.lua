-- TheGreatIceflowRelay.lua
-- Turtle WoW Lia 5.0 compatible
-- Event-driven checkpoint detection with 3-second message cooldown

-- Global frame
TheGreatIceflowRelayFrame = TheGreatIceflowRelayFrame or CreateFrame("Frame")
TheGreatIceflowRelayFrame:Hide()  -- hidden by default

-- Rectangle checkpoints (Iceflow Lake coordinates)
local checkpoints = {
    { name = "Brewnall Village – Landing Stage", minX = 31.3, maxX = 31.6, minY = 44.2, maxY = 44.9 },
    { name = "The Tree", minX = 32.3, maxX = 32.8, minY = 39.1, maxY = 39.2 },
    { name = "Carcass Island", minX = 34.1, maxX = 34.4, minY = 41.8, maxY = 42.1 },
    { name = "Wet Log", minX = 36.0, maxX = 36.2, minY = 40.5, maxY = 40.8 },
    { name = "Behind the Branch", minX = 34.5, maxX = 35.0, minY = 45.5, maxY = 46.0 },
}

local DUN_MOROGH_NAME = "Dun Morogh"  -- internal zone check
local running = false
local debugTick = false
local lastMessageTime = 0
local messageCooldown = 2 -- seconds

-- Helper: get validated player position
local function GetPlayerXY()
    SetMapZoom(0)
    SetMapToCurrentZone()
    local x, y = GetPlayerMapPosition("player")
    if not x or not y or (x == 0 and y == 0) then return nil end
    return x * 100, y * 100
end

-- Check if player is inside a checkpoint
local function CheckCheckpoint()
    local x, y = GetPlayerXY()
    if not x then return end

    local now = GetTime()
    if now - lastMessageTime < messageCooldown then return end

    -- Use Dun Morogh as the zone check
    if GetZoneText() ~= DUN_MOROGH_NAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r Player is not in Dun Morogh")
        lastMessageTime = now
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
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ffff[Iceflow Relay]|r Player is in checkpoint: %s", insideCheckpoint))
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r Player is not in any checkpoint")
    end

    lastMessageTime = now
end

-- OnUpdate loop for tracking
TheGreatIceflowRelayFrame:SetScript("OnUpdate", function(self, elapsed)
    if running then
        CheckCheckpoint()
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
        running = true
        lastMessageTime = 0
        TheGreatIceflowRelayFrame:Show()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r Iceflow Relay started. Move around to track checkpoints.")
    elseif m == "end" then
        if running then
            running = false
            TheGreatIceflowRelayFrame:Hide()
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r Iceflow Relay stopped.")
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
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ffff[Iceflow Relay]|r Player is in checkpoint: %s", insideCheckpoint))
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r Player is not in any checkpoint")
        end
    elseif m == "checkpoints" then
        for _, cp in ipairs(checkpoints) do
            DEFAULT_CHAT_FRAME:AddMessage(string.format("%s: minX=%.2f maxX=%.2f minY=%.2f maxY=%.2f", cp.name, cp.minX, cp.maxX, cp.minY, cp.maxY))
        end
    elseif m == "tick" then
        debugTick = not debugTick
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ffff[Iceflow Relay]|r Debug tick %s", debugTick and "ON" or "OFF"))
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r Usage: /iceflow start | end | pos | check | checkpoints | tick")
    end
end
