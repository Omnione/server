-----------------------------------
-- Zone: Bastok_Markets (235)
-----------------------------------
---@type TZone
local zoneObject = {}

zoneObject.onInitialize = function(zone)
    xi.events.harvestFestival.applyHalloweenNpcCostumes(zone:getID())
end

zoneObject.onZoneIn = function(player, prevZone)
    xi.events.theEliteAdventurerTrainingProgram.clearEventStatus(player, prevZone) -- incase of a crash reset and clear the event when they log back in

    return xi.moghouse.onMoghouseZoneEvent(player, prevZone)
end

zoneObject.onConquestUpdate = function(zone, updatetype, influence, owner, ranking, isConquestAlliance)
    xi.conquest.onConquestUpdate(zone, updatetype, influence, owner, ranking, isConquestAlliance)
end

zoneObject.onTriggerAreaEnter = function(player, triggerArea)
    xi.events.theEliteAdventurerTrainingProgram.applyAgentMoogleThreat(player, triggerArea)
end

zoneObject.onGameDay = function()
end

zoneObject.onEventUpdate = function(player, csid, option, npc)
end

zoneObject.onEventFinish = function(player, csid, option, npc)
end

return zoneObject
