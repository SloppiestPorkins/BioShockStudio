class CameraShockedAction extends BioshockCharacterAction
	collapsecategories
	hidecategories(Object,InternalParameters);

var private CameraDormantMovementGoal DormantMovementGoal;
var private SecurityCamera MyCamera;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
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
	// End:0x29
	if(__NFUN_119__(DormantMovementGoal, none))
	{
		DormantMovementGoal.__NFUN_198__();
		DormantMovementGoal = none;
		super(AI_CharacterAction).Cleanup();
		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

function StartDormantMovement()
{
	local Rotator TargetRotation;

	StopAllMovement();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x10E
	/*@Error*/
	TargetRotation = MyCamera.GetCurrentRotation();
	TargetRotation.Pitch = MyCamera.GetDormantPitch();
	DormantMovementGoal = Class'ShockAI.CameraDormantMovementGoal'.static.Allocate(self).;
	construct_AI_ResourceNameIntIntRotator(characterResource(), 'MovingSlow', MyCamera.GetSearchingPitchSpeed(), MyCamera.GetSearchingYawSpeed(), TargetRotation);
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
	// End:0x41
	if(__NFUN_119__(DormantMovementGoal, none))
	{
		DormantMovementGoal.unPostGoal(self);
		DormantMovementGoal.__NFUN_198__();
		DormantMovementGoal = none;
		return;
		@NULL
		CommanderAction
		EcologyFighterCommanderAction
	}
	@NULL
}

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting CameraShockedAction::Running."));
	MyCamera.SetDormant();
	__NFUN_256__(MyCamera.GetShockedDormantDelay());
	StartDormantMovement();
	stop;		
	@NULL
	@NULL
	@NULL
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.CameraShockedGoal'
}