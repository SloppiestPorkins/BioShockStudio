class WaitForGathererAction extends BioshockCharacterAction
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) private Gatherer targetGatherer;
var private MoveToGoal CurrentMoveToGoal;
var private int GestureAnimationHandle;
var private config Range TimeBeforeGesturingGatherer;
var private config float DesiredDistanceToTargetGatherer;
var private config float DesiredDegreesToGestureToGatherer;

function Cleanup()
{
	super(AI_CharacterAction).Cleanup();
	// End:0x33
	if(__NFUN_119__(CurrentMoveToGoal, none))
	{
		CurrentMoveToGoal.__NFUN_198__();
		CurrentMoveToGoal = none;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x76
		/*@Error*/
	}
	m_Pawn.SmartPerTrackEaseOutAnimation(GestureAnimationHandle);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function PlayGestureAnimation(name GestureAnimation)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x62
	/*@Error*/
	GestureAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, GestureAnimation);
	m_Pawn.FinishAnimation(GestureAnimationHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function bool ShouldStopMovingToGestureAtTarget()
{
	return __NFUN_153__(m_Pawn.GetNumLineOfSightsTo(targetGatherer), 4);
	return;
	@NULL
	CommanderAction
}

function MoveToGestureAtTarget()
{
	assert(__NFUN_114__(CurrentMoveToGoal, none));
	assert(__NFUN_119__(targetGatherer, none));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntActor(movementResource(), achievingGoal.Priority, targetGatherer);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__ShouldStopMoving__Delegate = ShouldStopMovingToGestureAtTarget;
	CurrentMoveToGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentMoveToGoal);
	CurrentMoveToGoal.unPostGoal(self);
	CurrentMoveToGoal.__NFUN_198__();
	CurrentMoveToGoal = none;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function bool ShouldStopMovingToTarget()
{
	local float DistanceToTarget;

	DistanceToTarget = __NFUN_175__(__NFUN_175__(__NFUN_225__(__NFUN_216__(targetGatherer.Location, m_Pawn.Location)), m_Pawn.CollisionRadius), targetGatherer.CollisionRadius);
	return __NFUN_130__(__NFUN_176__(DistanceToTarget, DesiredDistanceToTargetGatherer), __NFUN_153__(m_Pawn.GetNumLineOfSightsTo(targetGatherer), 4));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function MoveTowardTarget()
{
	assert(__NFUN_114__(CurrentMoveToGoal, none));
	assert(__NFUN_119__(targetGatherer, none));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntActor(movementResource(), achievingGoal.Priority, targetGatherer);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__ShouldStopMoving__Delegate = ShouldStopMovingToTarget;
	CurrentMoveToGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentMoveToGoal);
	CurrentMoveToGoal.unPostGoal(self);
	CurrentMoveToGoal.__NFUN_198__();
	CurrentMoveToGoal = none;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function bool GetRotationToTarget(out Rotator DesiredRotation)
{
	DesiredRotation = Rotator(__NFUN_216__(targetGatherer.Location, m_Pawn.Location));
	return true;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function FaceTarget()
{
	assert(__NFUN_114__(CurrentMoveToGoal, none));
	assert(__NFUN_119__(targetGatherer, none));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, m_Pawn.Location);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetRotationToTarget;
	CurrentMoveToGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentMoveToGoal);
	CurrentMoveToGoal.unPostGoal(self);
	CurrentMoveToGoal.__NFUN_198__();
	CurrentMoveToGoal = none;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function bool ShouldFaceTargetToPlayReaction()
{
	return __NFUN_129__(Class'ShockAI.MoveToAction'.static.IsRotatedTo(Rotator(__NFUN_216__(targetGatherer.Location, m_Pawn.Location)), m_Pawn.Rotation, int(__NFUN_172__(__NFUN_171__(DesiredDegreesToGestureToGatherer, 182.0444489), 2.0000000))));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	MoveToGestureAtTarget();
	// End:0x21
	if(ShouldFaceTargetToPlayReaction())
	{
		FaceTarget();
	}
	PlayGestureAnimation(Protector(m_Pawn).GetWaitingForGathererGestureAnimationName());
	MoveTowardTarget();
	// End:0x6C
	if(ShouldFaceTargetToPlayReaction())
	{
		FaceTarget();
		ShockAI().PlaySpeech('RespondedToGatherer');
	}
	PlayGestureAnimation(Protector(m_Pawn).GetSubsequentWaitingForGathererGestureAnimationName());
	// End:0xF1
	if(Class'Engine.Pawn'.static.checkAlive(targetGatherer))
	{
		targetGatherer.NotifyProtectorTellingUsToStopLooking();
		stop;				
		@NULL
	}
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

defaultproperties
{
	DesiredDistanceToTargetGatherer=150.0000000
	DesiredDegreesToGestureToGatherer=120.0000000
	satisfiesGoal=Class'ShockAI.WaitForGathererGoal'
	bExclusiveAction=true
}