class BotAttackTargetMovementGoal extends BotBaseMovementBehaviorGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn AttackTarget;
var(Parameters) Range HoverPointWaitTime;

overloaded function Construct(AI_Resource R)
{
	assert(false);
	return;
}

function Construct(AI_Resource R, ShockPawn inAttackTarget, Range inHoverPointWaitTime)
{
	construct_AI_Resource(R);
	AttackTarget = inAttackTarget;
	assert(__NFUN_119__(AttackTarget, none));
	HoverPointWaitTime = inHoverPointWaitTime;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}
