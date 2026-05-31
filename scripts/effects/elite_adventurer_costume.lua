-----------------------------------
-- xi.effect.ELITE_ADVENTURER_COSTUME
-- Helper for event: The Elite Adventurer Training Program
-----------------------------------
require('scripts/events/the_elite_adventurer_training_program')
-----------------------------------
---@type TEffect
local effectObject = {}

effectObject.onEffectGain = function(target, effect)
    if xi.events and xi.events.theEliteAdventurerTrainingProgram and xi.events.theEliteAdventurerTrainingProgram.onEffectGain then
        xi.events.theEliteAdventurerTrainingProgram.onEffectGain(target, effect)
    end
end

effectObject.onEffectTick = function(target, effect)
    if xi.events and xi.events.theEliteAdventurerTrainingProgram and xi.events.theEliteAdventurerTrainingProgram.onEffectTick then
        xi.events.theEliteAdventurerTrainingProgram.onEffectTick(target, effect)
    end
end

effectObject.onEffectLose = function(target, effect)
    if xi.events and xi.events.theEliteAdventurerTrainingProgram and xi.events.theEliteAdventurerTrainingProgram.onEffectLose then
        xi.events.theEliteAdventurerTrainingProgram.onEffectLose(target, effect)
    end
end

return effectObject
