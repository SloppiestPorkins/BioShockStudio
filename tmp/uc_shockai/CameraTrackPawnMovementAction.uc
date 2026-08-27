class CameraTrackPawnMovementAction extends BioshockCharacterAction implements ICameraMovementController
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn TrackingTarget;
var(Parameters) name MovingEffectEventName;
var(Parameters) int PitchSpeed;
var(Parameters) int YawSpeed;
var private SecurityCamera MyCamera;
var private Vector LastPawnLocation;

function float selectionHeuristic(AI_Goal Goal)
{
	// End:0x2A
	if(__NFUN_114__(Goal.Class, default.satisfiesGoal))
	{
		return 1.0000000;
		return 0.0000000;
		return;
		@NULL
	}
	CommanderAction
	Class'ShockAI.CommanderAction'
}

function UpdateTargetLocation()
{
	// End:0x2F
	if(__NFUN_119__(TrackingTarget, none))
	{
		LastPawnLocation = TrackingTarget.Location;
		return;
		@NULL
		CommanderAction
		BioshockMovementAction
	}
	@NULL
}

function Rotator CalculateRotationToTarget()
{
	local Rotator TargetRotation;

	TargetRotation = __NFUN_317__(Rotator(__NFUN_216__(LastPawnLocation, MyCamera.Location)), MyCamera.Rotation);
	TargetRotation.Pitch = __NFUN_251__(MyCamera.ReduceSmallestAngle(TargetRotation.Pitch), MyCamera.GetLowerPitchLimit(), MyCamera.GetUpperPitchLimit());
	TargetRotation.Yaw = __NFUN_251__(MyCamera.ReduceSmallestAngle(TargetRotation.Yaw), MyCamera.GetLeftYawLimit(), MyCamera.GetRightYawLimit());
	return TargetRotation;
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function float OnRotationReached()
{
	return 0.0000000;
	return;
}

function Rotator UpdateDesiredRotation()
{
	m_Pawn.SetIgnoreLODCount(1);
	UpdateTargetLocation();
	return CalculateRotationToTarget();
	return;
	@NULL
}

function float GetPitchSpeed()
{
	return float(PitchSpeed);
	return;
	@NULL
}

function float GetYawSpeed()
{
	return float(YawSpeed);
	return;
	@NULL
}

function name GetMovingEffectEventName()
{
	return MovingEffectEventName;
	return;
	@NULL
}

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	MyCamera = SecurityCamera(m_Pawn);
	MyCamera.GetCameraCommanderAction().RegisterMovementController(self);
	LastPawnLocation = TrackingTarget.Location;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	MyCamera.GetCameraCommanderAction().UnregisterMovementController(self);
	super(AI_CharacterAction).Cleanup();
	return;
	@NULL
	CommanderAction
}

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting track pawn movement action."));
	stop;			
	@NULL
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.CameraTrackPawnMovementGoal'
}