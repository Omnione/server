-----------------------------------
-- Area: Windurst Waters
-- NPC: Treasure Coffer
-- 24th Vana'versary Celebration Campaign Coffer
-- !pos -54.075 -3.500 45.366 238
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
