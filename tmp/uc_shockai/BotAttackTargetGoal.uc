class BotAttackTargetGoal extends BotBaseSubGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn AttackTarget;
//var delegate<TargetCanBeDetected> __TargetCanBeDetected__Delegate;

overloaded function Construct(AI_Resource R)
{
	assert(false);
	return;
}

function Construct(AI_Resource R, ShockPawn inAttackTarget)
{
	construct_AI_Resource(R);
	AttackTarget = inAttackTarget;
	assert(__NFUN_119__(AttackTarget, none));
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

delegate bool TargetCanBeDetected()
{
	return;
}

defaultproperties
{
	Priority=70
}