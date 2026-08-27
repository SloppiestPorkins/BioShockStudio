class BotSearchForAlarmTargetMovementGoal extends BotBaseMovementBehaviorGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) SecurityManager SecuritySystem;

overloaded function Construct(AI_Resource R)
{
	assert(false);
	return;
}

function Construct(AI_Resource R, SecurityManager inSecuritySystem)
{
	construct_AI_Resource(R);
	SecuritySystem = inSecuritySystem;
	assert(__NFUN_119__(SecuritySystem, none));
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}
