-----------------------------------
-- Area: Windurst Waters
-- NPC: Erudite Moogle
-- The Elite Adventurer Training Program
-- !pos -48.500 -3.500 59.500 238
-----------------------------------
local ID = zones[xi.zone.WINDURST_WATERS]
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
