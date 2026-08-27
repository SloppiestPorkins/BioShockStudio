class ProtectPlayerAction extends BioshockCharacterAction
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) private ShockPlayer TargetPlayer;
var private MoveToGoal CurrentMoveToGoal;
var private bool bWithinInnerRangeToPlayer;
var private float LastTimeStoppedMoving;
var private float TimeToRotateAgain;
var private Rotator DesiredStoppedRotation;
var private config Range DesiredRangeToPlayer;
var private config float MinTimeBeforeWeStartLookingAround;
var private config Range LookAroundTime;

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
	// End:0x33
	if(__NFUN_119__(CurrentMoveToGoal, none))
	{
		CurrentMoveToGoal.__NFUN_198__();
		CurrentMoveToGoal = none;
		TargetPlayer.UnregisterControllable(ICanBeControlled(m_Pawn));
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyPausedDueToExclusivity()
{
	super(AI_RunnableAction).NotifyPausedDueToExclusivity();
	return;
	@NULL
}

function NotifyRunningDueToExclusivity()
{
	super(AI_RunnableAction).NotifyRunningDueToExclusivity();
	ShockAI().BecomeAggressive();
	ShockAI().SetShouldRun();
	return;
	@NULL
}

function bool ShouldStopMovingToTarget()
{
	local float DistanceToTarget;
	local bool bIsWithinZHeightToPlayer;

	DistanceToTarget = __NFUN_175__(__NFUN_175__(__NFUN_228__(__NFUN_216__(TargetPlayer.Location, m_Pawn.Location)), m_Pawn.CollisionRadius), TargetPlayer.CollisionRadius);
	bIsWithinZHeightToPlayer = __NFUN_178__(__NFUN_186__(__NFUN_175__(TargetPlayer.Location.Z, m_Pawn.Location.Z)), __NFUN_171__(m_Pawn.CollisionHeight, 2.0000000));
	// End:0x142
	if(bWithinInnerRangeToPlayer)
	{
		// End:0x13D
		if(__NFUN_132__(__NFUN_177__(DistanceToTarget, DesiredRangeToPlayer.Max), __NFUN_129__(bIsWithinZHeightToPlayer)))
		{
			bWithinInnerRangeToPlayer = false;
			return false;
			goto J0x13F;
			return true;
			goto J0x1F6;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x18A
			/*@Error*/
			bWithinInnerRangeToPlayer = true;
			return true;
			goto J0x1F6;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x1DC
			/*@Error*/
			ShockAI().SetShouldWalk();
		}
		goto J0x1F4;
	}
	ShockAI().SetShouldRun();
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool GetDesiredRotationOverride(out Rotator DesiredRotation)
{
	local float CurrentTime;
	local Rotator OppositeRotation;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x124
	/*@Error*/
	CurrentTime = Level().TimeSeconds;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x10F
	/*@Error*/
	TimeToRotateAgain = __NFUN_174__(CurrentTime, RandRange(LookAroundTime.Min, LookAroundTime.Max));
	OppositeRotation = Rotator(__NFUN_211__(Vector(DesiredStoppedRotation)));
	DesiredStoppedRotation = ShockAI().GetGoodDirectionToLookIn(DesiredStoppedRotation);
	DesiredRotation = DesiredStoppedRotation;
	return true;
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnMoveEnded()
{
	LastTimeStoppedMoving = Level().TimeSeconds;
	DesiredStoppedRotation = Rotator(__NFUN_216__(TargetPlayer.Location, m_Pawn.Location));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function MoveTowardPlayer()
{
	assert(__NFUN_114__(CurrentMoveToGoal, none));
	assert(__NFUN_119__(TargetPlayer, none));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntActor(movementResource(), achievingGoal.Priority, TargetPlayer);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__ShouldStopMoving__Delegate = ShouldStopMovingToTarget;
	CurrentMoveToGoal.__OnMoveEnded__Delegate = OnMoveEnded;
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetDesiredRotationOverride;
	CurrentMoveToGoal.SetShouldNeverSucceed(true);
	CurrentMoveToGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	// End:0x89
	if(Class'Engine.Pawn'.static.checkAlive(Protector(m_Pawn).GetCurrentGatherer()))
	{
		Protector(m_Pawn).GetCurrentGatherer().NotifyLoseProtectorEscort();
		Protector(m_Pawn).SetCurrentGatherer(none);
		TargetPlayer.RegisterControllable(ICanBeControlled(m_Pawn));
		ShockAI().BecomeAggressive();
	}
	ShockAI().SetShouldRun();
	MoveTowardPlayer();
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
	DesiredRangeToPlayer=(Min=150.0000000,Max=250.0000000)
	MinTimeBeforeWeStartLookingAround=1.0000000
	LookAroundTime=(Min=2.0000000,Max=5.0000000)
	satisfiesGoal=Class'ShockAI.ProtectPlayerGoal'
	bExclusiveAction=true
}