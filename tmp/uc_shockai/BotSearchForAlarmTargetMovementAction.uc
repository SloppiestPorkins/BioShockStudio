class BotSearchForAlarmTargetMovementAction extends BotBaseMovementBehaviorAction
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) SecurityManager SecuritySystem;
var private SearchGoal CurrentSearchGoal;
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
	// End:0x33
	if(__NFUN_119__(CurrentSearchGoal, none))
	{
		CurrentSearchGoal.__NFUN_198__();
		CurrentSearchGoal = none;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function InitializeSearch(ShockPawn SearchTarget)
{
	assert(__NFUN_114__(CurrentSearchGoal, none));
	assert(__NFUN_119__(SearchTarget, none));
	CurrentSearchGoal = Class'ShockAI.SearchGoal'.static.Allocate(self).;
	construct_AI_ResourceShockPawnVectorVectorVector(characterResource(), SearchTarget, SecuritySystem.GetLastAlarmTargetLocation(), SecuritySystem.GetLastAlarmTargetVelocity(), m_Pawn.Location);
	CurrentSearchGoal.__NFUN_199__();
	CurrentSearchGoal.SetNeverStopSearching(true);
	CurrentSearchGoal.SetAlignmentAllowedDeltaYaw(MyBot.AlignmentAllowedDeltaYaw);
	CurrentSearchGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnBumpedOtherBot(SecurityBot OtherBot)
{
	return;
}

function bool TargetIsInDetectRange()
{
	local float DistanceToTarget;

	// End:0x1E
	if(__NFUN_129__(SecuritySystem.AlarmTargetIsVisible()))
	{
		return false;
		DistanceToTarget = __NFUN_225__(__NFUN_216__(MyBot.Location, SecuritySystem.GetAlarmTarget().Location));
	}
	// End:0x8D
	if(__NFUN_177__(DistanceToTarget, MyBot.GetDetectRadius()))
	{
		return false;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xDE
		/*@Error*/
	}
	return false;
	return true;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " at state 'Running' of BotSearchForAlarmTargetMovementAction."));
	// End:0xC3
	if(__NFUN_114__(SecuritySystem.GetAlarmTarget(), none))
	{
		log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " has no alarm target.  Failing."));
		fail(1);
		InitializeSearch(SecuritySystem.GetAlarmTarget());
	}
	// End:0x18A
	if(__NFUN_129__(TargetIsInDetectRange()))
	{
		// End:0x17D
		if(SecuritySystem.AlarmTargetIsVisible())
		{
			log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " has found the target has been seen by the security system.  Failing."));
			fail(1);
			yield();
			// [Loop Continue]
			goto J0xE4;
			log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " has found the target.  Succeeding."));
		}
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
	satisfiesGoal=Class'ShockAI.BotSearchForAlarmTargetMovementGoal'
}