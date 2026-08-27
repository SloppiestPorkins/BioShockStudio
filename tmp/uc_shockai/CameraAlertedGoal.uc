class CameraAlertedGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn AlarmTarget;

overloaded function Construct(AI_Resource R)
{
	assert(false);
	return;
}

function Construct(AI_Resource R, ShockPawn inAlarmTarget)
{
	construct_AI_Resource(R);
	AlarmTarget = inAlarmTarget;
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