class BotReturnHomeAction extends BotBehaviorActionInterface
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var private MoveToGoal CurrentMoveToGoal;
var private Vector CurrentDestination;
var private bool DestroyBotImmediately;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super.initAction(R, Goal);
	MyBot.StartEverything();
	MyBot.SetVisionState(false);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	super.Cleanup();
	// End:0x33
	if(__NFUN_119__(CurrentMoveToGoal, none))
	{
		CurrentMoveToGoal.__NFUN_198__();
		CurrentMoveToGoal = none;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function InitializeMovement()
{
	assert(__NFUN_114__(CurrentMoveToGoal, none));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, m_Pawn.Location, true);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__GetUpdatedDestination__Delegate = GetUpdatedDestination;
	CurrentMoveToGoal.__OnMoveStarted__Delegate = OnMoveStarted;
	CurrentMoveToGoal.__OnMoveEnded__Delegate = OnMoveEnded;
	CurrentMoveToGoal.__OnDestinationReached__Delegate = OnDestinationReached;
	CurrentMoveToGoal.__NotifyCannotFindWayToDestination__Delegate = NotifyCannotFindWayToDestination;
	CurrentMoveToGoal.SetShouldNeverSucceed(true);
	CurrentMoveToGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function GetUpdatedDestination(out Actor outDestinationActor, out Vector outDestinationLocation)
{
	outDestinationLocation = CurrentDestination;
	return;
	@NULL
	CommanderAction
}

function OnMoveStarted()
{
	return;
}

function OnMoveEnded()
{
	return;
}

function OnDestinationReached()
{
	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " has reached the destination but can still be seen.  Choosing a new destination."));
	SetDestination();
	return;
	@NULL
}

function NotifyCannotFindWayToDestination()
{
	log('AI_Security', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn), " cannot find it's way to the destination "), string(CurrentDestination)), "."));
	return;
	@NULL
	CommanderAction
}

// Export UBotReturnHomeAction::execSetDestination(FFrame&, void* const)
private native function SetDestination();

// Export UBotReturnHomeAction::execBotCanBeDestroyed(FFrame&, void* const)
private native function bool BotCanBeDestroyed();

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " is now running BotReturnHomeAction."));
	MyBot.SwitchToMotion(4);
	SetDestination();
	InitializeMovement();
	// End:0x8A
	if(__NFUN_129__(BotCanBeDestroyed()))
	{
		__NFUN_256__(0.2000000);
		// [Loop Continue]
		goto J0x70;
		log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " is out of range of the player and is now being destroyed."));
	}
	// End:0x151
	if(DestroyBotImmediately)
	{
		MyBot.DisallowHacking = true;
		MyBot.SetDyingStateTime(MyBot.BotLifeSpanAfterDeath);
		MyBot.__NFUN_113__('Dying');
		goto J0x161;
		MyBot.__NFUN_279__();
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
	satisfiesGoal=Class'ShockAI.BotReturnHomeGoal'
}