-----------------------------------
-- func: entityanimation
-- desc: Push entityAnimation packet from a source entity, optionally targeting another entity.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = 'sss'
}

local function error(player, msg)
    player:printToPlayer(msg)
    player:printToPlayer('!entityanimation <anim|ENUM_NAME> [sourceEntityId] [targetEntityId]')
    player:printToPlayer('Example: !entityanimation main 17760257 ' .. player:getID())
end

local function resolveEntity(idOrNil)
    if idOrNil == nil then
        return nil
    end

    local id = tonumber(idOrNil)
    if id == nil then
        return nil
    end

    return GetEntityByID(id, nil, true)
end

commandObj.onTrigger = function(player, a1, a2, a3)
    if a1 == nil then
        error(player, 'Missing animation argument.')
        return
    end

    local command = xi.animationString[string.upper(a1)] or a1
    if type(command) ~= 'string' or #command ~= 4 then
        error(player, 'Animation must resolve to a FOURCC (4 chars).')
        return
    end

    local source = resolveEntity(a2) or player:getCursorTarget()
    if source == nil then
        error(player, 'No source entity. Target something or pass sourceEntityId.')
        return
    end

    local target = resolveEntity(a3) or player
    source:entityAnimationPacket(command, target)

    player:printToPlayer(string.format(
        'entityAnimationPacket sent: cmd=%s source=%s(%u) target=%s(%u)',
        command, source:getName(), source:getID(), target:getName(), target:getID()
    ))
end

return commandObj