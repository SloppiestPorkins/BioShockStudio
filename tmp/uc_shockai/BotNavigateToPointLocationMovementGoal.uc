class BotNavigateToPointLocationMovementGoal extends BotBaseMovementBehaviorGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) Vector TargetLocation;

overloaded function Construct(AI_Resource R)
{
	assert(false);
	return;
}

function Construct(AI_Resource R, Vector inTargetLocation)
{
	construct_AI_Resource(R);
	TargetLocation = inTargetLocation;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}
