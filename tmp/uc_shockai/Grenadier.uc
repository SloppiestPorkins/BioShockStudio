class Grenadier extends Aggressor
	abstract
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

enum ESpecialCommitSuicideState
{
	kNoState,                       // 0
	kCommitSuicideImmediately,      // 1
	kMoveToCommitSuicide            // 2
};

var private bool bCommittedSuicide;
var private Grenadier.ESpecialCommitSuicideState SpecialCommitSuicideState;
var private bool bHasCheckedToCommitSuicide;
var private bool bChoseToMoveToCommitSuicide;
var private GrenadierGrenadeWeapon GrenadeWeapon;
var private GrenadierMeleeWeapon MeleeWeapon;
var private GrenadierSuicideWeapon SuicideWeapon;
var private GrenadierSmokeGrenadeWeapon SmokeGrenadeWeapon;
var private GrenadierLiveGrenadeWeapon LiveGrenadeWeapon;
var config Class<GrenadierGrenadeWeapon> GrenadeWeaponClass;
var config Class<GrenadierMeleeWeapon> MeleeWeaponClass;
var config Class<GrenadierSuicideWeapon> SuicideWeaponClass;
var config Class<GrenadierSmokeGrenadeWeapon> SmokeGrenadeWeaponClass;
var config Class<GrenadierLiveGrenadeWeapon> LiveGrenadeWeaponClass;
var private config float DamagePercentageToUseSuicideWeapon;
var private config float ChanceToMoveToUseSuicideWeapon;

function AddInitialKeywords()
{
	super.AddInitialKeywords();
	AddLocomotionKeyword('Grenadier', Class'ShockAI.ShockAI'.0);
	GetRagdoll().AddRequiredRiseFromRagdollKeyword('Grenadier');
	return;
	@NULL
	CommanderAction
}

function CharacterAICreated()
{
	super.CharacterAICreated();
	CharacterAI.addAbility_Class(Class'ShockAI.GrenadierAttackAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function bool CanDouse()
{
	return __NFUN_130__(__NFUN_130__(__NFUN_119__(GetActiveHoldable(), SuicideWeapon), __NFUN_129__(HasSpecialCommitSuicideState())), super(EcologyAI).CanDouse());
	return;
	@NULL
	CommanderAction
}

function bool CanHealAtHealthStation()
{
	return __NFUN_130__(__NFUN_119__(GetActiveHoldable(), SuicideWeapon), __NFUN_129__(HasSpecialCommitSuicideState()));
	return;
	@NULL
}

function OnDamaged(DamageStimuliSet DamageStimuli, float TotalDamageDealt, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, bool bIsCriticalHit, optional name HitHighBone, optional name HitLowBone)
{
	super(ShockAI).OnDamaged(DamageStimuli, TotalDamageDealt, Damager, HitLocation, HitNormal, HitImpulseDirection, EffectEventName, bIsCriticalHit, HitHighBone, HitLowBone);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xC6
	/*@Error*/
	bHasCheckedToCommitSuicide = true;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xC6
	/*@Error*/
	SpecialCommitSuicideState = 2;
	bChoseToMoveToCommitSuicide = true;
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function OnKilled(DamageStimuliSet DamageStimuli, float TotalDamageDealt, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, bool bIsCriticalHit, optional name HitHighBone, optional name HitLowBone)
{
	// End:0xAF
	if(__NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_114__(Damager, self), __NFUN_119__(SuicideWeapon, none)), __NFUN_119__(SuicideWeapon.GetCurrentAmmoSelection(), none)), __NFUN_254__(SuicideWeapon.static.GetCurrentAmmoSelection().default.DamageStimuliSetName, DamageStimuli.GetStimuliSetName())))
	{
		TriggerEffectEvent('CommittedSuicide');
		bCommittedSuicide = true;
		LifeSpan = 0.1000000;
		super.OnKilled(DamageStimuli, TotalDamageDealt, Damager, HitLocation, HitNormal, HitImpulseDirection, EffectEventName, bIsCriticalHit, HitHighBone, HitLowBone);
	}
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function bool ShouldDropWeaponsOnDeath()
{
	return __NFUN_129__(bCommittedSuicide);
	return;
	@NULL
}

function GrenadierMeleeWeapon GetMeleeWeapon()
{
	return MeleeWeapon;
	return;
	@NULL
}

function GrenadierGrenadeWeapon GetGrenadeWeapon()
{
	return GrenadeWeapon;
	return;
	@NULL
}

function GrenadierSuicideWeapon GetSuicideWeapon()
{
	return SuicideWeapon;
	return;
	@NULL
}

function GrenadierSmokeGrenadeWeapon GetSmokeGrenadeWeapon()
{
	return SmokeGrenadeWeapon;
	return;
	@NULL
}

function GrenadierLiveGrenadeWeapon GetLiveGrenadeWeapon()
{
	return LiveGrenadeWeapon;
	return;
	@NULL
}

function CreateWeapons()
{
	assert(__NFUN_119__(GrenadeWeaponClass, none));
	GrenadeWeapon = GrenadierGrenadeWeapon(CreateAIWeapon(GrenadeWeaponClass));
	AttachToBone(GrenadeWeapon, GrenadeWeapon.GetAttachBone(self));
	AddAvailableHoldable(GrenadeWeapon);
	assert(__NFUN_119__(MeleeWeaponClass, none));
	MeleeWeapon = GrenadierMeleeWeapon(CreateAIWeapon(MeleeWeaponClass));
	AddAvailableHoldable(MeleeWeapon);
	assert(__NFUN_119__(SuicideWeaponClass, none));
	SuicideWeapon = GrenadierSuicideWeapon(CreateAIWeapon(SuicideWeaponClass));
	AddAvailableHoldable(SuicideWeapon);
	assert(__NFUN_119__(SmokeGrenadeWeaponClass, none));
	SmokeGrenadeWeapon = GrenadierSmokeGrenadeWeapon(CreateAIWeapon(SmokeGrenadeWeaponClass));
	AttachToBone(SmokeGrenadeWeapon, GrenadeWeapon.GetAttachBone(self));
	AddAvailableHoldable(SmokeGrenadeWeapon);
	assert(__NFUN_119__(LiveGrenadeWeaponClass, none));
	LiveGrenadeWeapon = GrenadierLiveGrenadeWeapon(CreateAIWeapon(LiveGrenadeWeaponClass));
	AttachToBone(LiveGrenadeWeapon, GrenadeWeapon.GetAttachBone(self));
	AddAvailableHoldable(LiveGrenadeWeapon);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function bool ShouldCommittSuicideImmediately()
{
	return __NFUN_154__(int(SpecialCommitSuicideState), int(1));
	return;
	@NULL
}

function bool ShouldRunToCommitSuicideImmediately()
{
	return __NFUN_154__(int(SpecialCommitSuicideState), int(2));
	return;
	@NULL
}

function bool HasSpecialCommitSuicideState()
{
	return __NFUN_155__(int(SpecialCommitSuicideState), int(0));
	return;
	@NULL
}

function bool IsBelowHealthThresholdForSuicide()
{
	return __NFUN_176__(__NFUN_172__(Health, GetMaxHealth()), DamagePercentageToUseSuicideWeapon);
	return;
	@NULL
	CommanderAction
}

function bool ChoseToMoveToCommitSuicide()
{
	return bChoseToMoveToCommitSuicide;
	return;
	@NULL
}

function CancelSpecialCommitSuicideState()
{
	SpecialCommitSuicideState = 0;
	return;
	@NULL
}

function bool IsReadyForSuicideAttack()
{
	return __NFUN_132__(HasSpecialCommitSuicideState(), IsBelowHealthThresholdForSuicide());
	return;
}

function SetSpecialCommitSuicideState(Grenadier.ESpecialCommitSuicideState inSpecialCommitSuicideState)
{
	SpecialCommitSuicideState = inSpecialCommitSuicideState;
	return;
	@NULL
	CommanderAction
}

function UseLiveGrenadeWeapon()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x8F
	/*@Error*/
	LiveGrenadeWeapon.SetNextUsableAttackInfo(0, Rotator(__NFUN_211__(__NFUN_226__(PhysicsVolume.Gravity))), GetAttackTarget());
	// End:0x78
	if(__NFUN_119__(GetActiveHoldable(), LiveGrenadeWeapon))
	{
		Equip(LiveGrenadeWeapon);
		LiveGrenadeWeapon.BeginFiring();
		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

function HideGrenade()
{
	GrenadeWeapon.SetHidden(true);
	return;
	@NULL
	CommanderAction
}

function ShowGrenade()
{
	GrenadeWeapon.SetHidden(false);
	return;
	@NULL
	CommanderAction
}

defaultproperties
{
	MimicPoseAnimations[0]="GR_PlayDeadBack_Pose"
	MimicPoseAnimations[1]="GR_PlayDeadStomach_Pose"
	SearchAnimations[0]="GR_Searching_A"
	ResearchTrack="Grenadier"
	MinDistanceFromLastKnownLocationToLoseTarget=300.0000000
	HitFrontAnimations[0]="GR_hitFWD_A"
	HitFrontAnimations[1]="GR_hitFWD_B"
	HitFrontAnimations[2]="GR_hitFWD_D"
	HitLeftAnimations[0]="GR_hitLEFT_A"
	HitLeftAnimations[1]="GR_hitLEFT_C"
	HitLeftAnimations[2]="GR_hitLEFT_D"
	HitRightAnimations[0]="GR_hitRIGHT_A"
	HitRightAnimations[1]="GR_hitRIGHT_D"
	HitBackAnimations[0]="GR_hitBWD_A"
	HitBackAnimations[1]="GR_hitBWD_C"
	HitBackAnimations[2]="GR_hitBWD_D"
	HitFrontDeathAnimations[0]="GR_hitFWD_A"
	HitFrontDeathAnimations[1]="GR_hitFWD_B"
	HitLeftDeathAnimations[0]="GR_hitLEFT_A"
	HitRightDeathAnimations[0]="GR_hitRIGHT_A"
	HitBackDeathAnimations[0]="GR_hitBWD_A"
	HitBackDeathAnimations[1]="GR_hitBWD_D"
	EyeBoneName="eyes"
	bShouldUseLocomotion=true
	bShouldUseFootIKTracker=true
	bShouldUseQuickHitReaction=true
	bHasRangedAttack=true
	bPrefersRangedAttack=true
	PlayerUsingTelekinesisReadyToUseMultiplier=2.0000000
	DodgeAnimations[0]="GR_dodgeLEFT_A"
	DodgeAnimations[1]="GR_dodgeLEFT_B"
	DodgeAnimations[2]="GR_dodgeRIGHT_A"
	DodgeAnimations[3]="GR_dodgeRIGHT_B"
	DamageResistanceSetName="GrenadierResistanceSet"
	CollisionRadius=50.0000000
	CollisionHeight=86.0000000
	bRotateToDesired=false
	RequiredAnimationGroups=/* Array type was not detected. */
}