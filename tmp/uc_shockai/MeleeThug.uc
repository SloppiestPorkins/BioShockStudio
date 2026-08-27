class MeleeThug extends Aggressor
	abstract
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

var config Class<AIMeleeWeapon> MeleeWeaponClass;
var private AIMeleeWeapon MeleeWeapon;
var config Class<AIWeapon> ThreeSixtyWeaponClass;
var config AIWeapon ThreeSixtyWeapon;
var config float ChanceToRunAwayFromDeadlyTarget;
var config float ChanceToRunawayOnDamageFromTarget;
var array<name> UntriggerNonDominantEffectEvents;

function AddInitialKeywords()
{
	super.AddInitialKeywords();
	AddLocomotionKeyword('MeleeThug', Class'ShockAI.ShockAI'.0);
	GetRagdoll().AddRequiredRiseFromRagdollKeyword('MeleeThug');
	return;
	@NULL
	CommanderAction
}

function CharacterAICreated()
{
	super.CharacterAICreated();
	CharacterAI.addAbility_Class(Class'ShockAI.MeleeThugAttackAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function OnAcquiredState(name StateName, Actor Instigator)
{
	super.OnAcquiredState(StateName, Instigator);
	// End:0x6C
	if(__NFUN_254__(StateName, 'Frozen'))
	{
		UnTriggerEffectEvent('MeleeSpark');
		UnTriggerEffectEvent('MeleeSparkHit');
		UnTriggerEffectEvent('MeleeSparkDrag');
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function AIMeleeWeapon GetMeleeWeapon()
{
	return MeleeWeapon;
	return;
	@NULL
}

function AIWeapon GetThreeSixtyWeapon()
{
	return ThreeSixtyWeapon;
	return;
	@NULL
}

function CreateWeapons()
{
	assert(__NFUN_119__(ThreeSixtyWeaponClass, none));
	ThreeSixtyWeapon = CreateAIWeapon(ThreeSixtyWeaponClass);
	AddAvailableHoldable(ThreeSixtyWeapon);
	assert(__NFUN_119__(MeleeWeaponClass, none));
	MeleeWeapon = AIMeleeWeapon(CreateAIWeapon(MeleeWeaponClass));
	AttachToBone(MeleeWeapon, MeleeWeapon.GetAttachBone(self));
	Equip(MeleeWeapon);
	AddAvailableHoldable(MeleeWeapon);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

defaultproperties
{
	ChanceToRunAwayFromDeadlyTarget=0.2500000
	ChanceToRunawayOnDamageFromTarget=0.2500000
	MimicPoseAnimations[0]="ME_PlayDeadBack_Pose"
	MimicPoseAnimations[1]="ME_PlayDeadSitWall_Pose"
	SearchAnimations[0]="ME_Searching"
	AggroDistanceMultiplier=2.0000000
	ResearchTrack="MeleeThug"
	MinDistanceFromLastKnownLocationToLoseTarget=300.0000000
	HitFrontAnimations[0]="ME_hitFWD_A"
	HitFrontAnimations[1]="ME_hitFWD_B"
	HitFrontAnimations[2]="ME_hitFWD_C"
	HitFrontAnimations[3]="ME_hitFWD_D"
	HitLeftAnimations[0]="ME_hitFWD_D"
	HitRightAnimations[0]="ME_hitFWD_D"
	HitBackAnimations[0]="ME_hitBWD_A"
	HitBackAnimations[1]="ME_hitBWD_B"
	HitBackAnimations[2]="ME_hitBWD_C"
	HitBackAnimations[3]="ME_hitBWD_D"
	HitFrontDeathAnimations[0]="ME_hitFWD_D"
	HitFrontDeathAnimations[1]="ME_hitFWD_A"
	HitLeftDeathAnimations[0]="ME_hitFWD_D"
	HitRightDeathAnimations[0]="ME_hitFWD_D"
	HitBackDeathAnimations[0]="ME_hitBWD_D"
	TimeRangeBetweenFullBodyHitReactions=(Min=3.0000000,Max=6.0000000)
	EyeBoneName="eyes"
	bShouldUseLocomotion=true
	bShouldUseFootIKTracker=true
	bShouldUseQuickHitReaction=true
	LocomotionTranslationScaleAgainstPlayer=0.9000000
	DodgeAnimations[0]="ME_dodgeLEFT_A"
	DodgeAnimations[1]="ME_dodgeRIGHT_A"
	DamageResistanceSetName="MeleeThugResistanceSet"
	CollisionRadius=50.0000000
	CollisionHeight=82.0000000
	bRotateToDesired=false
	RequiredAnimationGroups=/* Array type was not detected. */
}