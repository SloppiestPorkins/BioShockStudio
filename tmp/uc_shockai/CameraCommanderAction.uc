class CameraCommanderAction extends CommanderAction implements IVisionNotification
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var private CameraSearchGoal CurrentSearchGoal;
var private CameraAlertedGoal CurrentAlertedGoal;
var private CameraDormantGoal CurrentDormantGoal;
var private CameraShockedGoal CurrentShockedGoal;
var private CameraMovementGoal CurrentMovementGoal;
var private ICameraMovementController CurrentMovementController;
var private Rotator DesiredRotation;
var array<ShockPawn> VisiblePawns;
var private SecurityCamera MyCamera;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super.initAction(R, Goal);
	MyCamera = SecurityCamera(m_Pawn);
	assert(__NFUN_119__(MyCamera, none));
	m_Pawn.RegisterVisionNotification(self);
	InitiateMovement();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	m_Pawn.UnregisterVisionNotification(self);
	// End:0x41
	if(__NFUN_119__(CurrentSearchGoal, none))
	{
		CurrentSearchGoal.__NFUN_198__();
		CurrentSearchGoal = none;
		// End:0x6A
		if(__NFUN_119__(CurrentAlertedGoal, none))
		{
			CurrentAlertedGoal.__NFUN_198__();
		}
		CurrentAlertedGoal = none;
		// End:0x93
		if(__NFUN_119__(CurrentDormantGoal, none))
		{
			CurrentDormantGoal.__NFUN_198__();
			CurrentDormantGoal = none;
		}
		// End:0xBC
		if(__NFUN_119__(CurrentShockedGoal, none))
		{
			CurrentShockedGoal.__NFUN_198__();
			CurrentShockedGoal = none;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x165
			/*@Error*/
		}
		CurrentMovementGoal.__GetDesiredRotation__Delegate = None;
		CurrentMovementGoal.__OnRotationReached__Delegate = None;
	}
	CurrentMovementGoal.__OnMovementStarted__Delegate = None;
	CurrentMovementGoal.__OnMovementEnded__Delegate = None;
	CurrentMovementGoal.__NFUN_198__();
	CurrentMovementGoal = none;
	super.Cleanup();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function CleanupGoals()
{
	// End:0x41
	if(__NFUN_119__(CurrentSearchGoal, none))
	{
		CurrentSearchGoal.unPostGoal(self);
		CurrentSearchGoal.__NFUN_198__();
		CurrentSearchGoal = none;
		// End:0x82
		if(__NFUN_119__(CurrentAlertedGoal, none))
		{
			CurrentAlertedGoal.unPostGoal(self);
		}
		CurrentAlertedGoal.__NFUN_198__();
		CurrentAlertedGoal = none;
		// End:0xC3
		if(__NFUN_119__(CurrentDormantGoal, none))
		{
			CurrentDormantGoal.unPostGoal(self);
			CurrentDormantGoal.__NFUN_198__();
		}
		CurrentDormantGoal = none;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x104
		/*@Error*/
		CurrentShockedGoal.unPostGoal(self);
		CurrentShockedGoal.__NFUN_198__();
		CurrentShockedGoal = none;
	}
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function Rotator GetDesiredRotation()
{
	// End:0x30
	if(__NFUN_119__(CurrentMovementController, none))
	{
		DesiredRotation = CurrentMovementController.UpdateDesiredRotation();
		return DesiredRotation;
		return;
		@NULL
	}
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function float OnRotationReached()
{
	// End:0x27
	if(__NFUN_119__(CurrentMovementController, none))
	{
		return CurrentMovementController.OnRotationReached();
		return 0.0000000;
		return;
	}
	@NULL
	CommanderAction
}

function OnMovementStarted()
{
	// End:0x64
	if(__NFUN_130__(__NFUN_119__(CurrentMovementController, none), __NFUN_255__(CurrentMovementController.GetMovingEffectEventName(), 'None')))
	{
		MyCamera.TriggerEffectEvent(CurrentMovementController.GetMovingEffectEventName());
		return;
		@NULL
		CommanderAction
		EcologyFighterCommanderAction
	}
	@NULL
}

function OnMovementEnded()
{
	// End:0x64
	if(__NFUN_130__(__NFUN_119__(CurrentMovementController, none), __NFUN_255__(CurrentMovementController.GetMovingEffectEventName(), 'None')))
	{
		MyCamera.UnTriggerEffectEvent(CurrentMovementController.GetMovingEffectEventName());
		return;
		@NULL
		CommanderAction
		EcologyFighterCommanderAction
	}
	@NULL
}

function InitiateMovement()
{
	assert(__NFUN_114__(CurrentMovementGoal, none));
	CurrentMovementGoal = Class'ShockAI.CameraMovementGoal'.static.Allocate(self).;
	construct_AI_ResourceIntInt(characterResource(), 0, 0);
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

function SetPitchSpeed(int NewPitchSpeed)
{
	CameraMovementAction(CurrentMovementGoal.achievingAction).SetPitchSpeed(NewPitchSpeed);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function SetYawSpeed(int NewYawSpeed)
{
	CameraMovementAction(CurrentMovementGoal.achievingAction).SetYawSpeed(NewYawSpeed);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function SetSpeedScale(float NewSpeedScale)
{
	CameraMovementAction(CurrentMovementGoal.achievingAction).SetSpeedScale(NewSpeedScale);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function RegisterMovementController(ICameraMovementController NewMovementController)
{
	CurrentMovementController = NewMovementController;
	SetPitchSpeed(int(NewMovementController.GetPitchSpeed()));
	SetYawSpeed(int(NewMovementController.GetYawSpeed()));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function UnregisterMovementController(ICameraMovementController OldMovementController)
{
	// End:0x22
	if(__NFUN_114__(CurrentMovementController, OldMovementController))
	{
		CurrentMovementController = none;
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function OnViewerSawPawn(VPawn Viewer, Pawn Seen)
{
	local ShockPawn SeenShockPawn;

	log('AI_Security', 3, __NFUN_112__(__NFUN_112__(string(Viewer.Name), " saw "), string(Seen.Name)));
	SeenShockPawn = ShockPawn(Seen);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB0
	/*@Error*/
	VisiblePawns[VisiblePawns.Length] = SeenShockPawn;
	NotifyChildSawPawn(Viewer, SeenShockPawn);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnViewerLostPawn(VPawn Viewer, Pawn Seen)
{
	local int i;
	local ShockPawn SeenShockPawn;

	log('AI_Security', 3, __NFUN_112__(__NFUN_112__(string(Viewer.Name), " lost view of "), string(Seen.Name)));
	SeenShockPawn = ShockPawn(Seen);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x104
	/*@Error*/
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x104
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xF6
	/*@Error*/
	VisiblePawns.Remove(i, 1);
	NotifyChildLostPawn(Viewer, SeenShockPawn);
	goto J0x104;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x8A;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnNumLOSChanged(VPawn Viewer, Pawn Seen, int NewNumLOS)
{
	return;
}

function NotifyChildSawPawn(VPawn Viewer, ShockPawn Seen)
{
	local CameraSearchAction CurrentSearchAction;
	local CameraAlertedAction CurrentAlertedAction;

	CurrentSearchAction = GetSearchAction();
	CurrentAlertedAction = GetAlertedAction();
	// End:0x60
	if(__NFUN_119__(CurrentSearchAction, none))
	{
		CurrentSearchAction.OnViewerSawPawn(Viewer, Seen);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x98
		/*@Error*/
		CurrentAlertedAction.OnViewerSawPawn(Viewer, Seen);
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyChildLostPawn(VPawn Viewer, ShockPawn Seen)
{
	local CameraSearchAction CurrentSearchAction;
	local CameraAlertedAction CurrentAlertedAction;

	CurrentSearchAction = GetSearchAction();
	CurrentAlertedAction = GetAlertedAction();
	// End:0x60
	if(__NFUN_119__(CurrentSearchAction, none))
	{
		CurrentSearchAction.OnViewerLostPawn(Viewer, Seen);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x98
		/*@Error*/
		CurrentAlertedAction.OnViewerLostPawn(Viewer, Seen);
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function GetVisiblePawns(out array<ShockPawn> pawns)
{
	pawns = VisiblePawns;
	return;
	@NULL
	CommanderAction
}

function ShockPawn GetHighestPriorityPawn(int BasePriority)
{
	local int i, HighestPriority, CurrentPriority;
	local ShockPawn HighestPriorityPawn;

	HighestPriority = BasePriority;
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xBF
	/*@Error*/
	CurrentPriority = MyCamera.GetTargetPriority(VisiblePawns[i]);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB1
	/*@Error*/
	HighestPriorityPawn = VisiblePawns[i];
	HighestPriority = CurrentPriority;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x1E;
	return HighestPriorityPawn;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool isVisible(ShockPawn Target)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x54
	/*@Error*/
	// End:0x46
	if(__NFUN_114__(Target, VisiblePawns[i]))
	{
		return true;
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x0B;
		return false;
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
	@NULL
}

function OnIntentionallyDamaged(ShockPawn Damager)
{
	local CameraSearchAction CurrentSearchAction;
	local CameraAlertedAction CurrentAlertedAction;

	CurrentSearchAction = GetSearchAction();
	CurrentAlertedAction = GetAlertedAction();
	// End:0x57
	if(__NFUN_119__(CurrentSearchAction, none))
	{
		CurrentSearchAction.OnIntentionallyDamaged(Damager);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x86
		/*@Error*/
		CurrentAlertedAction.OnIntentionallyDamaged(Damager);
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function CameraSearchAction GetSearchAction()
{
	// End:0x2F
	if(__NFUN_119__(CurrentSearchGoal, none))
	{
		return CameraSearchAction(CurrentSearchGoal.achievingAction);
		return none;
		return;
		@NULL
		CommanderAction
		EcologyFighterCommanderAction
	}
	@NULL
}

function CameraAlertedAction GetAlertedAction()
{
	// End:0x2F
	if(__NFUN_119__(CurrentAlertedGoal, none))
	{
		return CameraAlertedAction(CurrentAlertedGoal.achievingAction);
		return none;
		return;
		@NULL
		CommanderAction
		EcologyFighterCommanderAction
	}
	@NULL
}

function BeSearching()
{
	// End:0x6C
	if(__NFUN_129__(CanLeaveDormantState()))
	{
		log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " tried to start searching, but couldn't leave dormant state."));
		return;
		CleanupGoals();
	}
	CurrentSearchGoal = Class'ShockAI.CameraSearchGoal'.static.Allocate(self).;
	construct_AI_Resource(characterResource());
	assert(__NFUN_119__(CurrentSearchGoal, none));
	CurrentSearchGoal.__NFUN_199__();
	CurrentSearchGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function BeAlerted(ShockPawn AlarmTarget)
{
	// End:0x6C
	if(__NFUN_129__(CanLeaveDormantState()))
	{
		log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " tried to start searching, but couldn't leave dormant state."));
		return;
		CleanupGoals();
	}
	CurrentAlertedGoal = Class'ShockAI.CameraAlertedGoal'.static.Allocate(self).;
	construct_AI_ResourceShockPawn(characterResource(), AlarmTarget);
	assert(__NFUN_119__(CurrentAlertedGoal, none));
	CurrentAlertedGoal.__NFUN_199__();
	CurrentAlertedGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function BeDormant()
{
	CleanupGoals();
	CurrentDormantGoal = Class'ShockAI.CameraDormantGoal'.static.Allocate(self).;
	construct_AI_Resource(characterResource());
	assert(__NFUN_119__(CurrentDormantGoal, none));
	CurrentDormantGoal.__NFUN_199__();
	CurrentDormantGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool CanLeaveDormantState()
{
	return __NFUN_130__(__NFUN_129__(IsShocked()), __NFUN_132__(MyCamera.IsHacked(), MyCamera.GetSecurityManager().IsActive()));
	return;
	@NULL
	CommanderAction
}

function bool IsSearching()
{
	return __NFUN_119__(CurrentSearchGoal, none);
	return;
	@NULL
}

function bool IsAlerted()
{
	return __NFUN_119__(CurrentAlertedGoal, none);
	return;
	@NULL
}

function bool IsDormant()
{
	return __NFUN_119__(CurrentDormantGoal, none);
	return;
	@NULL
}

function bool IsShocked()
{
	return __NFUN_119__(CurrentShockedGoal, none);
	return;
	@NULL
}

function StartShockedBehavior()
{
	CleanupGoals();
	CurrentShockedGoal = Class'ShockAI.CameraShockedGoal'.static.Allocate(self).;
	construct_AI_Resource(characterResource());
	assert(__NFUN_119__(CurrentShockedGoal, none));
	CurrentShockedGoal.__NFUN_199__();
	CurrentShockedGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function StopShockedBehavior()
{
	CleanupGoals();
	// End:0x64
	if(MyCamera.GetSecurityManager().IsAlarmOn())
	{
		BeAlerted(MyCamera.GetSecurityManager().GetAlarmTarget());
		goto J0xC3;
		// End:0xB9
		if(__NFUN_130__(__NFUN_129__(MyCamera.IsHacked()), __NFUN_129__(MyCamera.GetSecurityManager().IsActive())))
		{
		}
		BeDormant();
		goto J0xC3;
		BeSearching();
		return;
		@NULL
	}
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function OnNotifySecuritySystemActive()
{
	BeSearching();
	return;
}

function OnNotifySecuritySystemInactive()
{
	BeDormant();
	return;
}

function OnNotifySecurityAlarmOn(ShockPawn inAlarmTarget)
{
	BeAlerted(inAlarmTarget);
	return;
	@NULL
}

function OnNotifySecurityAlarmOff(bool TurnedOffBySecurityStation)
{
	BeSearching();
	return;
}

function OnNotifySecurityBeaconApplied(Actor Damager, ShockPawn SecurityBeaconTarget)
{
	local CameraSearchAction CurrentSearchAction;
	local CameraAlertedAction CurrentAlertedAction;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x9C
	/*@Error*/
	CurrentSearchAction = GetSearchAction();
	CurrentAlertedAction = GetAlertedAction();
	// End:0x6D
	if(__NFUN_119__(CurrentSearchAction, none))
	{
		CurrentSearchAction.OnNotifySecurityBeaconApplied(SecurityBeaconTarget);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x9C
		/*@Error*/
		CurrentAlertedAction.OnNotifySecurityBeaconApplied(SecurityBeaconTarget);
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnNotifyAlarmTargetChanged(ShockPawn NewTarget)
{
	// End:0x25
	if(__NFUN_119__(NewTarget, none))
	{
		BeAlerted(NewTarget);
		goto J0x2F;
		BeSearching();
	}
	return;
	@NULL
	CommanderAction
}

function OnHackSucceeded(ShockPlayer Player)
{
	local CameraSearchAction CurrentSearchAction;
	local CameraAlertedAction CurrentAlertedAction;

	CurrentSearchAction = GetSearchAction();
	CurrentAlertedAction = GetAlertedAction();
	// End:0x57
	if(__NFUN_119__(CurrentSearchAction, none))
	{
		CurrentSearchAction.OnHackSucceeded(Player);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x86
		/*@Error*/
		CurrentAlertedAction.OnHackSucceeded(Player);
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnKilled()
{
	CleanupGoals();
	return;
}

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting commander action."));
	BeSearching();
	stop;			
	@NULL
}
