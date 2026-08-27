class ReactToGathererDeathGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) Gatherer DeadGatherer;
var(Parameters) ShockPawn Pacifier;

function Construct(AI_Resource R, Gatherer inDeadGatherer, ShockPawn inPacifier)
{
	construct_AI_Resource(R);
	assert(__NFUN_119__(inDeadGatherer, none));
	assert(__NFUN_129__(inDeadGatherer.IsAlive()));
	DeadGatherer = inDeadGatherer;
	Pacifier = inPacifier;
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