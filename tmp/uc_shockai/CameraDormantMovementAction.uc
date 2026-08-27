class CameraDormantMovementAction extends BioshockCharacterAction implements ICameraMovementController
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) name MovingEffectEventName;
var(Parameters) int PitchSpeed;
var(Parameters) int YawSpeed;
var(Parameters) Rotator TargetRotation;

function float OnRotationReached()
{
	return 0.0000000;
	return;
}

function Rotator UpdateDesiredRotation()
{
	return TargetRotation;
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
	SecurityCamera(m_Pawn).GetCameraCommanderAction().RegisterMovementController(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	SecurityCamera(m_Pawn).GetCameraCommanderAction().UnregisterMovementController(self);
	super(AI_CharacterAction).Cleanup();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting dormant movement action."));
	stop;		
	@NULL
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.CameraDormantMovementGoal'
}