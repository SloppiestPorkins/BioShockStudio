class BotProtectTargetAction extends BotBaseSubAction
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn ProtectTarget;
var private BotProtectTargetMovementGoal CurrentMoveGoal;
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
	assert(__NFUN_119__(ProtectTarget, none));
	CurrentMoveGoal = Class'ShockAI.BotProtectTargetMovementGoal'.static.Allocate(self).;
	construct_AI_ResourceShockPawn(characterResource(), ProtectTarget);
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

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(__NFUN_112__(string(m_Pawn), " at state 'Running' of BotProtectTargetAction.  ProtectTarget = "), string(ProtectTarget)));
	// End:0xEC
	if(__NFUN_114__(ProtectTarget, none))
	{
		log('AI_Security', 2, __NFUN_112__(string(m_Pawn), " no longer has a protect target.  Exiting from BotProtectTargetAction."));
		fail(1);
		MyBot.SwitchToMotion(2);
	}
	InitializeMovement();
	MyBot.SetSector(ProtectTarget.GetAvailableSector());
	// End:0x17C
	if(__NFUN_130__(__NFUN_119__(ProtectTarget, none), MyBot.CanDetectProtectTarget(ProtectTarget)))
	{
		__NFUN_256__(0.3000000);
		// [Loop Continue]
		goto J0x13D;
		fail(1);
		stop;						
		@NULL
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
	satisfiesGoal=Class'ShockAI.BotProtectTargetGoal'
}