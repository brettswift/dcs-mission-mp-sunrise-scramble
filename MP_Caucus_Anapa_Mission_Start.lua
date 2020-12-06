
-- ATIS Anapa_Vityazevo Airport on 145.00 MHz AM.
-- ATIS Vaziani Airport on 144.00 MHz AM.
atisVaziani=ATIS:New(AIRBASE.Caucasus.Vaziani, 144.00)
atisVaziani:SetRadioRelayUnitName("Radio Relay Vaziani")
atisVaziani:SetTowerFrequencies({269, 140})
atisVaziani:Start()

SCHEDULER:New( nil, function()
  atisVaziani:Stop()
  env.info("BSLOG ATIS Stopped",false)
end, {}, 600)
  
  
env.info("BSLOG Version Alpha - script is starting",false)

Darkstar = UNIT:FindByName( "Darkstar" )

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- Setup objects for B1 Bombing mission

-- Create a local variable (in this case called B1BAIEngagementZone) and 
-- using the ZONE function find the pre-defined zone called "Engagement Zone" 
-- currently on the map and assign it to this variable
B1BAIEngagementZone = ZONE:New( "B1 Engagement Zone" )

-- Create a local variable (in this case called B1BAIGroup1) and 
-- using the GROUP function find the aircraft group called "Plane" and assign to this variable
B1BAIGroup1 = GROUP:FindByName( "B1 Group 1" ) -- TODO: get set of groups and use them
B1BAIGroup2 = GROUP:FindByName( "B1 Group 2" )
-- Create a local Variable (in this cased called B1PatrolZone and 
-- using the ZONE function find the pre-defined zone called "Patrol Zone" and assign it to this variable
B1PatrolZone = ZONE:New( "B1 Patrol Zone" )

-- Create and object (in this case called AIBAIZone) and 
-- using the functions AI_BAI_ZONE assign the parameters that define this object 
-- (in this case B1PatrolZone, 500, 1000, 500, 600, B1BAIEngagementZone) 
AIBAIZone = AI_BAI_ZONE:New( B1PatrolZone, 10000, 11000, 500, 650, B1BAIEngagementZone )

-- end objects for B1 bombing mission -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

  
BomberFormationScheduler, BomberFormationSchedulerId = SCHEDULER:New( nil, StartFormation, {}, 10, 30, 0, 720)
BomberFormationScheduler:Stop(BomberFormationSchedulerId)

BomberLead = UNIT:FindByName( "B1 Leader" )

--- Behaviour Functions
 
function StartFormation()
    BASE:E( timer.getTime() .. "BSLOG  Starting Formation now")
    env.info("BSLOG Start Formation Function running",false)
    
    BomberFollowGroup = SET_GROUP:New():FilterCategories("plane"):FilterCoalitions("blue"):FilterPrefixes("B1 Group"):FilterStart()
    BomberFollowGroup:Flush()
    BomberLead:OptionROTNoReaction()
    BomberFormation = AI_FORMATION:New( BomberLead, BomberFollowGroup, "Left Wing Formation", "Bomber Breifing From MOOSE" )
    BomberFormation:FormationLeftWing( 150, 50, 0, 250, 250 )
    BomberFormation:__Start( 1 )
end

function BombersToPreBombingOrbit()
    BASE:E( "BSLOG  Bombers being sent to pre-bombing orbit") 
    BomberFormationScheduler:Stop( BomberFormationSchedulerId ) 
    -- Tell the program to use the object (in this case called B1BAIGroup1) as the group to use in the BAI function
    AIBAIZone:SetControllable( B1BAIGroup1 )
    -- Tell the group B1BAIGroup1 to start patrol in 10 seconds. 
    AIBAIZone:__Start( 10 ) -- They should start patrolling in the B1PatrolZone.
    MessageToBlue("Uzi, Darkstar:  Proceed to Marshall at waypoint 3",45)
--    BomberFollowGroup:ForEachGroup(function(Group)
--        BASE:E( Group.GroupName )
--        local b1Group = GROUP:New(Group.GroupName)
--        b1Group:CommandSwitchWayPoint(1,4)
--      end
--    )
end

function StopBomberFormation()
  BomberFormationScheduler:Stop( BomberFormationSchedulerId ) 
end

BomberLead:HandleEvent( EVENTS.Takeoff)

function BomberLead:OnEventTakeoff(EventData)
  -- start formation 30 seconds after B1 Leader takes off
  SCHEDULER:New( nil, function()
    StartFormation:Start()
  end, {}, 30)
end

--- When the SA6 site is hit, send in the bombers. 
SA6Sam = GROUP:FindByName( "Island SAM Group SA6" )
SA6Sam:HandleEvent( EVENTS.Hit )

function SA6Sam:OnEventHit( EventData )
  env.info("BSLOG SA6 site hit, sending bombers in. ",false)
  -- tell the group B1BAIGroup1 to engage the TankColumn1  
  AIBAIZone:__Engage( 3, 600, 10500, AI.Task.WeaponExpend.ALL ) -- Engage with a speed of 600 km/h and an altitude of 10500 meters 
  MessageToBlue("Uzi, Darkstar:  SA6 is out of commission. Begin attack.",45)
end

Swift = CLIENT:FindByName( "Swift" )
Swift:HandleEvent( EVENTS.Takeoff )

function Swift:OnEventTakeoff( EventData )
  BASE:E( timer.getTime() .. "BSLOG  Swift Has Taken Off")
  BomberFormationScheduler:Start() 
  
  -- in 16 min mission time send to pre-bombing orbit  TODO: make this based on a zone?
  -- Time it takes b1 bomber group #2 (air spawn) to get to waypoint 2. formation should stop by then 
  SCHEDULER:New( nil, StopBomberFormation, {}, 960)

-- in current DCS this seems to cause a bug. 
--  SCHEDULER:New( nil, BombersToPreBombingOrbit, {}, 990)

   
  RadioSpeech = RADIOSPEECH:New( 305 )  
  RadioSpeech:Start(60)   
  RadioSpeech:Speak("Colt, Darkstar. You are cleared for 38,000 feet, direct waypoint 2.")
  
  SCHEDULER:New( nil, function()
    RadioSpeech:Stop()
  end, {}, 120)

end


--  Blue planes plays the correct brevity on the radio when a weapon is launched :)
-- from: https://discord.com/channels/378590350614462464/378594528661340171/774845772697042945
-- TODO: Create Audio Tracks
--AIRBlueAll = SET_GROUP:New():FilterCoalitions("blue"):FilterCategoryAirplane()
--function AIRBlueAll:OnAfterAdded(From, Event, To, ObjectName, Object)
--    local NewGroup = GROUP:FindByName(ObjectName)
--    NewGroup:HandleEvent(EVENTS.Shot)
--    function NewGroup:OnEventShot(EventData)
--        local Brevity = "none"
--        local WeaponDesc = EventData.Weapon:getDesc() -- https://wiki.hoggitworld.com/view/DCS_enum_weapon
--        if WeaponDesc.category == 3 then
--            Brevity = "Pickle"
--        elseif WeaponDesc.category == 1 then
--            if WeaponDesc.guidance == 1 then
--                if WeaponDesc.missileCategory == 4 then
--                    Brevity = "LongRifle"
--                elseif WeaponDesc.missileCategory == 6 then
--                    Brevity = "Rifle"
--                end
--            elseif WeaponDesc.guidance == 2 then
--                Brevity = "Fox2"
--            elseif WeaponDesc.guidance == 3 then
--                Brevity = "Fox3"
--            elseif WeaponDesc.guidance == 4 then
--                Brevity = "Fox1"
--            elseif WeaponDesc.guidance == 5 and WeaponDesc.missileCategory == 6 then
--                Brevity = "Magnum"
--            elseif WeaponDesc.guidance == 7 then
--                Brevity = "Rifle"
--            end
--        end
--        if Brevity ~= "none"  then
--            local BrevitySound = Brevity .. ".ogg"
--            local GroupRadio = NewGroup:GetRadio()
--            GroupRadio:SetFileName(BrevitySound)
--            GroupRadio:SetFrequency(RadioGeneral)
--            GroupRadio:SetModulation(radio.modulation.AM)
--            GroupRadio:Broadcast()
--        end
--    end
--end
