class ReturnToVentGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) bool bReturningWithProtector;
var(Parameters) bool bRunWithoutProtector;

function Construct(AI_Resource R, bool inReturningWithProtector, bool inRunWithoutProtector)
{
	construct_AI_Resource(R);
	bReturningWithProtector = inReturningWithProtector;
	bRunWithoutProtector = inRunWithoutProtector;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

defaultproperties
{
	Priority=70
}