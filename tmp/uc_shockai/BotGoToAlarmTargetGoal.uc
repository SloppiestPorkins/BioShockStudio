class BotGoToAlarmTargetGoal extends BotBaseSubGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) SecurityManager SecuritySystem;
var(Parameters) float LookAtActorDistance;

overloaded function Construct(AI_Resource R)
{
	assert(false);
	return;
}

function Construct(AI_Resource R, SecurityManager inSecuritySystem, float inLookAtActorDistance)
{
	construct_AI_Resource(R);
	SecuritySystem = inSecuritySystem;
	assert(__NFUN_119__(SecuritySystem, none));
	LookAtActorDistance = inLookAtActorDistance;
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