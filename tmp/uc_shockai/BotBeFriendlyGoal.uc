class BotBeFriendlyGoal extends BotBehaviorGoalInterface
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn ProtectTarget;

overloaded function Construct(AI_Resource R)
{
	assert(false);
	return;
}

function Construct(AI_Resource R, ShockPawn inProtectTarget)
{
	construct_AI_Resource(R);
	ProtectTarget = inProtectTarget;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

defaultproperties
{
	bTryOnlyOnce=true
	Priority=90
}