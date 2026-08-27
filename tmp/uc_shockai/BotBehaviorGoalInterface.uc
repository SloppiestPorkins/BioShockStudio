class BotBehaviorGoalInterface extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

function OnSecurityBeaconApplied(Actor Damager, ShockPawn SecurityBeaconedTarget)
{
	local BotBehaviorActionInterface ActionInterface;

	ActionInterface = GetActionInterface();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x4C
	/*@Error*/
	ActionInterface.OnSecurityBeaconApplied(Damager, SecurityBeaconedTarget);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnAttackSpecifiedTarget(ShockPawn Target, bool ForceNewTarget)
{
	local BotBehaviorActionInterface ActionInterface;

	ActionInterface = GetActionInterface();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x4D
	/*@Error*/
	ActionInterface.OnAttackSpecifiedTarget(Target, ForceNewTarget);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnControllerDamaged(ShockPawn Damager, float TotalDamageDealt)
{
	local BotBehaviorActionInterface ActionInterface;

	ActionInterface = GetActionInterface();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x4C
	/*@Error*/
	ActionInterface.OnControllerDamaged(Damager, TotalDamageDealt);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnControllerDealtDamage(ShockPawn Damagee, float TotalDamageDealt)
{
	local BotBehaviorActionInterface ActionInterface;

	ActionInterface = GetActionInterface();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x4C
	/*@Error*/
	ActionInterface.OnControllerDealtDamage(Damagee, TotalDamageDealt);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnIntentionallyDamaged(ShockPawn Damager, float TotalDamageDealt)
{
	local BotBehaviorActionInterface ActionInterface;

	ActionInterface = GetActionInterface();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x4C
	/*@Error*/
	ActionInterface.OnIntentionallyDamaged(Damager, TotalDamageDealt);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnBumpedOtherBot(SecurityBot OtherBot)
{
	local BotBehaviorActionInterface ActionInterface;

	ActionInterface = GetActionInterface();
	// End:0x43
	if(__NFUN_119__(ActionInterface, none))
	{
		ActionInterface.OnBumpedOtherBot(OtherBot);
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function OnKilledOtherPawn(ShockPawn Killee)
{
	local BotBehaviorActionInterface ActionInterface;

	ActionInterface = GetActionInterface();
	// End:0x43
	if(__NFUN_119__(ActionInterface, none))
	{
		ActionInterface.OnKilledOtherPawn(Killee);
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function BotBehaviorActionInterface GetActionInterface()
{
	assert(__NFUN_132__(__NFUN_114__(achievingAction, none), __NFUN_119__(BotBehaviorActionInterface(achievingAction), none)));
	return BotBehaviorActionInterface(achievingAction);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}
