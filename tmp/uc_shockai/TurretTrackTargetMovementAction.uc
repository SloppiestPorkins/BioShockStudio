class TurretTrackTargetMovementAction extends BioshockCharacterAction
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) name MovingEffectEventName;
var(Parameters) int PitchSpeed;
var(Parameters) int YawSpeed;
var(Parameters) ShockPawn Target;
var(Parameters) float ProjectileVelocity;
var(Parameters) int LockOnDeadZone;
var private Turret MyTurret;
var private TurretMovementGoal CurrentMovementGoal;
var private Rotator TargetRotation;
var private float SineOfSupplementaryYawBetweenFireStartAndTurretFace;
var private float SineOfSupplementaryPitchBetweenFireStartAndTurretFace;
var private float WeaponYawDistanceFromTurret;
var private float WeaponPitchDistanceFromTurret;

function bool TargetIsVisible()
{
	assert(__NFUN_119__(TurretTrackTargetMovementGoal(achievingGoal), none));
	return TurretTrackTargetMovementGoal(achievingGoal).TargetIsVisible();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function GainedTargetLock()
{
	assert(__NFUN_119__(TurretTrackTargetMovementGoal(achievingGoal), none));
	TurretTrackTargetMovementGoal(achievingGoal).GainedTargetLock();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function LostTargetLock()
{
	assert(__NFUN_119__(TurretTrackTargetMovementGoal(achievingGoal), none));
	TurretTrackTargetMovementGoal(achievingGoal).LostTargetLock();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

// Export UTurretTrackTargetMovementAction::execUpdateTargetRotation(FFrame&, void* const)
native function UpdateTargetRotation();

// Export UTurretTrackTargetMovementAction::execCalculateSupplementaryAngles(FFrame&, void* const)
native function CalculateSupplementaryAngles();

function Rotator GetDesiredRotation()
{
	m_Pawn.SetIgnoreLODCount(1);
	// End:0x2F
	if(TargetIsVisible())
	{
		UpdateTargetRotation();
		return TargetRotation;
	}
	return;
	@NULL
	CommanderAction
}

private function OnRotationReached()
{
	return;
}

function OnMovementStarted()
{
	// End:0x37
	if(__NFUN_255__(MovingEffectEventName, 'None'))
	{
		MyTurret.TriggerEffectEvent(MovingEffectEventName);
		return;
		@NULL
		CommanderAction
	}
	EcologyFighterCommanderAction
}

function OnMovementEnded()
{
	// End:0x37
	if(__NFUN_255__(MovingEffectEventName, 'None'))
	{
		MyTurret.UnTriggerEffectEvent(MovingEffectEventName);
		return;
		@NULL
		CommanderAction
	}
	EcologyFighterCommanderAction
}

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	InitiateMovement();
	MyTurret = Turret(m_Pawn);
	assert(__NFUN_119__(MyTurret, none));
	CalculateSupplementaryAngles();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	CleanupMovement();
	super(AI_CharacterAction).Cleanup();
	return;
	@NULL
}

function InitiateMovement()
{
	assert(__NFUN_114__(CurrentMovementGoal, none));
	CurrentMovementGoal = Class'ShockAI.TurretMovementGoal'.static.Allocate(self).;
	construct_AI_ResourceIntInt(characterResource(), PitchSpeed, YawSpeed);
	CurrentMovementGoal.__NFUN_199__();
	CurrentMovementGoal.__GetDesiredRotation__Delegate = GetDesiredRotation;
	CurrentMovementGoal.__OnRotationReached__Delegate = OnRotationReached;
	CurrentMovementGoal.__OnMovementStarted__Delegate = OnMovementStarted;
	CurrentMovementGoal.__OnMovementEnded__Delegate = OnMovementEnded;
	CurrentMovementGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function CleanupMovement()
{
	OnMovementEnded();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB3
	/*@Error*/
	CurrentMovementGoal.__GetDesiredRotation__Delegate = None;
	CurrentMovementGoal.__OnRotationReached__Delegate = None;
	CurrentMovementGoal.__OnMovementStarted__Delegate = None;
	CurrentMovementGoal.__OnMovementEnded__Delegate = None;
	CurrentMovementGoal.__NFUN_198__();
	CurrentMovementGoal = none;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool TestDeadZone(bool TargetLocked)
{
	//native.TargetLocked;	
	@NULL
}

function WatchForTargetLock()
{
	local bool TargetLocked;

	UpdateTargetRotation();
	J0x0A:

	// End:0x45 [Loop If]
	if(__NFUN_119__(Target, none))
	{
		TargetLocked = TestDeadZone(TargetLocked);
		yield();
		// [Loop Continue]
		goto J0x0A;
		return;
		@NULL
		EcologyAI
	}
	CommanderAction
}

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting track target movement action."));
	// End:0x5F
	if(__NFUN_151__(LockOnDeadZone, 0))
	{
		WatchForTargetLock();
		stop;								
	}
	@NULL
	@NULL
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.TurretTrackTargetMovementGoal'
}