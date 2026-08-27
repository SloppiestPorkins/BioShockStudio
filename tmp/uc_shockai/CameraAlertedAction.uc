class CameraAlertedAction extends BioshockCharacterAction
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn AlarmTarget;
var private CameraPanMovementGoal PanMovementGoal;
var private CameraTrackPawnMovementGoal TrackPawnMovementGoal;
var private SecurityCamera MyCamera;
var private ShockPawn InspectTarget;

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
	MyCamera.UnTriggerEffectEvent('AlarmTargetVisible');
	// End:0x49
	if(__NFUN_119__(PanMovementGoal, none))
	{
		PanMovementGoal.__NFUN_198__();
		PanMovementGoal = none;
		// End:0x72
		if(__NFUN_119__(TrackPawnMovementGoal, none))
		{
			TrackPawnMovementGoal.__NFUN_198__();
		}
		TrackPawnMovementGoal = none;
		NotifySecuritySystemCannotSeeTarget();
		super(AI_CharacterAction).Cleanup();
		return;
		@NULL
		CommanderAction
	}
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

function StartTrackMovement(ShockPawn Target)
{
	StopAllMovement();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xBB
	/*@Error*/
	TrackPawnMovementGoal = Class'ShockAI.CameraTrackPawnMovementGoal'.static.Allocate(self).;
	construct_AI_ResourceNameShockPawnIntInt(characterResource(), 'MovingFast', Target, MyCamera.GetAlertedPitchSpeed(), MyCamera.GetAlertedYawSpeed());
	TrackPawnMovementGoal.__NFUN_199__();
	TrackPawnMovementGoal.postGoal(self);
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
		TrackPawnMovementGoal.unPostGoal(self);
	}
	TrackPawnMovementGoal.__NFUN_198__();
	TrackPawnMovementGoal = none;
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
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xBA
	/*@Error*/
	MyCamera.GetSecurityManager().NotifyNewTargetSeen(MyCamera, Seen);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
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

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xBD
	/*@Error*/
	MyCamera.GetSecurityManager().NotifyNewTargetSeen(MyCamera, SecurityBeaconTarget);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnHackSucceeded(ShockPlayer Player)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x41
	/*@Error*/
	__NFUN_113__('HackedAlerted');
	return;
	@NULL
	CommanderAction
}

function NotifySecuritySystemCanSeeTarget()
{
	MyCamera.GetSecurityManager().NotifySawTarget(MyCamera, AlarmTarget);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
}

function NotifySecuritySystemCannotSeeTarget()
{
	MyCamera.GetSecurityManager().NotifyLostTarget(MyCamera, AlarmTarget);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
}

function OnIntentionallyDamaged(ShockPawn Damager)
{
	return;
}

function WatchForAlarmTarget()
{
	// End:0x44
	if(__NFUN_130__(MyCamera.IsHacked(), AlarmTarget.ShouldPerceiveAsPlayer()))
	{
		__NFUN_113__('HackedAlerted');
		goto J0x80;
		// End:0x75
		if(MyCamera.isVisible(AlarmTarget))
		{
		}
		__NFUN_113__('CanSeeTarget');
		goto J0x80;
		__NFUN_113__('CannotSeeTarget');
		return;
		@NULL
	}
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting CameraAlertedAction::Running."));
	MyCamera.SetAlerted();
	WatchForAlarmTarget();
	stop;				
	@NULL
	@NULL
}

state CanSeeTarget
{
	ignores EndState, BeginState, OnPawnLost;
Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting CameraAlertedAction::CanSeeTarget."));
	MyCamera.TriggerEffectEvent('AlarmTargetVisible');
	StartTrackMovement(AlarmTarget);
	stop;	
	@NULL
	// BadToken (0x03)
	@NULL
	@NULL
}

state CannotSeeTarget
{
	ignores OnIntentionallyDamaged, OnPawnSeen;
Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting CameraAlertedAction::CannotSeeTarget."));
	MyCamera.UnTriggerEffectEvent('AlarmTargetVisible');
	StartSearchMovement();
	stop;			
	@NULL
	@NULL
}

state CannotSeeTargetTracking
{
	ignores OnPawnSeen;
Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting CameraAlertedAction::CannotSeeTargetTracking."));
	StartTrackMovement(AlarmTarget);
	__NFUN_256__(MyCamera.AlertedReturnToCannotSeeStateWhenDamaged);
	__NFUN_113__('CannotSeeTarget');
	stop;		
	@NULL
	@NULL
	@NULL
	@NULL
}

state TargetLost
{
	ignores OnPawnSeen;
Begin:

	__NFUN_256__(MyCamera.GetAlertedTargetLostPauseTime());
	__NFUN_113__('CannotSeeTarget');
	stop;		
	@NULL
}

state HackedAlerted
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting CameraAlertedAction::HackedAlerted."));
	StartSearchMovement();
	stop;	
	@NULL
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.CameraAlertedGoal'
}