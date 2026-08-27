class ScriptedAICommanderAction extends CommanderAction
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var private HeadTrackingGoal CurrentHeadTrackingGoal;

function Cleanup()
{
	super.Cleanup();
	// End:0x33
	if(__NFUN_119__(CurrentHeadTrackingGoal, none))
	{
		CurrentHeadTrackingGoal.__NFUN_198__();
		CurrentHeadTrackingGoal = none;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

protected function bool ShouldHandleDamageEvents()
{
	return false;
	return;
}

function QuickLook(Actor Target, optional float Duration, optional Vector Offset)
{
	HeadTrackingAction(CurrentHeadTrackingGoal.achievingAction).QuickLook(Target, Duration, Offset);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function CasualLook(Actor Target, optional float Duration, optional Vector Offset)
{
	HeadTrackingAction(CurrentHeadTrackingGoal.achievingAction).CasualLook(Target, Duration, Offset);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function StopTracking()
{
	HeadTrackingAction(CurrentHeadTrackingGoal.achievingAction).StopTracking();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function bool IsTracking()
{
	return HeadTrackingAction(CurrentHeadTrackingGoal.achievingAction).IsTracking();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

state Running
{Begin:

	// End:0x70
	if(__NFUN_114__(CurrentHeadTrackingGoal, none))
	{
		CurrentHeadTrackingGoal = HeadTrackingGoal(Class'ShockAI.HeadTrackingGoal'.static.Allocate(self)..@NULL.none);
		@NULL
		Aggressor				
		EcologyFighterCommanderAction
		postGoal(self);
		// End:0x400
		case myAddRef():
			Pause();
		}/* !MISMATCHING REMOVE, tried If got Type:Case Position:0x05D! */
		stop;		
		@NULL
		@NULL/* !MISMATCHING REMOVE, tried Case got Type:If Position:0x000! */
}
