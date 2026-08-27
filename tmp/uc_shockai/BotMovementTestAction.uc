class BotMovementTestAction extends BotBehaviorActionInterface
	collapsecategories
	hidecategories(Object,InternalParameters);

var private SecurityBot MyBot;
var private BotBaseMovementBehaviorGoal CurrentMoveGoal;
var private Vector CurrentTargetLocation;
var private ShockPawn CurrentTargetPawn;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super.initAction(R, Goal);
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
	// End:0x29
	if(__NFUN_119__(CurrentMoveGoal, none))
	{
		CurrentMoveGoal.__NFUN_198__();
		CurrentMoveGoal = none;
		super.Cleanup();
		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

function TestGoToLocation(Vector TargetLocation)
{
	StopAllMovement();
	CurrentTargetLocation = TargetLocation;
	__NFUN_113__('GoingToLocation');
	return;
	@NULL
	CommanderAction
}

function TestFakeAttackPawn(ShockPawn targetPawn)
{
	StopAllMovement();
	CurrentTargetPawn = targetPawn;
	// End:0x3A
	if(__NFUN_119__(targetPawn, none))
	{
		__NFUN_113__('FakeAttackingPawn');
		goto J0x62;
		log(,, "Could not find the target pawn.");
	}
	return;
	@NULL
	CommanderAction
	J0x62:

	CommanderAction
}

function InitializeNavigateToPointMovement()
{
	StopAllMovement();
	assert(__NFUN_114__(CurrentMoveGoal, none));
	CurrentMoveGoal = Class'ShockAI.BotNavigateToPointLocationMovementGoal'.static.Allocate(self).;
	construct_AI_ResourceVector(characterResource(), CurrentTargetLocation);
	assert(__NFUN_119__(CurrentMoveGoal, none));
	CurrentMoveGoal.__NFUN_199__();
	CurrentMoveGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function InitializeFakeAttackMovement()
{
	local Range HoverPointWaitRange;

	StopAllMovement();
	assert(__NFUN_114__(CurrentMoveGoal, none));
	// End:0x56
	if(CurrentTargetPawn.IsPlayer())
	{
		HoverPointWaitRange = MyBot.AttackingHoverPointWaitTimeRangePlayer;
		goto J0x76;
		HoverPointWaitRange = MyBot.AttackingHoverPointWaitTimeRangeAI;
	}
	CurrentMoveGoal = Class'ShockAI.BotAttackTargetMovementGoal'.static.Allocate(self).;
	construct_AI_ResourceShockPawnRange(characterResource(), CurrentTargetPawn, HoverPointWaitRange);
	assert(__NFUN_119__(CurrentMoveGoal, none));
	CurrentMoveGoal.__NFUN_199__();
	CurrentMoveGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function StopAllMovement()
{
	// End:0x41
	if(__NFUN_119__(CurrentMoveGoal, none))
	{
		CurrentMoveGoal.unPostGoal(self);
		CurrentMoveGoal.__NFUN_198__();
		CurrentMoveGoal = none;
		return;
		@NULL
		CommanderAction
		BioshockMovementAction
	}
	@NULL
}

state Running
{Begin:

	stop;			
}

state GoingToLocation
{Begin:

	log(,, __NFUN_112__(__NFUN_112__("Going to location ", string(CurrentTargetLocation)), "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"));
	MyBot.SwitchToMotion(0);
	InitializeNavigateToPointMovement();
	__NFUN_113__('Waiting');
	stop;			
	@NULL
	@NULL
	@NULL
}

state FakeAttackingPawn
{Begin:

	log(,, __NFUN_112__(__NFUN_112__("Fake attacking pawn ", string(CurrentTargetPawn)), "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"));
	MyBot.SwitchToMotion(1);
	InitializeFakeAttackMovement();
	__NFUN_113__('Waiting');
	stop;	
	@NULL
	@NULL
	@NULL
}

state Waiting
{Begin:

	waitForGoal_AI_Goal(CurrentMoveGoal);
	stop;				
	@NULL
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.BotMovementTestGoal'
}