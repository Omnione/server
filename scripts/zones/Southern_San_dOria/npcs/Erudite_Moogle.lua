-----------------------------------
-- Area: Southern San d'Oria
-- NPC: Erudite Moogle
-- The Elite Adventurer Training Program
-- !pos 26.000 2.100 -2.600 230
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
