class BotBeMeanAction extends BotBaseAction
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var private SecurityManager SecuritySystem;
var private bool WasSearching;
var private ShockPawn LastSawAttackTargetTarget;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super.initAction(R, Goal);
	SecuritySystem = SecurityManager(ShockGameInfo(MyBot.Level.Game).GetSecurityManager());
	assert(__NFUN_119__(SecuritySystem, none));
	AttackTarget = GetMostThreateningTarget();
	MyBot.SetVisionState(true);
	MyBot.ResetVisionCone();
	MyBot.SetHackedEffectEvent();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	NotifySecuritySystemCannotSeeTarget();
	super.Cleanup();
	return;
	@NULL
}

function StartGoingToAlarmTargetGoal(SecurityManager inSecurityManager, float LookAtActorDistance)
{
	StopSubGoals();
	CurrentSubGoal = Class'ShockAI.BotGoToAlarmTargetGoal'.static.Allocate(self).;
	construct_AI_ResourceSecurityManagerFloat(characterResource(), inSecurityManager, LookAtActorDistance);
	CurrentSubGoal.__NFUN_199__();
	CurrentSubGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function StartSearchForAlarmTargetGoal(SecurityManager inSecurityManager)
{
	StopSubGoals();
	CurrentSubGoal = Class'ShockAI.BotSearchForAlarmTargetGoal'.static.Allocate(self).;
	construct_AI_ResourceSecurityManager(characterResource(), inSecurityManager);
	CurrentSubGoal.__NFUN_199__();
	CurrentSubGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

// Export UBotBeMeanAction::execAttackTargetCanBeDetected(FFrame&, void* const)
native function bool AttackTargetCanBeDetected();

function ShockPawn GetMostThreateningTarget()
{
	local ShockPawn MostThreateningTarget;

	MostThreateningTarget = GetMostThreateningAlternateDamager(false);
	// End:0x2E
	if(__NFUN_119__(MostThreateningTarget, none))
	{
		return MostThreateningTarget;
		return SecuritySystem.GetAlarmTarget();
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnViewerSawPawn(VPawn Viewer, Pawn Seen)
{
	local ShockPawn SeenShockPawn;

	SeenShockPawn = ShockPawn(Seen);
	super.OnViewerSawPawn(Viewer, Seen);
	// End:0x86
	if(__NFUN_114__(Seen, SecuritySystem.GetAlarmTarget()))
	{
		assert(Seen.__NFUN_303__('ShockPawn'));
		NotifySecuritySystemCanSeeTarget();
		goto J0x102;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x102
		/*@Error*/
	}
	SecuritySystem.NotifyNewTargetSeen(MyBot, SeenShockPawn);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnViewerLostPawn(VPawn Viewer, Pawn Seen)
{
	super.OnViewerLostPawn(Viewer, Seen);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x67
	/*@Error*/
	assert(Seen.__NFUN_303__('ShockPawn'));
	NotifySecuritySystemCannotSeeTarget();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnSecurityBeaconApplied(Actor Damager, ShockPawn SecurityBeaconedTarget)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x94
	/*@Error*/
	SecuritySystem.NotifyNewTargetSeen(MyBot, SecurityBeaconedTarget);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnIntentionallyDamaged(ShockPawn Damager, float TotalDamageDealt)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x160
	/*@Error*/
	log('AI_Security', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn), " is adding alternate damager "), string(Damager)), " at "), string(MyBot.Level.TimeSeconds)), ".  Damage done is "), string(TotalDamageDealt)), "."));
	AddAlternateDamager(Damager, TotalDamageDealt);
	OnBotDamaged(Damager, TotalDamageDealt);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

private function OnBotDamaged(ShockPawn Damager, float TotalDamageDealt)
{
	return;
}

function NotifySecuritySystemCanSeeTarget()
{
	SecuritySystem.NotifySawTarget(MyBot, SecuritySystem.GetAlarmTarget());
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
}

function NotifySecuritySystemCannotSeeTarget()
{
	SecuritySystem.NotifyLostTarget(MyBot, SecuritySystem.GetAlarmTarget());
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
}

function DisconnectFromSecuritySystem()
{
	NotifySecuritySystemCannotSeeTarget();
	return;
}

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(Name), " Running of BotBeMeanAction"));
	MyBot.StartEverything();
	// End:0xC6
	if(__NFUN_114__(AttackTarget, none))
	{
		log('AI_Security', 2, __NFUN_112__(string(m_Pawn), " has no attack target, not doing anything in the mean state."));
		__NFUN_113__('None');
		__NFUN_113__('MovingToAlarmTarget');
		stop;				
	}
	@NULL
	@NULL
	@NULL
	@NULL
}

state MovingToAlarmTarget
{
	ignores OnBotDamaged;
Begin:

	log('AI_Security', 4, __NFUN_112__(__NFUN_112__(string(m_Pawn), " at state 'MovingToAlarmTarget' of BotBeMeanAction.  AttackTarget="), string(AttackTarget)));
	WasSearching = false;
	StartGoingToAlarmTargetGoal(SecuritySystem, MyBot.MeanLookAtAttackTargetDistance);
	waitForGoal_AI_Goal(CurrentSubGoal);
	// End:0xDE
	if(CurrentSubGoal.wasAchieved())
	{
		__NFUN_113__('Attacking');
		goto J0xE9;
		__NFUN_113__('SearchingForAlarmTarget');
		assert(false);
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

state SearchingForAlarmTarget
{
	ignores OnBotDamaged;
Begin:

	log('AI_Security', 4, __NFUN_112__(__NFUN_112__(string(m_Pawn), " at state 'SearchingForAlarmTarget' of BotBeMeanAction.  AttackTarget="), string(AttackTarget)));
	// End:0xD8
	if(__NFUN_114__(SecuritySystem.GetAlarmTarget(), none))
	{
		log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " has no alarm target.  Failing."));
		__NFUN_113__('None');
		WasSearching = true;
		StartSearchForAlarmTargetGoal(SecuritySystem);
	}
	waitForGoal_AI_Goal(CurrentSubGoal);
	WasSearching = false;
	// End:0x13E
	if(CurrentSubGoal.wasAchieved())
	{
		__NFUN_113__('Attacking');
		goto J0x149;
		__NFUN_113__('MovingToAlarmTarget');
		assert(false);
		stop;				
	}
	@NULL
	J0x149:

	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// BadToken (0x50)
	/*@Error*/
}

state Attacking
{
	ignores WaitForAttackGoal;
Begin:

	log('AI_Security', 4, __NFUN_112__(__NFUN_112__(string(m_Pawn), " at state 'Attacking' of BotBeMeanAction.  AttackTarget="), string(AttackTarget)));
	// End:0x87
	if(__NFUN_114__(AttackTarget, none))
	{
		AttackTarget = GetMostThreateningTarget();
		// End:0x18C
		if(__NFUN_119__(AttackTarget, none))
		{
			// End:0x18C
			if(true)
			{
				StartAttackTargetSubGoal(AttackTarget);
			}
			// End:0x108
			if(__NFUN_130__(__NFUN_119__(AttackTarget, none), __NFUN_119__(LastSawAttackTargetTarget, AttackTarget)))
			{
				MyBot.PlaySpeech('SawAttackTarget');
				LastSawAttackTargetTarget = AttackTarget;
				WaitForAttackGoal();
				AttackTarget = GetMostThreateningTarget();
				// End:0x13B
				if(__NFUN_114__(AttackTarget, none))
				{
					goto J0x18C;
					goto J0x189;
					// End:0x189
					if(__NFUN_114__(AttackTarget, SecuritySystem.GetAlarmTarget()))
					{
					}
					// End:0x17B
					if(WasSearching)
					{
						__NFUN_113__('SearchingForAlarmTarget');
						goto J0x186;
						__NFUN_113__('MovingToAlarmTarget');
					}
					goto J0x18C;
					// [Loop Continue]
					goto J0x96;
					assert(__NFUN_114__(AttackTarget, none));
					assert(__NFUN_114__(SecuritySystem.GetAlarmTarget(), none));
					stop;															
				}
				@NULL
			}
		}
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
	satisfiesGoal=Class'ShockAI.BotBeMeanGoal'
}