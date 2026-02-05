---------------------------------------------------------------------------------------------------
-- func: pathtoloc <optional <x> <y> <z>>
-- desc: Tells the target to path to the specified coordinates (or current pos)
-- test example: 
-- !zone Ru'Aun Gardens 
-- !pos 0.1 -43.6 -196.2
-- target a Groundskeeper
-- !pathtoloc 0 -34 -471
-- follow the Groundskeeper to the circle at the start
---------------------------------------------------------------------------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = "sss"
}

local function error(player, msg)
    player:printToPlayer(msg)
    player:printToPlayer('!pathtoloc (x) (y) (z)')
end

commandObj.onTrigger = function(player, x, y, z)
    local target = player:getCursorTarget()

    if target == nil or target:isPC() then
        player:printToPlayer("You must target a non-PC entity.")
        return
    end

    local destX = tonumber(x)
    local destY = tonumber(y)
    local destZ = tonumber(z)

    if destX == nil or destY == nil or destZ == nil then
        -- Use player's current position if no coordinates provided
        local pos = player:getPos()
        destX = pos.x
        destY = pos.y
        destZ = pos.z
        player:printToPlayer(string.format("Pathing %s to your position: (%.2f, %.2f, %.2f)", target:getName(), destX, destY, destZ))
    else
        player:printToPlayer(string.format("Pathing %s to: (%.2f, %.2f, %.2f)", target:getName(), destX, destY, destZ))
    end

    target:pathToLocation(destX, destY, destZ)
end

return commandObj
