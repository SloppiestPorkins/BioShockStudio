class TurretAttackAction extends BioshockCharacterAction
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn AttackTarget;
var(Parameters) bool ComingFromStandby;
var private TurretTrackTargetMovementGoal AttackMovementGoal;
var private Turret MyTurret;
var private bool CanSeeTarget;
var private bool HaveTargetLock;
var private bool CurrentlyFiringWeapon;
var private bool HasPostedEventNotification;
var private float LastTimeStartedFiring;
var private float NextCoolTime;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	MyTurret = Turret(m_Pawn);
	assert(__NFUN_119__(MyTurret, none));
	MyTurret.SetVisionState(true);
	CanSeeTarget = GetCommanderAction().isVisible(AttackTarget);
	ResetRangedWeaponAccuracy();
	HasPostedEventNotification = false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ResetRangedWeaponAccuracy()
{
	local AIRangedWeapon AIRangedWeapon;

	AIRangedWeapon = AIRangedWeapon(MyTurret.GetWeapon());
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x59
	/*@Error*/
	AIRangedWeapon.ResetChangingAccuracy(AttackTarget);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function Cleanup()
{
	StopFiringWeapon();
	// End:0x33
	if(__NFUN_119__(AttackMovementGoal, none))
	{
		AttackMovementGoal.__NFUN_198__();
		AttackMovementGoal = none;
		super(AI_CharacterAction).Cleanup();
		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

function StartAttackMovement()
{
	StopAllMovement();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x148
	/*@Error*/
	AttackMovementGoal = Class'ShockAI.TurretTrackTargetMovementGoal'.static.Allocate(self).;
	construct_AI_ResourceNameIntIntShockPawnFloatFloat(characterResource(), 'Turning', MyTurret.GetPitchSpeed(), MyTurret.GetYawSpeed(), AttackTarget, 0.0000000, float(MyTurret.GetTargetDeadZone()));
	assert(__NFUN_119__(AttackMovementGoal, none));
	AttackMovementGoal.__TargetIsVisible__Delegate = TargetIsVisible;
	AttackMovementGoal.__GainedTargetLock__Delegate = GainedTargetLock;
	AttackMovementGoal.__LostTargetLock__Delegate = LostTargetLock;
	AttackMovementGoal.__NFUN_199__();
	AttackMovementGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function StopAllMovement()
{
	// End:0x41
	if(__NFUN_119__(AttackMovementGoal, none))
	{
		AttackMovementGoal.unPostGoal(self);
		AttackMovementGoal.__NFUN_198__();
		AttackMovementGoal = none;
		return;
		@NULL
		CommanderAction
		EcologyFighterCommanderAction
	}
	@NULL
}

function OnViewerSawPawn(VPawn Viewer, ShockPawn Seen)
{
	// End:0x2D
	if(__NFUN_114__(Seen, AttackTarget))
	{
		CanSeeTarget = true;
		OnSawTarget();
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function OnViewerLostPawn(VPawn Viewer, ShockPawn Seen)
{
	// End:0x2D
	if(__NFUN_114__(Seen, AttackTarget))
	{
		CanSeeTarget = false;
		OnLostTarget();
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function bool TargetIsVisible()
{
	return CanSeeTarget;
	return;
	@NULL
}

private function OnSawTarget()
{
	return;
}

private function OnLostTarget()
{
	return;
}

function GainedTargetLock()
{
	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " gained a lock on its target."));
	HaveTargetLock = true;
	OnGainedTargetLock();
	return;
	@NULL
	CommanderAction
}

function LostTargetLock()
{
	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " lost a lock on its target."));
	HaveTargetLock = false;
	OnLostTargetLock();
	return;
	@NULL
	CommanderAction
}

private function OnGainedTargetLock()
{
	return;
}

private function OnLostTargetLock()
{
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

function float GetCurrentTime()
{
	return MyTurret.Level.TimeSeconds;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
}

function StartFiringWeapon()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x131
	/*@Error*/
	log(,, __NFUN_112__("Started firing weapon owned by ", string(MyTurret)));
	assert(__NFUN_178__(NextCoolTime, GetCurrentTime()));
	MyTurret.GetWeapon().SetNextUsableAttackInfo(0, MyTurret.Rotation, AttackTarget);
	LastTimeStartedFiring = GetCurrentTime();
	CurrentlyFiringWeapon = true;
	MyTurret.StartFiringWeapon();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x125
	/*@Error*/
	MyTurret.PostTurretAttackingNotification(AttackTarget.Location);
	HasPostedEventNotification = true;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function StopFiringWeapon()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x113
	/*@Error*/
	log(,, __NFUN_112__("Stopped firing weapon owned by ", string(MyTurret)));
	MyTurret.StopFiringWeapon();
	CurrentlyFiringWeapon = false;
	// End:0xE6
	if(__NFUN_177__(MyTurret.GetMaximumBurstTime(), 0.0000000))
	{
		NextCoolTime = __NFUN_174__(GetCurrentTime(), __NFUN_171__(__NFUN_172__(__NFUN_175__(GetCurrentTime(), LastTimeStartedFiring), MyTurret.GetMaximumBurstTime()), MyTurret.GetCoolOffTime()));
		goto J0x113;
		NextCoolTime = __NFUN_174__(GetCurrentTime(), MyTurret.GetCoolOffTime());
	}
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting TurretAttackAction::Running."));
	// End:0xD7
	if(ComingFromStandby)
	{
		__NFUN_256__(MyTurret.GetStandbyLightDelay());
		MyTurret.TurnLightsOn();
		__NFUN_256__(MyTurret.GetEngineStartupDelay(AttackTarget));
		MyTurret.StartEngine();
		__NFUN_256__(MyTurret.GetAttackDelay());
		StartAttackMovement();
		MyTurret.SetAttacking();
		__NFUN_113__('NotFiringWeapon');
	}
	stop;				
	@NULL
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/;
}

state NotFiringWeapon
{
	ignores OnSawTarget, OnGainedTargetLock;
Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting TurretAttackAction::NotFiringWeapon."));
	assert(__NFUN_129__(CurrentlyFiringWeapon));
	// End:0x83
	if(__NFUN_130__(HaveTargetLock, TargetIsVisible()))
	{
		__NFUN_113__('FiringWeapon');
		stop;								
	}
	@NULL
	@NULL
	@NULL
}

state FiringWeapon
{
	ignores WaitUntilWeaponIsCool, FireWeapon, OnLostTargetLock;
Begin:

	log('AI_Security', 4, __NFUN_112__(string(m_Pawn), " starting TurretAttackAction::FiringWeapon."));
	// End:0x64
	if(__NFUN_129__(HaveTargetLock))
	{
		__NFUN_113__('NotFiringWeapon');
		yield();
	}
	FireWeapon();
	stop;			
	@NULL
	@NULL
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.TurretAttackGoal'
}