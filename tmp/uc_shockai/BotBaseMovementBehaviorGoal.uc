class BotBaseMovementBehaviorGoal extends BioshockCharacterGoal
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

function OnBumpedOtherBot(SecurityBot OtherBot)
{
	local BotBaseMovementBehaviorAction ActionInterface;

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

function BotBaseMovementBehaviorAction GetActionInterface()
{
	assert(__NFUN_132__(__NFUN_114__(achievingAction, none), __NFUN_119__(BotBaseMovementBehaviorAction(achievingAction), none)));
	return BotBaseMovementBehaviorAction(achievingAction);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

defaultproperties
{
	bTryOnlyOnce=true
}