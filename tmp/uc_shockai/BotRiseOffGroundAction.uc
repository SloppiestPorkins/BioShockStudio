class BotRiseOffGroundAction extends BioshockCharacterAction
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
	return;
	@NULL
}

function ModifyGravityOverTime(float BaseValue, float TargetValue, float ChangeTimeDelta)
{
	local float ChangePerSecond, StartTime, Delta;

	ChangePerSecond = __NFUN_172__(__NFUN_175__(TargetValue, BaseValue), ChangeTimeDelta);
	StartTime = m_Pawn.Level.TimeSeconds;
	MyBot.AntiGravityForcePercentage = BaseValue;
	Delta = 0.0000000;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x117
	/*@Error*/
	yield();
	Delta = __NFUN_175__(m_Pawn.Level.TimeSeconds, StartTime);
	MyBot.AntiGravityForcePercentage = __NFUN_174__(BaseValue, __NFUN_171__(ChangePerSecond, Delta));
	// [Loop Continue]
	goto J0x85;
	MyBot.AntiGravityForcePercentage = TargetValue;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function FastEnableBot()
{
	MyBot.StartEverything();
	MyBot.PlayStartupSequenceWhenRisingOffGround = true;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
}

function PlayBotStartupSequence()
{
	__NFUN_256__(MyBot.GetHackedStartUpDelay());
	MyBot.PlaySpeech('WakeFromDormant');
	MyBot.TriggerEffectEvent('Awoke');
	MyBot.StartEngine();
	MyBot.TurnLightsOn();
	MyBot.SetHackedEffectEvent();
	__NFUN_256__(MyBot.GetHackedRotorStartDelay());
	MyBot.StartAnimations();
	__NFUN_256__(MyBot.GetHackedMovementStartDelay());
	MyBot.SwitchToMotion(5);
	MyBot.EnableMovement();
	MyBot.UnfreezeMotors();
	MyBot.StiffenPropeller();
	MyBot.AntiGravityForcePercentage = 0.0000000;
	MyBot.ThrustPercentage = 0.0000000;
	ModifyGravityOverTime(0.0000000, 0.8800000, 1.0000000);
	__NFUN_256__(1.1000000);
	MyBot.TriggerEffectEvent('StartupBoost');
	MyBot.AntiGravityForcePercentage = 1.3000000;
	__NFUN_256__(0.7000000);
	MyBot.AntiGravityForcePercentage = 0.8000000;
	__NFUN_256__(0.5000000);
	MyBot.TriggerEffectEvent('StartupBoost');
	ModifyGravityOverTime(0.8000000, 1.5000000, 0.3000000);
	__NFUN_256__(0.5000000);
	MyBot.AntiGravityForcePercentage = 1.0000000;
	MyBot.ThrustPercentage = 1.0000000;
	MyBot.PlaySpeech('ReadyForAction');
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting BotRiseOffGroundAction::Running."));
	// End:0x70
	if(MyBot.PlayStartupSequenceWhenRisingOffGround)
	{
		PlayBotStartupSequence();
		goto J0x7A;
		FastEnableBot();
		succeed();
	}
	stop;	
	J0x7A:
		
	@NULL
	@NULL
	@NULL
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.BotRiseOffGroundGoal'
}