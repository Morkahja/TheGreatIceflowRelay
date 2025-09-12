-- TheGreatIceflowRelay.lua
-- Turtle WoW Lua 5.0 compatible
-- /iceflow ready arms the addon, stepping into the starting stage begins the run.
-- Checkpoint messages -> party (if grouped) or local chat.
-- Ball messages -> local only. Auto-check increments +1 sec per tick when holding ball.

-- Frame
TheGreatIceflowRelayFrame = TheGreatIceflowRelayFrame or CreateFrame("Frame")
TheGreatIceflowRelayFrame:Hide()

-- Config / checkpoints
local BALL_NAME = "Heavy Leather Ball" -- adjust if needed
local CHECK_INTERVAL = 2 -- seconds (both checkpoint and ball auto-check intervals)

local checkpoints = {
    { name = "Brewnall Village – Starting Stage", minX = 31.3, maxX = 31.5, minY = 44.3, maxY = 44.5 },
    { name = "The Tree", minX = 32.65, maxX = 32.8, minY = 39.1, maxY = 39.25 },
    { name = "Carcass Island", minX = 34.1, maxX = 34.4, minY = 41.8, maxY = 42.1 },
    { name = "Wet Log", minX = 36.0, maxX = 36.2, minY = 40.5, maxY = 40.8 },
    { name = "Behind the Branch", minX = 34.5, maxX = 35.0, minY = 45.5, maxY = 46.0 },
    { name = "Brewnall Village – Finish Stage", minX = 31.4, maxX = 31.6, minY = 44.7, maxY = 44.9 },
}

-- State
local armed = false        -- set by /iceflow ready
local runActive = false    -- set to true when player enters start while armed
local lastCheckTime = 0

local playerShards = 0
local visitedCheckpoints = {}
local startTriggered = false
local finishTriggered = false

-- Ball state (auto counted only while runActive)
local hasBall = false
local totalBallTime = 0

-- Helpers for output
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

-- Position helper (returns coords scaled to 0..100)
local function GetPlayerXY()
    SetMapZoom(0)
    SetMapToCurrentZone()
    local x, y = GetPlayerMapPosition("player")
    if not x or not y or (x == 0 and y == 0) then return nil end
    return x * 100, y * 100
end

-- Start run (called when entering start stage while armed)
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

-- Stop / disarm run
local function StopAll()
    armed = false
    runActive = false
    TheGreatIceflowRelayFrame:Hide()
    RelayLocalMessage("Iceflow Relay disarmed/stopped.")
end

-- Checkpoint detection and messaging
local function CheckCheckpoint()
    local xy = GetPlayerXY()
    if not xy then return end
    local x, y = xy, nil
    -- because GetPlayerXY returns single value when used wrong earlier in conversation,
    -- do proper assignment:
    x, y = GetPlayerXY()
    if not x then return end

    local zone = GetZoneText()
    if zone ~= "Dun Morogh" then
        return
    end

    local insideAny = false
    for _, cp in ipairs(checkpoints) do
        if x >= cp.minX and x <= cp.maxX and y >= cp.minY and y <= cp.maxY then
            insideAny = true
            -- START: always starts run when armed and not already active
            if cp.name == "Brewnall Village – Starting Stage" then
                if armed and not runActive then
                    StartRun()
                end
                -- keep a local flag so we don't spam while staying in the zone
                startTriggered = true
                finishTriggered = false

            -- FINISH: only if runActive summarize once
            elseif cp.name == "Brewnall Village – Finish Stage" then
                if runActive and not finishTriggered then
                    RelayGroupMessage(string.format(
                        "I finished the relay with %d Iceflow shards! Total ball time: %d sec",
                        playerShards, totalBallTime
                    ))
                    finishTriggered = true
                    -- end run so ballchecks stop until next start (but addon remains armed)
                    runActive = false
                end
                startTriggered = false

            -- regular checkpoints: only active while runActive
            else
                if runActive then
                    if not visitedCheckpoints[cp.name] then
                        visitedCheckpoints[cp.name] = true
                        playerShards = playerShards + 1
                        RelayGroupMessage(string.format(
                            "I arrived at \"%s\" and collected 1 Iceflow shard. Total: %d",
                            cp.name, playerShards
                        ))
                    end
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

-- Ball check function
-- autoMode = true when called from OnUpdate auto-checking (increments +1 sec when runActive)
-- autoMode = false when user calls /iceflow ballcheck (manual, does not increment timer)
local function CheckBallInInventory(autoMode)
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

    if autoMode then
        -- auto behavior only when runActive is true
        if not runActive then
            return
        end

        if foundBall then
            -- every time auto says "have ball" we add +1 sec
            totalBallTime = totalBallTime + 1
            if not hasBall then
                hasBall = true
                RelayLocalMessage("You received a Heavy Leather Ball! Timer started.")
            else
                RelayLocalMessage("You have the Heavy Leather Ball! Pass it! [" .. totalBallTime .. " ]")
            end
        else
            if hasBall then
                hasBall = false
                RelayLocalMessage("You no longer have the Heavy Leather Ball.")
            end
        end

    else
        -- manual check: do not alter timing or hasBall state; just report presence and total
        if foundBall then
            RelayLocalMessage("You currently have a Heavy Leather Ball in your inventory. Total tracked time: " .. totalBallTime .. " sec")
        else
            RelayLocalMessage("You do NOT have a Heavy Leather Ball in your inventory.")
        end
    end
end

-- OnUpdate (time-driven, no elapsed arg)
local lastCheck = 0
TheGreatIceflowRelayFrame:SetScript("OnUpdate", function()
    if not armed and not runActive then return end
    local now = GetTime()
    if now - lastCheck >= CHECK_INTERVAL then
        lastCheck = now
        -- always check checkpoints while armed so we can detect entering start stage
        CheckCheckpoint()
        -- auto ball-check increments only after runActive true
        CheckBallInInventory(true)
    end
end)

-- Slash command handler:
SLASH_ICEFLOW1 = "/iceflow"
SlashCmdList["ICEFLOW"] = function(msg)
    local m = string.lower(msg or "")
    if m == "ready" then
        if armed then
            RelayLocalMessage("Already armed. Enter the starting stage to begin the run.")
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
        RelayLocalMessage("Iceflow Relay armed. Step into the Brewnall Starting Stage to begin the run.")
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
        local insideCheckpoint = nil
        for _, cp in ipairs(checkpoints) do
            if x >= cp.minX and x <= cp.maxX and y >= cp.minY and y <= cp.maxY then
                insideCheckpoint = cp.name
                break
            end
        end
        if insideCheckpoint then
            RelayLocalMessage("Player is in checkpoint: " .. insideCheckpoint)
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
        CheckBallInInventory(false) -- manual check (no increment)
    else
        RelayLocalMessage("Usage: /iceflow ready | end | pos | check | checkpoints | ballcheck")
    end
end
