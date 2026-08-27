class WaitForGathererGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) private Gatherer targetGatherer;

function Construct(AI_Resource R, Gatherer inTargetGatherer)
{
	construct_AI_Resource(R);
	assert(Class'Engine.Pawn'.static.checkAlive(inTargetGatherer));
	targetGatherer = inTargetGatherer;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

defaultproperties
{
	Priority=65
}