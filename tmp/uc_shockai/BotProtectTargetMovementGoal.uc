class BotProtectTargetMovementGoal extends BotBaseMovementBehaviorGoal
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
	assert(__NFUN_119__(ProtectTarget, none));
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}
