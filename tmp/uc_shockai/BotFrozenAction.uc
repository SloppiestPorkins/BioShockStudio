class BotFrozenAction extends BioshockCharacterAction
	collapsecategories
	hidecategories(Object,InternalParameters);

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
	// End:0xA1
	if(__NFUN_132__(__NFUN_132__(MyBot.IsFriendly(), MyBot.IsMean()), MyBot.IsReturningHome()))
	{
		MyBot.StartEngine();
		MyBot.StartAnimations();
		MyBot.StiffenPropeller();
		MyBot.UnfreezeMotors();
		MyBot.SetWeaponFrozen(false);
	}
	MyBot.AntiGravityForcePercentage = 1.0000000;
	MyBot.ThrustPercentage = 1.0000000;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Unfreeze()
{
	__NFUN_113__('Unfreezing');
	return;
}

function RunFrozenBehavior()
{
	local float EndTime, ThrustPercentage, StopDelay;

	StopDelay = MyBot.GetFrozenMovementStopDelay();
	// End:0xB3
	if(__NFUN_130__(MyBot.IsShocked(), __NFUN_177__(StopDelay, __NFUN_175__(MyBot.ShockedUntil, Level().TimeSeconds))))
	{
		StopDelay = __NFUN_175__(MyBot.ShockedUntil, Level().TimeSeconds);
		// End:0x145
		if(__NFUN_130__(MyBot.IsFrozen(), __NFUN_177__(StopDelay, __NFUN_175__(MyBot.FrozenUntil, Level().TimeSeconds))))
		{
		}
		StopDelay = __NFUN_175__(MyBot.FrozenUntil, Level().TimeSeconds);
		MyBot.StopEngine();
		MyBot.StopAnimations();
		MyBot.UnstiffenPropeller();
		EndTime = __NFUN_174__(Level().TimeSeconds, StopDelay);
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x266
	/*@Error*/
	ThrustPercentage = __NFUN_172__(__NFUN_175__(EndTime, Level().TimeSeconds), StopDelay);
	MyBot.AntiGravityForcePercentage = ThrustPercentage;
	MyBot.ThrustPercentage = ThrustPercentage;
	yield();
	// [Loop Continue]
	goto J0x1B6;
	MyBot.FreezeMotors();
	MyBot.AntiGravityForcePercentage = 1.0000000;
	MyBot.ThrustPercentage = 1.0000000;
	MyBot.SetWeaponFrozen(true, true);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function ReenableBot()
{
	local BotRiseOffGroundGoal RiseGoal;

	RiseGoal = Class'ShockAI.BotRiseOffGroundGoal'.static.Allocate(self).;
	construct_AI_Resource(characterResource());
	RiseGoal.postGoal(self);
	__NFUN_256__(1.5000000);
	MyBot.SetWeaponFrozen(false);
	waitForGoal_AI_Goal(RiseGoal);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting BotFrozenAction::Running."));
	RunFrozenBehavior();
	stop;			
	@NULL
}

state Unfreezing
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting BotFrozenAction::Unfreezing."));
	// End:0xE4
	if(__NFUN_132__(__NFUN_132__(MyBot.IsFriendly(), MyBot.IsMean()), MyBot.IsReturningHome()))
	{
		log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " running unfreeze reenable sequence."));
		ReenableBot();
		MyBot.GetBotCommanderAction().ClearFrozenGoal();
	}
	succeed();
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
	satisfiesGoal=Class'ShockAI.FrozenGoal'
}