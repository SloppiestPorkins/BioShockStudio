class TurretFrozenGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) Turret.TurretMovementDirection MovementDirection;

overloaded function Construct(AI_Resource R)
{
	assert(false);
	return;
}

function Construct(AI_Resource R, Turret.TurretMovementDirection inMovementDirection)
{
	construct_AI_Resource(R);
	MovementDirection = inMovementDirection;
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