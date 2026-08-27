class CameraSearchAction extends BioshockCharacterAction
	collapsecategories
	hidecategories(Object,InternalParameters);

var private CameraPanMovementGoal PanMovementGoal;
var private CameraInspectPawnMovementGoal InspectPawnMovementGoal;
var private CameraInspectGoal CurrentInspectGoal;
var private SecurityCamera MyCamera;
var private ShockPawn TrackingTarget;

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
	if(__NFUN_119__(CurrentInspectGoal, none))
	{
		CurrentInspectGoal.__NFUN_198__();
		CurrentInspectGoal = none;
		// End:0x52
		if(__NFUN_119__(PanMovementGoal, none))
		{
			PanMovementGoal.__NFUN_198__();
		}
		PanMovementGoal = none;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x7B
		/*@Error*/
		InspectPawnMovementGoal.__NFUN_198__();
		InspectPawnMovementGoal = none;
	}
	super(AI_CharacterAction).Cleanup();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function StartSearchMovement()
{
	StopAllMovement();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB2
	/*@Error*/
	PanMovementGoal = Class'ShockAI.CameraPanMovementGoal'.static.Allocate(self).;
	construct_AI_ResourceNameIntInt(characterResource(), 'MovingSlow', MyCamera.GetSearchingPitchSpeed(), MyCamera.GetSearchingYawSpeed());
	PanMovementGoal.__NFUN_199__();
	PanMovementGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function StartInspectMovement(ShockPawn Target)
{
	StopAllMovement();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xBB
	/*@Error*/
	InspectPawnMovementGoal = Class'ShockAI.CameraInspectPawnMovementGoal'.static.Allocate(self).;
	construct_AI_ResourceNameShockPawnIntInt(characterResource(), 'MovingSlow', Target, MyCamera.GetSearchingPitchSpeed(), MyCamera.GetSearchingYawSpeed());
	InspectPawnMovementGoal.__NFUN_199__();
	InspectPawnMovementGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function StopAllMovement()
{
	// End:0x41
	if(__NFUN_119__(PanMovementGoal, none))
	{
		PanMovementGoal.unPostGoal(self);
		PanMovementGoal.__NFUN_198__();
		PanMovementGoal = none;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x82
		/*@Error*/
		InspectPawnMovementGoal.unPostGoal(self);
	}
	InspectPawnMovementGoal.__NFUN_198__();
	InspectPawnMovementGoal = none;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function OnViewerSawPawn(VPawn Viewer, ShockPawn Seen)
{
	assert(__NFUN_119__(Seen, none));
	OnPawnSeen(Seen);
	return;
	@NULL
	CommanderAction
}

function OnViewerLostPawn(VPawn Viewer, ShockPawn Seen)
{
	assert(__NFUN_119__(Seen, none));
	OnPawnLost(Seen);
	return;
	@NULL
	CommanderAction
}

private function OnPawnSeen(ShockPawn Seen)
{
	return;
}

private function OnPawnLost(ShockPawn Seen)
{
	return;
}

function CameraCommanderAction GetCommanderAction()
{
	return CameraCommanderAction(achievingGoal.parentAction);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
}

function OnNotifySecurityBeaconApplied(ShockPawn SecurityBeaconTarget)
{
	return;
}

function OnHackSucceeded(ShockPlayer Player)
{
	// End:0x41
	if(__NFUN_119__(CurrentInspectGoal, none))
	{
		CurrentInspectGoal.unPostGoal(self);
		CurrentInspectGoal.__NFUN_198__();
		CurrentInspectGoal = none;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x7F
		/*@Error*/
	}
	TrackingTarget = none;
	__NFUN_113__('Searching');
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnIntentionallyDamaged(ShockPawn Damager)
{
	return;
}

function WaitForInspection()
{
	assert(__NFUN_119__(TrackingTarget, none));
	CurrentInspectGoal = Class'ShockAI.CameraInspectGoal'.static.Allocate(self).;
	construct_AI_ResourceShockPawnFloatFloat(characterResource(), TrackingTarget, MyCamera.GetInspectionDuration(TrackingTarget), MyCamera.GetLostContactDuration(TrackingTarget));
	CurrentInspectGoal.__NFUN_199__();
	assert(__NFUN_119__(TrackingTarget, none));
	CurrentInspectGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentInspectGoal);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x16C
	/*@Error*/
	MyCamera.GetSecurityManager().StartAlarm(MyCamera, TrackingTarget, MyCamera.SecurityBotClass, MyCamera.NumSecurityBotsSpawned);
	CurrentInspectGoal.unPostGoal(self);
	CurrentInspectGoal.__NFUN_198__();
	CurrentInspectGoal = none;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function ShockPawn GetHighestPriorityPawn()
{
	local int BasePriority;
	local CameraCommanderAction CurrentCommanderAction;

	CurrentCommanderAction = GetCommanderAction();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x7D
	/*@Error*/
	// End:0x5C
	if(__NFUN_119__(TrackingTarget, none))
	{
		BasePriority = MyCamera.GetTargetPriority(TrackingTarget);
		return CurrentCommanderAction.GetHighestPriorityPawn(BasePriority);
	}
	return none;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting CameraSearchAction::Running."));
	__NFUN_113__('Searching');
	stop;			
	@NULL
}

state Searching
{
	ignores OnIntentionallyDamaged, OnNotifySecurityBeaconApplied, OnPawnSeen;
Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting Searching behavior."));
	MyCamera.SetSearching();
	StartSearchMovement();
	assert(__NFUN_114__(TrackingTarget, none));
	TrackingTarget = GetHighestPriorityPawn();
	// End:0x9A
	if(__NFUN_119__(TrackingTarget, none))
	{
		__NFUN_113__('PreparingToInspect');
		stop;		
	}
	@NULL
	@NULL
	@NULL
	@NULL
}

state PreparingToInspect
{
	ignores OnNotifySecurityBeaconApplied, OnPawnLost, OnPawnSeen;
Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting PreparingToInspect behavior."));
	__NFUN_256__(MyCamera.GetSearchingInspectionPanOvershootTime());
	// End:0x7C
	if(__NFUN_119__(TrackingTarget, none))
	{
		__NFUN_113__('Inspecting');
		goto J0x87;
		__NFUN_113__('Searching');
		stop;
	}				
	@NULL
	@NULL
	@NULL
}

state Inspecting
{
	ignores OnNotifySecurityBeaconApplied, OnPawnLost, OnPawnSeen, ResetInspectingState;
Begin:

	log('AI_Security', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn), " starting Inspecting behavior on "), string(TrackingTarget)), "."));
	StopAllMovement();
	__NFUN_256__(MyCamera.GetSearchingInspectionPauseTime());
	// End:0x90
	if(__NFUN_114__(TrackingTarget, none))
	{
		__NFUN_113__('Searching');
		StartInspectMovement(TrackingTarget);
		MyCamera.SetInspecting();
	}
	WaitForInspection();
	yield();
	TrackingTarget = none;
	__NFUN_113__('Searching');
	stop;			
	@NULL
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.CameraSearchGoal'
}