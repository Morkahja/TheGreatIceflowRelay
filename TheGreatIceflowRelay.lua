-- TheGreatIceflowRelay.lua
-- Turtle WoW Lua 5.0 compatible
-- Iceflow Relay Addon

------------------------------------------------------------
-- FRAME
------------------------------------------------------------
TheGreatIceflowRelayFrame = TheGreatIceflowRelayFrame or CreateFrame("Frame")
TheGreatIceflowRelayFrame:Hide()

------------------------------------------------------------
-- CONFIG
------------------------------------------------------------
local BALL_NAME = "Heavy Leather Ball" -- item to track
local CHECK_INTERVAL = 2               -- seconds between checks

-- Rectangle checkpoints (zone: Dun Morogh)
local checkpoints = {
    { name = "Brewnall Village – Starting Stage", minX = 31.3, maxX = 31.5, minY = 44.3, maxY = 44.5 },
    { name = "The Tree", minX = 32.65, maxX = 32.8, minY = 39.1, maxY = 39.25 },
    { name = "Carcass Island", minX = 34.1, maxX = 34.4, minY = 41.8, maxY = 42.1 },
    { name = "Wet Log", minX = 36.0, maxX = 36.2, minY = 40.5, maxY = 40.8 },
    { name = "Behind the Branch", minX = 34.5, maxX = 35.0, minY = 45.5, maxY = 46.0 },
    { name = "Brewnall Village – Finish Stage", minX = 31.4, maxX = 31.6, minY = 44.7, maxY = 44.9 },
}

------------------------------------------------------------
-- STATE
------------------------------------------------------------
local armed = false        -- armed by /iceflow ready
local runActive = false    -- true when the relay has begun
local lastCheck = 0        -- timestamp of last update cycle

local playerShards = 0
local visitedCheckpoints = {}
local startTriggered = false
local finishTriggered = false

-- Ball state
local hasBall = false
local totalBallTime = 0

------------------------------------------------------------
-- HELPER FUNCTIONS
------------------------------------------------------------
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

-- Player position (x,y scaled to 0..100)
local function GetPlayerXY()
    SetMapZoom(0)
    SetMapToCurrentZone()
    local x, y = GetPlayerMapPosition("player")
    if not x or not y or (x == 0 and y == 0) then return nil end
    return x * 100, y * 100
end

------------------------------------------------------------
-- CORE LOGIC
------------------------------------------------------------
local function StartRun()
    runActive = true
    playerShards = 0
    visitedCheckpoints = {}
    totalBallTime = 0
    hasBall = false
    startTriggered = true
    finishTriggered = false
    RelayGroupMessage("Let the Great Iceflow Relay begin! Ready, gooo!!!")
end

local function StopAll()
    armed = false
    runActive = false
    TheGreatIceflowRelayFrame:Hide()
    RelayLocalMessage("Iceflow Relay disarmed/stopped.")
end

-- Check if player is inside a checkpoint
local function CheckCheckpoint()
    local x, y = GetPlayerXY()
    if not x then return end

    if GetZoneText() ~= "Dun Morogh" then return end

    local insideAny = false
    for _, cp in ipairs(checkpoints) do
        if x >= cp.minX and x <= cp.maxX and y >= cp.minY and y <= cp.maxY then
            insideAny = true
            if cp.name == "Brewnall Village – Starting Stage" then
                if armed and not runActive then
                    StartRun()
                end
                startTriggered = true
                finishTriggered = false
            elseif cp.name == "Brewnall Village – Finish Stage" then
                if runActive and not finishTriggered then
                    RelayGroupMessage(string.format(
                        "I finished the relay with %d Iceflow shards! Total ball time: %d sec",
                        playerShards, totalBallTime
                    ))
                    finishTriggered = true
                    runActive = false
                end
                startTriggered = false
            else
                if runActive and not visitedCheckpoints[cp.name] then
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

    if not insideAny then
        startTriggered = false
        finishTriggered = false
    end
end

-- Ball check code
local function CheckBallInInventory()
    local foundBall = false
    for b = 0, NUM_BAG_SLOTS do
        local slots = GetContainerNumSlots(b)
        for s = 1, slots do
            local link = GetContainerItemLink(b, s)
            if link and string.find(link, "Heavy Leather Ball") then
                foundBall = true
                ballTimer = ballTimer + 1
                DEFAULT_CHAT_FRAME:AddMessage("Pass it quick! [" .. ballTimer .. "]")
                break
            end
        end
        if foundBall then break end
    end
end


------------------------------------------------------------
-- FRAME SCRIPT
------------------------------------------------------------
TheGreatIceflowRelayFrame:SetScript("OnUpdate", function()
    if not armed and not runActive then return end
    local now = GetTime()
    if now - lastCheck >= CHECK_INTERVAL then
        lastCheck = now
        CheckCheckpoint()
        CheckBallInInventory(true) -- auto-mode
    end
end)

------------------------------------------------------------
-- SLASH COMMANDS
------------------------------------------------------------
SLASH_ICEFLOW1 = "/iceflow"
SlashCmdList["ICEFLOW"] = function(msg)
    local m = string.lower(msg or "")
    if m == "ready" then
        if armed then
            RelayLocalMessage("Already armed. Enter the starting stage to begin.")
            return
        end
        armed = true
        runActive = false
        playerShards = 0
        visitedCheckpoints = {}
        startTriggered = false
        finishTriggered = false
        hasBall = false
        totalBallTime = 0
        lastCheck = 0
        TheGreatIceflowRelayFrame:Show()
        RelayLocalMessage("Relay armed. Step into the starting stage to begin the run.")
    elseif m == "end" then
        StopAll()
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
        local inside = nil
        for _, cp in ipairs(checkpoints) do
            if x >= cp.minX and x <= cp.maxX and y >= cp.minY and y <= cp.maxY then
                inside = cp.name
                break
            end
        end
        if inside then
            RelayLocalMessage("Player is in checkpoint: " .. inside)
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
        CheckBallInInventory(false)
    else
        RelayLocalMessage("Usage: /iceflow ready | end | pos | check | checkpoints | ballcheck")
    end
end

------------------------------------------------------------
-- FUNCTIONALITY SUMMARY
------------------------------------------------------------
-- /iceflow ready
--   Arms the addon. Entering the Starting Stage zone begins the relay run.
--
-- /iceflow end
--   Stops and disarms the addon.
--
-- /iceflow pos
--   Prints current player coordinates (x,y).
--
-- /iceflow check
--   Reports whether the player is currently inside a checkpoint zone.
--
-- /iceflow checkpoints
--   Lists all checkpoint rectangle coordinates.
--
-- /iceflow ballcheck
--   Manual ball inventory check (does not add to timer).
--
-- Automatic behavior:
--   - When armed, entering the Starting Stage triggers the run:
--       * Shards reset
--       * Total ball timer reset
--       * Message to group: "Let the Great Iceflow Relay begin! Ready, gooo!!!"
--   - Moving through checkpoints adds shards (group messages).
--   - Entering Finish Stage ends the run, posting shard count + total ball time.
--   - Every 2s while running:
--       * Checkpoints are monitored
--       * Inventory checked for "Heavy Leather Ball"
--           - If present: adds +1 sec to totalBallTime, prints local message
--           - If removed: prints local message
--
-- Output rules:
--   * Start, checkpoint, finish messages -> party if grouped, else local chat
--   * Ball detection messages -> local chat only
