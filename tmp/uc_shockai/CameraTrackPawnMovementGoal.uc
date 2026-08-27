class CameraTrackPawnMovementGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn TrackingTarget;
var(Parameters) name MovingEffectEventName;
var(Parameters) int PitchSpeed;
var(Parameters) int YawSpeed;

overloaded function Construct(AI_Resource R)
{
	assert(false);
	return;
}

function Construct(AI_Resource R, name inMovingEffectEventName, ShockPawn inTrackingTarget, int inPitchSpeed, int inYawSpeed)
{
	construct_AI_Resource(R);
	MovingEffectEventName = inMovingEffectEventName;
	TrackingTarget = inTrackingTarget;
	PitchSpeed = inPitchSpeed;
	YawSpeed = inYawSpeed;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}
