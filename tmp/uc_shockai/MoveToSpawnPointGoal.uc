class MoveToSpawnPointGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) Actor SpawnPoint;

overloaded function Construct(AI_Resource R)
{
	assert(false);
	return;
}

function Construct(AI_Resource R, Actor inSpawnPoint)
{
	construct_AI_Resource(R);
	assert(__NFUN_119__(inSpawnPoint, none));
	SpawnPoint = inSpawnPoint;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

defaultproperties
{
	Priority=35
	goalName="MoveToSpawnPoint"
}