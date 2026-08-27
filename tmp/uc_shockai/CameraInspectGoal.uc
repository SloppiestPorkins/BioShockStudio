class CameraInspectGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn InspectTarget;
var(Parameters) float InspectionDuration;
var(Parameters) float LostDuration;

overloaded function Construct(AI_Resource R)
{
	assert(false);
	return;
}

function Construct(AI_Resource R, ShockPawn Target, float inInspectionDuration, float inLostDuration)
{
	construct_AI_Resource(R);
	assert(__NFUN_119__(Target, none));
	InspectTarget = Target;
	InspectionDuration = inInspectionDuration;
	LostDuration = inLostDuration;
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