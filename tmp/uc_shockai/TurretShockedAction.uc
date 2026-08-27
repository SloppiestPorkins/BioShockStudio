class TurretShockedAction extends BioshockCharacterAction
	collapsecategories
	hidecategories(Object,InternalParameters);

function PerformShockedBehavior()
{
	local TurretDormantGoal DormantGoal;
	local float DelayStartTime;
	local Turret MyTurret;

	MyTurret = Turret(m_Pawn);
	DelayStartTime = Level().TimeSeconds;
	// End:0xAF
	if(__NFUN_176__(__NFUN_175__(Level().TimeSeconds, DelayStartTime), MyTurret.GetShockedDormantDelay()))
	{
		MyTurret.ToggleLights();
		__NFUN_256__(MyTurret.GetRandomShockedFlickerDelay());
		// [Loop Continue]
		goto J0x3D;
		MyTurret.TurnLightsOff();
		DormantGoal = Class'ShockAI.TurretDormantGoal'.static.Allocate(self).;
	}
	construct_AI_Resource(characterResource());
	DormantGoal.postGoal(self);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting TurretShockedAction::Running."));
	PerformShockedBehavior();
	stop;			
	@NULL
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.TurretShockedGoal'
	bExclusiveAction=true
}