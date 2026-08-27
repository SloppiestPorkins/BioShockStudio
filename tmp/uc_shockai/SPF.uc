class SPF extends Protector
	abstract
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

var SPFRangedWeapon RangedWeapon;
var SPFMeleeWeapon MeleeWeapon;
var config Class<SPFMeleeWeapon> MeleeWeaponClass;
var config Class<SPFRangedWeapon> RangedWeaponClass;

function CharacterAICreated()
{
	super.CharacterAICreated();
	CharacterAI.addAbility_Class(Class'ShockAI.SPFAttackAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function AddInitialKeywords()
{
	super.AddInitialKeywords();
	AddLocomotionKeyword('Kneeling', -1);
	return;
	@NULL
}

function CreateWeapons()
{
	assert(__NFUN_119__(RangedWeaponClass, none));
	assert(__NFUN_119__(MeleeWeaponClass, none));
	RangedWeapon = __NFUN_278__(RangedWeaponClass, self);
	MeleeWeapon = __NFUN_278__(MeleeWeaponClass, self);
	AddAvailableHoldable(RangedWeapon);
	AddAvailableHoldable(MeleeWeapon);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function SPFRangedWeapon GetRangedWeapon()
{
	return RangedWeapon;
	return;
	@NULL
}

function SPFMeleeWeapon GetMeleeWeapon()
{
	return MeleeWeapon;
	return;
	@NULL
}

defaultproperties
{
	DistanceToPickUpGatherer=162.4519958
	ThreatenAnimations[0]="SP_Threaten_A"
	FinalThreatAnimations[0]="SP_insult_A"
	BeginPrepareVentAnimations[0]="None"
	LoopPrepareVentAnimations[0]="None"
	EndPrepareVentAnimations[0]="None"
	GathererPreEnterAnimations[0]="SP_gNoProblem_A"
	HelpGathererIntoVentAnimations[0]="SP_kneelVentHelpEnter"
	HelpGathererOutOfVentAnimations[0]="SP_kneelVentHelpExit"
	InitialCallVentAnimations[0]="SP_CallVent"
	SecondaryCallVentAnimations[0]="SP_CallVentAlt_A"
	WaitingForGathererGestureAnimations[0]="SP_gComeHere_A"
	SubsequentWaitingForGathererGestureAnimations[0]="SP_gComeHere_A"
	BashTargetAnimations[0]="SP_pushBack_A"
	InitialBashPlayerAnimations[0]="SP_pushBack_A"
	SecondBashPlayerAnimations[0]="SP_pushBack_A"
	FinalBashPlayerAnimations[0]="SP_pushBack_A"
	MournGathererAnimations[0]="SP_GathererMourn_A"
	ComeOnTiredGathererAnimations[0]="SP_gNotTired_A"
	FrustratedAtTiredGathererAnimations[0]="SP_gStillNotTired_A"
	SynchedUnevenSurfaceTiredGathererAnimations[0]="GA_RosieHandOutReaction_B"
	SynchedEvenSurfaceTiredGathererAnimations[0]="GA_RosieHandOutReaction"
	SynchedUnevenSurfaceTiredAnimations[0]="SP_HoldHandOutEndTired_B"
	SynchedEvenSurfaceTiredAnimations[0]="SP_HoldHandOutEndTired_A"
	PickUpGathererAnimations[0]="SP_GathererToss"
	GathererPickedUpAnimations[0]="GA_SloProToss"
	GathererJumpOffAnimations[0]="GA_jumpOffSPF"
	ScreamAnimations[0]="SP_insult_A"
	GathererAttachedBoneName="GathererAttach"
	AttackingVisionDecayTime=5.0000000
	MinDistanceFromLastKnownLocationToLoseTarget=300.0000000
	NormalVisionCones[0]=(NearGainTime=0.1000000,FarGainTime=1.0000000,FOV=90.0000000,NearDistance=1200.0000000,FarDistance=1200.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=-3641,Yaw=0,Roll=0),PawnType=none)
	NormalVisionCones[1]=(NearGainTime=0.1000000,FarGainTime=1.0000000,FOV=50.0000000,NearDistance=2000.0000000,FarDistance=3500.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=-3641,Yaw=0,Roll=0),PawnType=none)
	SearchingVisionCones[0]=(NearGainTime=0.1000000,FarGainTime=1.0000000,FOV=120.0000000,NearDistance=1200.0000000,FarDistance=1200.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=-3641,Yaw=0,Roll=0),PawnType=none)
	SearchingVisionCones[1]=(NearGainTime=0.1000000,FarGainTime=1.0000000,FOV=70.0000000,NearDistance=2000.0000000,FarDistance=3500.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=-3641,Yaw=0,Roll=0),PawnType=none)
	AttackingVisionCones[0]=(NearGainTime=0.1000000,FarGainTime=0.1000000,FOV=180.0000000,NearDistance=1000.0000000,FarDistance=3500.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=-3641,Yaw=0,Roll=0),PawnType=none)
	AttackingVisionCones[1]=(NearGainTime=0.2000000,FarGainTime=0.2000000,FOV=180.0000000,NearDistance=1000.0000000,FarDistance=1000.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=32768,Roll=0),PawnType=none)
	AttackingVisionCones[2]=(NearGainTime=0.1000000,FarGainTime=0.1000000,FOV=360.0000000,NearDistance=1000.0000000,FarDistance=3500.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=Class'ShockAI.ShockAI')
	HitFrontAnimations[0]="SP_hitFWD_A"
	HitLeftAnimations[0]="SP_hitLEFT_A"
	HitRightAnimations[0]="SP_hitRIGHT_A"
	HitBackAnimations[0]="SP_hitBWD_A"
	ShockedAnimations[0]="SP_ShockedLOOP"
	EyeBoneName="eyes"
	bShouldUseLocomotion=true
	bShouldUseFootIKTracker=true
	bShouldUseQuickHitReaction=true
	bCanUseAimPoses=true
	WeaponAimPoseSetupName="AttackRangedAimposes"
	bHasRangedAttack=true
	bPrefersRangedAttack=true
	bPlayAnimationInsteadOfRagdollFall=true
	CollisionRadius=70.0000000
	CollisionHeight=85.0000000
	bRotateToDesired=false
}