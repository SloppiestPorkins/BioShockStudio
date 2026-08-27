class BotBaseNavigateToTargetMovementAction extends BotBaseMovementBehaviorAction
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var private MoveToGoal CurrentMoveToGoal;
var private SecurityBot MyBot;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	MyBot = SecurityBot(m_Pawn);
	assert(__NFUN_119__(MyBot, none));
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
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function InitializeMovement(optional bool ShouldNeverSucceed)
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
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetDesiredRotationOverride;
	CurrentMoveToGoal.SetAlignmentAllowedDeltaYaw(MyBot.AlignmentAllowedDeltaYaw);
	CurrentMoveToGoal.SetShouldNeverSucceed(ShouldNeverSucceed);
	CurrentMoveToGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function GetUpdatedDestination(out Actor outDestinationActor, out Vector outDestinationLocation)
{
	assert(false);
	return;
}

function OnDestinationReached()
{
	return;
}

function NotifyCannotFindWayToDestination()
{
	local Vector DestinationLocation;
	local Actor DestinationActor;

	GetUpdatedDestination(DestinationActor, DestinationLocation);
	log('AI_Security', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn), " cannot find it's way to the destination "), string(DestinationLocation)), "."));
	OnDestinationReached();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool GetDesiredRotationOverride(out Rotator DesiredRotation)
{
	return false;
	return;
}

state Running
{Begin:

	InitializeMovement();
	waitForGoal_AI_Goal(CurrentMoveToGoal);
	succeed();
	stop;				
	@NULL
}
