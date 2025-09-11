-- TheGreatIceflowRelay.lua
-- Turtle WoW Lua 5.0 compatible
-- Event-driven checkpoint detection with Iceflow shard system and live Heavy Leather Ball detection

TheGreatIceflowRelayFrame = TheGreatIceflowRelayFrame or CreateFrame("Frame")
TheGreatIceflowRelayFrame:Hide()

-- Rectangle checkpoints
local checkpoints = {
    { name = "Brewnall Village – Starting Stage", minX = 31.3, maxX = 31.5, minY = 44.3, maxY = 44.5 },
    { name = "The Tree", minX = 32.65, maxX = 32.8, minY = 39.1, maxY = 39.25 },
    { name = "Carcass Island", minX = 34.1, maxX = 34.4, minY = 41.8, maxY = 42.1 },
    { name = "Wet Log", minX = 36.0, maxX = 36.2, minY = 40.5, maxY = 40.8 },
    { name = "Behind the Branch", minX = 34.5, maxX = 35.0, minY = 45.5, maxY = 46.0 },
    { name = "Brewnall Village – Finish Stage", minX = 31.4, maxX = 31.6, minY = 44.7, maxY = 44.9 },
}

-- State
local running = false
local lastCheckpointCheck = 0
local checkpointInterval = 2 -- seconds
local lastBallCheck = 0
local ballInterval = 2 -- seconds
local playerShards = 0
local visitedCheckpoints = {}
local startTriggered = false
local finishTriggered = false

-- Ball tracking
local hasBall = false
local totalBallTime = 0

-- Group vs. local print
local function RelayGroupMessage(msg)
    if GetNumPartyMembers() > 0 then
        SendChatMessage("[Iceflow Relay] " .. msg, "PARTY")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r " .. msg)
    end
end

local function RelayLocalMessage(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffaaaaaa[Iceflow Ball]|r " .. msg)
end

-- Helper: get validated player position
local function GetPlayerXY()
    SetMapZoom(0)
    SetMapToCurrentZone()
    local x, y = GetPlayerMapPosition("player")
    if not x or not y or (x == 0 and y == 0) then return nil end
    return x * 100, y * 100
end

-- Start the relay run
local function StartRelay()
    running = true
    playerShards = 0
    visitedCheckpoints = {}
    hasBall = false
    totalBallTime = 0
    lastCheckpointCheck = 0
    lastBallCheck = 0
    TheGreatIceflowRelayFrame:Show()
    RelayGroupMessage("Let the Great Iceflow Relay begin! Ready, gooo!!!")
end

-- Stop relay run
local function StopRelay()
    running = false
    TheGreatIceflowRelayFrame:Hide()
    RelayLocalMessage("Iceflow Relay stopped.")
end

-- Check for checkpoints and manage shards
local function CheckCheckpoint()
    local x, y = GetPlayerXY()
    if not x then return end

    local zone = GetZoneText()
    if zone ~= "Dun Morogh" then return end

    local insideAnyCheckpoint = false
    for _, cp in ipairs(checkpoints) do
        if x >= cp.minX and x <= cp.maxX and y >= cp.minY and y <= cp.maxY then
            insideAnyCheckpoint = true
            if cp.name == "Brewnall Village – Starting Stage" then
                if not startTriggered then
                    StartRelay()
                    startTriggered = true
                end
                finishTriggered = false
            elseif cp.name == "Brewnall Village – Finish Stage" then
                if not finishTriggered then
                    RelayGroupMessage(string.format(
                        "I finished the relay with %d Iceflow shards! Total time holding balls: %d sec",
                        playerShards, totalBallTime
                    ))
                    finishTriggered = true
                end
                startTriggered = false
            else
                if not visitedCheckpoints[cp.name] then
                    visitedCheckpoints[cp.name] = true
                    playerShards = playerShards + 1
                    RelayGroupMessage(string.format(
                        "I arrived at \"%s\" and collected 1 Iceflow shard. Total: %d",
                        cp.name, playerShards
                    ))
                end
            end
            return
        end
    end

    if not insideAnyCheckpoint then
        startTriggered = false
        finishTriggered = false
    end
end

-- Check if player has a Heavy Leather Ball
local function CheckBallInInventory()
    local foundBall = false
    for b = 0, NUM_BAG_SLOTS do
        local slots = GetContainerNumSlots(b)
        for s = 1, slots do
            local link = GetContainerItemLink(b, s)
            if link and string.find(link, "Heavy Leather Ball") then
                foundBall = true
                break
            end
        end
        if foundBall then break end
    end

    if foundBall then
        totalBallTime = totalBallTime + 1
        if not hasBall then
            hasBall = true
            RelayLocalMessage("You received a Heavy Leather Ball! Timer started.")
        else
            RelayLocalMessage("You currently have the Heavy Leather Ball! Time = " .. totalBallTime .. " sec")
        end
    else
        if hasBall then
            hasBall = false
            RelayLocalMessage("You no longer have the Heavy Leather Ball.")
        end
    end
end

-- OnUpdate loop with intervals
TheGreatIceflowRelayFrame:SetScript("OnUpdate", function(self, elapsed)
    if not running then return end
    local now = GetTime()

    if now - lastCheckpointCheck >= checkpointInterval then
        CheckCheckpoint()
        lastCheckpointCheck = now
    end

    if now - lastBallCheck >= ballInterval then
        CheckBallInInventory()
        lastBallCheck = now
    end
end)

-- Slash commands
SLASH_ICEFLOW1 = "/iceflow"
SlashCmdList["ICEFLOW"] = function(msg)
    local m = string.lower(msg or "")
    if m == "end" then
        StopRelay()
    elseif m == "pos" then
        local x, y = GetPlayerXY()
        if not x then
            RelayLocalMessage("Position unavailable.")
        else
            RelayLocalMessage(string.format("Current Position: x=%.2f y=%.2f", x, y))
        end
    elseif m == "check" then
        local x, y = GetPlayerXY()
        if not x then
            RelayLocalMessage("Position unavailable.")
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
            RelayLocalMessage(string.format("Player is in checkpoint: %s", insideCheckpoint))
        else
            RelayLocalMessage("Player is not in any checkpoint")
        end
    elseif m == "checkpoints" then
        for _, cp in ipairs(checkpoints) do
            RelayLocalMessage(string.format(
                "%s: minX=%.2f maxX=%.2f minY=%.2f maxY=%.2f",
                cp.name, cp.minX, cp.maxX, cp.minY, cp.maxY
            ))
        end
    elseif m == "ballcheck" then
        CheckBallInInventory()
    else
        RelayLocalMessage("Usage: /iceflow end | pos | check | checkpoints | ballcheck")
    end
end
