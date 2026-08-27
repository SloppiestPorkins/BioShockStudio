class TiredGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

function NotifyProtectorSaysComeOn()
{
	// End:0x2F
	if(__NFUN_119__(achievingAction, none))
	{
		TiredAction(achievingAction).NotifyProtectorSaysComeOn();
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function NotifyProtectorStartingTiredAnimation(bool bUseUnevenSurfaceAnimation)
{
	// End:0x39
	if(__NFUN_119__(achievingAction, none))
	{
		TiredAction(achievingAction).NotifyProtectorStartingTiredAnimation(bUseUnevenSurfaceAnimation);
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

defaultproperties
{
	Priority=72
}