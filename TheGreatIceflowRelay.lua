-- TheGreatIceflowRelay.lua
-- Turtle WoW Addon: The Great Iceflow Relay

local relayFrame = CreateFrame("Frame")
relayFrame:RegisterEvent("PLAYER_STARTED_MOVING")
relayFrame:RegisterEvent("PLAYER_STOPPED_MOVING")
relayFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

-- Saved state
local relayState = {
    running = false,
    shards = 0,
    visited = {},
    insideCheckpoint = nil, -- Track current checkpoint to avoid repeats
}

-- Helper: Send message to group if in party, else print
local function RelayMessage(msg)
    if GetNumPartyMembers() > 0 then
        SendChatMessage("[Iceflow Relay] " .. msg, "PARTY")
    else
        DEFAULT_CHAT_FRAME:AddMessage("[Iceflow Relay] " .. msg)
    end
end

-- Define checkpoints
local checkpoints = {
    { name = "Brewnall Village – Starting Stage", minX = 31.3, maxX = 31.5, minY = 44.3, maxY = 44.5, type = "start" },
    { name = "The Tree", minX = 32.5, maxX = 32.8, minY = 38.9, maxY = 39.2, type = "checkpoint" },
    { name = "Carcass Island", minX = 34.1, maxX = 34.4, minY = 41.8, maxY = 42.1, type = "checkpoint" },
    { name = "Wet Log", minX = 36.0, maxX = 36.1, minY = 40.5, maxY = 40.8, type = "checkpoint" },
    { name = "Behind the Branch", minX = 34.5, maxX = 34.7, minY = 45.7, maxY = 46.0, type = "checkpoint" },
    { name = "Brewnall Village – Finish Stage", minX = 31.4, maxX = 31.6, minY = 44.7, maxY = 44.9, type = "finish" },
}

-- Check if player is inside rectangle
local function IsInArea(x, y, area)
    return x >= area.minX and x <= area.maxX and y >= area.minY and y <= area.maxY
end

-- Main logic
local function CheckPlayerPosition()
    local x, y = GetPlayerMapPosition("player")
    if not x or not y then return end
    x, y = x * 100, y * 100

    local insideNow = nil

    for _, checkpoint in ipairs(checkpoints) do
        if IsInArea(x, y, checkpoint) then
            insideNow = checkpoint.name

            -- Only trigger when entering a new checkpoint
            if relayState.insideCheckpoint ~= checkpoint.name then
                relayState.insideCheckpoint = checkpoint.name

                if checkpoint.type == "start" then
                    relayState.shards = 0
                    relayState.visited = {}
                    RelayMessage("I am at the Starting Stage! My Iceflow shard counter has been reset.")
                elseif checkpoint.type == "checkpoint" and not relayState.visited[checkpoint.name] then
                    relayState.shards = relayState.shards + 1
                    relayState.visited[checkpoint.name] = true
                    RelayMessage("I arrived at \"" .. checkpoint.name .. "\" and collected 1 Iceflow shard.")
                elseif checkpoint.type == "finish" then
                    RelayMessage("I reached the Finish Stage with " .. relayState.shards .. " Iceflow shards collected!")
                end
            end
            break
        end
    end

    -- If not in any checkpoint area, reset tracker so re-entry can trigger again
    if not insideNow then
        relayState.insideCheckpoint = nil
    end
end

-- Event handler
relayFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_STARTED_MOVING" or event == "PLAYER_STOPPED_MOVING" then
        CheckPlayerPosition()
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        SetMapToCurrentZone()
    end
end)

-- Slash command
SLASH_ICEFLOW1 = "/iceflow"
SlashCmdList["ICEFLOW"] = function(msg)
    if msg == "start" then
        relayState.running = true
        RelayMessage("Relay started. Move to checkpoints to collect Iceflow shards!")
    elseif msg == "stop" then
        relayState.running = false
        RelayMessage("Relay stopped.")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00/Iceflow start|r - Begin the relay")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00/Iceflow stop|r - End the relay")
    end
end
