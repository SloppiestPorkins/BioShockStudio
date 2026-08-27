class CrawlThroughDoorGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ThreeStateDoor Door;
var(Parameters) bool bShouldUnlock;

function Construct(AI_Resource R, ThreeStateDoor _Door, bool _bShouldUnlock)
{
	construct_AI_Resource(R);
	Door = _Door;
	bShouldUnlock = _bShouldUnlock;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

defaultproperties
{
	Priority=90
}