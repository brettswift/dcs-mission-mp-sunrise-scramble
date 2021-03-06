

-- ATIS Anapa_Vityazevo Airport on 145.00 MHz AM.
atisAnapa=ATIS:New(AIRBASE.Caucasus.Anapa_Vityazevo, 121.00)
atisAnapa:SetRadioRelayUnitName("Radio Relay Anapa")
atisAnapa:SetTowerFrequencies({121, 250})
atisAnapa:SetActiveRunway("22")
atisAnapa:SetElevation()
atisAnapa:SetReportWindTrue()
atisAnapa:Start()

--Good morning!

--Several F5's have taken off and are on their way to this airbase!  S.U. 27's are also on their way.  ETA 20 minutes! 

--You must scramble immediately!   F14's are currently scrambling and will be your escort.   Call sign Ford. 

--Once Airborne head south and tank up with Arco.  Immediately proceed to Suppress Enemy Air Defences.  Once clear, two squadrons of B1 bombers will ripple hell onto the island.  The Warthogs will follow to clean up.   
 
--Refuel and resupply on one of the Carriers and provide support to the area, either to provide air superiority, or support the Warthogs to eliminate remaining ground forces.  This decision is up to you - do what is required. 
env.info("BSLOG Version Alpha - script is starting",false)
 
function StartFormation()
    BASE:E( timer.getTime() .. "BSLOG  Starting Formation now")
    env.info("BSLOG Start Formation Function running",false)
    
    BomberFollowGroup = SET_GROUP:New():FilterCategories("plane"):FilterCoalitions("blue"):FilterPrefixes("B1 Group"):FilterStart()
    BomberFollowGroup:Flush()
    BomberLead = UNIT:FindByName( "B1 Leader" )
    BomberLead:OptionROTNoReaction()
    BomberFormation = AI_FORMATION:New( BomberLead, BomberFollowGroup, "Left Wing Formation", "Bomber Breifing From MOOSE" )
    BomberFormation:FormationLeftWing( 150, 50, 0, 250, 250 )
    BomberFormation:__Start( 1 )
end
  
BomberFormationScheduler = SCHEDULER:New( nil, StartFormation, {}, 10, 120, 0, 600)
BomberFormationScheduler:Stop()

--Bombers to go to orbit waypoint
-- MUST be waypoint 4
function BombersToPreBombingOrbit()
    BASE:E( "BSLOG  Bombers being sent to pre-bombing orbit")
    BomberFollowGroup = SET_GROUP:New():FilterCategories("plane"):FilterCoalitions("blue"):FilterPrefixes("B1 Group"):FilterStart()
    BomberFollowGroup:Flush()
    BomberFormationScheduler:Stop()
    
    BomberFormation.SetFlightModeMission(BomberFollowGroup)
    
    BomberFollowGroup:ForEachGroup(function(Group)
      BASE:E( Group.GroupName )
      local b1Group = GROUP:New(Group.GroupName)
      b1Group:CommandSwitchWayPoint(1,4)
    end
    )
end

-- in 16 min mission time send to pre-bombing orbit  TODO: make this based on a zone?
SCHEDULER:New( nil, BombersToPreBombingOrbit, {}, 960)

Swift = CLIENT:FindByName( "Swift" )
Swift:HandleEvent( EVENTS.Takeoff )

function Swift:OnEventTakeoff( EventData )
  BASE:E( timer.getTime() .. "BSLOG  Swift Has Taken Off")
  BomberFormationScheduler:Start() 
  
  RadioSpeech = RADIOSPEECH:New( 305 )  
  RadioSpeech:Start(60)   
  RadioSpeech:Speak("Colt. You are cleared for 38,000 feet, direct waypoint 2.")
  
  SCHEDULER:New( nil, function()
    RadioSpeech:Stop()
  end, {}, 120)

end
