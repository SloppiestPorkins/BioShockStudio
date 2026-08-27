class FleeGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) Vector FleeOrigin;

function Construct(AI_Resource R, Vector inFleeOrigin)
{
	construct_AI_Resource(R);
	FleeOrigin = inFleeOrigin;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

defaultproperties
{
	bTryOnlyOnce=true
	Priority=77
}