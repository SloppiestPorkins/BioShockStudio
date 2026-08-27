class ScoopUpGathererGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn AttackTarget;

function Construct(AI_Resource R, ShockPawn inAttackTarget)
{
	construct_AI_Resource(R);
	assert(__NFUN_119__(inAttackTarget, none));
	AttackTarget = inAttackTarget;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

defaultproperties
{
	Priority=77
}