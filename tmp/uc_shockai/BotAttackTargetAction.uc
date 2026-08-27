class BotAttackTargetAction extends BotBaseSubAction
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn AttackTarget;
var private BotAttackTargetMovementGoal CurrentMoveGoal;
var private SecurityBot MyBot;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	MyBot = SecurityBot(m_Pawn);
	assert(__NFUN_119__(MyBot, none));
	ResetRangedWeaponAccuracy();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ResetRangedWeaponAccuracy()
{
	local AIRangedWeapon AIRangedWeapon;

	AIRangedWeapon = AIRangedWeapon(MyBot.theWeapon);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x58
	/*@Error*/
	AIRangedWeapon.ResetChangingAccuracy(AttackTarget);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
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

function bool TargetCanBeDetected()
{
	assert(__NFUN_119__(BotAttackTargetGoal(achievingGoal), none));
	return BotAttackTargetGoal(achievingGoal).TargetCanBeDetected();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function InitializeMovement()
{
	local Range HoverPointWaitRange;

	StopAllMovement();
	assert(__NFUN_114__(CurrentMoveGoal, none));
	assert(__NFUN_119__(AttackTarget, none));
	// End:0x65
	if(AttackTarget.IsPlayer())
	{
		HoverPointWaitRange = MyBot.AttackingHoverPointWaitTimeRangePlayer;
		goto J0x85;
		HoverPointWaitRange = MyBot.AttackingHoverPointWaitTimeRangeAI;
		CurrentMoveGoal = Class'ShockAI.BotAttackTargetMovementGoal'.static.Allocate(self).;
	}
	construct_AI_ResourceShockPawnRange(characterResource(), AttackTarget, HoverPointWaitRange);
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

function bool AttackTargetIsAlive()
{
	return __NFUN_130__(__NFUN_119__(AttackTarget, none), AttackTarget.IsAlive());
	return;
	@NULL
	CommanderAction
}

function OnBumpedOtherBot(SecurityBot OtherBot)
{
	CurrentMoveGoal.OnBumpedOtherBot(OtherBot);
	return;
	@NULL
	CommanderAction
}

function AttackUntilTargetIsLost()
{
	local float NextBurstTime;

	NextBurstTime = MyBot.Level.TimeSeconds;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x254
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x247
	/*@Error*/
	log('AI_Security', 5, __NFUN_112__(string(MyBot.Name), " is charging it's weapon."));
	MyBot.StartCharging();
	__NFUN_256__(MyBot.GetWeapon().GetChargeTime());
	log('AI_Security', 5, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(MyBot.Name), " is firing it's weapon at "), string(AttackTarget)), "."));
	MyBot.FireWeapon();
	NextBurstTime = __NFUN_174__(MyBot.Level.TimeSeconds, MyBot.GetRandomBurstInterval());
	yield();
	// [Loop Continue]
	goto J0x2D;
	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " has lost it's attack target."));
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(MyBot.Name), " running BotAttackTargetAction."));
	InitializeMovement();
	MyBot.SwitchToMotion(1);
	AttackUntilTargetIsLost();
	// End:0xBB
	if(__NFUN_130__(AttackTargetIsAlive(), __NFUN_129__(MyBot.PawnIsFriendly(AttackTarget))))
	{
		fail(1);
		goto J0xC5;
		succeed();
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

defaultproperties
{
	satisfiesGoal=Class'ShockAI.BotAttackTargetGoal'
}