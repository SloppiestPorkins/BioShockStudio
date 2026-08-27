class RangedAggressor extends Aggressor
	abstract
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

var config Class<AIRangedWeapon> RangedWeaponClass;
var private AIRangedWeapon RangedWeapon;
var config Class<AIMeleeWeapon> MeleeWeaponClass;
var private AIMeleeWeapon MeleeWeapon;
var config array<name> ReloadAnimations;

function CreateWeapons()
{
	assert(__NFUN_119__(MeleeWeaponClass, none));
	MeleeWeapon = AIMeleeWeapon(CreateAIWeapon(MeleeWeaponClass));
	AddAvailableHoldable(MeleeWeapon);
	assert(__NFUN_119__(RangedWeaponClass, none));
	RangedWeapon = AIRangedWeapon(CreateAIWeapon(RangedWeaponClass));
	AttachToBone(RangedWeapon, RangedWeapon.GetAttachBone(self));
	AddAvailableHoldable(RangedWeapon);
	Equip(RangedWeapon);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function AIMeleeWeapon GetMeleeWeapon()
{
	return MeleeWeapon;
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
	if(__NFUN_114__(inWeapon, RangedWeapon))
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

function float GetAnimationEaseOutTimeBeforeEndForWeapon(Weapon inWeapon)
{
	// End:0x1D
	if(__NFUN_114__(inWeapon, RangedWeapon))
	{
		return 0.0000000;
		return super(ShockPawn).GetAnimationEaseOutTimeBeforeEndForWeapon(inWeapon);
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function name GetReloadAnimationName()
{
	return ReloadAnimations[__NFUN_167__(ReloadAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

defaultproperties
{
	ResearchTrack="RangedAggressor"
	MinDistanceFromLastKnownLocationToLoseTarget=300.0000000
	EyeBoneName="eyes"
	bShouldUseLocomotion=true
	bShouldUseFootIKTracker=true
	bShouldUseQuickHitReaction=true
	bHasRangedAttack=true
	bPrefersRangedAttack=true
	DamageResistanceSetName="RangedAggressorResistanceSet"
	CollisionRadius=50.0000000
	CollisionHeight=82.0000000
	bRotateToDesired=false
}