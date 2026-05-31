-----------------------------------
-- Area: Windurst Waters
-- NPC: Statistics Moogle
-- 24th Vana'versary Celebration
-- !pos -57.563 -5.717 217.411 238
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
