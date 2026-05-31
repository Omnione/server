-----------------------------------
-- func: spawnprop
-- desc: Spawns a dynamic furnishing prop at your current position.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = 'ii'
}

local function error(player, msg)
    player:printToPlayer(msg)
    player:printToPlayer('!spawnprop (itemId) <rotation>')
end

commandObj.onTrigger = function(player, itemId, rotation)
    if itemId == nil or itemId <= 0 then
        error(player, 'You must provide a valid furnishing itemId.')
        return
    end

    ---@type CZone|CInstance?
    local zoneOrInstanceObj = player:getZone()

    local instance = player:getInstance()
    if instance then
        zoneOrInstanceObj = instance
    end

    if not zoneOrInstanceObj then
        error(player, 'Could not resolve zone/instance.')
        return
    end

    local rot = rotation or player:getRotPos()

    local prop = zoneOrInstanceObj:insertPropEntity({
        name        = string.format('prop_%u', itemId),
        itemId      = itemId,
        x           = player:getXPos(),
        y           = player:getYPos(),
        z           = player:getZPos(),
        rotation    = rot,
        entityFlags = 2051,
        namevis     = 96,
        widescan    = 0,
        releaseIdOnDisappear = true,
    })

    if not prop then
        error(player, string.format('Failed to spawn prop for itemId %u. Check that it is a furnishing item.', itemId))
        return
    end

    player:printToPlayer(string.format('Spawned prop: id=%u targ=%u item=%u rot=%u', prop:getID(), prop:getTargID(), itemId, rot))
end

return commandObj
