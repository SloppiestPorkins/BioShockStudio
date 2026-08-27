class Bouncer extends Protector implements IFilterDamageTargets
	abstract
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

var private float NextTimeCanUseStunAttack;
var private bool bCanStepBack;
var private BouncerMeleeHandWeapon HandWeapon;
var private BouncerShoulderWeapon ShoulderWeapon;
var private BouncerThreeSixtyWeapon ThreeSixtyWeapon;
var config Class<BouncerMeleeHandWeapon> BouncerMeleeHandWeaponClass;
var config Class<BouncerShoulderWeapon> BouncerMeleeShoulderWeaponClass;
var config Class<BouncerThreeSixtyWeapon> BouncerThreeSixtyWeaponClass;
var private config name DrillSpinAnimation;
var private int DrillSpinAnimationHandle;
var array<Actor> DamagedByShoulderWeapon;
var private config name ShoulderWeaponEffectEvent;

function CharacterAICreated()
{
	super.CharacterAICreated();
	CharacterAI.addAbility_Class(Class'ShockAI.BouncerAttackAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function OnBecameAggressive()
{
	PlayDrillSpinAnimation();
	return;
}

function OnBecamePassive()
{
	super.OnBecamePassive();
	EaseOutDrillSpinAnimation();
	return;
	@NULL
}

function PlayDrillSpinAnimation()
{
	DrillSpinAnimationHandle = PlayAnimationOnChannel(3, DrillSpinAnimation, 8);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
}

function EaseOutDrillSpinAnimation()
{
	// End:0x2E
	if(IsAnimationHandleValid(DrillSpinAnimationHandle))
	{
		FlatEaseOutAnimation(DrillSpinAnimationHandle, 0.2500000);
		return;
		@NULL
		CommanderAction
		EcologyFighterCommanderAction
	}
	@NULL
}

function float GetNextTimeCanUseStunAttack()
{
	return NextTimeCanUseStunAttack;
	return;
	@NULL
}

function SetNextTimeCanUseStunAttack(float inNextTimeCanUseStunAttack)
{
	NextTimeCanUseStunAttack = inNextTimeCanUseStunAttack;
	return;
	@NULL
	CommanderAction
}

function CreateWeapons()
{
	assert(__NFUN_119__(BouncerMeleeHandWeaponClass, none));
	assert(__NFUN_119__(BouncerMeleeShoulderWeaponClass, none));
	assert(__NFUN_119__(BouncerThreeSixtyWeaponClass, none));
	HandWeapon = BouncerMeleeHandWeapon(CreateAIWeapon(BouncerMeleeHandWeaponClass));
	ShoulderWeapon = BouncerShoulderWeapon(CreateAIWeapon(BouncerMeleeShoulderWeaponClass));
	ThreeSixtyWeapon = BouncerThreeSixtyWeapon(CreateAIWeapon(BouncerThreeSixtyWeaponClass));
	AddAvailableHoldable(HandWeapon);
	AddAvailableHoldable(ShoulderWeapon);
	AddAvailableHoldable(ThreeSixtyWeapon);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function BouncerMeleeHandWeapon GetHandWeapon()
{
	return HandWeapon;
	return;
	@NULL
}

function BouncerShoulderWeapon GetShoulderWeapon()
{
	return ShoulderWeapon;
	return;
	@NULL
}

function BouncerThreeSixtyWeapon GetThreeSixtyWeapon()
{
	return ThreeSixtyWeapon;
	return;
	@NULL
}

function bool ShouldDamageTarget(Actor Target)
{
	//native.Target;	
	@NULL
}

function NotifyHitTarget(Actor Target)
{
	//native.Target;	
	@NULL
}

function OnFiringStarted(Weapon theWeapon)
{
	super(ShockPawn).OnFiringStarted(theWeapon);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x3F
	/*@Error*/
	DamagedByShoulderWeapon.Remove(0, DamagedByShoulderWeapon.Length);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool HitTargetWithShoulderWeapon(Actor Target)
{
	//native.Target;	
	@NULL
}

function SetStepBack(bool inCanStepBack)
{
	bCanStepBack = inCanStepBack;
	return;
	@NULL
	CommanderAction
}

function bool CanStepBack()
{
	return bCanStepBack;
	return;
	@NULL
}

defaultproperties
{
	bCanStepBack=true
	DrillSpinAnimation="BO_DrillSpin"
	ShoulderWeaponEffectEvent="BigKnockDown"
	DistanceToPickUpGatherer=104.0000000
	DistanceGathererWillJumpOff=184.0000000
	HeightGathererWillJumpOff=125.1999969
	MoveTargetOutOfTheWayAnimation="BO_PushBackSweep"
	ThreatenAnimations[0]="BO_Threaten_D"
	ThreatenAnimations[1]="BO_Threaten_B"
	FinalThreatAnimations[0]="BO_insult_A"
	BeginPrepareVentAnimations[0]="None"
	LoopPrepareVentAnimations[0]="None"
	EndPrepareVentAnimations[0]="None"
	HelpGathererIntoVentAnimations[0]="BO_kneelVentHelpEnter"
	HelpGathererOutOfVentAnimations[0]="BO_kneelVentHelpExit"
	InitialCallVentAnimations[0]="BO_CallVent"
	SecondaryCallVentAnimations[0]="BO_CallVentAlt_A"
	WaitingForGathererGestureAnimations[0]="BO_gBigShrug"
	SubsequentWaitingForGathererGestureAnimations[0]="BO_gComeHere_A"
	BashTargetAnimations[0]="BO_PushBack"
	InitialBashPlayerAnimations[0]="BO_PushBack"
	SecondBashPlayerAnimations[0]="BO_PushBack"
	FinalBashPlayerAnimations[0]="BO_PushBack"
	MournGathererAnimations[0]="BO_GathererMourn_A"
	ComeOnTiredGathererAnimations[0]="BO_gNotTired_A"
	FrustratedAtTiredGathererAnimations[0]="BO_gStillNotTired_A"
	SynchedUnevenSurfaceTiredGathererAnimations[0]="GA_RosieHandOutReaction_B"
	SynchedEvenSurfaceTiredGathererAnimations[0]="GA_RosieHandOutReaction"
	SynchedUnevenSurfaceTiredAnimations[0]="BO_HoldHandOutEndTired_B"
	SynchedEvenSurfaceTiredAnimations[0]="BO_HoldHandOutEndTired"
	PickUpGathererAnimations[0]="BO_GathererToss"
	GathererPickedUpAnimations[0]="GA_BouncerToss"
	GathererJumpOffAnimations[0]="GA_ProBouncerGathererRelease_B"
	ReleaseGathererAnimations[0]="BO_GathererRelease_B"
	StunnedGathererLoopingAnimations[0]="BO_ReactStunnedGA"
	ScreamAnimations[0]="BO_Threaten_D"
	WaitToPickUpGathererAnimations[0]="BO_gathererWaitForToss"
	TransitionToAggressiveAnimation="BO_IdleToAgg"
	TransitionToIdleAnimation="BO_AggToIdle"
	GathererAttachedBoneName="SocketGatherer"
	TimeBetweenPickingUpGatherer=300.0000000
	SearchAnimations[0]="BO_Guard_A"
	AggroDistanceMultiplier=2.0000000
	MinDistanceFromLastKnownLocationToLoseTarget=500.0000000
	HitFrontAnimations[0]="BO_hitFWD_A"
	HitFrontAnimations[1]="BO_hitFWD_B"
	HitLeftAnimations[0]="BO_hitFWD_A"
	HitLeftAnimations[1]="BO_hitLEFT_B"
	HitRightAnimations[0]="BO_hitFWD_A"
	HitRightAnimations[1]="BO_hitRIGHT_B"
	HitBackAnimations[0]="BO_hitBWD_A"
	HitBackAnimations[1]="BO_hitBWD_B"
	HitFrontDeathAnimations[0]="BO_hitFWD_A"
	HitFrontDeathAnimations[1]="BO_hitFWD_B"
	HitLeftDeathAnimations[0]="BO_hitLEFT_B"
	HitRightDeathAnimations[0]="BO_hitRIGHT_B"
	HitBackDeathAnimations[0]="BO_hitBWD_B"
	ShockedAnimations[0]="BO_ShockedLOOP"
	PostShatteredAnimations[0]="BO_BreakIce"
	bShouldUseLocomotion=true
	bShouldUseFootIKTracker=true
	bShouldUseQuickHitReaction=true
	bCanUseAimPoses=true
	WeaponAimPoseSetupName="AggressiveAim"
	LocomotionTranslationScaleAgainstPlayer=0.9000000
	bPlayAnimationInsteadOfRagdollFall=true
	HealthBarNormalOffset=(X=0.0000000,Y=0.0000000,Z=120.0000000)
	CollisionRadius=70.0000000
	CollisionHeight=85.0000000
	bRotateToDesired=false
}