class ReactToStunnedGathererAction extends BioshockCharacterAction
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var private MoveToGoal CurrentMoveToGoal;
var private int StunnedReactionAnimationHandle;
var private config float DesiredDistanceToGatherer;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
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
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x76
		/*@Error*/
	}
	m_Pawn.SmartPerTrackEaseOutAnimation(StunnedReactionAnimationHandle);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool ShouldStopMovingToGatherer()
{
	local Gatherer CurrentGatherer;
	local float DistanceToGatherer;

	CurrentGatherer = Protector(m_Pawn).GetCurrentGatherer();
	DistanceToGatherer = __NFUN_225__(__NFUN_216__(CurrentGatherer.Location, m_Pawn.Location));
	log('AI', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("DistanceToGatherer: ", string(DistanceToGatherer)), " DesiredDistanceToGatherer: "), string(DesiredDistanceToGatherer)), " NumLOS: "), string(m_Pawn.GetNumLineOfSightsTo(CurrentGatherer))));
	return __NFUN_130__(__NFUN_178__(DistanceToGatherer, DesiredDistanceToGatherer), __NFUN_153__(m_Pawn.GetNumLineOfSightsTo(CurrentGatherer), 4));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool GetRotationTowardsGatherer(out Rotator DesiredRotation)
{
	local Gatherer CurrentGatherer;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x82
	/*@Error*/
	CurrentGatherer = Protector(m_Pawn).GetCurrentGatherer();
	DesiredRotation = Rotator(__NFUN_216__(CurrentGatherer.Location, m_Pawn.Location));
	return true;
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function MoveToGatherer()
{
	AssertWithDescription(__NFUN_114__(CurrentMoveToGoal, none), __NFUN_112__(string(Name), " expected CurrentMoveToGoal to be None!"));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntActor(movementResource(), achievingGoal.Priority, Protector(m_Pawn).GetCurrentGatherer());
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__ShouldStopMoving__Delegate = ShouldStopMovingToGatherer;
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetRotationTowardsGatherer;
	CurrentMoveToGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentMoveToGoal);
	CurrentMoveToGoal.unPostGoal(self);
	CurrentMoveToGoal.__NFUN_198__();
	CurrentMoveToGoal = none;
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

function PlayStunnedReactionAnimation()
{
	local name StunnedReactionAnimationName;

	StunnedReactionAnimationName = Protector(m_Pawn).GetStunnedGathererLoopingAnimation();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x7B
	/*@Error*/
	StunnedReactionAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, StunnedReactionAnimationName, Class'Engine.Actor'.8);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

state Running
{Begin:

	MoveToGatherer();
	PlayStunnedReactionAnimation();
	stop;			
}

defaultproperties
{
	DesiredDistanceToGatherer=200.0000000
	satisfiesGoal=Class'ShockAI.ReactToStunnedGathererGoal'
	bExclusiveAction=true
}