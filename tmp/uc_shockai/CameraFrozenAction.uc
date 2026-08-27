class CameraFrozenAction extends BioshockCharacterAction
	collapsecategories
	hidecategories(Object,InternalParameters);

function Cleanup()
{
	SecurityCamera(m_Pawn).GetCameraCommanderAction().SetSpeedScale(1.0000000);
	super(AI_CharacterAction).Cleanup();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function RunFrozenBehavior()
{
	local SecurityCamera MyCamera;
	local float StartTime;

	MyCamera = SecurityCamera(m_Pawn);
	StartTime = Level().TimeSeconds;
	// End:0xEF
	if(__NFUN_176__(__NFUN_175__(Level().TimeSeconds, StartTime), MyCamera.GetFrozenTransitionTime()))
	{
		MyCamera.GetCameraCommanderAction().SetSpeedScale(__NFUN_175__(1.0000000, __NFUN_172__(__NFUN_175__(Level().TimeSeconds, StartTime), MyCamera.GetFrozenTransitionTime())));
		yield();
		// [Loop Continue]
		goto J0x3D;
		MyCamera.GetCameraCommanderAction().SetSpeedScale(0.0000000);
		return;
		@NULL
		EcologyAI
	}
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting CameraFrozenAction::Running."));
	RunFrozenBehavior();
	// End:0x81
	if(__NFUN_129__(BioshockCharacterGoal(achievingGoal).ShouldFinishUp()))
	{
		yield();
		// [Loop Continue]
		goto J0x4F;
		succeed();
		stop;		
	}			
	@NULL
	@NULL
	@NULL
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.FrozenGoal'
}