class SearchAction extends BioshockCharacterAction implements IInterestedActorDestroyed
	native
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

const kMinNumMovesToSearch = 2;

var(Parameters) private ShockPawn SearchTarget;
var(Parameters) private Vector LastKnownLocation;
var(Parameters) private Vector LastMovingDirection;
var(Parameters) private Vector LocationWhenLostTarget;
var(Parameters) private Actor AnchorActor;
var(Parameters) private float MaxDistanceFromAnchor;
var(Parameters) private int AlignmentAllowedDeltaYaw;
var(Parameters) private bool NeverStopSearching;
var private MoveToGoal CurrentMoveToGoal;
var private TeleportGoal CurrentTeleportGoal;
var private DistanceTraveledSensor CurrentDistanceTraveledSensor;
var private config float MinTimeToPlaySearchAnim;
var private config float MaxTimeToPlaySearchAnim;
var private config float MinTimeBetweenRespondingToSuspiciousEvents;
var private config float QuickLookToLastKnownLocationDuration;
var array<NavigationPoint> BestPlacesToSearch;
var private NavigationPoint CurrentSearchDestination;
var private bool bShouldStopShortAtCurrentDestination;
var private Vector AvgMoveDirection;
var private int NumMoves;
var private int SearchAnimHandle;
var private float EndSearchTime;
var private float LastTimeOfSuspiciousEvent;
var private bool bSearchingFromLastKnownLocation;
var private bool bResetSearch;
var private Rotator SearchLookRotation;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	ShockAI().NotifySearchingVisionDesired();
	m_Pawn.Level.RegisterNotifyActorDestroyed(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	super(AI_CharacterAction).Cleanup();
	// End:0x33
	if(__NFUN_119__(CurrentMoveToGoal, none))
	{
		CurrentMoveToGoal.__NFUN_198__();
		CurrentMoveToGoal = none;
		// End:0x5C
		if(__NFUN_119__(CurrentTeleportGoal, none))
		{
			CurrentTeleportGoal.__NFUN_198__();
		}
		CurrentTeleportGoal = none;
		DeactivateDistanceTraveledSensor();
		// End:0xA9
		if(m_Pawn.IsAnimationHandleValid(SearchAnimHandle))
		{
		}
		m_Pawn.SmartPerTrackEaseOutAnimation(SearchAnimHandle);
		ShockAI().StopSpeech('TargetLost');
		ShockAI().NotifySearchingVisionNoLongerDesired();
	}
	m_Pawn.Level.UnRegisterNotifyActorDestroyed(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnOtherActorDestroyed(Actor ActorBeingDestroyed)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x21
	/*@Error*/
	instantSucceed();
	return;
	@NULL
	CommanderAction
}

function ActivateDistanceTraveledSensor()
{
	CurrentDistanceTraveledSensor = DistanceTraveledSensor(Class'VengeanceShared.AI_Sensor'.static.activateSensor(self, Class'ShockAI.DistanceTraveledSensor', characterResource(), 0.0000000, 1000000.0000000));
	CurrentDistanceTraveledSensor.setParameters(m_Pawn, EcologyFighter(m_Pawn).GetDistanceToRunWhileSearching(), true);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function DeactivateDistanceTraveledSensor()
{
	// End:0x32
	if(__NFUN_119__(CurrentDistanceTraveledSensor, none))
	{
		CurrentDistanceTraveledSensor.deactivateSensor(self);
		CurrentDistanceTraveledSensor = none;
		return;
		@NULL
		CommanderAction
	}
	EcologyFighterCommanderAction
}

function OnSensorMessage(AI_Sensor sensor, AI_SensorData Value, Object userData)
{
	super(AI_Action).OnSensorMessage(sensor, Value, userData);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x7F
	/*@Error*/
	ShockAI().PlaySpeech('TargetLost');
	ShockAI().SetShouldWalk();
	DeactivateDistanceTraveledSensor();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function UpdateSuspiciousLocation(Vector SuspiciousLocation, Vector SuspiciousTargetVelocity)
{
	local float CurrentTime;

	CurrentTime = Level().TimeSeconds;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x11A
	/*@Error*/
	LastKnownLocation = SuspiciousLocation;
	LastMovingDirection = SuspiciousTargetVelocity;
	LocationWhenLostTarget = m_Pawn.Location;
	LastTimeOfSuspiciousEvent = CurrentTime;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x11A
	/*@Error*/
	bResetSearch = true;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x104
	/*@Error*/
	CurrentMoveToGoal.unPostGoal(self);
	CurrentMoveToGoal.__NFUN_198__();
	CurrentMoveToGoal = none;
	__NFUN_113__('None');
	__NFUN_113__('Running');
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool ShouldTeleportToLastKnownLocation()
{
	return __NFUN_130__(ShockAI().CanTeleport(), __NFUN_129__(m_Pawn.__NFUN_521__(LastKnownLocation)));
	return;
	@NULL
	CommanderAction
}

function TeleportToLastKnownLocation()
{
	// End:0x41
	if(__NFUN_119__(CurrentTeleportGoal, none))
	{
		CurrentTeleportGoal.unPostGoal(self);
		CurrentTeleportGoal.__NFUN_198__();
		CurrentTeleportGoal = none;
		CurrentTeleportGoal = Class'ShockAI.TeleportGoal'.static.Allocate(self).;
	}
	construct_AI_ResourceVectorBoolBoolRotatorBool(characterResource(), LastKnownLocation);
	CurrentTeleportGoal.__NFUN_199__();
	CurrentTeleportGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentTeleportGoal);
	CurrentTeleportGoal.unPostGoal(self);
	CurrentTeleportGoal.__NFUN_198__();
	CurrentTeleportGoal = none;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function bool HasSearchExpired()
{
	return __NFUN_130__(m_Pawn.__NFUN_303__('EcologyFighter'), __NFUN_179__(Level().TimeSeconds, EndSearchTime));
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function bool ShouldStopMovingToLastKnownLocation()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x99
	/*@Error*/
	return __NFUN_179__(__NFUN_225__(__NFUN_216__(AnchorActor.Location, m_Pawn.Location)), MaxDistanceFromAnchor);
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function MoveToLastKnownLocation()
{
	local bool bCouldMoveToLastKnownLocation;

	AssertWithDescription(__NFUN_114__(CurrentMoveToGoal, none), __NFUN_112__(string(Name), " expected CurrentMoveToGoal to be None!"));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, LastKnownLocation);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__ShouldStopMoving__Delegate = ShouldStopMovingToLastKnownLocation;
	CurrentMoveToGoal.SetAlignmentAllowedDeltaYaw(AlignmentAllowedDeltaYaw);
	CurrentMoveToGoal.postGoal(self);
	// End:0x1AE
	if(__NFUN_130__(__NFUN_129__(HasSearchExpired()), __NFUN_129__(CurrentMoveToGoal.hasCompleted())))
	{
		// End:0x1A1
		if(m_Pawn.__NFUN_548__(LastKnownLocation, m_Pawn.GetViewPoint()))
		{
			ShockAI().QuickLook(Level(), QuickLookToLastKnownLocationDuration, LastKnownLocation);
			yield();
			// [Loop Continue]
			goto J0x10D;
			ShockAI().QuickLook(Level(), QuickLookToLastKnownLocationDuration, __NFUN_215__(LastKnownLocation, __NFUN_213__(1000.0000000, LastMovingDirection)));
			bCouldMoveToLastKnownLocation = CurrentMoveToGoal.wasAchieved();
		}
	}
	CurrentMoveToGoal.unPostGoal(self);
	CurrentMoveToGoal.__NFUN_198__();
	CurrentMoveToGoal = none;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x261
	/*@Error*/
	MoveToNavigationPointNearLastKnownLocation();
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

function MoveToNavigationPointNearLastKnownLocation()
{
	local NavigationPoint NavPointCloseToLastKnownLocation;

	NavPointCloseToLastKnownLocation = ShockAI().FindUsablePointClosestTo(LastKnownLocation);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x240
	/*@Error*/
	AssertWithDescription(__NFUN_114__(CurrentMoveToGoal, none), __NFUN_112__(string(Name), " expected CurrentMoveToGoal to be None!"));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntActor(movementResource(), achievingGoal.Priority, NavPointCloseToLastKnownLocation);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__ShouldStopMoving__Delegate = ShouldStopMovingToLastKnownLocation;
	CurrentMoveToGoal.postGoal(self);
	// End:0x1C8
	if(__NFUN_130__(__NFUN_129__(HasSearchExpired()), __NFUN_129__(CurrentMoveToGoal.hasCompleted())))
	{
		// End:0x1BB
		if(m_Pawn.__NFUN_548__(LastKnownLocation, m_Pawn.GetViewPoint()))
		{
			ShockAI().QuickLook(Level(), QuickLookToLastKnownLocationDuration, LastKnownLocation);
			yield();
			// [Loop Continue]
			goto J0x127;
			ShockAI().QuickLook(Level(), QuickLookToLastKnownLocationDuration, __NFUN_215__(LastKnownLocation, __NFUN_213__(1000.0000000, LastMovingDirection)));
			CurrentMoveToGoal.unPostGoal(self);
		}
		CurrentMoveToGoal.__NFUN_198__();
	}
	CurrentMoveToGoal = none;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function bool ShouldStopMovingToSearchDestination()
{
	// End:0x9D
	if(__NFUN_130__(__NFUN_119__(AnchorActor, none), __NFUN_132__(__NFUN_129__(AnchorActor.__NFUN_303__('ShockPawn')), Class'Engine.Pawn'.static.checkAlive(ShockPawn(AnchorActor)))))
	{
		// End:0x9D
		if(__NFUN_179__(__NFUN_225__(__NFUN_216__(AnchorActor.Location, CurrentSearchDestination.Location)), MaxDistanceFromAnchor))
		{
			return true;
			return __NFUN_130__(m_Pawn.IsInDefinedVisionCone(CurrentSearchDestination, m_Pawn.GetViewPoint(), m_Pawn.GetViewDirection(), m_Pawn.PeripheralVision, 300.0000000), m_Pawn.__NFUN_548__(CurrentSearchDestination.Location, m_Pawn.Location));
		}
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function MoveToCurrentSearchDestination()
{
	AssertWithDescription(__NFUN_114__(CurrentMoveToGoal, none), __NFUN_112__(string(Name), " expected CurrentMoveToGoal to be None!"));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntActor(movementResource(), achievingGoal.Priority, CurrentSearchDestination);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__ShouldStopMoving__Delegate = ShouldStopMovingToSearchDestination;
	CurrentMoveToGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentMoveToGoal);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x141
	/*@Error*/
	CurrentMoveToGoal.unPostGoal(self);
	CurrentMoveToGoal.__NFUN_198__();
	CurrentMoveToGoal = none;
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

function bool GetDesiredRotationOverride(out Rotator DesiredRotation)
{
	DesiredRotation = SearchLookRotation;
	return true;
	return;
	@NULL
	CommanderAction
}

function RotateToLook()
{
	AssertWithDescription(__NFUN_114__(CurrentMoveToGoal, none), __NFUN_112__(string(Name), " expected CurrentMoveToGoal to be None!"));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, m_Pawn.Location);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetDesiredRotationOverride;
	CurrentMoveToGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentMoveToGoal);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x14E
	/*@Error*/
	CurrentMoveToGoal.unPostGoal(self);
	CurrentMoveToGoal.__NFUN_198__();
	CurrentMoveToGoal = none;
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

function SearchAtCurrentSearchDestination()
{
	local float EndSearchAnimTime;
	local Rotator OppositeRotation;
	local name SearchAnimation;

	OppositeRotation = Rotator(__NFUN_211__(Vector(m_Pawn.Rotation)));
	SearchLookRotation = ShockAI().GetGoodDirectionToLookIn(OppositeRotation);
	RotateToLook();
	SearchAnimation = EcologyFighter(m_Pawn).GetSearchAnimation();
	// End:0xEA
	if(__NFUN_255__(SearchAnimation, 'None'))
	{
		SearchAnimHandle = m_Pawn.PlayAnimationOnChannel(0, SearchAnimation);
		m_Pawn.FinishAnimation(SearchAnimHandle);
		goto J0x16C;
		EndSearchAnimTime = __NFUN_174__(Level().TimeSeconds, RandRange(MinTimeToPlaySearchAnim, MaxTimeToPlaySearchAnim));
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x16C
		/*@Error*/
	}
	yield();
	goto J0x129;
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

function SearchBestPlaces()
{
	local int i;
	local NavigationPoint NextSearchDestination;

	bSearchingFromLastKnownLocation = true;
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x23F
	/*@Error*/
	NextSearchDestination = BestPlacesToSearch[i];
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1BE
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1BE
	/*@Error*/
	assert(__NFUN_119__(CurrentSearchDestination, none));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1BE
	/*@Error*/
	SearchAtCurrentSearchDestination();
	NumMoves = 0;
	AvgMoveDirection = vect(0.0000000, 0.0000000, 0.0000000);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1CE
	/*@Error*/
	goto J0x23F;
	CurrentSearchDestination = NextSearchDestination;
	__NFUN_223__(AvgMoveDirection, __NFUN_226__(__NFUN_216__(CurrentSearchDestination.Location, m_Pawn.Location)));
	__NFUN_163__(NumMoves);
	MoveToCurrentSearchDestination();
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x17;
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

// Export USearchAction::execDetermineBestPlacesToSearch(FFrame&, void* const)
native function DetermineBestPlacesToSearch();

state Running
{Begin:

	useResources(Class'VengeanceShared.AI_Resource'.2);
	ShockAI().BecomeAggressive();
	ShockAI().SetShouldRun();
	// End:0xB2
	if(m_Pawn.__NFUN_303__('EcologyFighter'))
	{
		ActivateDistanceTraveledSensor();
		EndSearchTime = __NFUN_174__(Level().TimeSeconds, EcologyFighter(m_Pawn).GetSearchTime());
		// End:0xCC
		if(ShouldTeleportToLastKnownLocation())
		{
			TeleportToLastKnownLocation();
			goto J0xD6;
		}
		MoveToLastKnownLocation();
		// End:0x1B2
		if(Class'Engine.Pawn'.static.checkAlive(SearchTarget))
		{
		}
		ShockAI().SetShouldWalk();
		// End:0x170
		if(__NFUN_129__(HasSearchExpired()))
		{
			DetermineBestPlacesToSearch();
			SearchBestPlaces();
			// End:0x170
			if(__NFUN_132__(NeverStopSearching, bResetSearch))
			{
				bResetSearch = false;
				yield();
				goto 'SearchAround';
				ShockAI().StopSpeech('TargetLost');
				ShockAI().PlaySpeech('FinishedSearching');
			}
		}
		succeed();
		stop;						
	}
	@NULL
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

defaultproperties
{
	MinTimeToPlaySearchAnim=2.0000000
	MaxTimeToPlaySearchAnim=5.0000000
	MinTimeBetweenRespondingToSuspiciousEvents=3.0000000
	QuickLookToLastKnownLocationDuration=1.0000000
	satisfiesGoal=Class'ShockAI.SearchGoal'
	bExclusiveAction=true
}