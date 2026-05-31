-----------------------------------
-- Area: Bastok Markets
-- NPC: Agent Moogle
-- The Elite Adventurer Training Program Event NPC
-----------------------------------
local ID = zones[xi.zone.BASTOK_MARKETS]
-----------------------------------
---@type TNpcEntity
local entity = {}

local pathNodes =
{
    [1] = 
    {
        { x =  0.000, y = 0.000, z = 0.00, rotation = 180, wait = 1500 },
    },
    [2] =
    {
        { x =  0.000, y = 0.000, z = 0.00, rotation = 180, wait = 1500 },
    },
    [3] =
    {
        { x =  0.000, y = 0.000, z = 0.00, rotation = 180, wait = 1500 },
    },
    [4] =
    {
        { x =  0.000, y = 0.000, z = 0.00, rotation = 180, wait = 1500 },
    },
    [5] =
    {
        { x =  0.000, y = 0.000, z = 0.00, rotation = 180, wait = 1500 },
    },
    [6] =
    {
        { x =  0.000, y = 0.000, z = 0.00, rotation = 180, wait = 1500 },
    },
    [7] =
    {
        { x =  0.000, y = 0.000, z = 0.00, rotation = 180, wait = 1500 },
    },
    [8] =
    {
        { x =  0.000, y = 0.000, z = 0.00, rotation = 180, wait = 1500 },
    },
}

entity.onSpawn = function(npc)
    npc:registerEntityTriggerArea(npc:getID(), 8.0, 1.5)

    npc:initNpcAi()

    local trackIndex = (npc:getID() - ID.npc.TEATP_AGENT_MOOGLE_1) + 1

    npc:setPos(xi.path.first(pathNodes[trackIndex]))
    npc:pathThrough(pathNodes[trackIndex], xi.path.flag.COORDS)
end

entity.onPath = function(npc)
    if not npc:isFollowingPath() then
        local trackIndex = (npc:getID() - ID.npc.TEATP_AGENT_MOOGLE_1) + 1

        npc:clearPath()
        
        if npc:atPoint(xi.path.last(pathNodes[trackIndex])) then
            npc:pathThrough(pathNodes[trackIndex], bit.bor(xi.path.flag.COORDS, xi.path.flag.REVERSE))
        elseif npc:atPoint(xi.path.first(pathNodes[trackIndex])) then
            npc:pathThrough(pathNodes[trackIndex], xi.path.flag.COORDS)
        end
    end
end

return entity
