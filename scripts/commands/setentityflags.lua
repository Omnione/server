-----------------------------------
-- func: setentityflags <flags>
-- desc: Used to manipulate an entities entityflags for testing.
--       MUST target an entity first.
-----------------------------------

cmdprops =
{
    permission = 1,
    parameters = "i"
}

function error(player, msg)
    player:PrintToPlayer(msg)
    player:PrintToPlayer("!setentityflags <flags>")
end

function onTrigger(player, flags, target)
    -- validate flags
    if flags ~= nil and tonumber(flags) ~= nil then
        flags = tonumber(flags)
    else
        error(player, "You must supply a flags value.")
        return
    end

    -- validate target
    local targ
    if target == nil then
        targ = player:getCursorTarget()
        if (targ == nil) then
            error(player, "You must target an entity.")
            return
        end
    end

    -- set flags
    player:setEntityFlags(flags, targ:getID())
    local hex = "0x" .. string.format("%08x", flags)
    player:PrintToPlayer( string.format("Set %s %i entity flags to %s (%i).", targ:getName(), targ:getID(), hex, flags) )
end
