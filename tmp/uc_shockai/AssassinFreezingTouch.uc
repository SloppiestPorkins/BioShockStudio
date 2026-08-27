class AssassinFreezingTouch extends AIMeleeWeapon
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced);

defaultproperties
{
	AttackAnimationInfos[0]=(AttackAnimation="ME_attackMelee_F",Weight=1.0000000,SourceSocketName="None",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	BaseMinTimeBetweenUsage=0.2500000
	BaseMaxTimeBetweenUsage=0.5000000
	AvailableAmmoTypes=/* Array type was not detected. */
	DefaultAmmoSelection=Class'ShockAI.AssassinFreezingTouchAmmo'
	UsesAmmunition=false
}