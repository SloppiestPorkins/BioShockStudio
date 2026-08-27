class HealAtHealthStationAction extends BioshockCharacterAction
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn AvoidTarget;
var(Parameters) HealthStation TargetHealthStation;
var private MoveToGoal CurrentMoveToGoal;
var private int HealAnimationHandle;
var private bool bFinishedUsingHealthStation;
var private config float MaxPathfindingDistanceToUsableHealthStation;
var private config float MinApproachDistanceToAttackTarget;
var private config DamageStimuliSet.DamageStimulusType PoisonedHealthStationDamageStimuliType;
var private config float TimeToWaitForGoingToHealEvent;
var private float ActionStartTime;

function Cleanup()
{
	super(AI_CharacterAction).Cleanup();
	// End:0x33
	if(__NFUN_119__(CurrentMoveToGoal, none))
	{
		CurrentMoveToGoal.__NFUN_198__();
		CurrentMoveToGoal = none;
		// End:0x76
		if(m_Pawn.IsAnimationHandleValid(HealAnimationHandle))
		{
		}
		m_Pawn.SmartPerTrackEaseOutAnimation(HealAnimationHandle);
		ShockAI().SetAvoidTarget(none);
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function bool IsHealthStationUsable(HealthStation TestHealthStation)
{
	assert(__NFUN_119__(TestHealthStation, none));
	return __NFUN_130__(__NFUN_119__(TestHealthStation.AggressorUseNavigationPoint, none), TestHealthStation.CanInteractWithAI());
	return;
	@NULL
	CommanderAction
	Class'ShockAI.EcologyFighterCommanderAction'
	@NULL
}

function float selectionHeuristic(AI_Goal Goal)
{
	local ShockAI AI;
	local HealthStation HealthStation;

	AI = ShockAI(Goal.resource.Pawn());
	assert(__NFUN_119__(AI, none));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x105
	/*@Error*/
	HealthStation = FindUsableHealthStation(AI);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x105
	/*@Error*/
	HealAtHealthStationGoal(Goal).TargetHealthStation = HealthStation;
	return 1.0000000;
	return 0.0000000;
	return;
	@NULL
	CommanderAction
	Class'ShockAI.CommanderAction'
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

function HealthStation FindUsableHealthStation(ShockAI AI)
{
	local int i;
	local float IterPathfindingDistanceToHealthStation, ClosestPathfindingDistanceToHealthStation;
	local NavigationPoint HealthStationAnchor;
	local HealthStation IterHealthStation, ClosestHealthStation;
	local ShockAIScout GameScout;

	GameScout = SpawningManager(AI.Level.SpawningManager).GetGameScout();
	assert(__NFUN_119__(GameScout, none));
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x237
	/*@Error*/
	IterHealthStation = SpawningManager(AI.Level.SpawningManager).HealthStations[i];
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x229
	/*@Error*/
	HealthStationAnchor = IterHealthStation.AggressorUseNavigationPoint;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x229
	/*@Error*/
	IterPathfindingDistanceToHealthStation = GameScout.GetPathfindingDistanceBetween(AI, AI.Location, HealthStationAnchor, HealthStationAnchor.Location, AI.Class);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x229
	/*@Error*/
	ClosestHealthStation = IterHealthStation;
	ClosestPathfindingDistanceToHealthStation = IterPathfindingDistanceToHealthStation;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x5E;
	return ClosestHealthStation;
	return;
	@NULL
	CommanderAction
	Class'ShockAI.EcologyFighterCommanderAction'
	@NULL
}

function MoveToTargetHealthStation()
{
	// End:0x4D
	if(Class'Engine.Pawn'.static.checkAlive(AvoidTarget))
	{
		ShockAI().SetAvoidTarget(AvoidTarget, MinApproachDistanceToAttackTarget);
		AssertWithDescription(__NFUN_114__(CurrentMoveToGoal, none), __NFUN_112__(string(Name), " expected CurrentMoveToGoal to be None!"));
	}
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntActor(movementResource(), achievingGoal.Priority, TargetHealthStation.AggressorUseNavigationPoint);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetDesiredRotationOverride;
	CurrentMoveToGoal.SetShouldNeverSucceed(true);
	CurrentMoveToGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool GetDesiredRotationOverride(out Rotator DesiredRotation)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x58
	/*@Error*/
	DesiredRotation = Rotator(__NFUN_216__(TargetHealthStation.Location, m_Pawn.Location));
	return true;
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function UseTargetHealthStation()
{
	local name HealAnimationName;
	local float PoisonedDamageAmount, TimeToHeal;
	local bool bHealthStationIsHacked;

	TargetHealthStation.OnAIInteract(ShockAI());
	ShockAI().PlaySpeech('HitVendingMachine');
	bHealthStationIsHacked = TargetHealthStation.IsHacked();
	// End:0x91
	if(bHealthStationIsHacked)
	{
		TargetHealthStation.TriggerEffectEvent('PoisonedAI');
		HealAnimationName = Aggressor(m_Pawn).GetHealAtHealthStationAnimation(bHealthStationIsHacked);
	}
	// End:0x116
	if(__NFUN_255__(HealAnimationName, 'None'))
	{
		HealAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, HealAnimationName, Class'Engine.Actor'.8);
		TimeToHeal = __NFUN_174__(Level().TimeSeconds, Aggressor(m_Pawn).GetHealAtHealthStationTime());
		// End:0x1A9
		if(__NFUN_130__(__NFUN_176__(Level().TimeSeconds, TimeToHeal), __NFUN_129__(TargetHealthStation.IsBroken())))
		{
		}
		yield();
		goto J0x159;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x351
		/*@Error*/
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x345
		/*@Error*/
		// End:0x2B3
		if(bHealthStationIsHacked)
		{
			ShockAI().PlaySpeech('Poisoned');
			PoisonedDamageAmount = Aggressor(m_Pawn).GetPoisonedDamageAmount();
		}
		Class'ShockGame.DamageFactory'.static.DealSimpleDamage(TargetHealthStation, ShockAI(), PoisonedHealthStationDamageStimuliType, PoisonedDamageAmount);
		ShockGameDriver(Level().GetGameDriver()).GetPlayerStatsManager().AggressorPoisonedAtHealthStation();
		goto J0x345;
		m_Pawn.Health = __NFUN_175__(ShockAI().GetMaxHealth(), float(1));
		ShockAI().PlaySpeech('Healed');
		ShockGameDriver(Level().GetGameDriver()).GetPlayerStatsManager().AggressorHealedAtHealthStation();
		bFinishedUsingHealthStation = true;
	}
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	// End:0x197
	if(__NFUN_119__(TargetHealthStation, none))
	{
		ShockAI().BecomeAggressive();
		ShockAI().SetShouldRun();
		ActionStartTime = ShockAI().Level.TimeSeconds;
		ShockAI().PlaySpeech('WentToHealthStation');
		MoveToTargetHealthStation();
		// End:0x197
		if(__NFUN_130__(IsHealthStationUsable(TargetHealthStation), __NFUN_129__(bFinishedUsingHealthStation)))
		{
			// End:0xE9
			if(CurrentMoveToGoal.IsMovementSatisfied())
			{
				UseTargetHealthStation();
				goto J0x197;
				goto J0x106;
				// End:0x106
				if(CurrentMoveToGoal.CannotFindWayToDestination())
				{
					goto J0x197;
					// End:0x18A
					if(__NFUN_179__(__NFUN_175__(ShockAI().Level.TimeSeconds, ActionStartTime), TimeToWaitForGoingToHealEvent))
					{
					}
				}
				else
				{
					ShockGameDriver(Level().GetGameDriver()).GetPlayerStatsManager().AggressorGoingToHealthStation(ShockAI());
					yield();
					// [Loop Continue]
					goto J0x98;
					succeed();
					stop;										
					@NULL
				}
			}
			@NULL
			@NULL
		}
	}
	J0x197:

	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

defaultproperties
{
	MaxPathfindingDistanceToUsableHealthStation=4000.0000000
	MinApproachDistanceToAttackTarget=300.0000000
	PoisonedHealthStationDamageStimuliType=18
	TimeToWaitForGoingToHealEvent=5.0000000
	satisfiesGoal=Class'ShockAI.HealAtHealthStationGoal'
	bExclusiveAction=true
}