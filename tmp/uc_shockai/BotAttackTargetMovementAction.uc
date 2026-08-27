class BotAttackTargetMovementAction extends BotBaseMovementBehaviorAction
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn AttackTarget;
var(Parameters) Range HoverPointWaitTime;
var private MoveToGoal CurrentMoveToGoal;
var private Vector HoverPoint;
var private SecurityBot MyBot;
var private int FailureCount;
var private int HoverPointFailureCount;
var private Vector LastBotLocation;
var private float BotStuckEndTime;
var private float MinNotStuckDistanceSquared;
var private float MinNotStuckTime;

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

function InitializeMovement()
{
	// End:0x41
	if(__NFUN_119__(CurrentMoveToGoal, none))
	{
		CurrentMoveToGoal.unPostGoal(self);
		CurrentMoveToGoal.__NFUN_198__();
		CurrentMoveToGoal = none;
		CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	}
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, m_Pawn.Location, true);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__GetUpdatedDestination__Delegate = GetUpdatedDestination;
	CurrentMoveToGoal.__OnMoveStarted__Delegate = OnMoveStarted;
	CurrentMoveToGoal.__OnMoveEnded__Delegate = OnMoveEnded;
	CurrentMoveToGoal.__OnDestinationReached__Delegate = OnDestinationReached;
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetDesiredRotationOverride;
	CurrentMoveToGoal.__NotifyCannotFindWayToDestination__Delegate = NotifyCannotFindWayToDestination;
	CurrentMoveToGoal.SetAlignmentAllowedDeltaYaw(MyBot.AlignmentAllowedDeltaYaw);
	CurrentMoveToGoal.SetShouldNeverSucceed(true);
	CurrentMoveToGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool FindAdjacentHoverPoint(ShockPawn Target, out Vector FoundPoint)
{
	//native.Target;
	//native.FoundPoint;	
	@NULL
	@NULL
}

function bool FindNewHoverPoint(ShockPawn Target, out Vector FoundPoint)
{
	//native.Target;
	//native.FoundPoint;	
	@NULL
	@NULL
}

function bool SetNextHoverPoint(ShockPawn Target)
{
	local Vector NewPoint;
	local bool Found;

	Found = FindAdjacentHoverPoint(Target, NewPoint);
	// End:0x47
	if(Found)
	{
		HoverPoint = NewPoint;
		log('AI_Security', 4, __NFUN_112__(__NFUN_112__(string(m_Pawn), " next HoverPoint = "), string(HoverPoint)));
	}
	return Found;
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function bool SetNewHoverPoint(ShockPawn Target)
{
	local Vector NewPoint;
	local bool Found;

	Found = FindNewHoverPoint(Target, NewPoint);
	// End:0x47
	if(Found)
	{
		HoverPoint = NewPoint;
		log('AI_Security', 4, __NFUN_112__(__NFUN_112__(string(m_Pawn), " new HoverPoint = "), string(HoverPoint)));
	}
	return Found;
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function OnBumpedOtherBot(SecurityBot OtherBot)
{
	// End:0x7F
	if(__NFUN_176__(__NFUN_195__(), MyBot.OnBumpedBotNewPointChance))
	{
		log('AI_Security', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn), " bumped into "), string(OtherBot)), " moving to a new point."));
		__NFUN_113__('FindingNewHoverPoint');
		goto J0xE4;
		log('AI_Security', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn), " bumped into "), string(OtherBot)), " moving to an adjacent point."));
	}
	__NFUN_113__('FindingAdjacentHoverPoint');
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

private function DestinationReached()
{
	log('AI_Security', 4, __NFUN_112__(string(self), "---BotBaseAction::OnDestinationReached() called, choosing new hover point based on attack target."));
	__NFUN_113__('WaitingBeforeFindingAdjacentHoverPoint');
	return;
}

function DestinationUnreachable()
{
	log('AI_Security', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn), " cannot find it's way to the destination "), string(HoverPoint)), "."));
	HoverPoint = MyBot.Location;
	DestinationReached();
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function GetUpdatedDestination(out Actor outDestinationActor, out Vector outDestinationLocation)
{
	outDestinationActor = none;
	outDestinationLocation = HoverPoint;
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function OnDestinationReached()
{
	DestinationReached();
	return;
}

function NotifyCannotFindWayToDestination()
{
	DestinationUnreachable();
	return;
}

function bool GetDesiredRotationOverride(out Rotator DesiredRotation)
{
	assert(__NFUN_119__(MyBot, none));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x5B
	/*@Error*/
	DesiredRotation = Rotator(__NFUN_216__(AttackTarget.GetTargetTrackingLocation(), MyBot.Location));
	return true;
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

// Export UBotAttackTargetMovementAction::execCloseEnoughToTarget(FFrame&, void* const)
private native function bool CloseEnoughToTarget();

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " has began the Running state in BotAttackTargetMovementAction."));
	InitializeMovement();
	__NFUN_113__('GoingToTarget');
	stop;	
	@NULL
}

state GoingToTarget
{
	ignores GetUpdatedDestination;
Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " has began the GoingToTarget state in BotAttackTargetMovementAction."));
	// End:0x7F
	if(__NFUN_129__(CloseEnoughToTarget()))
	{
		yield();
		// [Loop Continue]
		goto J0x63;
		HoverPoint = MyBot.Location;
	}
	SetNextHoverPoint(AttackTarget);
	__NFUN_113__('WaitingBeforeFindingAdjacentHoverPoint');
	stop;		
	@NULL
	@NULL
	@NULL
	@NULL
}

state WaitingBeforeFindingAdjacentHoverPoint
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " has began the WaitingBeforeFindingAdjacentHoverPoint state in BotAttackTargetMovementAction."));
	__NFUN_256__(RandRange(HoverPointWaitTime.Min, HoverPointWaitTime.Max));
	__NFUN_113__('FindingAdjacentHoverPoint');
	stop;			
	@NULL
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

state FindingAdjacentHoverPoint
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " has began the FindingAdjacentHoverPoint state in BotAttackTargetMovementAction."));
	assert(__NFUN_151__(HoverPointFailureCount, 0));
	FailureCount = 0;
	// End:0xD1
	if(__NFUN_150__(FailureCount, HoverPointFailureCount))
	{
		// End:0xB9
		if(SetNextHoverPoint(AttackTarget))
		{
			goto J0xD1;
			__NFUN_163__(FailureCount);
			yield();
			// [Loop Continue]
			goto J0x89;
			// End:0xF6
			if(__NFUN_153__(FailureCount, HoverPointFailureCount))
			{
			}
			__NFUN_113__('FindingNewHoverPoint');
			goto J0x101;
		}
		__NFUN_113__('GoingToHoverPoint');
		stop;				
	}
	@NULL
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/;
}

state FindingNewHoverPoint
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " could not find an adjacent hover point, going to a new hover point."));
	InitializeMovement();
	// End:0x92
	if(__NFUN_129__(SetNewHoverPoint(AttackTarget)))
	{
		yield();
		// [Loop Continue]
		goto J0x6D;
		__NFUN_113__('GoingToHoverPoint');
	}
	stop;		
	@NULL
	@NULL
}

state GoingToHoverPoint
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " started GoingToHoverPoint in BotAttackTargetMovementAction."));
	LastBotLocation = MyBot.Location;
	BotStuckEndTime = __NFUN_174__(MyBot.Level.TimeSeconds, MinNotStuckTime);
	// End:0x182
	if(__NFUN_177__(BotStuckEndTime, MyBot.Level.TimeSeconds))
	{
		// End:0x175
		if(__NFUN_177__(VSizeSquared(__NFUN_216__(MyBot.Location, LastBotLocation)), MinNotStuckDistanceSquared))
		{
			LastBotLocation = MyBot.Location;
			BotStuckEndTime = __NFUN_174__(MyBot.Level.TimeSeconds, MinNotStuckTime);
			yield();
			// [Loop Continue]
			goto J0xB3;
			log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " is stuck, going to a new hover point."));
			__NFUN_113__('FindingNewHoverPoint');
			stop;			
		}
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
	HoverPointFailureCount=3
	MinNotStuckDistanceSquared=100.0000000
	MinNotStuckTime=1.0000000
	satisfiesGoal=Class'ShockAI.BotAttackTargetMovementGoal'
}