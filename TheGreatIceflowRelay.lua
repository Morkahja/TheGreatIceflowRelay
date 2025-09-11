-- TheGreatIceflowRelay.lua
-- Turtle WoW Lia 5.0 compatible
-- Tracks checkpoints in Dun Morogh and prints enter/exit messages

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
local DEBUG = false  -- set true to print coordinates for testing

-- Utility: same-side / cross-product method
local function Sign(px, py, x1, y1, x2, y2)
    return (px - x2)*(y1 - y2) - (x1 - x2)*(py - y2)
end

local function IsInsideTriangle(px, py, ax, ay, bx, by, cx, cy)
    local d1 = Sign(px, py, ax, ay, bx, by)
    local d2 = Sign(px, py, bx, by, cx, cy)
    local d3 = Sign(px, py, cx, cy, ax, ay)

    local has_neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
    local has_pos = (d1 > 0) or (d2 > 0) or (d3 > 0)

    return not (has_neg and has_pos)
end

local f = CreateFrame("Frame")
f:SetScript("OnUpdate", function(_, elapsed)
    elapsed = elapsed or 0
    updateTimer = updateTimer + elapsed
    if updateTimer < 0.5 then return end
    updateTimer = 0

    -- Only track in Dun Morogh
    local continent = GetCurrentMapContinent()
    if continent ~= DUN_MOROGH then
        if currentCheckpoint then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ffff[Iceflow Relay]|r %s exits checkpoint: %s", UnitName("player"), currentCheckpoint))
            currentCheckpoint = nil
        end
        return
    end

    -- Ensure map coordinates are valid
    SetMapZoom(0)
    SetMapToCurrentZone()
    local x, y = GetPlayerMapPosition("player")
    if x == 0 and y == 0 then return end
    x, y = x*100, y*100

    if DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("DEBUG: x=%.1f y=%.1f", x, y))
    end

    local insideCheckpoint = nil
    for _, cp in ipairs(checkpoints) do
        local A, B, C = cp.points[1], cp.points[2], cp.points[3]
        if IsInsideTriangle(x, y, A[1], A[2], B[1], B[2], C[1], C[2]) then
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
