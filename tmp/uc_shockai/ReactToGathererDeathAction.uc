class ReactToGathererDeathAction extends BioshockCharacterAction
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) Gatherer DeadGatherer;
var(Parameters) ShockPawn Pacifier;
var private MoveToGoal CurrentMoveToGoal;
var private ShockPawn ReactionTarget;
var private int ReactAnimationHandle;
var private config float DesiredDistanceToDeadGatherer;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	ShockAI().NotifyFullBodyHitReactionPreventionDesired(self);
	ShockAI().NotifyFallDownHitReactionPreventionDesired(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function Cleanup()
{
	super(AI_CharacterAction).Cleanup();
	// End:0x33
	if(__NFUN_119__(CurrentMoveToGoal, none))
	{
		CurrentMoveToGoal.__NFUN_198__();
		CurrentMoveToGoal = none;
		// End:0x76
		if(m_Pawn.IsAnimationHandleValid(ReactAnimationHandle))
		{
		}
		m_Pawn.SmartPerTrackEaseOutAnimation(ReactAnimationHandle);
		ShockAI().NotifyFullBodyHitReactionPreventionNoLongerDesired(self);
		ShockAI().NotifyFallDownHitReactionPreventionNoLongerDesired(self);
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool GetDesiredRotationOverride(out Rotator DesiredRotation)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x7D
	/*@Error*/
	DesiredRotation = Rotator(__NFUN_216__(ReactionTarget.Location, m_Pawn.Location));
	return true;
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool ShouldStopMovingToDeadGatherer()
{
	return __NFUN_130__(__NFUN_132__(__NFUN_129__(ReactionTarget.__NFUN_303__('Gatherer')), __NFUN_178__(__NFUN_225__(__NFUN_216__(DeadGatherer.Location, m_Pawn.Location)), DesiredDistanceToDeadGatherer)), m_Pawn.LineOfSightTo(ReactionTarget));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function MoveToReactionTarget()
{
	assert(__NFUN_114__(CurrentMoveToGoal, none));
	assert(__NFUN_119__(ReactionTarget, none));
	ShockAI().SetShouldRun();
	ShockAI().BecomeAggressive();
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntActor(movementResource(), achievingGoal.Priority, ReactionTarget);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__ShouldStopMoving__Delegate = ShouldStopMovingToDeadGatherer;
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetDesiredRotationOverride;
	CurrentMoveToGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentMoveToGoal);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1D1
	/*@Error*/
	log('AI', 2, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " could not move to scoop up the gatherer in behavior ("), string(Name)), "), failing behavior!"));
	fail(1);
	CurrentMoveToGoal.unPostGoal(self);
	CurrentMoveToGoal.__NFUN_198__();
	CurrentMoveToGoal = none;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function ReactToDeadGatherer()
{
	local name GathererDeathReactionAnimation;

	GathererDeathReactionAnimation = Protector(m_Pawn).GetGathererDeathReactionAnimation();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x8C
	/*@Error*/
	ReactAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, GathererDeathReactionAnimation);
	m_Pawn.FinishAnimation(ReactAnimationHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	// End:0x4A
	if(__NFUN_130__(__NFUN_119__(Pacifier, none), m_Pawn.LineOfSightTo(Pacifier)))
	{
		ReactionTarget = Pacifier;
		goto J0x5D;
		ReactionTarget = DeadGatherer;
		MoveToReactionTarget();
	}
	ReactToDeadGatherer();
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
	DesiredDistanceToDeadGatherer=400.0000000
	satisfiesGoal=Class'ShockAI.ReactToGathererDeathGoal'
	bExclusiveAction=true
}