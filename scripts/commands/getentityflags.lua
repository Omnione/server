-----------------------------------
-- func: getentityflags
-- desc: Used to get an entities entity flags for testing.
--       MUST target an entity first.
-----------------------------------

cmdprops =
{
    permission = 1,
    parameters = ""
}

function error(player, msg)
    player:PrintToPlayer(msg)
    player:PrintToPlayer("!getentityflags")
end

function onTrigger(player, target)
    -- validate target
    local targ
    if not target then
        targ = player:getCursorTarget()
        if not targ then
            error(player, "You must target an entity.")
            return
        end
    end

    -- set flags
    local flags = targ:getEntityFlags()
    local hex = "0x" .. string.format("%08x", flags)
    player:PrintToPlayer(string.format("%s's flags: %s (%u)", targ:getName(), hex, flags))
end
