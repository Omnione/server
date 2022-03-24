-----------------------------------
-- Area: Qufim Island (126)
-- NPC: Undulating Confluence
-- !pos -204.531 -20.027 75.318 126
-----------------------------------
require("scripts/settings/main")
require("scripts/globals/missions")
require("scripts/globals/teleports")
-----------------------------------
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    if xi.settings.ENABLE_ROV ~= 1 then
        return
    end

    if player:getCurrentMission(ROV) == xi.mission.id.rov.AT_THE_HEAVENS_DOOR then
        player:startEvent(63)
    elseif player:getCurrentMission(ROV) == xi.mission.id.rov.THE_LIONS_ROAR then
        npcUtil.popFromQM(player, npc, ID.mob.OPHIOTAURUS, { look=true, hide=0 })
    elseif player:getCurrentMission(ROV) == xi.mission.id.rov.EDDIES_OF_DESPAIR_I then
        player:startEvent(64)
    else
        player:startEvent(65)
    end
end

entity.onEventUpdate = function(player, csid, option)
end

entity.onEventFinish = function(player, csid, option)
    if csid == 65 and option == 1 then
        xi.teleport.to(player, xi.teleport.id.ESCHA_ZITAH)
    elseif csid == 65 and option == 1 then
        xi.teleport.to(player, xi.teleport.id.ESCHA_ZITAH)
    end
end

return entity
