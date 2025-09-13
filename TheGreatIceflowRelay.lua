-- TheGreatIceflowRelay.lua
-- Turtle WoW Lua 5.0 compatible

-------------------------------------------------
-- 1. Frame
-------------------------------------------------
TheGreatIceflowRelayFrame = TheGreatIceflowRelayFrame or CreateFrame("Frame")
TheGreatIceflowRelayFrame:Hide()

-------------------------------------------------
-- 2. Config / checkpoints
-------------------------------------------------
local BALL_NAME = "Heavy Leather Ball"
local BALL_ICON = "INV_Misc_ThrowingBall_01"
local CHECK_INTERVAL = 2 -- seconds

local checkpoints = {
    { name = "Brewnall Village – Starting Stage", minX = 31.3, maxX = 31.5, minY = 44.3, maxY = 44.5 },
    { name = "The Tree", minX = 32.65, maxX = 32.8, minY = 39.1, maxY = 39.25 },
    { name = "Carcass Island", minX = 34.1, maxX = 34.4, minY = 41.8, maxY = 42.1 },
    { name = "Wet Log", minX = 36.0, maxX = 36.2, minY = 40.5, maxY = 40.8 },
    { name = "Behind the Branch", minX = 34.5, maxX = 35.0, minY = 45.5, maxY = 46.0 },
    { name = "Brewnall Village – Finish Stage", minX = 31.4, maxX = 31.6, minY = 44.7, maxY = 44.9 },
}

-------------------------------------------------
-- 3. State
-------------------------------------------------
local armed = false
local runActive = false
local playerShards = 0
local visitedCheckpoints = {}
local startTriggered = false
local finishTriggered = false

-- Ball state
local hasBall = false
local totalBallTime = 0
local lastCheck = 0
local lastBallCatch = 0
local BALL_CATCH_COOLDOWN = 0.1

-- Target distance penalty
local targetPenaltyPoints = 0
local totalPenalty = 0

-------------------------------------------------
-- 4. Output helpers
-------------------------------------------------
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

-------------------------------------------------
-- 5. Position helper
-------------------------------------------------
local function GetPlayerXY()
    SetMapZoom(0)
    SetMapToCurrentZone()
    local x, y = GetPlayerMapPosition("player")
    if not x or not y or (x == 0 and y == 0) then return nil end
    return x * 100, y * 100
end

-------------------------------------------------
-- 6. Run control
-------------------------------------------------
local function StartRun()
    runActive = true
    playerShards = 0
    visitedCheckpoints = {}
    totalBallTime = 0
    hasBall = false
    targetPenaltyPoints = 0
    totalPenalty = 0
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

-------------------------------------------------
-- 7. Checkpoint detection
-------------------------------------------------
local function CheckCheckpoint()
    local x, y = GetPlayerXY()
    if not x then return end
    if GetZoneText() ~= "Dun Morogh" then return end

    for _, cp in ipairs(checkpoints) do
        if x >= cp.minX and x <= cp.maxX and y >= cp.minY and y <= cp.maxY then
            if cp.name == "Brewnall Village – Starting Stage" then
                if armed and not runActive then
                    StartRun()
                end
                startTriggered = true
                finishTriggered = false
            elseif cp.name == "Brewnall Village – Finish Stage" then
                if runActive and not finishTriggered then
                    -- Sum total penalties
                    totalPenalty = targetPenaltyPoints + totalBallTime
                    local netShards = playerShards - totalPenalty
                    if netShards < 0 then netShards = 0 end

                    RelayGroupMessage(string.format(
                        "%s finished the Great Iceflow Relay with %d Iceflow shards! Total shards: %d Total penalty: %d",
                        UnitName("player"), netShards, playerShards, totalPenalty
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

    startTriggered = false
    finishTriggered = false
end

-------------------------------------------------
-- 8. Ball tracking
-------------------------------------------------
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
        if not runActive then return end
        if foundBall then
            totalBallTime = totalBallTime + 1
            if not hasBall then
                hasBall = true
                RelayLocalMessage("You received a Heavy Leather Ball! Timer started.")
            else
                RelayLocalMessage("You have the Heavy Leather Ball! Pass it! [" .. totalBallTime .. "]")
            end
        else
            if hasBall then
                hasBall = false
                RelayLocalMessage("You no longer have the Heavy Leather Ball.")
            end
        end
    else
        if foundBall then
            RelayLocalMessage("You currently have a Heavy Leather Ball. Total tracked time: " .. totalBallTime .. " sec")
        else
            RelayLocalMessage("You do NOT have a Heavy Leather Ball.")
        end
    end
end

-- ITEM_PUSH handler (catching ball = +1 shard)
local function OnItemPush(arg1, arg2)
    if not runActive then return end
    if arg2 and string.find(arg2, BALL_ICON) then
        local now = GetTime()
        if now - lastBallCatch > BALL_CATCH_COOLDOWN then
            lastBallCatch = now
            playerShards = playerShards + 1
            RelayLocalMessage("Caught a Heavy Leather Ball! +1 shard. Total: " .. playerShards)
        end
    end
end

-------------------------------------------------
-- 8b. Target distance helper
-------------------------------------------------
local function CheckTargetDistance()
    if not UnitExists("target") then return end
    local tooClose = CheckInteractDistance("target", 1) or CheckInteractDistance("target", 2)
                      or CheckInteractDistance("target", 3) or CheckInteractDistance("target", 4)
    if tooClose then
        targetPenaltyPoints = targetPenaltyPoints + 1
        RelayLocalMessage("|cffff0000Target too close!|r Penalty: "..targetPenaltyPoints)
    else
        RelayLocalMessage("|cff00ff00Distance ok!|r")
    end
end

-------------------------------------------------
-- 9. OnUpdate loop
-------------------------------------------------
TheGreatIceflowRelayFrame:SetScript("OnUpdate", function()
    if not armed and not runActive then return end
    local now = GetTime()
    if now - lastCheck >= CHECK_INTERVAL then
        lastCheck = now
        CheckCheckpoint()
        CheckBallInInventory(true)
        CheckTargetDistance()
    end
end)

-------------------------------------------------
-- 10. OnEvent handler
-------------------------------------------------
TheGreatIceflowRelayFrame:SetScript("OnEvent", function()
    if event == "ITEM_PUSH" then
        OnItemPush(arg1, arg2)
    end
end)

-------------------------------------------------
-- 11. Slash commands
-------------------------------------------------
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
        lastBallCatch = 0
        targetPenaltyPoints = 0
        totalPenalty = 0
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
        CheckBallInInventory(false)
    else
        RelayLocalMessage("Usage: /iceflow ready | end | pos | check | checkpoints | ballcheck")
    end
end

-------------------------------------------------
-- 12. Event registration
-------------------------------------------------
TheGreatIceflowRelayFrame:RegisterEvent("ITEM_PUSH")
