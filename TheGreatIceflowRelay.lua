-- Ball check
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
                RelayLocalMessage("You received the Heavy Leather Ball! Pass it quickly! [" .. totalBallTime .. "]")
            else
                RelayLocalMessage("Hold onto it briefly! [" .. totalBallTime .. "]")
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
            RelayLocalMessage("You do NOT have a Heavy Leather Ball in your inventory.")
        end
    end
end
