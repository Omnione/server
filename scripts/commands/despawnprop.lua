-----------------------------------
-- func: despawnprop
-- desc: Despawns a dynamic prop by ID or current target.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = 'i'
}

local function error(player, msg)
    player:printToPlayer(msg)
    player:printToPlayer('!despawnprop <entityId>')
end

commandObj.onTrigger = function(player, entityId)
    local targ = nil

    if entityId ~= nil and entityId > 0 then
        ---@diagnostic disable-next-line param-type-mismatch
        targ = GetNPCByID(entityId)
    else
        targ = player:getCursorTarget()
    end

    if targ == nil then
        error(player, 'You must target a prop NPC or provide a valid entityId.')
        return
    end

    if not targ:isNPC() then
        error(player, 'Targeted entity is not an NPC.')
        return
    end

    targ:setStatus(xi.status.DISAPPEAR)
    player:printToPlayer(string.format('Despawned NPC: id=%u targ=%u name=%s', targ:getID(), targ:getTargID(), targ:getName()))
end

return commandObj
