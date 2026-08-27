class TurretStandbyAction extends BioshockCharacterAction
	collapsecategories
	hidecategories(Object,InternalParameters);

var private TurretGoToLocationMovementGoal StandbyMovementGoal;
var private Turret MyTurret;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	MyTurret = Turret(m_Pawn);
	assert(__NFUN_119__(MyTurret, none));
	MyTurret.SetVisionState(true);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	// End:0x49
	if(__NFUN_119__(StandbyMovementGoal, none))
	{
		StandbyMovementGoal.__OnRotationReached__Delegate = None;
		StandbyMovementGoal.__NFUN_198__();
		StandbyMovementGoal = none;
		super(AI_CharacterAction).Cleanup();
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function StartStandbyMovement()
{
	local Rotator TargetRotation;

	StopAllMovement();
	TargetRotation.Pitch = MyTurret.GetDefaultPitch();
	TargetRotation.Yaw = MyTurret.GetStandbyYaw();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x13F
	/*@Error*/
	StandbyMovementGoal = Class'ShockAI.TurretGoToLocationMovementGoal'.static.Allocate(self).;
	construct_AI_ResourceNameIntIntRotator(characterResource(), 'Moving', MyTurret.GetPitchSpeed(), MyTurret.GetYawSpeed(), TargetRotation);
	StandbyMovementGoal.__OnRotationReached__Delegate = OnRotationReached;
	StandbyMovementGoal.__NFUN_199__();
	StandbyMovementGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function StopAllMovement()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x61
	/*@Error*/
	StandbyMovementGoal.__OnRotationReached__Delegate = None;
	StandbyMovementGoal.unPostGoal(self);
	StandbyMovementGoal.__NFUN_198__();
	StandbyMovementGoal = none;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function OnRotationReached()
{
	StopAllMovement();
	MyTurret.SetStandby();
	return;
	@NULL
}

function OnStandbyPositionChanged()
{
	StartStandbyMovement();
	return;
}

function TurretCommanderAction GetCommanderAction()
{
	return TurretCommanderAction(achievingGoal.parentAction);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
}

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting TurretStandbyAction::Running."));
	StartStandbyMovement();
	stop;			
	@NULL
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.TurretStandbyGoal'
}