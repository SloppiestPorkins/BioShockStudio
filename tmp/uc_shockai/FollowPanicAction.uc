class FollowPanicAction extends BasePanicAction implements IInterestedActorDestroyed, IInterestedPawnDied
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

const kFollowPanicStateUpdateTime = 0.25;

var(Parameters) ShockPawn AttackPawn;
var private MoveToGoal CurrentMoveToGoal;
var private config float DesiredDistanceBehindProtector;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super.initAction(R, Goal);
	assert(__NFUN_119__(m_Pawn, none));
	m_Pawn.Level.RegisterNotifyPawnDied(self);
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
		ShockAI().StopSpeech('Panicked');
	}
	m_Pawn.Level.UnRegisterNotifyPawnDied(self);
	m_Pawn.Level.UnRegisterNotifyActorDestroyed(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

static function float selectionHeuristic(AI_Goal Goal)
{
	return 0.1000000;
	return;
}

function OnOtherPawnDied(Pawn DeadPawn)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x61
	/*@Error*/
	BioshockCharacterGoal(achievingGoal).FinishUp();
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
	// End:0x61
	/*@Error*/
	BioshockCharacterGoal(achievingGoal).FinishUp();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ShockPawn GetEscort()
{
	assert(__NFUN_132__(__NFUN_119__(ProtectorEscort, none), __NFUN_119__(PlayerEscort, none)));
	// End:0x3C
	if(__NFUN_119__(ProtectorEscort, none))
	{
		return ProtectorEscort;
		goto J0x46;
		return PlayerEscort;
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
	@NULL
}

function GetUpdatedDestination(out Actor outDestinationActor, out Vector outDestinationLocation)
{
	local Vector DirectionBehindProtector, PositionBehindEscort;
	local ShockPawn Escort;

	Escort = GetEscort();
	DirectionBehindProtector = __NFUN_226__(__NFUN_216__(Escort.Location, AttackPawn.Location));
	PositionBehindEscort = __NFUN_215__(Escort.Location, __NFUN_212__(DirectionBehindProtector, DesiredDistanceBehindProtector));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x11E
	/*@Error*/
	outDestinationLocation = PositionBehindEscort;
	goto J0x13E;
	outDestinationLocation = m_Pawn.Location;
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
	// End:0x58
	/*@Error*/
	DesiredRotation = Rotator(__NFUN_216__(AttackPawn.Location, m_Pawn.Location));
	return true;
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function StartMovementBehavior()
{
	AssertWithDescription(__NFUN_114__(CurrentMoveToGoal, none), __NFUN_112__(string(Name), " expected CurrentMoveToGoal to be None!"));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntActor(movementResource(), achievingGoal.Priority, GetEscort());
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__GetUpdatedDestination__Delegate = GetUpdatedDestination;
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetDesiredRotationOverride;
	CurrentMoveToGoal.SetShouldNeverSucceed(true);
	CurrentMoveToGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

state Running
{Begin:

	ShockAI().PlaySpeech('Panicked');
	ShockAI().SetShouldRun();
	ShockAI().BecomeAggressive();
	StartMovementBehavior();
Loop:


	__NFUN_256__(0.2500000);
	// End:0x93
	if(BioshockCharacterGoal(achievingGoal).ShouldFinishUp())
	{
		succeed();
		goto J0x9D;
		goto 'Loop';
	}
	stop;		
	@NULL
	@NULL
}

defaultproperties
{
	DesiredDistanceBehindProtector=200.0000000
	bExclusiveAction=true
}