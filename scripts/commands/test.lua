-----------------------------------
-- func: test
-- desc: It prints a thing
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = 'iii'
}

local function error(player)
    player:printToPlayer(msg)
    player:printToPlayer('!test')
end

commandObj.onTrigger = function(player, type, anim)
    local target = player:getCursorTarget()

    if target == nil then
        target = player
    end
    --print(target:getPacketName())
    --local C_GREEN  = "|c002|"
    --local C_RESET  = "|c001|"

    -- The entire string will display cleanly in the chat window
    --local completeLine = "The " .. C_GREEN .. "Poo Stick +1" .. C_RESET .. " has been destroyed!"

    --player:printRawText(completeLine, 0)
    --local points = 600
    player:setCharVar('TEATP_Total_Points', 600)
    --player:printToPlayer("Points now set to: "..player:getCharVar('TEATP_Total_Points'))
    --player:setCharVar("TEATP_PurchaseHistory", 0)
    --player:printToPlayer("midnight: "..JstMidnight() - GetSystemTime())
    --[[
    1 = shaded moogle rod +1
    2 = silver voucher
    3 = rod + silver voucher
    4 = #ANV key
    5 = rod + #ANV key
    6 = silver voucher + #ANV key
    7 = shaded moogle rod +1 + #ANV key
    8 = FES gobbiedial key
    9 = shaded moogle rod +1 + FES gobbiedial key
    10 = silver voucher + FES gobbiedial key
    11 = shaded moogle rod +1 + silver voucher + FES gobbiedial key
    12 = #ANV key + FES gobbiedial key
    13 = shaded moogle rod +1 + #ANV key + FES gobbiedial key
    14 = silver voucher + #ANV key + FES gobbiedial key
    15 = shaded moogle rod +1 + silver voucher + #ANV key + FES gobbiedial key
    16 = Trust tome
    17 = shaded moogle rod +1 + Trust tome
    18 = Trust tome + silver voucher
    19 = shaded moogle rod +1 + Trust tome + silver voucher
    20 = Trust tome + #ANV key
    21 = shaded moogle rod +1 + Trust tome + #ANV key
    22 = rust tome + silver voucher + #ANV key






    ]]
    --target:setStatus(xi.status.NORMAL)
    --target:injectAction(player:getID(), 4, 7)
    --player:setCharVar('TEATP_TutorialStatus', 0)
    --player:setCharVar('TEATP_Total_Points', 0)
    --player:independentAnimation(target, type, anim)
    --[[local savedPacked   = player:getLocalVar('TEATP_TrapDisarmed')
    local disarmedCount = 0
    local failedCount   = 0

    for i = 1, 16 do
        local shiftAmount = (i - 1) * 2

        local shifted = bit.rshift(savedPacked, shiftAmount)
        local trapState = bit.band(shifted, 3)

        if trapState == 2 then
            disarmedCount = disarmedCount + 1
        elseif trapState == 1 then
            failedCount = failedCount + 1
        end
    end


    print("current traps = "..player:getLocalVar('TEATP_TrapsRemaining'))]]
end

return commandObj
