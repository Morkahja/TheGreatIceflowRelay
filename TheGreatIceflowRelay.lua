-- Create a global frame to ensure OnUpdate is called
local IceflowFrame = CreateFrame("Frame", "IceflowFrameGlobal", UIParent)
IceflowFrame:Show()

-- Timer variables
local elapsedTime = 0
local interval = 0.5  -- seconds
local countdown = 5
local cdTimer = 0
local running = false
local currentCheckpoint = nil

-- Checkpoints (example)
local checkpoints = {
    { name = "Checkpoint 1", minX = 30, maxX = 35, minY = 40, maxY = 45 },
    -- Add more checkpoints as needed
}

-- Countdown function
local function StartCountdown()
    if countdown > 0 then
        print(string.format("Starting in %d...", countdown))
        countdown = countdown - 1
        cdTimer = 0
    else
        print("START!")
        running = true
        IceflowFrame:SetScript("OnUpdate", function(self, elapsed)
            elapsedTime = elapsedTime + elapsed
            if elapsedTime >= interval then
                CheckPlayerPosition()
                elapsedTime = 0
            end
        end)
    end
end

-- Position checking function
local function CheckPlayerPosition()
    local x, y = GetPlayerMapPosition("player")
    if x == 0 and y == 0 then return end
    x, y = x * 100, y * 100

    local insideCheckpoint = nil
    for _, cp in ipairs(checkpoints) do
        if x >= cp.minX and x <= cp.maxX and y >= cp.minY and y <= cp.maxY then
            insideCheckpoint = cp.name
            break
        end
    end

    if insideCheckpoint then
        if currentCheckpoint ~= insideCheckpoint then
            print(string.format("Entered: %s", insideCheckpoint))
            currentCheckpoint = insideCheckpoint
        end
    else
        if currentCheckpoint then
            print(string.format("Exited: %s", currentCheckpoint))
            currentCheckpoint = nil
        end
    end
end

-- Slash command handler
SLASH_ICEFLOW1 = "/iceflow"
SlashCmdList["ICEFLOW"] = function(msg)
    if msg == "start" then
        if running then
            print("Already running!")
            return
        end
        StartCountdown()
    elseif msg == "end" then
        running = false
        IceflowFrame:SetScript("OnUpdate", nil)
        print("Stopped.")
    else
        print("Usage: /iceflow start | end")
    end
end
