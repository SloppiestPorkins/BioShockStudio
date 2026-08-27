class InsectSwarmAttackGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn AttackTarget;
var(Parameters) Rotator StartingRotation;

overloaded function Construct(AI_Resource R)
{
	assert(false);
	return;
}

function Construct(AI_Resource R, ShockPawn inAttackTarget, Rotator inStartingRotation)
{
	construct_AI_Resource(R);
	AttackTarget = inAttackTarget;
	StartingRotation = inStartingRotation;
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