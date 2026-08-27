class GatherResourceGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) Actor Booty;
var(Parameters) bool bShouldRun;

function Construct(AI_Resource R, Actor inBooty, bool inbShouldRun)
{
	construct_AI_Resource(R);
	Booty = inBooty;
	bShouldRun = inbShouldRun;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}
