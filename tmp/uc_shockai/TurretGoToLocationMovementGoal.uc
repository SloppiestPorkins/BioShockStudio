class TurretGoToLocationMovementGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) name MovingEffectEventName;
var(Parameters) int PitchSpeed;
var(Parameters) int YawSpeed;
var(Parameters) Rotator TargetRotation;
//var delegate<OnRotationReached> __OnRotationReached__Delegate;

delegate OnRotationReached()
{
	return;
}

overloaded function Construct(AI_Resource R)
{
	assert(false);
	return;
}

function Construct(AI_Resource R, name inMovingEffectEventName, int inPitchSpeed, int inYawSpeed, Rotator inTargetRotation)
{
	construct_AI_Resource(R);
	MovingEffectEventName = inMovingEffectEventName;
	PitchSpeed = inPitchSpeed;
	YawSpeed = inYawSpeed;
	TargetRotation = inTargetRotation;
	assert(__NFUN_154__(TargetRotation.Roll, 0));
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}
