class BotBeDormantGoal extends BotBehaviorGoalInterface
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) bool NeverDie;

overloaded function Construct(AI_Resource R)
{
	assert(false);
	return;
}

function Construct(AI_Resource R, bool inNeverDie)
{
	construct_AI_Resource(R);
	NeverDie = inNeverDie;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

defaultproperties
{
	bTryOnlyOnce=true
	Priority=70
}