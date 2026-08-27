class BotCommanderAction extends CommanderAction
	native
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

enum EBotBehaviorMode
{
	kInitializing,                  // 0
	kNoBehavior,                    // 1
	kTesting,                       // 2
	kMean,                          // 3
	kDormant,                       // 4
	kReturningHome,                 // 5
	kFriendly                       // 6
};

var private BotCommanderAction.EBotBehaviorMode BotBehaviorMode;
var private BotBeDormantGoal CurrentBeDormantGoal;
var private BotReturnHomeGoal CurrentReturnHomeGoal;
var private BotMovementTestGoal CurrentMovementTestGoal;
var private BotBeMeanGoal CurrentBeMeanGoal;
var private BotBeFriendlyGoal CurrentBeFriendlyGoal;
var private FrozenGoal BotFrozenGoal;
var private BotBehaviorGoalInterface CurrentTopLevelGoal;
var private SecurityBot MyBot;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super.initAction(R, Goal);
	MyBot = SecurityBot(m_Pawn);
	assert(__NFUN_119__(MyBot, none));
	SetInitialBehavior();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	log(,, __NFUN_112__("Cleanup called for ", string(m_Pawn)));
	// End:0x52
	if(__NFUN_119__(CurrentTopLevelGoal, none))
	{
		CurrentTopLevelGoal.__NFUN_198__();
		CurrentTopLevelGoal = none;
		// End:0xA8
		if(__NFUN_119__(CurrentBeMeanGoal, none))
		{
			BotBeMeanAction(CurrentBeMeanGoal.achievingAction).DisconnectFromSecuritySystem();
		}
		CurrentBeMeanGoal.__NFUN_198__();
		CurrentBeMeanGoal = none;
		// End:0xD1
		if(__NFUN_119__(CurrentBeDormantGoal, none))
		{
			CurrentBeDormantGoal.__NFUN_198__();
			CurrentBeDormantGoal = none;
			// End:0xFA
			if(__NFUN_119__(CurrentBeFriendlyGoal, none))
			{
			}
			CurrentBeFriendlyGoal.__NFUN_198__();
			CurrentBeFriendlyGoal = none;
			// End:0x123
			if(__NFUN_119__(CurrentReturnHomeGoal, none))
			{
				CurrentReturnHomeGoal.__NFUN_198__();
				CurrentReturnHomeGoal = none;
			}
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x14C
			/*@Error*/
			CurrentMovementTestGoal.__NFUN_198__();
			CurrentMovementTestGoal = none;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x175
			/*@Error*/
		}
		BotFrozenGoal.__NFUN_198__();
		BotFrozenGoal = none;
		super.Cleanup();
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
	@NULL
}

function CleanupGoals()
{
	log(,, __NFUN_112__("CleanupGoals called for ", string(m_Pawn)));
	// End:0x57
	if(__NFUN_119__(CurrentTopLevelGoal, none))
	{
		CurrentTopLevelGoal.__NFUN_198__();
		CurrentTopLevelGoal = none;
		// End:0xC5
		if(__NFUN_119__(CurrentBeMeanGoal, none))
		{
			BotBeMeanAction(CurrentBeMeanGoal.achievingAction).DisconnectFromSecuritySystem();
		}
		CurrentBeMeanGoal.unPostGoal(self);
		CurrentBeMeanGoal.__NFUN_198__();
		CurrentBeMeanGoal = none;
		// End:0x106
		if(__NFUN_119__(CurrentBeDormantGoal, none))
		{
			CurrentBeDormantGoal.unPostGoal(self);
			CurrentBeDormantGoal.__NFUN_198__();
			CurrentBeDormantGoal = none;
		}
		// End:0x147
		if(__NFUN_119__(CurrentBeFriendlyGoal, none))
		{
			CurrentBeFriendlyGoal.unPostGoal(self);
			CurrentBeFriendlyGoal.__NFUN_198__();
			CurrentBeFriendlyGoal = none;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x188
			/*@Error*/
		}
		CurrentReturnHomeGoal.unPostGoal(self);
		CurrentReturnHomeGoal.__NFUN_198__();
		CurrentReturnHomeGoal = none;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x1C9
		/*@Error*/
		CurrentMovementTestGoal.unPostGoal(self);
	}
	CurrentMovementTestGoal.__NFUN_198__();
	CurrentMovementTestGoal = none;
	BotBehaviorMode = 1;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

protected function bool ShouldHandleDamageEvents()
{
	return false;
	return;
}

function BeMean()
{
	CleanupGoals();
	CurrentBeMeanGoal = Class'ShockAI.BotBeMeanGoal'.static.Allocate(self).;
	construct_AI_Resource(characterResource());
	assert(__NFUN_119__(CurrentBeMeanGoal, none));
	CurrentBeMeanGoal.__NFUN_199__();
	CurrentBeMeanGoal.postGoal(self);
	BotBehaviorMode = 3;
	assert(__NFUN_114__(CurrentTopLevelGoal, none));
	CurrentTopLevelGoal = CurrentBeMeanGoal;
	CurrentTopLevelGoal.__NFUN_199__();
	MyBot.ScriptedFriendlyAttackTarget = none;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function BeDormant(optional bool NeverDie)
{
	CleanupGoals();
	// End:0x87
	if(__NFUN_130__(__NFUN_130__(__NFUN_129__(MyBot.IsFrozen()), __NFUN_129__(MyBot.IsShocked())), __NFUN_119__(BotFrozenGoal, none)))
	{
		BotFrozenGoal.unPostGoal(self);
		BotFrozenGoal.__NFUN_198__();
		BotFrozenGoal = none;
		CurrentBeDormantGoal = Class'ShockAI.BotBeDormantGoal'.static.Allocate(self).;
	}
	construct_AI_ResourceBool(characterResource(), NeverDie);
	assert(__NFUN_119__(CurrentBeDormantGoal, none));
	CurrentBeDormantGoal.__NFUN_199__();
	CurrentBeDormantGoal.postGoal(self);
	BotBehaviorMode = 4;
	assert(__NFUN_114__(CurrentTopLevelGoal, none));
	CurrentTopLevelGoal = CurrentBeDormantGoal;
	CurrentTopLevelGoal.__NFUN_199__();
	MyBot.ScriptedFriendlyAttackTarget = none;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function BeFriendly(ShockPawn Protectee)
{
	// End:0x6C
	if(IsFriendly())
	{
		assert(__NFUN_119__(CurrentBeFriendlyGoal, none));
		log('AI_Security', 2, __NFUN_112__(string(Name), " is already using the BeFriendly behavior type."));
		return;
		MyBot.RegisterBotControllable(Protectee);
	}
	CleanupGoals();
	CurrentBeFriendlyGoal = Class'ShockAI.BotBeFriendlyGoal'.static.Allocate(self).;
	construct_AI_ResourceShockPawn(characterResource(), Protectee);
	assert(__NFUN_119__(CurrentBeFriendlyGoal, none));
	CurrentBeFriendlyGoal.__NFUN_199__();
	CurrentBeFriendlyGoal.postGoal(self);
	BotBehaviorMode = 6;
	assert(__NFUN_114__(CurrentTopLevelGoal, none));
	CurrentTopLevelGoal = CurrentBeFriendlyGoal;
	CurrentTopLevelGoal.__NFUN_199__();
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function ReturnHome()
{
	// End:0x6F
	if(IsReturningHome())
	{
		assert(__NFUN_119__(CurrentReturnHomeGoal, none));
		log('AI_Security', 2, __NFUN_112__(string(Name), " is already using the ReturningHome behavior type."));
		return;
		CleanupGoals();
	}
	CurrentReturnHomeGoal = Class'ShockAI.BotReturnHomeGoal'.static.Allocate(self).;
	construct_AI_Resource(characterResource());
	assert(__NFUN_119__(CurrentReturnHomeGoal, none));
	CurrentReturnHomeGoal.__NFUN_199__();
	CurrentReturnHomeGoal.postGoal(self);
	BotBehaviorMode = 5;
	ShockAI().PlaySpeech('AlarmEnded');
	assert(__NFUN_114__(CurrentTopLevelGoal, none));
	CurrentTopLevelGoal = CurrentReturnHomeGoal;
	CurrentTopLevelGoal.__NFUN_199__();
	MyBot.ScriptedFriendlyAttackTarget = none;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function MovementTestMode()
{
	CleanupGoals();
	CurrentMovementTestGoal = Class'ShockAI.BotMovementTestGoal'.static.Allocate(self).;
	construct_AI_Resource(characterResource());
	assert(__NFUN_119__(CurrentMovementTestGoal, none));
	CurrentMovementTestGoal.__NFUN_199__();
	CurrentMovementTestGoal.postGoal(self);
	BotBehaviorMode = 2;
	assert(__NFUN_114__(CurrentTopLevelGoal, none));
	CurrentTopLevelGoal = CurrentMovementTestGoal;
	CurrentTopLevelGoal.__NFUN_199__();
	MyBot.ScriptedFriendlyAttackTarget = none;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

// Export UBotCommanderAction::execIsInitializing(FFrame&, void* const)
native function bool IsInitializing();

// Export UBotCommanderAction::execIsMean(FFrame&, void* const)
native function bool IsMean();

// Export UBotCommanderAction::execIsDormant(FFrame&, void* const)
native function bool IsDormant();

// Export UBotCommanderAction::execIsFriendly(FFrame&, void* const)
native function bool IsFriendly();

// Export UBotCommanderAction::execIsReturningHome(FFrame&, void* const)
native function bool IsReturningHome();

function OnSecurityAlarmEnded(bool TurnedOffBySecurityStation, optional bool CleanupSecurityImmediately)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x10D
	/*@Error*/
	log('AI_Security', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Security alarm ended, TurnedOffBySecurityStation = ", string(TurnedOffBySecurityStation)), ", CleanupSecurityImmediately = "), string(CleanupSecurityImmediately)), ", "), string(Name)), " going home or being destroyed."));
	// End:0xFD
	if(__NFUN_129__(CleanupSecurityImmediately))
	{
		// End:0xF0
		if(TurnedOffBySecurityStation)
		{
			BeDormant();
			goto J0xFA;
			ReturnHome();
			goto J0x10D;
			MyBot.__NFUN_279__();
		}
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
	@NULL
}

function OnSecuritySystemDeactivated()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x73
	/*@Error*/
	log('AI_Security', 4, __NFUN_112__(__NFUN_112__("The security system has been deactivated, ", string(Name)), " going dormant."));
	BeDormant();
	return;
	@NULL
}

function OnSecurityAlarmReactivated()
{
	// End:0x17
	if(IsReturningHome())
	{
		BeMean();
	}
	return;
}

function OnSecurityBeaconApplied(Actor Damager, ShockPawn SecurityBeaconedTarget)
{
	// End:0x38
	if(__NFUN_119__(CurrentTopLevelGoal, none))
	{
		CurrentTopLevelGoal.OnSecurityBeaconApplied(Damager, SecurityBeaconedTarget);
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function OnControllerDamaged(ShockPawn Damager, float TotalDamageDealt)
{
	// End:0x38
	if(__NFUN_119__(CurrentTopLevelGoal, none))
	{
		CurrentTopLevelGoal.OnControllerDamaged(Damager, TotalDamageDealt);
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function OnControllerDealtDamage(ShockPawn Damagee, float TotalDamageDealt)
{
	// End:0x38
	if(__NFUN_119__(CurrentTopLevelGoal, none))
	{
		CurrentTopLevelGoal.OnControllerDealtDamage(Damagee, TotalDamageDealt);
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function AttackSpecifiedTarget(ShockPawn Target, bool ForceNewTarget)
{
	// End:0x39
	if(__NFUN_119__(CurrentTopLevelGoal, none))
	{
		CurrentTopLevelGoal.OnAttackSpecifiedTarget(Target, ForceNewTarget);
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function OnControllerKilled(ShockPawn Controller)
{
	assert(IsFriendly());
	Deactivate();
	return;
}

function OnControllerDestroyed(ShockPawn Controller)
{
	assert(IsFriendly());
	Deactivate();
	MyBot.SetCurrentOwner(none);
	return;
	@NULL
}

function OnHacked(ShockPawn Hacker)
{
	// End:0x9E
	if(__NFUN_129__(__NFUN_132__(__NFUN_132__(IsDormant(), MyBot.IsFrozen()), MyBot.IsShocked())))
	{
		log('AI_Security', 2, __NFUN_112__(string(MyBot), " is being hacked but is not dormant, frozen, or shocked."));
		// End:0xD9
		if(MyBot.IsFrozen())
		{
		}
		MyBot.ClearFrozen();
		CleanupGoals();
		// End:0x114
		if(MyBot.IsShocked())
		{
		}
		MyBot.ClearShocked();
		CleanupGoals();
		// End:0x185
		if(__NFUN_130__(__NFUN_119__(MyBot.GetCurrentOwner(), none), MyBot.GetCurrentOwner().OwnsControllable(MyBot)))
		{
		}
		CleanupGoals();
		MyBot.UnregisterBotControllable();
		MyBot.SetCurrentOwner(Hacker);
		MyBot.AddHealth(MyBot.GetMaxHealth());
	}
	Reactivate(Hacker);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnAlarmTargetChanged(ShockPawn NewTarget)
{
	// End:0x17
	if(IsMean())
	{
		BeMean();
	}
	return;
}

function OnIntentionallyDamaged(ShockPawn Damager, float TotalDamageDealt)
{
	CurrentTopLevelGoal.OnIntentionallyDamaged(Damager, TotalDamageDealt);
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function OnBumpedOtherBot(SecurityBot OtherBot)
{
	CurrentTopLevelGoal.OnBumpedOtherBot(OtherBot);
	return;
	@NULL
	CommanderAction
}

function OnKilledOtherPawn(ShockPawn Killee)
{
	CurrentTopLevelGoal.OnKilledOtherPawn(Killee);
	return;
	@NULL
	CommanderAction
}

function Deactivate()
{
	assert(IsFriendly());
	ShockAI().PlaySpeech('Deactivated');
	BeDormant();
	ShockPlayerController(MyBot.Level.GetLocalPlayerController()).ResetFocii();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Reactivate(ShockPawn Reactivator)
{
	BeFriendly(Reactivator);
	ShockPlayerController(MyBot.Level.GetLocalPlayerController()).ResetFocii();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

private function StartShockedBehavior()
{
	StartFrozenBehavior();
	return;
}

private function StopShockedBehavior()
{
	StopFrozenBehavior();
	return;
}

function StartFrozenBehavior()
{
	// End:0x41
	if(__NFUN_119__(BotFrozenGoal, none))
	{
		BotFrozenGoal.unPostGoal(self);
		BotFrozenGoal.__NFUN_198__();
		BotFrozenGoal = none;
		BotFrozenGoal = Class'ShockAI.FrozenGoal'.static.Allocate(self).;
	}
	construct_AI_Resource(characterResource());
	BotFrozenGoal.__NFUN_199__();
	BotFrozenGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function StopFrozenBehavior()
{
	// End:0x3C
	if(__NFUN_119__(BotFrozenGoal, none))
	{
		BotFrozenAction(BotFrozenGoal.achievingAction).Unfreeze();
		return;
		@NULL
		CommanderAction
		EcologyFighterCommanderAction
	}
	@NULL
}

function ClearFrozenGoal()
{
	BotFrozenGoal.__NFUN_198__();
	BotFrozenGoal = none;
	return;
	@NULL
	CommanderAction
}

function EnterTestMode()
{
	MovementTestMode();
	return;
}

function TestGoToLocation(Vector testLocation)
{
	BotMovementTestAction(CurrentMovementTestGoal.achievingAction).TestGoToLocation(testLocation);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function FakeAttackPawn(ShockPawn targetPawn)
{
	BotMovementTestAction(CurrentMovementTestGoal.achievingAction).TestFakeAttackPawn(targetPawn);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

// Export UBotCommanderAction::execGetAttackTarget(FFrame&, void* const)
native function ShockPawn GetAttackTarget();

// Export UBotCommanderAction::execGetProtectTarget(FFrame&, void* const)
native function ShockPawn GetProtectTarget();

function SetInitialBehavior()
{
	// End:0x17B
	if(__NFUN_119__(MyBot.StartOwnerPawn, none))
	{
		assert(__NFUN_129__(MyBot.StartOwnerPawn.OwnsControllable(MyBot)));
		// End:0xC5
		if(MyBot.StartOwnerPawn.CanHaveMoreBotControllables())
		{
			MyBot.SetCurrentOwner(MyBot.StartOwnerPawn);
			BeFriendly(MyBot.StartOwnerPawn);
			goto J0x178;
			log('AI_Security', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn), " attempted to start activated but could not because "), string(MyBot.StartOwnerPawn)), " cannot have any more controllables.  Starting dormant!"));
		}
		BeDormant(true);
		goto J0x218;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x20E
		/*@Error*/
		BeDormant(true);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x20B
		/*@Error*/
		MyBot.SetCurrentOwner(ShockPawn(MyBot.Level.GetLocalPlayerController().Pawn));
	}
	goto J0x218;
	BeMean();
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}
