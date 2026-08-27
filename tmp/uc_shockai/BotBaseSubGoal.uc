class BotBaseSubGoal extends BioshockCharacterGoal
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

function OnBumpedOtherBot(SecurityBot OtherBot)
{
	local BotBaseSubAction ActionInterface;

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

function BotBaseSubAction GetActionInterface()
{
	assert(__NFUN_132__(__NFUN_114__(achievingAction, none), __NFUN_119__(BotBaseSubAction(achievingAction), none)));
	return BotBaseSubAction(achievingAction);
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