class BotNavigateToActorLocationMovementGoal extends BotBaseMovementBehaviorGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) Actor targetActor;
var(Parameters) float LookAtActorDistance;

overloaded function Construct(AI_Resource R)
{
	assert(false);
	return;
}

function Construct(AI_Resource R, Actor inTargetActor, float inLookAtActorDistance)
{
	construct_AI_Resource(R);
	targetActor = inTargetActor;
	assert(__NFUN_119__(targetActor, none));
	LookAtActorDistance = inLookAtActorDistance;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}
