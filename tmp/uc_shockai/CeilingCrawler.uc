class CeilingCrawler extends Aggressor
	abstract
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

var private bool bCanAttackWithRangedWeapon;
var private CeilingCrawlerMeleeHandWeapon HandWeapon;
var private CeilingCrawlerMeleeSlashWeapon SlashWeapon;
var private CeilingCrawlerMeleeFootWeapon KickWeapon;
var private AIRangedWeapon RangedWeapon;
var private int BackpackOnAnimationHandle;
var private config name BackpackOnAnimationName;
var private config Class<AIMeleeWeapon> HandWeaponClass;
var private config Class<AIMeleeWeapon> SlashWeaponClass;
var private config Class<AIMeleeWeapon> KickWeaponClass;
var private config Class<AIRangedWeapon> RangedWeaponClass;
var private config name CrushAIDamageStimuliSetName;
var config array<name> CeilingShockedAnimations;

function PostBeginPlay()
{
	super(ShockAI).PostBeginPlay();
	PlayBackpackOnAnimation();
	return;
	@NULL
}

function AddInitialKeywords()
{
	super.AddInitialKeywords();
	AddLocomotionKeyword('CeilingCrawler', Class'ShockAI.ShockAI'.0);
	GetRagdoll().AddRequiredRiseFromRagdollKeyword('CeilingCrawler');
	return;
	@NULL
	CommanderAction
}

function PlayBackpackOnAnimation()
{
	BackpackOnAnimationHandle = PlayAnimationOnChannel(5, BackpackOnAnimationName, 8);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
}

function EaseOutBackpackOnAnimation()
{
	// End:0x2E
	if(IsAnimationHandleValid(BackpackOnAnimationHandle))
	{
		FlatEaseOutAnimation(BackpackOnAnimationHandle, 0.2500000);
		return;
		@NULL
		CommanderAction
		EcologyFighterCommanderAction
	}
	@NULL
}

function name GetShockedAnimation()
{
	// End:0x27
	if(IsOnCeiling())
	{
		return CeilingShockedAnimations[__NFUN_167__(CeilingShockedAnimations.Length)];
		goto J0x32;
		return super(ShockAI).GetShockedAnimation();
		return;
	}
	@NULL
	CommanderAction
	J0x32:

	CommanderAction
}

function CharacterAICreated()
{
	super.CharacterAICreated();
	AddAttackAbility();
	return;
	@NULL
}

function AddAttackAbility()
{
	CharacterAI.addAbility_Class(Class'ShockAI.CeilingCrawlerAttackAction');
	CharacterAI.addAbility_Class(Class'ShockAI.JumpToCeilingAction');
	CharacterAI.addAbility_Class(Class'ShockAI.JumpToFloorAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function OnDealtDamage(DamageStimuliSet DamageStimuli, float TotalDamageDealt, Actor Damagee, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, bool bIsCriticalHit, optional name HitHighBone, optional name HitLowBone)
{
	super(ShockAI).OnDealtDamage(DamageStimuli, TotalDamageDealt, Damagee, HitLocation, HitNormal, HitImpulseDirection, EffectEventName, bIsCriticalHit, HitHighBone, HitLowBone);
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function CreateWeapons()
{
	assert(__NFUN_119__(HandWeaponClass, none));
	HandWeapon = CeilingCrawlerMeleeHandWeapon(CreateAIWeapon(HandWeaponClass));
	AddAvailableHoldable(HandWeapon);
	assert(__NFUN_119__(SlashWeaponClass, none));
	SlashWeapon = CeilingCrawlerMeleeSlashWeapon(CreateAIWeapon(SlashWeaponClass));
	AddAvailableHoldable(SlashWeapon);
	assert(__NFUN_119__(KickWeaponClass, none));
	KickWeapon = CeilingCrawlerMeleeFootWeapon(CreateAIWeapon(KickWeaponClass));
	AddAvailableHoldable(KickWeapon);
	assert(__NFUN_119__(RangedWeaponClass, none));
	RangedWeapon = AIRangedWeapon(CreateAIWeapon(RangedWeaponClass));
	AddAvailableHoldable(RangedWeapon);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function CeilingCrawlerMeleeHandWeapon GetHandWeapon()
{
	return HandWeapon;
	return;
	@NULL
}

function CeilingCrawlerMeleeSlashWeapon GetSlashWeapon()
{
	return SlashWeapon;
	return;
	@NULL
}

function CeilingCrawlerMeleeFootWeapon GetKickWeapon()
{
	return KickWeapon;
	return;
	@NULL
}

function AIRangedWeapon GetRangedWeapon()
{
	return RangedWeapon;
	return;
	@NULL
}

function float GetAnimationTweenTimeForWeapon(Weapon inWeapon)
{
	// End:0x1D
	if(__NFUN_114__(inWeapon, KickWeapon))
	{
		return 0.0000000;
		return super(ShockPawn).GetAnimationTweenTimeForWeapon(inWeapon);
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function SetCanAttackWithRangedWeapon(bool inCanAttackWithRangedWeapon)
{
	bCanAttackWithRangedWeapon = inCanAttackWithRangedWeapon;
	return;
	@NULL
	CommanderAction
}

function bool CanAttackTargetWithRangedWeapon(ShockPawn Target)
{
	return __NFUN_132__(bCanAttackWithRangedWeapon, __NFUN_130__(__NFUN_119__(Target, none), __NFUN_129__(Target.__NFUN_303__('ShockPlayer'))));
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function bool CrushPawn(Pawn Target)
{
	local Vector HitLocation, HitNormal, HitImpulseDir;
	local DamageStimuliSet DamageSet;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x12C
	/*@Error*/
	HitLocation = Location;
	__NFUN_185__(HitLocation.Z, CollisionHeight);
	HitNormal = __NFUN_226__(__NFUN_216__(Location, Target.Location));
	HitImpulseDir = __NFUN_211__(HitNormal);
	DamageSet = Class'Engine.DamageStimuliSet'.static.GetDamageStimuliSet(CrushAIDamageStimuliSetName);
	ShockAI(Target).Fall(HitLocation, HitNormal, HitImpulseDir, 0.0000000, 'None', 'None', DamageSet);
	DamageSet.__NFUN_200__();
	return true;
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	bCanAttackWithRangedWeapon=true
	CrushAIDamageStimuliSetName="CrushAIDamageStimuliSet"
	MimicPoseAnimations[0]="CR_PlayDeadBack_POSE"
	MimicPoseAnimations[1]="CR_PlayDeadStomach_POSE"
	SearchAnimations[0]="CR_Searching"
	FriendlyName="Spider Splicer"
	ResearchTrack="CeilingCrawler"
	NormalVisionDecayTime=1.0000000
	SearchingVisionDecayTime=1.0000000
	AttackingVisionDecayTime=3.0000000
	CeilingVisionDecayTime=10.0000000
	MinDistanceFromLastKnownLocationToLoseTarget=300.0000000
	CeilingVisionCones[0]=(NearGainTime=0.1000000,FarGainTime=0.1000000,FOV=360.0000000,NearDistance=1000.0000000,FarDistance=3500.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=-3641,Yaw=0,Roll=0),PawnType=none)
	CeilingVisionCones[1]=(NearGainTime=0.2000000,FarGainTime=0.2000000,FOV=360.0000000,NearDistance=1000.0000000,FarDistance=1000.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=32768,Roll=0),PawnType=none)
	HitFrontAnimations[0]="CR_hitFWD_D"
	HitLeftAnimations[0]="CR_hitLEFT_C"
	HitRightAnimations[0]="CR_hitRIGHT_C"
	HitBackAnimations[0]="CR_hitBWD_C"
	CeilingHitFrontAnimations[0]="CR_hitFWD_A_ceiling"
	CeilingHitLeftAnimations[0]="CR_hitFWD_A_ceiling"
	CeilingHitRightAnimations[0]="CR_hitFWD_A_ceiling"
	CeilingHitBackAnimations[0]="CR_hitFWD_A_ceiling"
	HitFrontDeathAnimations[0]="Death_SpinLeft"
	HitFrontDeathAnimations[1]="Death_StumbleBWD"
	HitLeftDeathAnimations[0]="CR_hitLEFT_C"
	HitRightDeathAnimations[0]="CR_hitRIGHT_C"
	HitBackDeathAnimations[0]="Death_StumbleFWD"
	EyeBoneName="eyes"
	bShouldUseLocomotion=true
	bShouldUseFootIKTracker=true
	bShouldUseQuickHitReaction=true
	bHasRangedAttack=true
	DamageResistanceSetName="CeilingCrawlerResistanceSet"
	HealthBarNormalOffset=(X=0.0000000,Y=0.0000000,Z=60.0000000)
	HealthBarCeilingOffset=(X=0.0000000,Y=0.0000000,Z=-10.0000000)
	bCanUseCeiling=true
	CollisionRadius=40.0000000
	CollisionHeight=78.0000000
	bRotateToDesired=false
	RequiredAnimationGroups=/* Array type was not detected. */
}