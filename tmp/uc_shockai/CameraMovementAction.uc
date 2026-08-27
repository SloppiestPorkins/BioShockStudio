class CameraMovementAction extends BioshockCharacterAction
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) int PitchSpeed;
var(Parameters) int YawSpeed;
var private SecurityCamera MyCamera;
var private CameraMovementGoal CurrentMovementGoal;
var private float SpeedScale;

function Rotator GetDesiredRotation()
{
	assert(__NFUN_119__(CurrentMovementGoal, none));
	m_Pawn.SetIgnoreLODCount(1);
	return CurrentMovementGoal.GetDesiredRotation();
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function float OnRotationReached()
{
	assert(__NFUN_119__(CurrentMovementGoal, none));
	return CurrentMovementGoal.OnRotationReached();
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
}

function OnMovementStarted()
{
	assert(__NFUN_119__(CurrentMovementGoal, none));
	CurrentMovementGoal.OnMovementStarted();
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
}

function OnMovementEnded()
{
	assert(__NFUN_119__(CurrentMovementGoal, none));
	CurrentMovementGoal.OnMovementEnded();
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
}

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	CurrentMovementGoal = CameraMovementGoal(Goal);
	CurrentMovementGoal.__NFUN_199__();
	MyCamera = SecurityCamera(m_Pawn);
	assert(__NFUN_119__(MyCamera, none));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	OnMovementEnded();
	// End:0x33
	if(__NFUN_119__(CurrentMovementGoal, none))
	{
		CurrentMovementGoal.__NFUN_198__();
		CurrentMovementGoal = none;
		super(AI_CharacterAction).Cleanup();
		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

function SetPitchSpeed(int NewPitchSpeed)
{
	PitchSpeed = NewPitchSpeed;
	return;
	@NULL
	CommanderAction
}

function SetYawSpeed(int NewYawSpeed)
{
	YawSpeed = NewYawSpeed;
	return;
	@NULL
	CommanderAction
}

function SetSpeedScale(float NewSpeedScale)
{
	SpeedScale = NewSpeedScale;
	return;
	@NULL
	CommanderAction
}

function MoveCameraTowardsRotation(Rotator DesiredRotation, float DeltaTime)
{
	//native.DesiredRotation;
	//native.DeltaTime;	
	@NULL
	@NULL
}

function bool RotatorIsClose(Rotator AngleA, Rotator AngleB)
{
	return __NFUN_130__(__NFUN_130__(__NFUN_176__(__NFUN_186__(float(__NFUN_147__(AngleA.Pitch, AngleB.Pitch))), float(5)), __NFUN_176__(__NFUN_186__(float(__NFUN_147__(AngleA.Yaw, AngleB.Yaw))), float(5))), __NFUN_176__(__NFUN_186__(float(__NFUN_147__(AngleA.Roll, AngleB.Roll))), float(5)));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function RunCameraMovement()
{
	local Rotator DesiredRotation;
	local float PreviousTime, CurrentTime, DeltaTime, PauseTime;

	J0x00:
	// End:0x19B [Loop If]
	if(true)
	{
		J0x04:

		// End:0x53 [Loop If]
		if(RotatorIsClose(Normalize(GetDesiredRotation()), Normalize(MyCamera.GetCurrentRotation())))
		{
			yield();
			// [Loop Continue]
			goto J0x04;
			PreviousTime = Level().TimeSeconds;
		}
		yield();
		DesiredRotation = GetDesiredRotation();
		OnMovementStarted();
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x16E
		/*@Error*/
		CurrentTime = Level().TimeSeconds;
		DeltaTime = __NFUN_175__(CurrentTime, PreviousTime);
		PreviousTime = CurrentTime;
		MoveCameraTowardsRotation(DesiredRotation, DeltaTime);
		yield();
		DesiredRotation = GetDesiredRotation();
		// [Loop Continue]
		goto J0x9C;
		OnMovementEnded();
		PauseTime = OnRotationReached();
		__NFUN_256__(PauseTime);
		// [Loop Continue]
		goto J0x00;
		return;
		@NULL
		EcologyAI
		EcologyFighterCommanderAction
		@NULL
	}
}

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting movement action."));
	RunCameraMovement();
	assert(false);
	stop;				
	@NULL
}

defaultproperties
{
	SpeedScale=1.0000000
	satisfiesGoal=Class'ShockAI.CameraMovementGoal'
}