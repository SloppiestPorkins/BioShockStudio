class TurretAttackGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn AttackTarget;
var(Parameters) bool ComingFromStandby;

overloaded function Construct(AI_Resource R)
{
	assert(false);
	return;
}

function Construct(AI_Resource R, ShockPawn inAttackTarget, bool inComingFromStandby)
{
	construct_AI_Resource(R);
	AttackTarget = inAttackTarget;
	ComingFromStandby = inComingFromStandby;
	assert(__NFUN_119__(AttackTarget, none));
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

defaultproperties
{
	bTryOnlyOnce=true
}