class FleeAction extends BioshockCharacterAction
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) Vector FleeOrigin;
var private Actor FleePoint;
var private bool bFinishedMoving;
var private float NextTimeToRotate;
var private Rotator FleeRotation;
var private MoveToGoal CurrentMoveToGoal;
var private config float MinDistanceToFlee;
var private config Range FleeCooldownTimeRange;
var private config Range FleeLookAroundRotationUpdateTime;
var private config Range TimeToLookAtFleeOrigin;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	ShockAI().StopAnyScriptedLoopingAnimations();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function Cleanup()
{
	super(AI_CharacterAction).Cleanup();
	ShockAI().StopSpeech('Terrified');
	// End:0x54
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

function NotifyPausedDueToExclusivity()
{
	super(AI_RunnableAction).NotifyPausedDueToExclusivity();
	instantSucceed();
	return;
	@NULL
}

function OnMoveEnded()
{
	bFinishedMoving = true;
	return;
	@NULL
}

function bool GetDesiredRotationOverride(out Rotator DesiredRotation)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xF8
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xE3
	/*@Error*/
	FleeRotation = ShockAI().GetGoodDirectionToLookIn(m_Pawn.Rotation);
	NextTimeToRotate = __NFUN_174__(m_Pawn.Level.TimeSeconds, RandRange(FleeLookAroundRotationUpdateTime.Min, FleeLookAroundRotationUpdateTime.Max));
	DesiredRotation = FleeRotation;
	return true;
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function MoveToFleePoint()
{
	assert(__NFUN_114__(CurrentMoveToGoal, none));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntActor(movementResource(), achievingGoal.Priority, FleePoint);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__OnMoveEnded__Delegate = OnMoveEnded;
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetDesiredRotationOverride;
	CurrentMoveToGoal.SetShouldNeverSucceed(true);
	CurrentMoveToGoal.postGoal(self);
	// End:0x104
	if(__NFUN_129__(bFinishedMoving))
	{
		yield();
		goto J0xE8;
		ShockAI().bAvoidLastPath = true;
		achievingGoal.changePriority(51);
		CurrentMoveToGoal.changePriority(51);
	}
	DummyWeaponGoal.changePriority(51);
	FleeRotation = Rotator(__NFUN_211__(ShockAI().GetAverageVelocity()));
	ShockAI().PlaySpeech('Terrified');
	__NFUN_256__(RandRange(FleeCooldownTimeRange.Min, FleeCooldownTimeRange.Max));
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	// End:0x106
	if(ShockAI().FindPointToAvoidTarget(ShockAI(), FleePoint, true, 0.0000000, 0.0000000, MinDistanceToFlee))
	{
		ShockAI().QuickLook(Level(), RandRange(TimeToLookAtFleeOrigin.Min, TimeToLookAtFleeOrigin.Max), FleeOrigin);
		ShockAI().SetShouldRun();
		ShockAI().BecomeAggressive();
		ShockAI().PlaySpeech('FledSpeech');
		MoveToFleePoint();
		succeed();
		stop;						
		@NULL
	}
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/;
}

defaultproperties
{
	MinDistanceToFlee=1000.0000000
	FleeCooldownTimeRange=(Min=20.0000000,Max=40.0000000)
	FleeLookAroundRotationUpdateTime=(Min=3.0000000,Max=6.0000000)
	TimeToLookAtFleeOrigin=(Min=2.0000000,Max=5.0000000)
	satisfiesGoal=Class'ShockAI.FleeGoal'
	bExclusiveAction=true
}