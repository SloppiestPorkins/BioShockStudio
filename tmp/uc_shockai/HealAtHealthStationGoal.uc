class HealAtHealthStationGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn AvoidTarget;
var(Parameters) HealthStation TargetHealthStation;

function Construct(AI_Resource R, ShockPawn inAvoidTarget)
{
	construct_AI_Resource(R);
	AvoidTarget = inAvoidTarget;
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