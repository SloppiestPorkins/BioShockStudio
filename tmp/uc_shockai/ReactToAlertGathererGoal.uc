class ReactToAlertGathererGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) Gatherer AlertGatherer;
var(Parameters) Protector ThreateningProtector;

overloaded function Construct(AI_Resource R)
{
	assert(false);
	return;
}

function Construct(AI_Resource R, Gatherer inAlertGatherer, Protector inThreateningProtector)
{
	construct_AI_Resource(R);
	assert(Class'Engine.Pawn'.static.checkAlive(inAlertGatherer));
	AlertGatherer = inAlertGatherer;
	assert(Class'Engine.Pawn'.static.checkAlive(inThreateningProtector));
	ThreateningProtector = inThreateningProtector;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

function NotifyProtectorThreatening(Protector ThreateningProtector)
{
	// End:0x38
	if(__NFUN_119__(achievingAction, none))
	{
		ReactToAlertGathererAction(achievingAction).NotifyProtectorThreatening(ThreateningProtector);
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function NotifyKnockedBackByThreateningProtector(Protector ThreateningProtector)
{
	// End:0x38
	if(__NFUN_119__(achievingAction, none))
	{
		ReactToAlertGathererAction(achievingAction).NotifyKnockedBackByThreateningProtector(ThreateningProtector);
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function NotifyCausedGathererAlert(Gatherer AlertGatherer, Protector ThreateningProtector)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x41
	/*@Error*/
	ReactToAlertGathererAction(achievingAction).NotifyCausedGathererAlert(AlertGatherer, ThreateningProtector);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyGathererAlertOver(Gatherer FormerAlertGatherer, Protector FormerThreateningProtector)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x41
	/*@Error*/
	ReactToAlertGathererAction(achievingAction).NotifyGathererAlertOver(FormerAlertGatherer, FormerThreateningProtector);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	bTryOnlyOnce=true
	Priority=65
}