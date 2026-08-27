class TurretTrackTargetMovementGoal extends BioshockCharacterGoal
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) name MovingEffectEventName;
var(Parameters) int PitchSpeed;
var(Parameters) int YawSpeed;
var(Parameters) ShockPawn Target;
var(Parameters) float ProjectileVelocity;
var(Parameters) int LockOnDeadZone;
//var delegate<TargetIsVisible> __TargetIsVisible__Delegate;
//var delegate<GainedTargetLock> __GainedTargetLock__Delegate;
//var delegate<LostTargetLock> __LostTargetLock__Delegate;

delegate bool TargetIsVisible()
{
	return;
}

delegate GainedTargetLock()
{
	return;
}

delegate LostTargetLock()
{
	return;
}

overloaded function Construct(AI_Resource R)
{
	assert(false);
	return;
}

function Construct(AI_Resource R, name inMovingEffectEventName, int inPitchSpeed, int inYawSpeed, ShockPawn inTarget, float inProjectileVelocity, float inLockOnDeadZone)
{
	construct_AI_Resource(R);
	MovingEffectEventName = inMovingEffectEventName;
	PitchSpeed = inPitchSpeed;
	YawSpeed = inYawSpeed;
	Target = inTarget;
	ProjectileVelocity = inProjectileVelocity;
	LockOnDeadZone = int(inLockOnDeadZone);
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}
