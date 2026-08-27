class InsectSwarmAttackAction extends BioshockCharacterAction
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn AttackTarget;
var(Parameters) Rotator StartingRotation;
var private MoveToGoal CurrentMoveToGoal;
var private InsectSwarm MySwarm;
var private Vector Destination;
var private bool HasNotifiedAIOfAttack;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	MySwarm = InsectSwarm(m_Pawn);
	InitiateMovement();
	HasNotifiedAIOfAttack = false;
	MySwarm.CurrentAttackTarget = AttackTarget;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	MySwarm.CurrentAttackTarget = none;
	// End:0x2F
	if(HasNotifiedAIOfAttack)
	{
		NotifyTargetNotBeingAttacked();
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x58
		/*@Error*/
		CurrentMoveToGoal.__NFUN_198__();
	}
	CurrentMoveToGoal = none;
	super(AI_CharacterAction).Cleanup();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function InitiateMovement()
{
	assert(__NFUN_114__(CurrentMoveToGoal, none));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, m_Pawn.Location, true);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__GetUpdatedDestination__Delegate = GetUpdatedDestination;
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetDesiredRotationOverride;
	CurrentMoveToGoal.SetShouldNeverSucceed(true);
	CurrentMoveToGoal.SetOverriddenReachedDestinationThreshold(20.0000000);
	CurrentMoveToGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function GetUpdatedDestination(out Actor outDestinationActor, out Vector outDestinationLocation)
{
	// End:0x33
	if(IsValidTarget(AttackTarget))
	{
		Destination = TargetLocation(AttackTarget);
		outDestinationLocation = Destination;
		return;
	}
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool GetDesiredRotationOverride(out Rotator DesiredRotation)
{
	DesiredRotation = StartingRotation;
	return true;
	return;
	@NULL
	CommanderAction
}

function Vector TargetLocation(ShockPawn Target)
{
	return Target.GetTargetTrackingLocation();
	return;
	@NULL
}

function bool IsValidTarget(ShockPawn Target)
{
	return __NFUN_130__(Target.IsAlive(), Target.CanBeAttacked());
	return;
	@NULL
	CommanderAction
}

function bool IsWithinAttackRange()
{
	local Vector ZeroZ;

	ZeroZ = __NFUN_216__(MySwarm.Location, TargetLocation(AttackTarget));
	ZeroZ.Z = 0.0000000;
	return __NFUN_176__(__NFUN_225__(ZeroZ), MySwarm.GetAttackRange());
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function DoDamage(float DamageAmount)
{
	local DamageStimuliSet DamageSet;
	local int i;

	DamageSet = Class'Engine.DamageStimuliSet'.static.GetDamageStimuliSet(MySwarm.GetDamageStimuliSetName());
	i = 0;
	// End:0xB1
	if(__NFUN_150__(i, DamageSet.Stimulus.Length))
	{
		DamageSet.Stimulus[i].Amount = DamageAmount;
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x43;
		AttackTarget.TakeDamage(DamageSet, 0.0000000, MySwarm, vect(0.0000000, 0.0000000, 0.0000000), vect(0.0000000, 0.0000000, 0.0000000), vect(0.0000000, 0.0000000, 0.0000000), 'None', 1.0000000);
	}
	DamageSet.__NFUN_200__();
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function Attack()
{
	local float NextAttackTimeDelta, DamageAmount;

	NotifyTargetOfAttack();
	J0x0A:

	// End:0xBC [Loop If]
	if(__NFUN_130__(IsWithinAttackRange(), IsValidTarget(AttackTarget)))
	{
		NextAttackTimeDelta = MySwarm.GetRandomAttackTimeDelta();
		DamageAmount = __NFUN_171__(MySwarm.GetDamagePerSecond(), NextAttackTimeDelta);
		// End:0xAD
		if(__NFUN_176__(__NFUN_195__(), MySwarm.GetHealthPercentage()))
		{
			DoDamage(DamageAmount);
			__NFUN_256__(NextAttackTimeDelta);
			// [Loop Continue]
			goto J0x0A;
			NotifyTargetNotBeingAttacked();
			return;
			@NULL
			EcologyAI
		}
		EcologyFighterCommanderAction
		@NULL
	}
}

function NotifyTargetOfAttack()
{
	// End:0x38
	if(__NFUN_119__(ShockAI(AttackTarget), none))
	{
		ShockAI(AttackTarget).StartAttackedByInsectSwarmBehavior();
		MySwarm.TriggerEffectEvent('Attacking');
	}
	HasNotifiedAIOfAttack = true;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function NotifyTargetNotBeingAttacked()
{
	// End:0x38
	if(__NFUN_119__(ShockAI(AttackTarget), none))
	{
		ShockAI(AttackTarget).StopAttackedByInsectSwarmBehavior();
		MySwarm.UnTriggerEffectEvent('Attacking');
	}
	HasNotifiedAIOfAttack = false;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	log('AI_Bioweapon', 4, __NFUN_112__(string(Name), " Running of InsectSwarmAttackAction"));
	// End:0x76
	if(__NFUN_130__(__NFUN_129__(IsWithinAttackRange()), IsValidTarget(AttackTarget)))
	{
		yield();
		// [Loop Continue]
		goto J0x42;
		// End:0xA8
		if(IsValidTarget(AttackTarget))
		{
		}
		Attack();
		__NFUN_256__(0.2000000);
		goto 'Attack';
		assert(__NFUN_129__(IsValidTarget(AttackTarget)));
	}
	log(,, __NFUN_112__(string(MySwarm.Name), " succeeded in attacking."));
	succeed();
	stop;		
	@NULL
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/;
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.InsectSwarmAttackGoal'
	bExclusiveAction=true
}