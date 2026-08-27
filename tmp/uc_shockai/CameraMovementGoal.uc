class CameraMovementGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) int PitchSpeed;
var(Parameters) int YawSpeed;
//var delegate<GetDesiredRotation> __GetDesiredRotation__Delegate;
//var delegate<OnRotationReached> __OnRotationReached__Delegate;
//var delegate<OnMovementStarted> __OnMovementStarted__Delegate;
//var delegate<OnMovementEnded> __OnMovementEnded__Delegate;

delegate Rotator GetDesiredRotation()
{
	return;
}

delegate float OnRotationReached()
{
	return;
}

delegate OnMovementStarted()
{
	return;
}

delegate OnMovementEnded()
{
	return;
}

overloaded function Construct(AI_Resource R)
{
	assert(false);
	return;
}

function Construct(AI_Resource R, int inPitchSpeed, int inYawSpeed)
{
	construct_AI_Resource(R);
	PitchSpeed = inPitchSpeed;
	YawSpeed = inYawSpeed;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}
