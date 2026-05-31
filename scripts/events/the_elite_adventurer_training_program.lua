-------------------------------------------
-- The Elite Adventurer Training Program
-------------------------------------------
xi = xi or {}
xi.events = xi.events or {}
xi.events.theEliteAdventurerTrainingProgram = xi.events.theEliteAdventurerTrainingProgram or {}
xi.events.theEliteAdventurerTrainingProgram.data = xi.events.theEliteAdventurerTrainingProgram.data or {}
xi.events.theEliteAdventurerTrainingProgram.entities = xi.events.theEliteAdventurerTrainingProgram.entities or {}

local event = SeasonalEvent:new('TheEliteAdventurerTrainingProgram')

local musicZones =
{
    xi.zone.SOUTHERN_SAN_DORIA,
    xi.zone.BASTOK_MARKETS,
    xi.zone.WINDURST_WATERS,
}

local shadedMoogleCostume = 2364 -- 30 min costume in event, rod +1 gives 1hr when used as an item.

local updateMogEnergyUI
local clearMogEnergyUI
local stopMogEnergyDrain

local mogEnergy =
{
    max              = 100,
    start            = 100,
    duration         = 1800,
    effectTick       = 3,
    passiveDrainTick = 1,
    stareCost        = 0,
    failCost         = 15,
    disarmGain       = 15,
    warningPercent   = 20,
}

local agentThreat =
{
    detectRange   = 10,
    detectConeDeg = 65,
    drainAmount   = 5,
    cooldownSec   = 15,
}

local actions =
{
    stare = 1,
    slap  = 2,
}

local trapStates =
{
    notTriggered = 0,
    failed       = 1,
    disarmed     = 2,
}

local messageOffset =
{
    SH_MOOGLE_ROD_DOESNT_RESPOND = 0,  -- The ≺item≻ doesn't respond.
    SH_MOOGLE_ROD_RESPONDS       = 1,  -- The ≺item> responds! Target and /slap it to disarm!
    COUNTDOWN                    = 2,  -- ...≺munber≻.
    DISARM_UNSUCCESSFUL          = 3,  -- Disarm unsuccessful! (≺number≻ left)
    DISARM_SUCCESSFUL            = 4,  -- Disarm successful! (≺number≻ left.) You receive ≺number≻ points for a total of ≺number≻.
    FINISH_SUCCESSFUL_ALL_TRAPS  = 5,  -- Disarm successful! Perfectly done! You receive ≺number≻ points and a ≺number≻ point bonus for a total of ≺number≻.
    END_EVENT                    = 6,  -- The Elite Adventurer Training Program is complete, kupo.
    RESULTS                      = 7,  -- Results: ≺number≻ points acquired for a total of ≺number≻.≺number≻
    POINT_LIMIT                  = 8,  -- You have reached the point limit of ≺number≻. Any excess points have been discarded.
    ENEGRY_DEPLETED              = 9,  -- Your Enchanting Energy has run out.
    COSTUME_REMOVED              = 10, -- The Moogle Magic has worn off.
    SPOTTED                      = 11, -- An Agent Moogle has spotted you!
    WRONG_AREA_NOTICE            = 12, -- The program is only active in the North Area. There are no traps in the South Area.
}

local function getTotalPoints(player)
    return player:getCharVar('TEATP_Total_Points')
end

local function getRoundPoints(player)
    return player:getLocalVar('TEATP_Round_Points')
end

local function getPurchaseHistory(player)
    return player:getCharVar('TEATP_PurchaseHistory')
end

local function getMogEnergy(player)
    return player:getLocalVar('TEATP_MogEnergy')
end

local function isRodEquiped(player)
    local mainWeapon = player:getEquipID(xi.slot.MAIN)

    return (mainWeapon == xi.item.SHADED_MOOGLE_ROD or mainWeapon == xi.item.SHADED_MOOGLE_ROD_P1) and 1 or 0
end

local function getEventStatus(player)
    return player:getCharVar('TEATP_TutorialStatus')
end

local function eventCostumeActive(player)
    return player:hasStatusEffect(xi.effect.ELITE_ADVENTURER_COSTUME)
end

local function isAgentMoogle(npc)
    if not npc then
        return false
    end

    local name = (npc:getName() or ''):lower()
    return name:find('agent_moogle') ~= nil
end

local function pauseOnThreat(npc, player)
    npc:setBaseSpeed(0)
    npc:facePlayer(player, false)

    npc:timer(3000, function(npc)
        npc:setBaseSpeed(80)
    end)
end

local function isTrap(npc)
    if not npc or not npc:isNPC() then
        return false 
    end
    
    local name = npc:getPacketName() or ''

    if string.find(name, '???') then
        return true
    end

    return false
end

local function getTrapIndex(npc, zoneID)
    if not npc or not zoneID then
        return
    end
    local firstID = zones[zoneID].npc.TEATP_TRAP_1
    local trapID  = npc:getID()
    local index   = trapID - firstID

    return zones[zoneID].npc.TEATP_TRAP_1 - npc:getID()
end

local function getTrapState(player, trapIndex)
    local shiftAmount   = (trapIndex - 1) * 2
    local currentPacked = player:getLocalVar('TEATP_TrapStates')
    local shifted       = bit.rshift(currentPacked, shiftAmount)

    return bit.band(shifted, 3)
end

local function setTrapState(player, trapIndex, newState)
    local shiftAmount   = (trapIndex - 1) * 2
    local currentPacked = player:getLocalVar('TEATP_TrapStates')
    local clearMask     = bit.bnot(bit.lshift(3, shiftAmount))
    local clearedPacked = bit.band(currentPacked, clearMask)
    local shiftedState  = bit.lshift(newState, shiftAmount)
    local updatedPacked = bit.bor(clearedPacked, shiftedState)

    player:setLocalVar('TEATP_TrapStates', updatedPacked)
end

local function getAllTrapStates(player)
    local savedPacked   = player:getLocalVar('TEATP_TrapStates')
    local disarmedCount = 0
    local failedCount   = 0

    for i = 1, 16 do
        local shiftAmount = (i - 1) * 2

        local shifted   = bit.rshift(savedPacked, shiftAmount)
        local trapState = bit.band(shifted, 3)

        if trapState == trapStates.disarmed then
            disarmedCount = disarmedCount + 1
        elseif trapState == trapStates.failed then
            failedCount = failedCount + 1
        end
    end

    return disarmedCount, failedCount
end

updateMogEnergyUI = function(player, value)
    local clamped = utils.clamp(value, 0, mogEnergy.max)

    player:setLocalVar('TEATP_MogEnergy', clamped)
    player:objectiveUtility({ bars = { [1] = { title = 'Mog Energy', value = clamped, }, }, })

    return clamped
end

clearMogEnergyUI = function(player)
    player:setLocalVar('TEATP_MogEnergy', 0)
    player:objectiveUtility({})
end

stopMogEnergyDrain = function(player)
    player:delStatusEffectSilent(xi.effect.ELITE_ADVENTURER_COSTUME)
    player:setLocalVar('TEATP_AgentDrainNext', 0)
end

local function startMogEnergyDrain(player)
    if not player:hasStatusEffect(xi.effect.ELITE_ADVENTURER_COSTUME) then
        player:addStatusEffect(xi.effect.ELITE_ADVENTURER_COSTUME,
        {
            power    = shadedMoogleCostume,
            tick     = mogEnergy.effectTick,
            duration = mogEnergy.duration,
            origin   = player,
            icon     = xi.effect.COSTUME,
        })
    end
end

local function restoreZoneMusic(player)
    local zone = GetZone(player:getZoneID())

    player:changeMusic(0, zone:getBackgroundMusicDay())
    player:changeMusic(1, zone:getBackgroundMusicNight())
end

local function endEliteCourse(player)
    local zoneID = player:getZoneID()

    player:messageSpecial(zones[zoneID].text.TEATP_OFFSET + messageOffset.END_EVENT)

    local points      = getRoundPoints(player)
    local totalPoints = getTotalPoints(player)

    player:messageSpecial(zones[zoneID].text.TEATP_OFFSET + messageOffset.RESULTS, points, totalPoints)

    player:setCostume(0)
    player:setLocalVar('TEATP_Active', 0)
    player:setLocalVar('TEATP_AgentDrainNext', 0)
    player:enableEntities({})

    stopMogEnergyDrain(player)
    clearMogEnergyUI(player)
    restoreZoneMusic(player)
end

xi.events.theEliteAdventurerTrainingProgram.clearEventStatus = function(player, prevZone)
    if not player:getZoneID() == prevZone then
        return
    end

    if eventCostumeActive(player) then
        player:delStatusEffectSilent(xi.effect.ELITE_ADVENTURER_COSTUME)
    end

    if getMogEnergy(player) > 0 then
        player:enableEntities({})
        stopMogEnergyDrain(player)
        clearMogEnergyUI(player)
    end
end

local function proccessTrapAction(player, npc, action)
    local zoneID    = player:getZoneID()
    local trapID    = npc:getID()
    local trapIndex = getTrapIndex(npc, zoneID)
    local trapState = getTrapState(player, trapIndex) 

    if action == actions.stare then
        -- Create a unique token ID for this specific staring sequence
        local uniqueTrapToken = math.random(100000, 999999)
        player:setLocalVar('TEATP_ActiveTrapID', uniqueTrapToken)

        player:enableEntities({ trapID })

        player:timer(750, function(targetPlayer)
            -- Verify this timer belongs to the CURRENT, UNBROKEN stare session
            if targetPlayer:getLocalVar('TEATP_ActiveTrapID') ~= uniqueTrapToken then return end

            local lastTrapID  = targetPlayer:getLocalVar('TEATP_LastTrapID')
            local currentZone = targetPlayer:getZoneID()
            local trapNpc     = GetNPCByID(lastTrapID)
            
            if trapNpc then
                local currentIdx = getTrapIndex(trapNpc, currentZone)
                if getTrapState(targetPlayer, currentIdx) == trapStates.notTriggered then
                    targetPlayer:messageSpecial(zones[currentZone].text.TEATP_OFFSET + messageOffset.COUNTDOWN, 3)
                end
            end
        end)

        player:timer(1500, function(targetPlayer)
            if targetPlayer:getLocalVar('TEATP_ActiveTrapID') ~= uniqueTrapToken then return end

            local lastTrapID  = targetPlayer:getLocalVar('TEATP_LastTrapID')
            local currentZone = targetPlayer:getZoneID()
            local trapNpc     = GetNPCByID(lastTrapID)

            if trapNpc then
                local currentIdx = getTrapIndex(trapNpc, currentZone)
                if getTrapState(targetPlayer, currentIdx) == trapStates.notTriggered then
                    targetPlayer:messageSpecial(zones[currentZone].text.TEATP_OFFSET + messageOffset.COUNTDOWN, 2)
                end
            end
        end)

        player:timer(2250, function(targetPlayer)
            if targetPlayer:getLocalVar('TEATP_ActiveTrapID') ~= uniqueTrapToken then return end

            local lastTrapID  = targetPlayer:getLocalVar('TEATP_LastTrapID')
            local currentZone = targetPlayer:getZoneID()
            local trapNpc     = GetNPCByID(lastTrapID)

            if trapNpc then
                local currentIdx = getTrapIndex(trapNpc, currentZone)
                if getTrapState(targetPlayer, currentIdx) == trapStates.notTriggered then
                    targetPlayer:messageSpecial(zones[currentZone].text.TEATP_OFFSET + messageOffset.COUNTDOWN, 1)
                end
            end
        end)

        player:timer(3000, function(targetPlayer)
            -- If they slapped even 1ms ago, this token is mismatched, and this entire block vanishes safely!
            if targetPlayer:getLocalVar('TEATP_ActiveTrapID') ~= uniqueTrapToken then return end

            local lastTrapID  = targetPlayer:getLocalVar('TEATP_LastTrapID')
            local currentZone = targetPlayer:getZoneID()
            local trapNpc     = GetNPCByID(lastTrapID)

            if trapNpc then
                local currentIdx = getTrapIndex(trapNpc, currentZone)
                if getTrapState(targetPlayer, currentIdx) == trapStates.notTriggered then
                    
                    -- Close out the token session since the failure is running natively
                    targetPlayer:setLocalVar('TEATP_ActiveTrapID', 0)

                    setTrapState(targetPlayer, currentIdx, trapStates.failed)
                    
                    local currentEnergy = targetPlayer:getLocalVar('TEATP_MogEnergy')
                    updateMogEnergyUI(targetPlayer, currentEnergy - mogEnergy.failCost)
                    
                    targetPlayer:independentAnimation(targetPlayer, 53, 8)
                    
                    if isTrap(trapNpc) then
                        local remainingTrapCount = targetPlayer:getLocalVar('TEATP_TrapsRemaining')

                        if remainingTrapCount > 1 then
                            targetPlayer:messageSpecial(zones[currentZone].text.TEATP_OFFSET + messageOffset.DISARM_UNSUCCESSFUL, 0, 0, remainingTrapCount - 1)
                            targetPlayer:setLocalVar('TEATP_TrapsRemaining', remainingTrapCount - 1)
                        else
                            print("unsuccessful disarm, last trap endingCourse")
                            endEliteCourse(targetPlayer)
                        end
                        targetPlayer:enableEntities({})
                    end

                    targetPlayer:addStatusEffect(xi.effect.BIND, { duration = 5, origin = targetPlayer })
                end
            end
        end)
    elseif action == actions.slap then
        local lastTrapID = player:getLocalVar('TEATP_LastTrapID')

        if not lastTrapID or lastTrapID == 0 then
            return
        end

        local trapNpc = GetNPCByID(lastTrapID)
        if trapNpc then
            local currentIdx = getTrapIndex(trapNpc, zoneID)
            
            -- Check if the trap is already handled before running slap logic
            if getTrapState(player, currentIdx) ~= trapStates.notTriggered then
                return
            end

            -- Invalidate any scheduled or pending stare timers
            player:setLocalVar('TEATP_ActiveTrapID', 0)
            
            setTrapState(player, currentIdx, trapStates.disarmed)
            player:independentAnimation(player, 250, 4)
            player:enableEntities({})

            local currentEnergy = getMogEnergy(player)
            updateMogEnergyUI(player, currentEnergy + mogEnergy.disarmGain)

            local disarmed, failed   = getAllTrapStates(player)
            local roundPoints        = getRoundPoints(player)
            local totalPoints        = getTotalPoints(player)
            local startingPoints     = 0 
            local remainingTrapCount = player:getLocalVar('TEATP_TrapsRemaining')

            if player:getEquipID(xi.slot.MAIN) == xi.item.SHADED_MOOGLE_ROD_P1 then 
                startingPoints = 1
            end

            local trapScore = startingPoints + disarmed

            if remainingTrapCount <= 1 then
                local finalEventPoints = 0

                if failed == 0 then
                    local energyBonus = math.floor(currentEnergy * 0.3)

                    finalEventPoints = roundPoints + trapScore + energyBonus
                    print(string.format("trapScore = %s, roundPoints = %s, energyBonus = %s, finalEventPoints = %s", trapScore, roundPoints, energyBonus, finalEventPoints))

                    player:messageSpecial(zones[zoneID].text.TEATP_OFFSET + messageOffset.FINISH_SUCCESSFUL_ALL_TRAPS, trapScore, finalEventPoints, energyBonus)
                else
                    finalEventPoints = roundPoints + trapScore
                end

                player:setCharVar('TEATP_Total_Points', totalPoints + finalEventPoints)
                player:setLocalVar('TEATP_Round_Points', finalEventPoints)

                print("/slap last trap endingCourse")
                endEliteCourse(player)  
            else
                player:messageSpecial(zones[zoneID].text.TEATP_OFFSET + messageOffset.DISARM_SUCCESSFUL, trapScore, roundPoints + trapScore, remainingTrapCount - 1)
                player:setLocalVar('TEATP_Round_Points', roundPoints + trapScore)
                player:setLocalVar('TEATP_TrapsRemaining', remainingTrapCount - 1)
            end
        end
    end
end

-----------------------------------
-- Agent Moogle functions
-----------------------------------

xi.events.theEliteAdventurerTrainingProgram.applyAgentMoogleThreat = function(player, triggerArea)
    local npcID = triggerArea:getTriggerAreaID()
    local npc   = GetNPCByID(npcID)

    if not player or not npcID or not npc then
        return
    end

    if not eventCostumeActive(player) and player:getLocalVar('TEATP_Active') ~= 1 then
        return
    end

    if not npc:isFacing(player) then
        return
    end

    local now         = GetSystemTime()
    local nextAllowed = player:getLocalVar('TEATP_AgentDrainNext')

    if nextAllowed ~= 0 and now < nextAllowed then
        return
    end

    local allowMogDrain = false

    for _, entityID in pairs(xi.events.theEliteAdventurerTrainingProgram.entities) do
        if entityID == npcID then
            allowMogDrain = true
            break
        end
    end

    if not allowMogDrain then
        return
    end

    
    local playerZone = player:getZoneID()

    if npc and npc:getZoneID() == playerZone then
        pauseOnThreat(npc, player)
        npc:injectActionPacket(player:getID(), 11, 1499, 0, 0x18, 0, 0, 0)
        player:messageSpecial(zones[playerZone].text.TEATP_OFFSET + messageOffset.SPOTTED)
        player:setLocalVar('TEATP_AgentDrainNext', now + agentThreat.cooldownSec)
        local currentEnergy = getMogEnergy(player)
        updateMogEnergyUI(player, currentEnergy - agentThreat.drainAmount)
    end
end

-----------------------------------
-- Costume Effect Handlers
-----------------------------------

xi.events.theEliteAdventurerTrainingProgram.onEffectGain = function(target, effect)
    if getMogEnergy(target) <= 0 then
        updateMogEnergyUI(target, mogEnergy.start)
    end
end

xi.events.theEliteAdventurerTrainingProgram.onEffectTick = function(target, effect)
    if not eventCostumeActive(target) then
        if target:getLocalVar('TEATP_Active') == 1 then
            print("onEffectTick not eventCostumeActive endingCourse")
            endEliteCourse(target)
        else
            stopMogEnergyDrain(target)
            clearMogEnergyUI(target)
        end
        return
    end

    local currentEnergy = getMogEnergy(target)
    local nextEnergy    = updateMogEnergyUI(target, currentEnergy - mogEnergy.passiveDrainTick)

    if nextEnergy <= 0 then
        target:messageSpecial(zones[target:getZoneID()].text.TEATP_OFFSET + messageOffset.ENEGRY_DEPLETED)
        print("onEffectTick endingCourse")
        endEliteCourse(target)
    end
end

xi.events.theEliteAdventurerTrainingProgram.onEffectLose = function(target, effect)
    if target:getLocalVar('TEATP_Active') == 1 and target:getLocalVar("TEATP_TrapsRemaining") > 0 then
        target:messageSpecial(zones[target:getZoneID()].text.TEATP_OFFSET + messageOffset.COSTUME_REMOVED)
        print("onEffectLose endingCourse")
        local roundPoints = getRoundPoints(target)
        local totalPoints = getTotalPoints(target)
        target:setCharVar('TEATP_Total_Points', totalPoints + roundPoints)
        endEliteCourse(target)
    end
end

-----------------------------------
-- Data
-----------------------------------

xi.events.theEliteAdventurerTrainingProgram.statisticMoogleItems =
{
    27556, -- Echad Ring
    27557, -- Trizek Ring
    26164, -- Caliber Ring
    26165, -- Facility Ring
    6412,  -- Leaf Bench
    6143,  -- Astral Cube
    27899, -- Alliance Shirt
}

xi.events.theEliteAdventurerTrainingProgram.chestItems =
{
    [1] = 
    {
        11355, -- Dinner Jacket
        16378, -- Dinner Hose
        11853, -- Novennial Coat
        11956, -- Novennial Hose
        10430, -- Decennial Crown
        10251, -- Decennial Coat
        10593, -- Decennial Tights
        10432, -- Decennial Crown +1
    },
    [2] =
    {
        10253, -- Decennial Coat +1
        10595, -- Decennial Tights +1
        3652,  -- Memorial Cake
        10809, -- Moogle Guard
        10811, -- Chocobo Shield
        10810, -- Moogle Guard +1
        10812, -- Choco. Shield +1
        27716, -- Green moogle masque
    },
    [3] =
    {
        27687, -- Green moogle suit
        27715, -- Goblin Masque
        27866, -- Goblin Suit
        10127, -- Cipher of a moogle's alter ego
        10128, -- Cipher of Fablinix's alter ego
        10126, -- Cipher of Aldo's alter ego
        26798, -- Behemoth Masque
        26954, -- Behemoth Suit
    },
    [4] =
    {
        26799, -- Behemoth masque +1
        26955, -- Behemoth Suit +1
        3706,  -- Vana'clock
        10162, -- Cipher of Kupofried's alter ego
        26520, -- Akitu Shirt
        10052, -- Red Crab Mount
        25755, -- Crustacean Shirt
        22069, -- Hapy Staff
    },
    [5] =
    {
        3725,  -- Cornelia Statue
        21509, -- Premium Mogti
        26518, -- Jody Shirt
        27623, -- Jody Shield
        26519, -- Mandragora Shirt
        3742,  -- Painting of a mercenary
        3745,  -- Korrigan Pot
        3746,  -- Adenium pot 
    },
    [6] =
    {
        3747,  -- Citrullus Pot
        26546, -- Moogle Shirt
        22047, -- Korrigan Mallet
        22048, -- Adenium Mallet
        22049, -- Citrullus Mallet
    }
}

local eruditeItemOptions =
{
    [3]  = { itemID = 21951, cost = 50, quantity =  1, purchaseFlag =  1 }, -- Shaded Moogle Rod +1
    [11] = { itemID =  6717, cost =  5, quantity =  1, purchaseFlag = 16 }, -- Trust Magic Tome
    [19] = { itemID =  5724, cost = 10, quantity = 12, purchaseFlag =  0 }, -- Pinch of pungent powder
    [27] = { itemID =  6535, cost = 10, quantity = 12, purchaseFlag =  0 }, -- Pinch of pungent powder II
    [35] = { itemID =  6537, cost = 10, quantity = 12, purchaseFlag =  0 }, -- Pinch of pungent powder III
    [43] = { itemID =  8711, cost = 30, quantity =  1, purchaseFlag =  0 }, -- Copper A.M.A.N voucher
    [51] = { itemID =  8973, cost = 30, quantity =  1, purchaseFlag =  0 }, -- Special gobbiedial key
    [59] = { itemID =  9218, cost = 30, quantity =  1, purchaseFlag =  0 }, -- Dial key #Fo
    [67] = { itemID =  9277, cost = 50, quantity =  1, purchaseFlag =  2, nextPurchaseTime = "TEATP_nextPurchaseTime_VOUCHER" }, -- Silver A.M.A.N voucher
    [75] = { itemID =  9274, cost = 50, quantity =  1, purchaseFlag =  4, nextPurchaseTime = "TEATP_nextPurchaseTime_ANV_KEY" }, -- Dial key #ANV
    [83] = { itemID =  2517, cost = 50, quantity =  1, purchaseFlag =  8, nextPurchaseTime = "TEATP_nextPurchaseTime_FES_KEY" }, -- FES gobbiedial key
}

xi.events.theEliteAdventurerTrainingProgram.data =
{
    [xi.zone.SOUTHERN_SAN_DORIA] =
    {
        cs = 
        {
            eruditeMoogle  = 3638,
            vanaMoogle     = 3637,
            statMoogle     = 32757,
            treasureCoffer = 974,
        },
        decorations = 
        {
            { 'blank',   0, -138.590,  -7.150,  48.210, '0x0000E90A00000000000000000000000000000000' },
            { 'blank',  64, -168.500,  -2.000,  69.500, '0x0000740900000000000000000000000000000000' },
            { 'blank', 168,  -88.880, -13.490,  94.890, '0x0000AC0900000000000000000000000000000000' },
            { 'blank',  32,  -17.110,   0.200, -97.430, '0x0000D70B00000000000000000000000000000000' },
            { 'blank',  32,  -34.500,   0.000,  34.500, '0x00002E0300000000000000000000000000000000' },
            { 'blank',  56,  166.710,  -8.000,  46.580, '0x0000D40300000000000000000000000000000000' },
            { 'blank',   0,   94.160,  -1.100, 117.650, '0x0000E70A00000000000000000000000000000000' },
        },
        furnitureDecorations = 
        {
            { 3753,   0, -280.150,  -8.700, 105.900, '0x0400000000000000000000000000000000000000' },
            { 356,  160, -190.400, -11.000,  22.160, '0x0400000000000000000000000000000000000000' },
            { 3744,   0,  -54.900,  -8.600, -29.270, '0x0400000000000000000000000000000000000000' },
            { 3717,   0, -111.360,   2.150, -19.280, '0x0400000000000000000000000000000000000000' },
            { 193,  128,    9.000,  -5.500, -38.000, '0x0400000000000000000000000000000000000000' },
            { 461,   64,   61.450,   1.055,  -8.150, '0x0400000000000000000000000000000000000000' },
            { 186,  128,   77.000,  -2.300,  32.200, '0x0400000000000000000000000000000000000000' },
            { 90,    64,  134.640,   0.000,  58.560, '0x0400000000000000000000000000000000000000' },
            { 95,     0,  163.280,  -2.000, 121.100, '0x0400000000000000000000000000000000000000' },
        },
    },
    [xi.zone.BASTOK_MARKETS] =
    {
        cs = 
        {
            eruditeMoogle  = 695,
            vanaMoogle     = 694,
            statMoogle     = 32757,
            treasureCoffer = 560,
        },
        decorations = 
        {
            
            { 'blank', 232, -306.110, -15.850, -162.540, '0x00001B0900000000000000000000000000000000' },
            { 'blank',  96, -296.340, -12.370, -135.000, '0x0000F60800000000000000000000000000000000' },
            { 'blank',  70, -293.048, -10.000, -102.558, '0x0000390000000000000000000000000000000000' },
            { 'blank', 106, -218.750,  -6.700,  -94.600, '0x0000F00A00000000000000000000000000000000' },
            { 'blank', 192, -157.380,  -6.015, -118.260, '0x0000F80A00000000000000000000000000000000' },
            { 'blank',   0, -122.400,  -1.840,  -85.600, '0x00006C0900000000000000000000000000000000' },
            { 'blank', 160, -237.000, -12.000,  -42.500, '0x0000070900000000000000000000000000000000' },
            { 'blank', 192, -199.000,  -8.000,  -38.200, '0x0000C20300000000000000000000000000000000' },
            { 'blank',   0, -234.000,  -8.000,   26.000, '0x00001E0900000000000000000000000000000000' },
            { 'blank',  16, -219.900,  -3.710,   50.120, '0x0000E30800000000000000000000000000000000' },
            
        },
        furnitureDecorations = 
        {
            { 110,   64, -179.400,   2.000, -116.800, '0x0400000000000000000000000000000000000000' },
            { 346,   64, -323.850, -17.500,  -68.000, '0x0400000000000000000000000000000000000000' },
            { 3586,   0, -348.300, -10.000, -162.300, '0x0400000000000000000000000000000000000000' },
            { 3592,   4, -201.850,  -7.710,  -57.710, '0x0400000000000000000000000000000000000000' },
            { 3641,   0, -173.550,  -7.570,   65.600, '0x0400000000000000000000000000000000000000' },
            { 3667, 192,  -31.100,  -7.710,  -76.700, '0x0400000000000000000000000000000000000000' },
        },
    },
    [xi.zone.WINDURST_WATERS] =
    {
        cs = 
        {
            eruditeMoogle  = 1177,
            vanaMoogle     = 1176,
            statMoogle     = 32757,
            treasureCoffer = 1033,
        },
        decorations = -- Blank named static untargetable placeholder npcs
        {
            
            { 'blank', 224,  125.550,  -0.250, 167.000, '0x0000EE0500000000000000000000000000000000' }, -- (K-6)  [Judgment Day painting] inside the left Aurastery.
            { 'blank', 168,  169.400,  -0.700, 168.790, '0x00000F0B00000000000000000000000000000000' }, -- (L-6)  [Pendent] on the counter inside the right Aurastery where Tauwawa is.
            { 'blank', 143,  148.700,  -4.650,  52.890, '0x0000CC0700000000000000000000000000000000' }, -- (K-9)  [Chocobo Egg] near the tree before the tunnel to Windurst Walls.
            { 'blank',   0,  152.750,  -1.800, -36.800, '0x0000100B00000000000000000000000000000000' }, -- (K-11) [Tarutaru doll] at Mog House behind a flag near Nine of Hearts.
            { 'blank', 128,  108.870,  -2.160,  47.180, '0x0000530C00000000000000000000000000000000' }, -- (J-9)  [Decorated Egg] in the grass by Jourille.
            { 'blank',  24,   18.120,  -2.900,  62.720, '0x0000F70A00000000000000000000000000000000' }, -- (H-8)  [Small white bench] on the right inside Ensasa's Calysis.
            { 'blank',   8,  -20.900,  -8.750, 115.180, '0x0000F90A00000000000000000000000000000000' }, -- (G-7)  [Library Book] on top of the shelf inside the right Optistery.
            { 'blank',  16,  -27.500,  -4.980, 218.500, '0x0000280900000000000000000000000000000000' }, -- (G-5)  [Red Hunt Guide].
            { 'blank', 111,  -48.270,  -5.000,  92.170, '0x0000E20800000000000000000000000000000000' }, -- (F-8)  [Chess Table] between Shante-Fante and Pojimo-Rojimo.
            { 'blank',  16,  -51.470, -11.790, 124.590, '0x0000DF0800000000000000000000000000000000' }, -- (F-7)  [Blue orb] on the flag by Ropunono, 2nd floor of the left Optistery.
            { 'blank',   0,  -77.300,  -4.330,  -5.220, '0x0000E00800000000000000000000000000000000' }, -- (F-10) [Tonberry's Latern], First floor inside of the Rarab Tail on the table in the corner.
            { 'blank',  32,  -53.100, -10.221,  20.030, '0x0000AB0900000000000000000000000000000000' }, -- (F-10) [Sleeping Moogle] Second floor inside of the Hostrly room #2.
            { 'blank', 160,  -14.630,  -2.000, -21.280, '0x0000A20A00000000000000000000000000000000' }, -- (G-11) [Susuroon] Fishing Qiqirn.
        },
        furnitureDecorations =
        {
            { 107,   16,  133.800,  -8.280, 226.500, '0x0400000000000000000000000000000000000000' }, -- (K-5)  [Water Jug on a shelf] 2nd floor on the left side of the Acolyte Hostel.
            { 338,  240, -118.700,  -2.000,  52.430, '0x0400000000000000000000000000000000000000' }, -- (E-9)  [Culinarian's Sign] by Isanie.
            { 3695,  48,  -66.300, -10.130,  -6.730, '0x0400000000000000000000000000000000000000' }, -- (F-10) [Cait Sith Carving], 2nd floor of the Rarab Tail inside Hostrly room by Angelica.g
        },
    },
}

-------------------------------------------------------------
-- Show/hide Moogles, Decorations, Traps, and Agent Moogles
-------------------------------------------------------------

local function insertDecoration(zone, entry)
    local name = entry[1]
    local rot  = entry[2]
    local x    = entry[3]
    local y    = entry[4]
    local z    = entry[5]
    local look = entry[6]

    local npc = zone:insertDynamicEntity({
        objtype     = xi.objType.NPC,
        name        = name,
        look        = look,
        x           = x,
        y           = y,
        z           = z,
        rotation    = rot,
        entityFlags = 2051,
        namevis     = 96,
        moving      = 0x8000,
        releaseIdOnINVISIBLE = true,
    })
    table.insert(xi.events.theEliteAdventurerTrainingProgram.entities, npc:getID())
end

local function insertFurnitureDecoration(zone, entry)
    local itemID = entry[1]
    local rot    = entry[2]
    local x      = entry[3]
    local y      = entry[4]
    local z      = entry[5]

    local npc = zone:insertPropEntity({
        name        = 'blank',
        itemId      = itemID,
        x           = x,
        y           = y,
        z           = z,
        rotation    = rot,
        entityFlags = 2051,
        namevis     = 96,
        releaseIdOnINVISIBLE = true,
    })

    if npc then
        table.insert(xi.events.theEliteAdventurerTrainingProgram.entities, npc:getID())
    end
end

local function insertTrap(zone, id)
    local npc = GetNPCByID(id)

    if npc then
        table.insert(xi.events.theEliteAdventurerTrainingProgram.entities, id)
    end
end

local function insertNPC(zone, id)
    local npc = GetNPCByID(id)

    if npc then
        table.insert(xi.events.theEliteAdventurerTrainingProgram.entities, id)
    end
end

-----------------------------------
-- Event handlers
-----------------------------------

xi.events.theEliteAdventurerTrainingProgram.processEmote = function(player, emoteId)
    local zoneID    = player:getZoneID()
    local eventData = xi.events.theEliteAdventurerTrainingProgram.data[zoneID]

    if not eventData then
        return
    end

    if not eventCostumeActive(player) then
        if getMogEnergy(player) > 0 then
            clearMogEnergyUI(player)
        end
        stopMogEnergyDrain(player)
        return
    end

    local currentEnergy = getMogEnergy(player)
    local entities      = xi.events.theEliteAdventurerTrainingProgram.entities or {}

    if emoteId == xi.emote.STARE then
        player:independentAnimation(player, 53, 4) -- Light up eyes animation
    
        local closestTrap      = nil
        local shortestDistance = 4.0

        for _, entityId in pairs(entities) do
            local npc = GetNPCByID(entityId)
        
            if npc and isTrap(npc) then
                local trapIndex = getTrapIndex(npc, zoneID)

                if getTrapState(player, trapIndex) == trapStates.notTriggered then
                    local distance = player:checkDistance(npc)
                
                    if distance <= shortestDistance then
                        shortestDistance = distance
                        closestTrap = npc
                    end
                end
            end
        end

        local mainWeapon = player:getEquipID(xi.slot.MAIN)

        if closestTrap then
            local targetTrapID = closestTrap:getID()

            player:setLocalVar('TEATP_LastTrapID', targetTrapID)
            player:messageSpecial(zones[zoneID].text.TEATP_OFFSET + messageOffset.SH_MOOGLE_ROD_RESPONDS, mainWeapon)
            proccessTrapAction(player, closestTrap, actions.stare)
        else
            player:messageSpecial(zones[zoneID].text.TEATP_OFFSET + messageOffset.SH_MOOGLE_ROD_DOESNT_RESPOND, mainWeapon)
        end
    elseif emoteId == xi.emote.SLAP then
        local targ = player:getCursorTarget()

        if targ:isNPC() and isTrap(targ) then
            local npc       = GetNPCByID(targ:getID())
            local trapIndex = getTrapIndex(npc, zoneID)
            local trapState = getTrapState(npc, trapIndex)

            if npc and trapState == trapStates.notTriggered and npc:getStatus() == xi.status.NORMAL and player:checkDistance(npc) <= 5 then
                proccessTrapAction(player, npc, actions.slap)
            end
        end
    elseif emoteId == xi.emote.POKE then
        local targ = player:getCursorTarget()
        if targ and targ:isNPC() and player:checkDistance(targ) <= 5 then
            local lowerName = (targ:getPacketName() or ''):lower()
            if lowerName:find('door:') and targ:getAnimation() ~= xi.animation.OPEN_DOOR then
                targ:openDoor(6)
            end
        end
    end
end

-----------------------------------
-- CS handlers
-----------------------------------

xi.events.theEliteAdventurerTrainingProgram.onTrigger = function(player, npc)
    local zoneID   = player:getZoneID()
    local npcID    = npc:getID()
    local zoneData = xi.events.theEliteAdventurerTrainingProgram.data[zoneID]

    if not zoneData then
        return
    end

    local rodEquipStatus    = isRodEquiped(player)
    local points            = getTotalPoints(player)
    local progress          = getEventStatus(player)
    local pointsAndProgress = bit.bor(bit.lshift(points, 4), progress)

    local cs = 0
    local p0 = 0
    local p1 = 0
    local p2 = 0
    local p3 = 0
    local p4 = 0
    local p5 = 0
    local p6 = 0
    local p7 = 0

    if npcID == zones[zoneID].npc.TEATP_MOOGLE then
        cs = zoneData.cs.vanaMoogle

        p0 = progress
        p1 = player:hasItem(xi.item.SHADED_MOOGLE_ROD) and 1 or 0 -- 0 triggers the dialog: not have rod

        player:startEvent(cs, p0, p1)
    elseif npcID == zones[zoneID].npc.TEATP_ERUDITE_MOOGLE then
        cs = zoneData.cs.eruditeMoogle

        p0 = pointsAndProgress
        p1 = rodEquipStatus

        local purchaseMask = getPurchaseHistory(player)

        for idx, item in pairs(eruditeItemOptions) do
            if idx == 3 and not player:hasItem(xi.item.SHADED_MOOGLE_ROD_P1) and bit.band(purchaseMask, item.purchaseFlag) > 0 then
                local invertedFlag = bit.bnot(item.purchaseFlag)
                local newMask      = bit.band(purchaseMask, invertedFlag)
                print("resetting pruchase mask for xi.item.SHADED_MOOGLE_ROD_P1")
                purchaseMask = newMask
            elseif 
                idx >= 67 and
                player:getCharVar(item.nextPurchaseTime) > 0 and
                GetSystemTime() > player:getCharVar(item.nextPurchaseTime) and
                bit.band(purchaseMask, item.purchaseFlag) > 0
            then
                local invertedFlag = bit.bnot(item.purchaseFlag)
                local newMask      = bit.band(purchaseMask, invertedFlag)
                print("resetting pruchase mask for daily item: "..item.itemID)
                purchaseMask = newMask
            end
            if item.nextPurchaseTime ~= nil then
                print("item: ["..item.itemID.. "] "..item.nextPurchaseTime..": " ..player:getCharVar(item.nextPurchaseTime)..", GetSystemTime() = "..GetSystemTime())
            end
        end


        player:setCharVar('TEATP_PurchaseHistory', purchaseMask)

        p2 = purchaseMask  

        player:startEvent(cs, p0, p1, p2, p3, p4, p5, p6, p7)
    elseif npcID == zones[zoneID].npc.TEATP_TREASURE_COFFER  then
        cs = zoneData.cs.treasureCoffer
        local items = xi.events.theEliteAdventurerTrainingProgram.chestItems
        if not items then
            return
        end

        player:startEvent(cs, items[1], items[2], items[3], items[4], items[5], items[6], 0, 0)
    elseif npcID == zones[zoneID].npc.TEATP_STAT_MOOGLE  then
        cs = zoneData.cs.statMoogle
        local items = xi.events.theEliteAdventurerTrainingProgram.statisticMoogleItems
        if not items then
            return
        end

        player:startEvent(cs)
    end
end

xi.events.theEliteAdventurerTrainingProgram.onEventUpdate = function(player, csid, option, npc)
    local zoneID   = player:getZoneID()
    local npcID    = npc:getID()
    local zoneData = xi.events.theEliteAdventurerTrainingProgram.data[zoneID]

    if not zoneData then
        return
    end

    local rodEquipStatus    = isRodEquiped(player)
    local points            = getTotalPoints(player)
    local progress          = getEventStatus(player)
    local pointsAndProgress = bit.bor(bit.lshift(points, 4), progress)

    local p0 = 0
    local p1 = 0
    local p2 = 0
    local p3 = 0
    local p4 = 0
    local p5 = 0
    local p6 = 0
    local p7 = 0

    if csid == zoneData.cs.vanaMoogle then
        if player:getFreeSlotsCount() < 1 then
            p7 = 2
        end

        player:updateEvent(p0, p1, p2, p3, p4, p5, p6, p7)
    elseif csid == zoneData.cs.eruditeMoogle then
        
        if option == 1 then
            if progress == 2 then
                player:setCharVar('TEATP_TutorialStatus', 3)
            end
        elseif option >= 3 and option <= 83 then
            local itemData = eruditeItemOptions[option]

            if not itemData then
                return
            end

            if player:getFreeSlotsCount() < 1 then
                p7 = 2
            end

            local purchaseMask   = getPurchaseHistory(player)
            local deductedPoints = 0

            if bit.band(purchaseMask, itemData.purchaseFlag) == 0 then
                print("Item does not exist in the purchaseMask")
                if npcUtil.giveItem(player, { { itemData.itemID, itemData.quantity } }) then
                    local currentPoints = getTotalPoints(player)
                    player:setCharVar("TEATP_PurchaseHistory", bit.bor(purchaseMask, itemData.purchaseFlag))
                    deductedPoints = currentPoints - itemData.cost
                    player:setCharVar('TEATP_Total_Points', deductedPoints)
                    if itemData.nextPurchaseTime then
                        player:setCharVar(itemData.nextPurchaseTime, JstMidnight())
                    end
                end
            end

            p1 = isRodEquiped(player)
            p2 = getPurchaseHistory(player)

            local updatedPointsAndProgress = bit.bor(bit.lshift(deductedPoints, 4), progress)

            player:updateEvent(updatedPointsAndProgress, p1, p2, 0, 0, 0, 0, p7)
        end
    elseif csid == zoneData.cs.statMoogle then
        if bit.band(option, 0xFF) == 2 then
            local items = xi.events.theEliteAdventurerTrainingProgram.statisticMoogleItems

            if not items then
                return
            end

            player:updateEvent(unpack(items))
        else
            local chatsSent       = player:getHistory(xi.history.CHATS_SENT)
            local npcInterations  = player:getHistory(xi.history.NPC_INTERACTIONS)
            local partiesJoined   = player:getHistory(xi.history.JOINED_PARTIES) + player:getHistory(xi.history.JOINED_ALLIANCES)
            local battlesFought   = player:getHistory(xi.history.BATTLES_FOUGHT)
            local timesKnockedOut = player:getHistory(xi.history.TIMES_KNOCKED_OUT)
            local enemiesDefeated = player:getHistory(xi.history.ENEMIES_DEFEATED)
            local gmCallsMade     = player:getHistory(xi.history.GM_CALLS)

            player:updateEvent(chatsSent, npcInterations, partiesJoined, battlesFought, timesKnockedOut, enemiesDefeated, gmCallsMade, 0)
        end
    elseif csid == zoneData.cs.treasureCoffer then
        local items = xi.events.theEliteAdventurerTrainingProgram.chestItems

        if not items then
            return
        end

        player:updateEvent(unpack(items))
    end
end

xi.events.theEliteAdventurerTrainingProgram.onEventFinish = function(player, csid, option, npc)
    local zoneID   = player:getZoneID()
    local npcName  = npc:getName()
    local zoneData = xi.events.theEliteAdventurerTrainingProgram.data[zoneID]

    if not zoneData then
        return
    end

    local rodEquipStatus    = isRodEquiped(player)
    local points            = getTotalPoints(player)
    local progress          = getEventStatus(player)
    local pointsAndProgress = bit.bor(points, progress)

    if csid == zoneData.cs.vanaMoogle then
        if option == 0 then
            if not player:hasItem(xi.item.SHADED_MOOGLE_ROD) then
                if npcUtil.giveItem(player, xi.item.SHADED_MOOGLE_ROD) then
                    player:setCharVar('TEATP_TutorialStatus', 2)
                else
                    player:setCharVar('TEATP_TutorialStatus', 1)
                end
            end
        end
    elseif csid == zoneData.cs.eruditeMoogle then  
        if option == 2 then -- start-course selection
            startMogEnergyDrain(player)
            player:setLocalVar('TEATP_Active', 1)
            player:setLocalVar('TEATP_Round_Points', 0)
            player:setLocalVar('TEATP_TrapStates', 0)
            player:setLocalVar('TEATP_AgentDrainNext', GetSystemTime())
            player:setLocalVar('TEATP_TrapsRemaining', 16)
            player:enableEntities({})
            updateMogEnergyUI(player, mogEnergy.start)
            player:setCostume(shadedMoogleCostume)
            player:changeMusic(0, 70)
            player:changeMusic(1, 70)
        end
    elseif csid == zoneData.cs.treasureCoffer then
    end
end

xi.events.theEliteAdventurerTrainingProgram.generateEntities = function()
    for zoneID, data in pairs(xi.events.theEliteAdventurerTrainingProgram.data) do
        local zone         = GetZone(zoneID)
        local ID           = zones[zoneID]
        local entitiesList = xi.events.theEliteAdventurerTrainingProgram.entities
        if zone then
            insertNPC(zone, ID.npc.TEATP_MOOGLE)
            insertNPC(zone, ID.npc.TEATP_ERUDITE_MOOGLE)
            insertNPC(zone, ID.npc.TEATP_TREASURE_COFFER)
            insertNPC(zone, ID.npc.TEATP_STAT_MOOGLE)

            for i = 1, 16 do
                insertNPC(zone, (ID.npc.TEATP_TRAP_1 - 1) + i)
            end
            
            for i = 1, 8 do
                insertNPC(zone, (ID.npc.TEATP_AGENT_MOOGLE_1 - 1) + i)
            end

            for _, decoration in pairs(data.decorations or {}) do
                insertDecoration(zone, decoration)
            end

            for _, fDecoration in pairs(data.furnitureDecorations or {}) do
                insertFurnitureDecoration(zone, fDecoration)
            end
        end
    end
end

xi.events.theEliteAdventurerTrainingProgram.showEntities = function()
    if #xi.events.theEliteAdventurerTrainingProgram.entities == 0 then
        xi.events.theEliteAdventurerTrainingProgram.generateEntities()
    end
    
    for _, entityID in pairs(xi.events.theEliteAdventurerTrainingProgram.entities) do
        local entity = GetNPCByID(entityID)
        if entity then
            entity:setStatus(xi.status.NORMAL)
        end
    end
    print("generated "..#xi.events.theEliteAdventurerTrainingProgram.entities.." entities.")
end

xi.events.theEliteAdventurerTrainingProgram.removeEntities = function()
    if #xi.events.theEliteAdventurerTrainingProgram.entities <= 0 then
        return
    end

    for _, entityID in pairs(xi.events.theEliteAdventurerTrainingProgram.entities) do
        local entity = GetNPCByID(entityID)
        if entity then
            entity:setStatus(xi.status.INVISIBLE)
        end
    end

    xi.events.theEliteAdventurerTrainingProgram.entities = {}
end

event:setEnableCheck(function()
    return xi.settings.main.ENABLE_THE_ELITE_ADVENTURER_TRAINING_PROGRAM == 1
end)


event:setStartFunction(function()
    xi.events.theEliteAdventurerTrainingProgram.showEntities()
end)

event:setEndFunction(function()
    xi.events.theEliteAdventurerTrainingProgram.removeEntities()
end)

return event
