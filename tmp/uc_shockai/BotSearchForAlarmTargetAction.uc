class BotSearchForAlarmTargetAction extends BotBaseSubAction
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) SecurityManager SecuritySystem;
var private BotSearchForAlarmTargetMovementGoal CurrentMoveGoal;
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
	// End:0x29
	if(__NFUN_119__(CurrentMoveGoal, none))
	{
		CurrentMoveGoal.__NFUN_198__();
		CurrentMoveGoal = none;
		super(AI_CharacterAction).Cleanup();
		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

function InitializeMovement()
{
	StopAllMovement();
	assert(__NFUN_114__(CurrentMoveGoal, none));
	assert(__NFUN_119__(SecuritySystem, none));
	CurrentMoveGoal = Class'ShockAI.BotSearchForAlarmTargetMovementGoal'.static.Allocate(self).;
	construct_AI_ResourceSecurityManager(characterResource(), SecuritySystem);
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

function OnBumpedOtherBot(SecurityBot OtherBot)
{
	CurrentMoveGoal.OnBumpedOtherBot(OtherBot);
	return;
	@NULL
	CommanderAction
}

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(MyBot.Name), " running BotSearchForAlarmTargetAction."));
	// End:0xC8
	if(__NFUN_114__(SecuritySystem.GetAlarmTarget(), none))
	{
		log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " has no alarm target to search for.  Failing."));
		fail(1);
		InitializeMovement();
		waitForGoal_AI_Goal(CurrentMoveGoal);
	}
	// End:0x10C
	if(CurrentMoveGoal.wasAchieved())
	{
		succeed();
		goto J0x118;
		fail(1);
		stop;						
	}
	@NULL
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Object reference not set to an instance of an object.
		
	*/

	/*@Error*/
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.BotSearchForAlarmTargetGoal'
}