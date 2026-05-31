-----------------------------------
-- Area: Southern San d'Oria
-- NPC: Treasure Coffer
-- 24th Vana'versary Celebration Campaign Coffer
-- !pos 13.559 2.100 11.330 230
-----------------------------------
local ID = zones[xi.zone.SOUTHERN_SAN_DORIA]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrigger = function(player, npc)
    xi.events.theEliteAdventurerTrainingProgram.onTrigger(player, npc)
end

entity.onEventUpdate = function(player, csid, option, npc)
    xi.events.theEliteAdventurerTrainingProgram.onEventUpdate(player, csid, option, npc)
end

entity.onEventFinish = function(player, csid, option, npc)
    xi.events.theEliteAdventurerTrainingProgram.onEventFinish(player, csid, option, npc)
end

return entity
