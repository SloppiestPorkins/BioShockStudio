class PatrolGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) PatrolList Patrol;
var int CurrentPatrolIndex;

overloaded function Construct(AI_Resource R)
{
	assert(false);
	return;
}

function Construct(AI_Resource R, PatrolList inPatrol)
{
	construct_AI_Resource(R);
	assert(__NFUN_119__(inPatrol, none));
	Patrol = inPatrol;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

defaultproperties
{
	Priority=35
}