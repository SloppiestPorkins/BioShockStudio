class JumpToFloorGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) private Vector StartLocation;

function Construct(AI_Resource R, int inPriority, Vector inStartLocation)
{
	construct_AI_Resource(R);
	Priority = inPriority;
	StartLocation = inStartLocation;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

defaultproperties
{
	bTryOnlyOnce=true
}