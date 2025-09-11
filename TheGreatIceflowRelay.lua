-- TheGreatIceflowRelay.lua
-- Turtle WoW Lua 5.0 compatible
-- Event-driven checkpoint detection with Iceflow shard system and ball timer

-- Global frame
TheGreatIceflowRelayFrame = TheGreatIceflowRelayFrame or CreateFrame("Frame")
TheGreatIceflowRelayFrame:Hide() -- hidden by default

-- Rectangle checkpoints
local checkpoints = {
    { name = "Brewnall Village – Starting Stage", minX = 31.3, maxX = 31.5, minY = 44.3, maxY = 44.5 },
    { name = "The Tree", minX = 32.65, maxX = 32.8, minY = 39.1, maxY = 39.4 }, -- 0.3 x 0.3 square
    { name = "Carcass Island", minX = 34.1, maxX = 34.4, minY = 41.8, maxY = 42.1 },
    { name = "Wet Log", minX = 36.0, maxX = 36.2, minY = 40.5, maxY = 40.8 },
    { name = "Behind the Branch", minX = 34.5, maxX = 35.0, minY = 45.5, maxY = 46.0 },
    { name = "Brewnall Village – Finish Stage", minX = 31.4, maxX = 31.6, minY = 44.7, maxY = 44.9 },
}

-- State
local running = false
local lastMessageTime = 0
local messageCooldown = 2 -- seconds
local playerShards = 0
local visitedCheckpoints = {}
local startPrinted = false
local finishPrinted = false

-- Ball timer state
local ballTimerRunning = false
local ballStartTime = 0
local totalBallTime = 0

-- Helper: send message to group if in party, else to chat
local function RelayMessage(msg)
    if GetNumPartyMembers() > 0 then
        SendChatMessage("[Iceflow Relay] " .. msg, "PARTY")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r " .. msg)
    end
end

-- Helper: get validated player position
local function GetPlayerXY()
    SetMapZoom(0)
    SetMapToCurrentZone()
    local x, y = GetPlayerMapPosition("player")
    if not x or not y or (x == 0 and y == 0) then return nil end
    return x * 100, y * 100
end

-- Ball detection helper
local function HasBall()
    for b = 0, NUM_BAG_SLOTS do
        local slots = GetContainerNumSlots(b)
        for s = 1, slots do
            local link = GetContainerItemLink(b, s)
            if link and string.find(link, "Heavy Leather Ball") then
                return true
            end
        end
    end
    return false
end

-- Checkpoint handling
local function CheckCheckpoint()
    local x, y = GetPlayerXY()
    if not x then return end
    local now = GetTime()
    if now - lastMessageTime < messageCooldown then return end

    local zone = GetZoneText()
    if zone ~= "Dun Morogh" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r Not in Dun Morogh (current: " .. zone .. ")")
        lastMessageTime = now
        return
    end

    for _, cp in ipairs(checkpoints) do
        if x >= cp.minX and x <= cp.maxX and y >= cp.minY and y <= cp.maxY then
            -- Start stage
            if cp.name == "Brewnall Village – Starting Stage" and not startPrinted then
                playerShards = 0
                visitedCheckpoints = {}
                startPrinted = true
                finishPrinted = false
                totalBallTime = 0
                RelayMessage("I am at the starting stage. My Iceflow shard counter has been reset.")
            -- Finish stage
            elseif cp.name == "Brewnall Village – Finish Stage" and not finishPrinted then
                finishPrinted = true
                RelayMessage(string.format("I finished the relay with %d Iceflow shards and %.1f seconds holding the ball!", playerShards, totalBallTime))
            -- Other checkpoints
            elseif cp.name ~= "Brewnall Village – Starting Stage" and cp.name ~= "Brewnall Village – Finish Stage" then
                if not visitedCheckpoints[cp.name] then
                    visitedCheckpoints[cp.name] = true
                    playerShards = playerShards + 1
                    RelayMessage(string.format("I arrived at \"%s\" and collected 1 Iceflow shard. Total: %d", cp.name, playerShards))
                end
            end
            lastMessageTime = now
            return
        end
    end
end

-- Ball timer handling
local function UpdateBallTimer()
    if HasBall() then
        if not ballTimerRunning then
            ballStartTime = GetTime()
            ballTimerRunning = true
            -- optional: RelayMessage("Ball timer started!")
        end
    else
        if ballTimerRunning then
            totalBallTime = totalBallTime + (GetTime() - ballStartTime)
            ballTimerRunning = false
            -- optional: RelayMessage("Ball timer stopped!")
        end
    end
end

-- OnUpdate loop for tracking
TheGreatIceflowRelayFrame:SetScript("OnUpdate", function(self, elapsed)
    if running then
        CheckCheckpoint()
        UpdateBallTimer()
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
        playerShards = 0
        visitedCheckpoints = {}
        startPrinted = false
        finishPrinted = false
        lastMessageTime = 0
        totalBallTime = 0
        ballTimerRunning = false
        TheGreatIceflowRelayFrame:Show()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r Iceflow Relay started. Move around to track checkpoints.")
    elseif m == "end" then
        if running then
            running = false
            TheGreatIceflowRelayFrame:Hide()
            -- stop ball timer if still running
            if ballTimerRunning then
                totalBallTime = totalBallTime + (GetTime() - ballStartTime)
                ballTimerRunning = false
            end
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
    elseif m == "ballcheck" then
        if HasBall() then
            RelayMessage("I currently have a Heavy Leather Ball in my inventory!")
        else
            RelayMessage("I do NOT have a Heavy Leather Ball in my inventory.")
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r Usage: /iceflow start | end | pos | check | checkpoints | ballcheck")
    end
end
