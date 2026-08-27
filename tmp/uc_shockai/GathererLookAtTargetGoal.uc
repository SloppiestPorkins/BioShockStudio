class GathererLookAtTargetGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) Actor Target;

function Construct(AI_Resource R, Actor inTarget)
{
	construct_AI_Resource(R);
	assert(__NFUN_119__(inTarget, none));
	Target = inTarget;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

function NotifyProtectorTellingUsToStopLooking()
{
	// End:0x2F
	if(__NFUN_119__(achievingAction, none))
	{
		GathererLookAtTargetAction(achievingAction).NotifyProtectorTellingUsToStopLooking();
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

defaultproperties
{
	Priority=71
}