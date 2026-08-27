class CameraPanMovementAction extends BioshockCharacterAction implements ICameraMovementController
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) name MovingEffectEventName;
var(Parameters) int PitchSpeed;
var(Parameters) int YawSpeed;
var private SecurityCamera MyCamera;
var private Rotator DesiredRotation;

function float OnRotationReached()
{
	m_Pawn.SetIgnoreLODCount(1);
	// End:0x55
	if(MyCamera.IsCurrentlyPanningLeft())
	{
		MyCamera.TriggerEffectEvent('ReachedLeftPanRotation');
		goto J0x75;
		MyCamera.TriggerEffectEvent('ReachedRightPanRotation');
	}
	DesiredRotation = MyCamera.GetNextPanRotation();
	log('AI_Security', 6, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn), " Current rotation = "), string(MyCamera.GetCurrentRotation())), "."));
	log('AI_Security', 6, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn), " Rightmost rotation = "), string(MyCamera.GetRightmostSearchRotation())), "."));
	log('AI_Security', 6, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn), " Leftmost rotation = "), string(MyCamera.GetLeftmostSearchRotation())), "."));
	log('AI_Security', 6, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn), " searching setting DesiredRotation to "), string(DesiredRotation)), "."));
	return MyCamera.GetSearchLimitPauseTime();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Rotator UpdateDesiredRotation()
{
	return DesiredRotation;
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

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting pan movement action."));
	DesiredRotation = MyCamera.GetNextPanRotation();
	log('AI_Security', 4, __NFUN_112__("Starting going to ", string(DesiredRotation)));
	stop;				
	@NULL
	@NULL
	@NULL
	@NULL
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.CameraPanMovementGoal'
}