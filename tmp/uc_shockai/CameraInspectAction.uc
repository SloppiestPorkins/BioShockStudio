class CameraInspectAction extends BioshockCharacterAction
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn InspectTarget;
var(Parameters) float InspectionDuration;
var(Parameters) float LostDuration;
var private SecurityCamera MyCamera;
var private float InspectionTimeLeft;
var private float InspectionStartTime;
var private bool CanSeeTarget;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	MyCamera = SecurityCamera(m_Pawn);
	assert(__NFUN_119__(MyCamera, none));
	InspectionStartTime = Level().TimeSeconds;
	InspectionTimeLeft = InspectionDuration;
	// End:0xB8
	if(__NFUN_114__(MyCamera.GetSpecificTarget(), InspectTarget))
	{
		MyCamera.SetSpecificTargetIgnoreResetTime(true);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x10B
		/*@Error*/
		ShockPlayerController(InspectTarget.Controller).GetPlayerStatsManager().PlayerInspectedBySecurityCamera();
	}
	CanSeeTarget = MyCamera.isVisible(InspectTarget);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	// End:0x3C
	if(__NFUN_114__(MyCamera.GetSpecificTarget(), InspectTarget))
	{
		MyCamera.ClearSpecificTarget();
		MyCamera.InspectionTargetVisibleStop();
	}
	MyCamera.InspectionTargetNotVisibleStop();
	super(AI_CharacterAction).Cleanup();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnTargetSeen()
{
	assert(__NFUN_129__(CanSeeTarget));
	CanSeeTarget = true;
	__NFUN_113__('TargetIsVisible');
	return;
	@NULL
	CommanderAction
}

function OnTargetLost()
{
	assert(CanSeeTarget);
	CanSeeTarget = false;
	InspectionTimeLeft = __NFUN_175__(InspectionTimeLeft, __NFUN_175__(Level().TimeSeconds, InspectionStartTime));
	__NFUN_113__('TargetIsNotVisible');
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function PostCameraEventNotification()
{
	local AIEventNotification Event;

	Event = Class'Engine.AIEventNotification'.static.CreateAIEventNotification(Level());
	Event.NotificationType = 2;
	Event.SetLocation(MyCamera.Location, InspectTarget.Location, true);
	Event.Radius = MyCamera.GetEventNotificationCylinderRadius();
	Event.Height = MyCamera.GetEventNotificationCylinderHeight();
	Event.SourceActor = MyCamera;
	MyCamera.Level.SpawningManager.PostAIEventNotification(Event);
	Event.__NFUN_200__();
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn), " starting inspect behavior on target "), string(InspectTarget)), " for "), string(InspectionDuration)), " seconds."));
	MyCamera.TriggerEffectEvent('InspectionStarted');
	PostCameraEventNotification();
	CanSeeTarget = MyCamera.isVisible(InspectTarget);
	// End:0xE4
	if(CanSeeTarget)
	{
		__NFUN_113__('TargetIsVisible');
		goto J0xEF;
		__NFUN_113__('TargetIsNotVisible');
		stop;								
	}
	@NULL
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

state TargetIsVisible
{Begin:

	log('AI_Security', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn), " CameraInspectAction saw target.  "), string(InspectionTimeLeft)), " seconds left."));
	MyCamera.InspectionTargetNotVisibleStop();
	MyCamera.InspectionTargetVisibleStart();
	InspectionStartTime = Level().TimeSeconds;
	// End:0xCE
	if(__NFUN_177__(InspectionTimeLeft, 0.0000000))
	{
		__NFUN_256__(InspectionTimeLeft);
		log('AI_Security', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn), " has succeeded in inspecting "), string(InspectTarget)), ".  Triggering alarm."));
	}
	MyCamera.TriggerEffectEvent('InspectionSucceeded');
	MyCamera.InspectionTargetVisibleStop();
	succeed();
	stop;			
	@NULL
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

state TargetIsNotVisible
{Begin:

	log('AI_Security', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn), " CameraInspectAction lost target.  "), string(InspectionTimeLeft)), " seconds left.  "), string(LostDuration)), " seconds left until failing inspection."));
	MyCamera.InspectionTargetVisibleStop();
	MyCamera.InspectionTargetNotVisibleStart();
	__NFUN_256__(LostDuration);
	log('AI_Security', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn), " has failed in inspecting "), string(InspectTarget)), "."));
	MyCamera.TriggerEffectEvent('InspectionFailed');
	MyCamera.InspectionTargetNotVisibleStop();
	fail(1);
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
	satisfiesGoal=Class'ShockAI.CameraInspectGoal'
}