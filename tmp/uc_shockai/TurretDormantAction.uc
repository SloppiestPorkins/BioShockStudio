class TurretDormantAction extends BioshockCharacterAction
	collapsecategories
	hidecategories(Object,InternalParameters);

var private TurretGoToLocationMovementGoal DormantMovementGoal;
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
	if(__NFUN_119__(DormantMovementGoal, none))
	{
		DormantMovementGoal.__OnRotationReached__Delegate = None;
		DormantMovementGoal.__NFUN_198__();
		DormantMovementGoal = none;
		super(AI_CharacterAction).Cleanup();
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function StartDormantMovement()
{
	local Rotator TargetRotation;

	StopAllMovement();
	TargetRotation = MyTurret.GetCurrentRotation();
	TargetRotation.Pitch = MyTurret.GetDormantPitch();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x12E
	/*@Error*/
	DormantMovementGoal = Class'ShockAI.TurretGoToLocationMovementGoal'.static.Allocate(self).;
	construct_AI_ResourceNameIntIntRotator(characterResource(), 'Moving', MyTurret.GetPitchSpeed(), MyTurret.GetYawSpeed(), TargetRotation);
	DormantMovementGoal.__OnRotationReached__Delegate = OnRotationReached;
	DormantMovementGoal.__NFUN_199__();
	DormantMovementGoal.postGoal(self);
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
	DormantMovementGoal.__OnRotationReached__Delegate = None;
	DormantMovementGoal.unPostGoal(self);
	DormantMovementGoal.__NFUN_198__();
	DormantMovementGoal = none;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

private function OnRotationReached()
{
	StopAllMovement();
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

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting TurretDormantAction::Running."));
	MyTurret.SetDormant();
	StartDormantMovement();
	stop;				
	@NULL
	@NULL
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.TurretDormantGoal'
}