-- TheGreatIceflowRelay.lua
-- Turtle WoW Lia 5.0 compatible
-- Uses barycentric coordinates for reliable checkpoint detection

-- Checkpoints
local checkpoints = {
    { name = "Brewnall Village – Landing Stage", points = {{31.5,44.2},{31.6,44.8},{30.9,44.9}} },
    { name = "The Tree", points = {{32.8,39.1},{32.3,39.2},{32.6,38.5}} },
    { name = "Carcass Island", points = {{34.4,41.8},{34.1,42.1},{34.1,41.4}} },
    { name = "Wet Log", points = {{36.1,40.8},{36.1,40.5},{36.0,40.7}} },
    { name = "Behind the Branch", points = {{34.7,45.7},{34.6,46.0},{34.5,46.0}} },
}

local DUN_MOROGH = 1
local currentCheckpoint = nil
local updateTimer = 0
local DEBUG = false

-- Barycentric method
local function IsInsideTriangleBarycentric(px, py, A, B, C)
    local v0x, v0y = C[1]-A[1], C[2]-A[2]
    local v1x, v1y = B[1]-A[1], B[2]-A[2]
    local v2x, v2y = px-A[1], py-A[2]

    local dot00 = v0x*v0x + v0y*v0y
    local dot01 = v0x*v1x + v0y*v1y
    local dot02 = v0x*v2x + v0y*v2y
    local dot11 = v1x*v1x + v1y*v1y
    local dot12 = v1x*v2x + v1y*v2y

    local denom = dot00*dot11 - dot01*dot01
    if denom == 0 then return false end  -- degenerate triangle

    local u = (dot11*dot02 - dot01*dot12) / denom
    local v = (dot00*dot12 - dot01*dot02) / denom

    return (u >= 0) and (v >= 0) and (u+v <= 1)
end

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
        if IsInsideTriangleBarycentric(x, y, cp.points[1], cp.points[2], cp.points[3]) then
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
