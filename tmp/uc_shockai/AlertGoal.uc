class AlertGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn AlertedPawn;

function Construct(AI_Resource R, ShockPawn inAlertedPawn)
{
	construct_AI_Resource(R);
	assert(Class'Engine.Pawn'.static.checkAlive(inAlertedPawn));
	AlertedPawn = inAlertedPawn;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

defaultproperties
{
	Priority=73
}