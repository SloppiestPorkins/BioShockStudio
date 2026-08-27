class Rosie extends Protector
	abstract
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

var private RosieMeleeWeapon MeleeWeapon;
var private RosieRangedWeapon RangedWeapon;
var private RosieGrenadeWeapon GrenadeWeapon;
var private RosieThreeSixtyWeapon ThreeSixtyWeapon;
var config Class<RosieMeleeWeapon> MeleeWeaponClass;
var config Class<RosieRangedWeapon> RangedWeaponClass;
var config Class<RosieGrenadeWeapon> GrenadeWeaponClass;
var config Class<RosieThreeSixtyWeapon> ThreeSixtyWeaponClass;

function CharacterAICreated()
{
	super.CharacterAICreated();
	CharacterAI.addAbility_Class(Class'ShockAI.RosieAttackAction');
	CharacterAI.addAbility_Class(Class'ShockAI.ScoopUpGathererAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function CreateWeapons()
{
	assert(__NFUN_119__(MeleeWeaponClass, none));
	assert(__NFUN_119__(RangedWeaponClass, none));
	assert(__NFUN_119__(GrenadeWeaponClass, none));
	assert(__NFUN_119__(ThreeSixtyWeaponClass, none));
	MeleeWeapon = RosieMeleeWeapon(CreateAIWeapon(MeleeWeaponClass));
	assert(__NFUN_119__(MeleeWeapon, none));
	AddAvailableHoldable(MeleeWeapon);
	ThreeSixtyWeapon = RosieThreeSixtyWeapon(CreateAIWeapon(ThreeSixtyWeaponClass));
	assert(__NFUN_119__(ThreeSixtyWeapon, none));
	AddAvailableHoldable(ThreeSixtyWeapon);
	RangedWeapon = RosieRangedWeapon(CreateAIWeapon(RangedWeaponClass));
	assert(__NFUN_119__(RangedWeapon, none));
	AttachToBone(RangedWeapon, RangedWeapon.GetAttachBone(self));
	AddAvailableHoldable(RangedWeapon);
	GrenadeWeapon = RosieGrenadeWeapon(CreateAIWeapon(GrenadeWeaponClass));
	assert(__NFUN_119__(GrenadeWeapon, none));
	AttachToBone(GrenadeWeapon, GrenadeWeapon.GetAttachBone(self));
	AddAvailableHoldable(GrenadeWeapon);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function RosieMeleeWeapon GetMeleeWeapon()
{
	return MeleeWeapon;
	return;
	@NULL
}

function RosieRangedWeapon GetRangedWeapon()
{
	return RangedWeapon;
	return;
	@NULL
}

function RosieGrenadeWeapon GetGrenadeWeapon()
{
	return GrenadeWeapon;
	return;
	@NULL
}

function RosieThreeSixtyWeapon GetThreeSixtyWeapon()
{
	return ThreeSixtyWeapon;
	return;
	@NULL
}

function bool LootSlotLocked()
{
	return __NFUN_129__(ShockPawn(Level.GetLocalPlayerController().Pawn).HasMod('RosieLootSlotUnlocked_Exists'));
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

defaultproperties
{
	MaxDistanceFromGathererWhileSearching=750.0000000
	MoveTargetOutOfTheWayAnimation="MG_PushBackSweep"
	ThreatenAnimations[0]="MG_Threaten_A_agg"
	FinalThreatAnimations[0]="MG_insult_A"
	BeginPrepareVentAnimations[0]="MG_kneelVENTbegin_idle_mid"
	LoopPrepareVentAnimations[0]="MG_kneelVENTloop_idle_mid"
	EndPrepareVentAnimations[0]="MG_kneelVENTend_idle_mid"
	HelpGathererIntoVentAnimations[0]="MG_kneelVENTHelpEnter"
	HelpGathererOutOfVentAnimations[0]="MG_kneelVentHelpExit"
	InitialCallVentAnimations[0]="MG_CallVent"
	SecondaryCallVentAnimations[0]="MG_CallVentAlt_A"
	WaitingForGathererGestureAnimations[0]="MG_gComeHere_A"
	SubsequentWaitingForGathererGestureAnimations[0]="MG_gComeHere_C"
	BashTargetAnimations[0]="MG_PushBack"
	InitialBashPlayerAnimations[0]="MG_PushBack"
	SecondBashPlayerAnimations[0]="MG_PushBack"
	FinalBashPlayerAnimations[0]="MG_PushBack"
	MournGathererAnimations[0]="MG_GathererMourn_A"
	GathererDeathReactionAnimations[0]="MG_GathererMourn_B"
	ComeOnTiredGathererAnimations[0]="MG_gNotTired_A"
	FrustratedAtTiredGathererAnimations[0]="MG_gStillNotTired_A"
	SynchedUnevenSurfaceTiredGathererAnimations[0]="GA_RosieHandOutReaction_B"
	SynchedEvenSurfaceTiredGathererAnimations[0]="GA_RosieHandOutReaction"
	SynchedUnevenSurfaceTiredAnimations[0]="MG_HoldHandOutEndTired_B"
	SynchedEvenSurfaceTiredAnimations[0]="MG_HoldHandOutEndTired"
	ScreamAnimations[0]="MG_GathererMourn_B"
	TransitionToAggressiveAnimation="MG_IdleToAgg"
	TransitionToIdleAnimation="MG_AggToIdle"
	TimeBetweenPickingUpGatherer=500.0000000
	SearchAnimations[0]="MG_Searching_A_agg_mid"
	AttackingVisionDecayTime=5.0000000
	MinDistanceFromLastKnownLocationToLoseTarget=500.0000000
	HitFrontAnimations[0]="MG_hitFWD_A"
	HitFrontAnimations[1]="MG_hitFWD_B"
	HitFrontAnimations[2]="MG_hitFWD_C"
	HitLeftAnimations[0]="MG_hitFWD_A"
	HitLeftAnimations[1]="MG_hitFWD_B"
	HitLeftAnimations[2]="MG_hitFWD_C"
	HitRightAnimations[0]="MG_hitFWD_A"
	HitRightAnimations[1]="MG_hitFWD_B"
	HitRightAnimations[2]="MG_hitFWD_C"
	HitBackAnimations[0]="MG_hitBWD_A"
	HitBackAnimations[1]="MG_hitBWD_B"
	HitFrontDeathAnimations[0]="MG_hitFWD_death"
	HitLeftDeathAnimations[0]="MG_hitFWD_death"
	HitRightDeathAnimations[0]="MG_hitFWD_death"
	HitBackDeathAnimations[0]="MG_hitFWD_death"
	ShockedAnimations[0]="MG_ShockedLOOP"
	PostShatteredAnimations[0]="MG_BreakIce"
	EyeBoneName="eyes"
	bShouldUseLocomotion=true
	bShouldUseFootIKTracker=true
	bShouldUseQuickHitReaction=true
	bCanUseAimPoses=true
	WeaponAimPoseSetupName="FidgetAimPoses"
	bHasRangedAttack=true
	bPrefersRangedAttack=true
	DodgeAnimations[0]="MG_dodgeLEFT_A"
	DodgeAnimations[1]="MG_dodgeRIGHT_A"
	bPlayAnimationInsteadOfRagdollFall=true
	CollisionRadius=70.0000000
	CollisionHeight=80.0000000
	bRotateToDesired=false
}