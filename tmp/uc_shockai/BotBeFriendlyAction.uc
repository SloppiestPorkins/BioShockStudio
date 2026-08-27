class BotBeFriendlyAction extends BotBaseAction implements IInterestedActorDestroyed, IInterestedPawnDied
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn ProtectTarget;
var private bool RunningInitialized;
var private float NextSetTargetTime;
var private ShockPawn LastSawAttackTargetTarget;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super.initAction(R, Goal);
	log('AI_Security', 4, __NFUN_112__(__NFUN_112__("Protect target: ", string(ProtectTarget)), "."));
	assert(__NFUN_119__(ProtectTarget, none));
	assert(ProtectTarget.OwnsControllable(MyBot));
	// End:0xB7
	if(ProtectTarget.IsPlayer())
	{
		MyBot.SetVisionState(false);
		goto J0xEB;
		MyBot.SetVisionState(true);
		MyBot.PeripheralVision = -1.0000000;
	}
	MyBot.UnTriggerEffectEvent('HalfHealth');
	MyBot.UnTriggerEffectEvent('QuarterHealth');
	// End:0x1A4
	if(__NFUN_129__(ProtectTarget.IsPlayer()))
	{
		MyBot.TriggerEffectEvent('BotAILink');
		// End:0x1A4
		if(__NFUN_152__(ProtectTarget.GetNumBotControllables(), 1))
		{
			ProtectTarget.TriggerEffectEvent('BotAILink');
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x1E1
			/*@Error*/
			AttackSpecifiedTarget(MyBot.ScriptedFriendlyAttackTarget, true);
			Level().RegisterNotifyActorDestroyed(self);
			Level().RegisterNotifyPawnDied(self);
		}
	}
	RunningInitialized = false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	local int NumBotsOwned;

	MyBot.UnTriggerEffectEvent('BotAILink');
	// End:0xAF
	if(__NFUN_119__(ProtectTarget, none))
	{
		NumBotsOwned = ProtectTarget.GetNumBotControllables();
		// End:0x80
		if(__NFUN_129__(ProtectTarget.OwnsControllable(MyBot)))
		{
			__NFUN_163__(NumBotsOwned);
			// End:0xAF
			if(__NFUN_152__(NumBotsOwned, 1))
			{
				ProtectTarget.UnTriggerEffectEvent('BotAILink');
			}
			MyBot.UnregisterBotControllable();
			Level().UnRegisterNotifyActorDestroyed(self);
		}
	}
	Level().UnRegisterNotifyPawnDied(self);
	super.Cleanup();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

// Export UBotBeFriendlyAction::execGetProtectTarget(FFrame&, void* const)
native function ShockPawn GetProtectTarget();

function OnViewerSawPawn(VPawn Viewer, Pawn Seen)
{
	local ShockPawn SeenShockPawn;

	super.OnViewerSawPawn(Viewer, Seen);
	SeenShockPawn = ShockPawn(Seen);
	// End:0x72
	if(__NFUN_114__(Seen, ProtectTarget))
	{
		MyBot.TriggerEffectEvent('SawProtectee');
		goto J0xE9;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xE9
		/*@Error*/
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xE9
	/*@Error*/
	AttackSpecifiedTarget(SeenShockPawn, true);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnViewerLostPawn(VPawn Viewer, Pawn Seen)
{
	OnViewerSawPawn(Viewer, Seen);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x53
	/*@Error*/
	MyBot.TriggerEffectEvent('LostProtectee');
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnSecurityBeaconApplied(Actor Damager, ShockPawn SecurityBeaconedTarget)
{
	// End:0x2B
	if(__NFUN_114__(Damager, ProtectTarget))
	{
		AttackSpecifiedTarget(SecurityBeaconedTarget, true);
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function OnAttackSpecifiedTarget(ShockPawn Target, bool ForceNewTarget)
{
	AttackSpecifiedTarget(Target, ForceNewTarget);
	return;
	@NULL
	CommanderAction
}

function OnIntentionallyDamaged(ShockPawn Damager, float TotalDamageDealt)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x124
	/*@Error*/
	log('AI_Security', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn), " is adding alternate damager "), string(Damager)), " at "), string(MyBot.Level.TimeSeconds)), ".  Damage done is "), string(TotalDamageDealt)), " * "), string(MyBot.DamageToFriendlyBotAggroWeight)), "."));
	AddAlternateDamager(Damager, __NFUN_171__(TotalDamageDealt, MyBot.DamageToFriendlyBotAggroWeight));
	AttackNewTargetIfNecessary();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnControllerDamaged(ShockPawn Damager, float TotalDamageDealt)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x124
	/*@Error*/
	log('AI_Security', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn), " is adding alternate damager "), string(Damager)), " at "), string(MyBot.Level.TimeSeconds)), ".  Damage done is "), string(TotalDamageDealt)), " * "), string(MyBot.DamageToProtectTargetAggroWeight)), "."));
	AddAlternateDamager(Damager, __NFUN_171__(TotalDamageDealt, MyBot.DamageToProtectTargetAggroWeight));
	AttackNewTargetIfNecessary();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnControllerDealtDamage(ShockPawn Damagee, float TotalDamageDealt)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x124
	/*@Error*/
	log('AI_Security', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn), " is adding alternate damager "), string(Damagee)), " at "), string(MyBot.Level.TimeSeconds)), ".  Damage done is "), string(TotalDamageDealt)), " * "), string(MyBot.DamageFromProtectTargetAggroWeight)), "."));
	AddAlternateDamager(Damagee, __NFUN_171__(TotalDamageDealt, MyBot.DamageFromProtectTargetAggroWeight));
	AttackNewTargetIfNecessary();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnOtherActorDestroyed(Actor ActorBeingDestroyed)
{
	log(,, __NFUN_112__("ACTOR DESTROYED ", string(ActorBeingDestroyed)));
	// End:0x52
	if(__NFUN_114__(ActorBeingDestroyed, AttackTarget))
	{
		AttackTarget = none;
		AttackNewTargetIfNecessary();
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function OnOtherPawnDied(Pawn DeadPawn)
{
	log(,, __NFUN_112__("PAWN DIED ", string(DeadPawn)));
	// End:0x5D
	if(__NFUN_114__(DeadPawn, AttackTarget))
	{
		assert(__NFUN_129__(DeadPawn.IsAlive()));
		AttackNewTargetIfNecessary();
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function StartGoingToActorSubGoal(Actor targetActor, float LookAtActorDistance)
{
	StopSubGoals();
	CurrentSubGoal = Class'ShockAI.BotGoToActorGoal'.static.Allocate(self).;
	construct_AI_ResourceActorFloat(characterResource(), targetActor, LookAtActorDistance);
	CurrentSubGoal.__NFUN_199__();
	CurrentSubGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function StartProtectingSubGoal(ShockPawn Target)
{
	StopSubGoals();
	CurrentSubGoal = Class'ShockAI.BotProtectTargetGoal'.static.Allocate(self).;
	construct_AI_ResourceShockPawn(characterResource(), Target);
	CurrentSubGoal.__NFUN_199__();
	CurrentSubGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function bool AttackTargetCanBeDetected()
{
	return CanDetectAttackTarget();
	return;
}

function AttackSpecifiedTarget(ShockPawn Target, bool ForceNewTarget)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x1A2
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1A2
	/*@Error*/
	log('AI_Security', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(MyBot.Name), " is now attacking "), string(Target)), "."));
	MyBot.PlaySpeech('StartingToAttackTarget');
	AttackTarget = Target;
	StopSubGoals();
	// End:0x15D
	if(RunningInitialized)
	{
		__NFUN_113__('MovingToAttackTarget');
		NextSetTargetTime = __NFUN_174__(MyBot.Level.TimeSeconds, MyBot.MinFriendlyAttackTargetSwitchTime);
		MyBot.ScriptedFriendlyAttackTarget = none;
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
	@NULL
}

function AttackNewTargetIfNecessary()
{
	local ShockPawn MostThreateningTarget;

	// End:0x70
	if(__NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_119__(AttackTarget, none), AttackTarget.IsAlive()), AttackTarget.CanBeAttacked()), __NFUN_129__(MyBot.PawnIsFriendly(AttackTarget))))
	{
		return;
		MostThreateningTarget = GetMostThreateningAlternateDamager(true);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xA8
		/*@Error*/
	}
	else
	{
		AttackSpecifiedTarget(MostThreateningTarget, true);
		return;
		@NULL
		CommanderAction
		CommanderAction
		@NULL
	}
}

function bool CanDetectAttackTarget()
{
	return __NFUN_130__(__NFUN_176__(VSizeSquared(__NFUN_216__(AttackTarget.Location, MyBot.Location)), __NFUN_171__(MyBot.GetDetectRadius(), MyBot.GetDetectRadius())), CanTraceToTarget(AttackTarget));
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function ReenableBot()
{
	local BotRiseOffGroundGoal RiseGoal;

	RiseGoal = Class'ShockAI.BotRiseOffGroundGoal'.static.Allocate(self).;
	construct_AI_Resource(characterResource());
	RiseGoal.postGoal(self);
	waitForGoal_AI_Goal(RiseGoal);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(Name), " Running of BotBeFriendlyAction"));
	RunningInitialized = true;
	__NFUN_113__('StartingUp');
	stop;		
	@NULL
	@NULL
}

state StartingUp
{Begin:

	log('AI_Security', 4, __NFUN_112__("At state 'StartingUp' of BotBeFriendlyAction.  ProtectTarget=", string(ProtectTarget)));
	// End:0xA0
	if(__NFUN_130__(__NFUN_129__(MyBot.IsFrozen()), __NFUN_129__(MyBot.IsShocked())))
	{
		ReenableBot();
		// End:0xBD
		if(__NFUN_119__(AttackTarget, none))
		{
			__NFUN_113__('MovingToAttackTarget');
		}
		goto J0xC8;
		__NFUN_113__('MovingToProtectTarget');
		stop;						
	}
	@NULL
	@NULL
	@NULL
	@NULL
}

state MovingToProtectTarget
{Begin:

	log('AI_Security', 4, __NFUN_112__("At state 'MovingToProtectTarget' of BotBeFriendlyAction.  ProtectTarget=", string(ProtectTarget)));
	yield();
	// End:0x1CD
	if(true)
	{
		J0x71:

		// End:0xE9 [Loop If]
		if(__NFUN_114__(ProtectTarget, none))
		{
			log('AI_Security', 3, __NFUN_112__(string(m_Pawn), " no longer has a protect target.  Failing friendly action."));
			fail(1);
			StartGoingToActorSubGoal(ProtectTarget, 0.0000000);
		}
		waitForGoal_AI_Goal(CurrentSubGoal);
		// End:0x139
		if(CurrentSubGoal.wasAchieved())
		{
			__NFUN_113__('Protecting');
			log('AI_Security', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn), " could not find a way to it's protect target "), string(ProtectTarget)), " at location "), string(ProtectTarget.Location)), "."));
		}
		__NFUN_256__(0.5000000);
		// [Loop Continue]
		goto J0x71;
		stop;				
		@NULL
		@NULL
		@NULL
	}
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

state Protecting
{Begin:

	log('AI_Security', 4, __NFUN_112__(__NFUN_112__(string(m_Pawn), " at state 'Protecting' of BotBeFriendlyAction.  ProtectTarget = "), string(ProtectTarget)));
	yield();
	// End:0xEA
	if(__NFUN_114__(ProtectTarget, none))
	{
		log('AI_Security', 3, __NFUN_112__(string(m_Pawn), " no longer has a protect target.  Failing friendly action."));
		fail(1);
		StartProtectingSubGoal(ProtectTarget);
		waitForGoal_AI_Goal(CurrentSubGoal);
	}
	__NFUN_113__('MovingToProtectTarget');
	stop;				
	@NULL
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

state MovingToAttackTarget
{Begin:

	log('AI_Security', 4, __NFUN_112__(__NFUN_112__(string(m_Pawn), " at state 'MovingToAttackTarget' of BotBeFriendlyAction.  AttackTarget="), string(AttackTarget)));
	yield();
	// End:0xA0
	if(__NFUN_129__(IsValidAttackTarget(AttackTarget)))
	{
		__NFUN_113__('MovingToProtectTarget');
		StartGoingToActorSubGoal(AttackTarget, MyBot.FriendlyLookAtAttackTargetDistance);
	}
	// End:0x108
	if(__NFUN_130__(IsValidAttackTarget(AttackTarget), __NFUN_129__(CurrentSubGoal.hasCompleted())))
	{
		__NFUN_256__(0.5000000);
		// [Loop Continue]
		goto J0xC9;
		// End:0x148
		if(__NFUN_130__(IsValidAttackTarget(AttackTarget), CurrentSubGoal.wasAchieved()))
		{
		}
		__NFUN_113__('Attacking');
		goto J0x153;
		__NFUN_113__('MovingToProtectTarget');
		stop;								
	}
	@NULL
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// BadToken (0x58)
	/*@Error*/
}

state Attacking
{Begin:

	log('AI_Security', 4, __NFUN_112__(__NFUN_112__(string(m_Pawn), " at state 'Attacking' of BotBeFriendlyAction.  AttackTarget="), string(AttackTarget)));
	yield();
	// End:0x8C
	if(__NFUN_114__(AttackTarget, none))
	{
		__NFUN_113__('MovingToProtectTarget');
		StartAttackTargetSubGoal(AttackTarget);
	}
	// End:0xFA
	if(__NFUN_130__(__NFUN_119__(AttackTarget, none), __NFUN_119__(LastSawAttackTargetTarget, AttackTarget)))
	{
		MyBot.PlaySpeech('SawAttackTarget');
		LastSawAttackTargetTarget = AttackTarget;
		waitForGoal_AI_Goal(CurrentSubGoal);
		// End:0x135
		if(CurrentSubGoal.wasNotAchieved())
		{
			__NFUN_113__('MovingToAttackTarget');
		}
		goto J0x140;
		__NFUN_113__('MovingToProtectTarget');
		stop;						
		@NULL
		@NULL
	}
	@NULL
	@NULL
	J0x140:

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.BotBeFriendlyGoal'
}