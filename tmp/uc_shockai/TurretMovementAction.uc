class TurretMovementAction extends BioshockCharacterAction
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) int PitchSpeed;
var(Parameters) int YawSpeed;
var private Turret MyTurret;
var private TurretMovementGoal CurrentMovementGoal;

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

function OnRotationReached()
{
	assert(__NFUN_119__(CurrentMovementGoal, none));
	CurrentMovementGoal.OnRotationReached();
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

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	CurrentMovementGoal = TurretMovementGoal(Goal);
	CurrentMovementGoal.__NFUN_199__();
	MyTurret = Turret(m_Pawn);
	assert(__NFUN_119__(MyTurret, none));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	OnMovementEnded();
	CurrentMovementGoal.__NFUN_198__();
	CurrentMovementGoal = none;
	super(AI_CharacterAction).Cleanup();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function MoveTurretTowardsRotation(Rotator DesiredRotation, float DeltaTime)
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

function RunTurretMovement()
{
	local Rotator DesiredRotation;
	local float PreviousTime, CurrentTime, DeltaTime;

	J0x00:
	// End:0x1A4 [Loop If]
	if(true)
	{
		PreviousTime = Level().TimeSeconds;
		yield();
		DesiredRotation = GetDesiredRotation();
		OnMovementStarted();
		// End:0x11F
		if(__NFUN_129__(RotatorIsClose(Normalize(DesiredRotation), Normalize(MyTurret.GetCurrentRotation()))))
		{
			CurrentTime = Level().TimeSeconds;
			DeltaTime = __NFUN_175__(CurrentTime, PreviousTime);
			PreviousTime = CurrentTime;
			MoveTurretTowardsRotation(DesiredRotation, DeltaTime);
			yield();
			DesiredRotation = GetDesiredRotation();
			// [Loop Continue]
			goto J0x4D;
			OnMovementEnded();
			log('AI_Security', 6, __NFUN_112__(string(m_Pawn), " reached destination.  OnRotationReached being called."));
		}
		OnRotationReached();
		MyTurret.SetCurrentMovementDirection(2);
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
	RunTurretMovement();
	assert(false);
	stop;				
	@NULL
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.TurretMovementGoal'
}