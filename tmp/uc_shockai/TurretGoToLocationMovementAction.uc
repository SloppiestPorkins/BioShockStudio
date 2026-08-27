class TurretGoToLocationMovementAction extends BioshockCharacterAction
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) name MovingEffectEventName;
var(Parameters) int PitchSpeed;
var(Parameters) int YawSpeed;
var(Parameters) Rotator TargetRotation;
var private Turret MyTurret;
var private TurretMovementGoal CurrentMovementGoal;

function Rotator GetDesiredRotation()
{
	m_Pawn.SetIgnoreLODCount(1);
	return TargetRotation;
	return;
	@NULL
	CommanderAction
}

function OnRotationReached()
{
	assert(__NFUN_119__(TurretGoToLocationMovementGoal(achievingGoal), none));
	TurretGoToLocationMovementGoal(achievingGoal).OnRotationReached();
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
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

function SetPitchSpeed(int NewPitchSpeed)
{
	PitchSpeed = NewPitchSpeed;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x76
	/*@Error*/
	TurretMovementAction(CurrentMovementGoal.achievingAction).SetPitchSpeed(PitchSpeed);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function SetYawSpeed(int NewYawSpeed)
{
	YawSpeed = NewYawSpeed;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x76
	/*@Error*/
	TurretMovementAction(CurrentMovementGoal.achievingAction).SetYawSpeed(YawSpeed);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting go to location movement action."));
	stop;			
	@NULL
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.TurretGoToLocationMovementGoal'
}