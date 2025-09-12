-- TheGreatIceflowRelay.lua
-- Turtle WoW Lua 5.0 compatible
-- Event-driven checkpoint detection with Iceflow shard system and live ball timer

-- Global frame
TheGreatIceflowRelayFrame = TheGreatIceflowRelayFrame or CreateFrame("Frame")
TheGreatIceflowRelayFrame:Hide() -- hidden by default

-- Ball settings
local BALL_NAME = "Heavy Leather Ball"

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
local runActive = false
local lastMessageTime = 0
local messageCooldown = 2 -- seconds
local lastBallCheck = 0
local ballCheckInterval = 2 -- seconds
local playerShards = 0
local visitedCheckpoints = {}
local startTriggered = false
local finishTriggered = false
local totalBallTime = 0
local hasBall = false

-- Helper: send message to group if in party, else to chat
local function RelayMessage(msg)
    if GetNumPartyMembers() > 0 then
        SendChatMessage("[Iceflow Relay] " .. msg, "PARTY")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r " .. msg)
    end
end

-- Helper: send local chat message only
local function RelayLocalMessage(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r " .. msg)
end

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

    local zone = GetZoneText()
    if zone ~= "Dun Morogh" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r Not in Dun Morogh (current: " .. zone .. ")")
        lastMessageTime = now
        return
    end

    local insideAnyCheckpoint = false

    for _, cp in ipairs(checkpoints) do
        if x >= cp.minX and x <= cp.maxX and y >= cp.minY and y <= cp.maxY then
            insideAnyCheckpoint = true
            if cp.name == "Brewnall Village – Starting Stage" then
                if not startTriggered then
                    runActive = true
                    playerShards = 0
                    visitedCheckpoints = {}
                    totalBallTime = 0
                    hasBall = false
                    RelayMessage("Let the Great Iceflow Relay begin!")
                    startTriggered = true
                end
                finishTriggered = false
            elseif cp.name == "Brewnall Village – Finish Stage" then
                if not finishTriggered then
                    RelayMessage(string.format("I finished the relay with %d Iceflow shards! Total ball time: %d sec", playerShards, totalBallTime))
                    runActive = false
                    finishTriggered = true
                end
                startTriggered = false
            else
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

    if not insideAnyCheckpoint then
        startTriggered = false
        finishTriggered = false
    end
end

-- Ball check
local function CheckBallInInventory()
    local foundBall = false
    for b = 0, NUM_BAG_SLOTS do
        local slots = GetContainerNumSlots(b)
        if slots and slots > 0 then
            for s = 1, slots do
                local link = GetContainerItemLink(b, s)
                if link and string.find(link, BALL_NAME) then
                    foundBall = true
                    break
                end
            end
        end
        if foundBall then break end
    end

    if not runActive then return end

    if foundBall then
        totalBallTime = totalBallTime + 1
        RelayLocalMessage("Hold the ball briefly, pass it quickly! [" .. totalBallTime .. "]")
        hasBall = true
    else
        hasBall = false
    end
end

-- OnUpdate loop for tracking
TheGreatIceflowRelayFrame:SetScript("OnUpdate", function(self, elapsed)
    if running then
        CheckCheckpoint()
        local now = GetTime()
        if now - lastBallCheck >= ballCheckInterval then
            lastBallCheck = now
            CheckBallInInventory()
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
        running = true
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
    elseif m == "ballcheck" then
        CheckBallInInventory()
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Iceflow Relay]|r Usage: /iceflow start | end | pos | check | checkpoints | ballcheck")
    end
end

--[[ 
TheGreatIceflowRelay Addon - Turtle WoW Lua 5.0 compatible
------------------------------------------------------------

Functionality:

1. Automatic checkpoint detection:
   - Tracks player position every 2 seconds.
   - Detects entry into checkpoint rectangles.
   - Start zone: automatically triggers the relay run.
   - Checkpoints: collect Iceflow shards (points) when entered.
   - Finish zone: summarizes total Iceflow shards collected.

2. Ball timer system:
   - Detects when the player has a Heavy Leather Ball.
   - Tracks how long the player holds the ball (adds 1 sec per 2-second check).
   - Provides live feedback in the chat to encourage quick passes.

3. Messages:
   - Checkpoint, start, and finish messages are sent to party chat if in a group, else to local chat.
   - Ball messages are always printed only to local chat.
   - Start message: "Let the great Iceflow Relay begin!"
   - Finish message: announces total Iceflow shards and total ball holding time.

Slash commands:

/iceflow ready     → Activates Iceflow Relay functionality (checks start zone to begin run)
/iceflow end       → Stops the Iceflow Relay addon
/iceflow pos       → Prints current player coordinates
/iceflow check     → Checks if player is currently inside any checkpoint
/iceflow checkpoints → Lists all defined checkpoints with coordinates
/iceflow ballcheck → Manually checks if you have a Heavy Leather Ball and prints tracked time

Notes:
- The addon automatically starts a run when entering the start zone.
- Ball holding timer only counts while the player actually has a ball in inventory.
- The addon is fully event-driven and optimized for Turtle WoW Lua 5.0.
]]--
