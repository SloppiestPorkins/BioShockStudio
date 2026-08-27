class InvestigateAction extends BioshockCharacterAction
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var private MoveToGoal CurrentMoveToGoal;
var private config float MinTimeToViewInvestigateOrigin;
var private config float MaxTimeToViewInvestigateOrigin;
var private config float MinTimeToSearchAtInvestigateOrigin;
var private config float MaxTimeToSearchAtInvestigateOrigin;
var private config float MinDistanceToFaceInvestigateDirection;
var private config float DistanceToSearch;
var private config float MaxDistanceToApproachVisibleInvestigateLocation;
var private config float MinTimeBetweenRestartingInvestigation;
var private config float HeadTrackingInitialLookTime;
var private config Range TimeBeforePlayingSearchAnimation;
var private bool bFinishedTurning;
var private int SearchAnimHandle;
var private Rotator IdealInvestigateRotation;
var private float LastTimeStartedInvestigating;
var array<NavigationPoint> QuickSearchDestinations;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	ShockAI().StopAnyScriptedLoopingAnimations();
	AssertWithDescription(m_Pawn.__NFUN_303__('EcologyFighter'), __NFUN_112__(__NFUN_112__("InvestigateAction::initAction - ", string(m_Pawn)), " is not an Ecology Fighter!"));
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
		// End:0x93
		if(__NFUN_129__(ShockAI().IsFrozen()))
		{
		}
		// End:0x93
		if(m_Pawn.IsAnimationHandleValid(SearchAnimHandle))
		{
			m_Pawn.SmartPerTrackEaseOutAnimation(SearchAnimHandle);
			ShockAI().StopSpeech('CurrentlyInvestigating');
			return;
			@NULL
		}
	}
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyPausedDueToExclusivity()
{
	super(AI_RunnableAction).NotifyPausedDueToExclusivity();
	ShockAI().StopSpeech('CurrentlyInvestigating');
	return;
	@NULL
}

function NotifyRunningDueToExclusivity()
{
	super(AI_RunnableAction).NotifyRunningDueToExclusivity();
	ShockAI().PlaySpeech('CurrentlyInvestigating');
	return;
	@NULL
}

function NotifyInvestigateLocationUpdated()
{
	// End:0x50
	if(__NFUN_179__(Level().TimeSeconds, __NFUN_174__(LastTimeStartedInvestigating, MinTimeBetweenRestartingInvestigation)))
	{
		StopAnyMovementOrAnimation();
		__NFUN_113__('None');
		__NFUN_113__('Running');
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function bool GetRotationToInvestigateLocation(out Rotator DesiredRotation)
{
	ShockAI().QuickLook(m_Pawn.Level, HeadTrackingInitialLookTime, InvestigateGoal(achievingGoal).GetInvestigateLocation());
	DesiredRotation = Rotator(__NFUN_216__(InvestigateGoal(achievingGoal).GetInvestigateLocation(), m_Pawn.Location));
	return true;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnTurnEnded()
{
	bFinishedTurning = true;
	return;
	@NULL
}

function RotateToFaceInvestigateLocation()
{
	ShockAI().QuickLook(m_Pawn.Level, HeadTrackingInitialLookTime, InvestigateGoal(achievingGoal).GetInvestigateLocation());
	__NFUN_256__(ShockAI().SpotEnemyTurnDelay);
	AssertWithDescription(__NFUN_114__(CurrentMoveToGoal, none), __NFUN_112__(string(Name), " expected CurrentMoveToGoal to be None!"));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, m_Pawn.Location, true);
	assert(__NFUN_119__(CurrentMoveToGoal, none));
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetRotationToInvestigateLocation;
	CurrentMoveToGoal.__OnTurnEnded__Delegate = OnTurnEnded;
	CurrentMoveToGoal.SetShouldNeverSucceed(true);
	CurrentMoveToGoal.postGoal(self);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1D7
	/*@Error*/
	yield();
	goto J0x1BB;
	__NFUN_256__(RandRange(MinTimeToViewInvestigateOrigin, MaxTimeToViewInvestigateOrigin));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x237
	/*@Error*/
	CurrentMoveToGoal.unPostGoal(self);
	CurrentMoveToGoal.__NFUN_198__();
	CurrentMoveToGoal = none;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function bool ShouldStopMovingToInvestigate()
{
	local Vector InvestigateLocation;

	InvestigateLocation = InvestigateGoal(achievingGoal).GetInvestigateLocation();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB0
	/*@Error*/
	return true;
	goto J0xB2;
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool GetRotationToInvestigate(out Rotator DesiredRotation)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x6A
	/*@Error*/
	DesiredRotation = Rotator(__NFUN_216__(InvestigateGoal(achievingGoal).GetInvestigateLocation(), m_Pawn.Location));
	return true;
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function GetUpdatedDestination(out Actor outDestinationActor, out Vector outDestinationLocation)
{
	outDestinationLocation = InvestigateGoal(achievingGoal).GetInvestigateLocation();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function MoveToInvestigate()
{
	AssertWithDescription(__NFUN_114__(CurrentMoveToGoal, none), __NFUN_112__(string(Name), " expected CurrentMoveToGoal to be None!"));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, InvestigateGoal(achievingGoal).GetInvestigateLocation(), true);
	assert(__NFUN_119__(CurrentMoveToGoal, none));
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetRotationToInvestigate;
	CurrentMoveToGoal.__GetUpdatedDestination__Delegate = GetUpdatedDestination;
	CurrentMoveToGoal.__ShouldStopMoving__Delegate = ShouldStopMovingToInvestigate;
	// End:0x182
	if(EcologyFighter(m_Pawn).ShouldRunWhileInvestigating())
	{
		ShockAI().SetShouldRun();
		goto J0x19A;
		ShockAI().SetShouldWalk();
		CurrentMoveToGoal.postGoal(self);
		waitForGoal_AI_Goal(CurrentMoveToGoal);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x206
		/*@Error*/
		CurrentMoveToGoal.unPostGoal(self);
	}
	CurrentMoveToGoal.__NFUN_198__();
	CurrentMoveToGoal = none;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function FindIdealInvestigateRotation()
{
	local Vector InvestigateDirection;
	local NavigationPoint Anchor;
	local bool bFoundInvestigateRotation;
	local array<ReachSpec> SupportedReachSpecsOnAnchor;

	InvestigateDirection = InvestigateGoal(achievingGoal).GetInvestigateDirection();
	// End:0xB7
	if(__NFUN_130__(__NFUN_177__(VSizeSquared(InvestigateDirection), 0.0000000), m_Pawn.__NFUN_548__(__NFUN_215__(m_Pawn.Location, __NFUN_212__(InvestigateDirection, MinDistanceToFaceInvestigateDirection)), m_Pawn.GetViewPoint())))
	{
		IdealInvestigateRotation = Rotator(InvestigateDirection);
		goto J0x1C0;
		Anchor = m_Pawn.GetAnchor();
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x19C
		/*@Error*/
	}
	Anchor.GetReachSpecsThatSupport(m_Pawn, SupportedReachSpecsOnAnchor);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x19C
	/*@Error*/
	IdealInvestigateRotation = Rotator(__NFUN_216__(SupportedReachSpecsOnAnchor[__NFUN_167__(SupportedReachSpecsOnAnchor.Length)].End.Location, m_Pawn.Location));
	bFoundInvestigateRotation = true;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1C0
	/*@Error*/
	IdealInvestigateRotation = Rotator(InvestigateDirection);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool GetIdealInvestigateRotation(out Rotator DesiredRotation)
{
	DesiredRotation = IdealInvestigateRotation;
	return true;
	return;
	@NULL
	CommanderAction
}

function RotateToFaceInvestigateDirection()
{
	FindIdealInvestigateRotation();
	AssertWithDescription(__NFUN_114__(CurrentMoveToGoal, none), __NFUN_112__(string(Name), " expected CurrentMoveToGoal to be None!"));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, m_Pawn.Location);
	assert(__NFUN_119__(CurrentMoveToGoal, none));
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetIdealInvestigateRotation;
	CurrentMoveToGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentMoveToGoal);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x167
	/*@Error*/
	CurrentMoveToGoal.unPostGoal(self);
	CurrentMoveToGoal.__NFUN_198__();
	CurrentMoveToGoal = none;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function PlaySearchAnimation()
{
	SearchAnimHandle = m_Pawn.PlayAnimationOnChannel(0, EcologyFighter(m_Pawn).GetSearchAnimation(), Class'Engine.Actor'.8);
	__NFUN_256__(RandRange(MinTimeToSearchAtInvestigateOrigin, MaxTimeToSearchAtInvestigateOrigin));
	m_Pawn.FinishAnimation(SearchAnimHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function bool IsPointAQuickSearchDestination(NavigationPoint TestPoint)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x54
	/*@Error*/
	// End:0x46
	if(__NFUN_114__(QuickSearchDestinations[i], TestPoint))
	{
		return true;
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x0B;
		return false;
		return;
		@NULL
		CommanderAction
	}
	EcologyFighterCommanderAction
	@NULL
}

function NavigationPoint FindQuickSearchDestinationFrom(NavigationPoint StartPoint, Vector InvestigateDirection, Vector StartLocation)
{
	local NavigationPoint IterPoint, PointClosestToDirection;
	local int i;
	local array<ReachSpec> SupportedReachSpecs;
	local float ClosestDotAngle, IterDotAngle;

	StartPoint.GetReachSpecsThatSupport(m_Pawn, SupportedReachSpecs);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x13C
	/*@Error*/
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x132
	/*@Error*/
	IterPoint = SupportedReachSpecs[i].End;
	IterDotAngle = __NFUN_219__(InvestigateDirection, __NFUN_226__(__NFUN_216__(IterPoint.Location, StartLocation)));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x124
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x124
	/*@Error*/
	PointClosestToDirection = IterPoint;
	ClosestDotAngle = IterDotAngle;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x44;
	return PointClosestToDirection;
	return none;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function FindQuickSearchDestinations()
{
	local Vector InvestigateDirection, InvestigateLocation, StartLocation;
	local float RemainingSearchDistance;
	local bool bFinishedLookingForPoints;
	local NavigationPoint StartPoint, SearchPoint;

	InvestigateLocation = InvestigateGoal(achievingGoal).GetInvestigateLocation();
	InvestigateDirection = InvestigateGoal(achievingGoal).GetInvestigateDirection();
	RemainingSearchDistance = DistanceToSearch;
	QuickSearchDestinations.Remove(0, QuickSearchDestinations.Length);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x200
	/*@Error*/
	StartPoint = m_Pawn.GetAnchor();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x200
	/*@Error*/
	StartLocation = InvestigateLocation;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x200
	/*@Error*/
	SearchPoint = FindQuickSearchDestinationFrom(StartPoint, InvestigateDirection, StartLocation);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1F1
	/*@Error*/
	QuickSearchDestinations[QuickSearchDestinations.Length] = SearchPoint;
	__NFUN_185__(RemainingSearchDistance, __NFUN_225__(__NFUN_216__(StartLocation, SearchPoint.Location)));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1BB
	/*@Error*/
	bFinishedLookingForPoints = true;
	goto J0x1EE;
	StartPoint = SearchPoint;
	StartLocation = SearchPoint.Location;
	goto J0x1FD;
	bFinishedLookingForPoints = true;
	// [Loop Continue]
	goto J0x100;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function SearchAround()
{
	local NavigationPoint QuickSearchDestination;

	FindQuickSearchDestinations();
	J0x0A:

	// End:0x16E [Loop If]
	if(__NFUN_151__(QuickSearchDestinations.Length, 0))
	{
		QuickSearchDestination = QuickSearchDestinations[0];
		AssertWithDescription(__NFUN_114__(CurrentMoveToGoal, none), __NFUN_112__(string(Name), " expected CurrentMoveToGoal to be None!"));
		CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
		construct_AI_ResourceIntActor(movementResource(), achievingGoal.Priority, QuickSearchDestination);
		assert(__NFUN_119__(CurrentMoveToGoal, none));
		CurrentMoveToGoal.__NFUN_199__();
		CurrentMoveToGoal.postGoal(self);
		waitForGoal_AI_Goal(CurrentMoveToGoal);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x15F
		/*@Error*/
		CurrentMoveToGoal.unPostGoal(self);
		CurrentMoveToGoal.__NFUN_198__();
		CurrentMoveToGoal = none;
		QuickSearchDestinations.Remove(0, 1);
		// [Loop Continue]
		goto J0x0A;
		return;
		@NULL
		EcologyAI
		EcologyFighterCommanderAction
		@NULL
	}
}

function StopAnyMovementOrAnimation()
{
	// End:0x41
	if(__NFUN_119__(CurrentMoveToGoal, none))
	{
		CurrentMoveToGoal.unPostGoal(self);
		CurrentMoveToGoal.__NFUN_198__();
		CurrentMoveToGoal = none;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x84
		/*@Error*/
	}
	m_Pawn.SmartPerTrackEaseOutAnimation(SearchAnimHandle);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	// End:0x28
	if(__NFUN_114__(DummyWeaponGoal, none))
	{
		useResources(Class'VengeanceShared.AI_Resource'.2);
		LastTimeStartedInvestigating = Level().TimeSeconds;
	}
	ShockAI().BecomeAggressive();
	ShockAI().PlaySpeech('BeganInvestigating');
	SpawningManager(Level().SpawningManager).NotifyAggressorIsInvestigating(Aggressor(m_Pawn), InvestigateGoal(achievingGoal).GetInvestigateLocation(), InvestigateGoal(achievingGoal).GetInvestigateDirection());
	RotateToFaceInvestigateLocation();
	ShockAI().PlaySpeech('CurrentlyInvestigating');
	MoveToInvestigate();
	RotateToFaceInvestigateDirection();
	__NFUN_256__(RandRange(TimeBeforePlayingSearchAnimation.Min, TimeBeforePlayingSearchAnimation.Max));
	PlaySearchAnimation();
	SearchAround();
	ShockAI().PlaySpeech('FinishedInvestigating');
	succeed();
	stop;		
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
	MinTimeToViewInvestigateOrigin=0.5000000
	MaxTimeToViewInvestigateOrigin=0.5000000
	MinTimeToSearchAtInvestigateOrigin=3.0000000
	MaxTimeToSearchAtInvestigateOrigin=5.0000000
	MinDistanceToFaceInvestigateDirection=100.0000000
	DistanceToSearch=500.0000000
	MaxDistanceToApproachVisibleInvestigateLocation=200.0000000
	MinTimeBetweenRestartingInvestigation=2.0000000
	HeadTrackingInitialLookTime=2.0000000
	TimeBeforePlayingSearchAnimation=(Min=0.0000000,Max=0.5000000)
	satisfiesGoal=Class'ShockAI.InvestigateGoal'
	bExclusiveAction=true
}