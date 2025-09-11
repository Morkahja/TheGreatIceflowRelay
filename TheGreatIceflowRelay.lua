-- Create a visible frame
local IceflowFrame = CreateFrame("Frame", "IceflowFrameGlobal")

-- Show the frame to ensure OnUpdate runs
IceflowFrame:Show()

-- Timer variables
local elapsedTime = 0
local interval = 0.5  -- seconds

-- OnUpdate function
IceflowFrame:SetScript("OnUpdate", function(self, elapsed)
    elapsedTime = elapsedTime + (elapsed or 0)
    if elapsedTime >= interval then
        -- Your position check logic goes here
        local x, y = GetPlayerMapPosition("player")
        if x and y then
            x, y = x*100, y*100
            print(string.format("[Iceflow Relay] Tick: x=%.2f y=%.2f", x, y))
        end

        elapsedTime = 0
    end
end)
