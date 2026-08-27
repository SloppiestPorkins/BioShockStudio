class EscapeFromRepellantAction extends BioshockCharacterAction
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var private MoveToGoal CurrentMoveGoal;
var private NavigationPoint EscapePoint;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	m_Pawn.bEscapingFromRepellingVolume = true;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	m_Pawn.bEscapingFromRepellingVolume = false;
	CleanupGoals();
	super(AI_CharacterAction).Cleanup();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function CleanupGoals()
{
	// End:0x29
	if(__NFUN_119__(CurrentMoveGoal, none))
	{
		CurrentMoveGoal.__NFUN_198__();
		CurrentMoveGoal = none;
		return;
		@NULL
		CommanderAction
	}
	EcologyFighterCommanderAction
}

function GetUpdatedDestination(out Actor outDestinationActor, out Vector outDestinationLocation)
{
	outDestinationActor = EscapePoint;
	return;
	@NULL
	CommanderAction
}

// Export UEscapeFromRepellantAction::execGetUpdatedMovementLocation(FFrame&, void* const)
private native function GetUpdatedMovementLocation();

function StartMovement()
{
	CurrentMoveGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntActor(movementResource(), achievingGoal.Priority, EscapePoint);
	assert(__NFUN_119__(CurrentMoveGoal, none));
	CurrentMoveGoal.__GetUpdatedDestination__Delegate = GetUpdatedDestination;
	CurrentMoveGoal.__NFUN_199__();
	CurrentMoveGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	ShockAI(m_Pawn).SetShouldRun();
	GetUpdatedMovementLocation();
	StartMovement();
	// End:0x86
	if(m_Pawn.Level.InRepellingVolume(m_Pawn.Location))
	{
		__NFUN_256__(0.2000000);
		GetUpdatedMovementLocation();
		// [Loop Continue]
		goto J0x34;
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
	satisfiesGoal=Class'ShockAI.EscapeFromRepellantGoal'
	bExclusiveAction=true
}