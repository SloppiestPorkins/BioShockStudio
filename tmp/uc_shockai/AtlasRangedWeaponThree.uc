class AtlasRangedWeaponThree extends AIRangedWeapon
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced);

defaultproperties
{
	AccuracyRangeVsPlayer=(Min=0.7500000,Max=4.0000000)
	AccuracyChangeTimeRangeVsPlayer=(Min=7.0000000,Max=12.0000000)
	AccuracyRangeVsAI=(Min=0.5000000,Max=0.5000000)
	AttackAnimationInfos[0]=(AttackAnimation="AT_AttackRanged_Electric",Weight=1.0000000,SourceSocketName="Bip01_R_Hand",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	WeaponFireStartOffsetType=3
	WeaponFireStartRotationType=2
	BaseMinTimeBetweenUsage=2.5000000
	BaseMaxTimeBetweenUsage=3.0000000
	AvailableAmmoTypes=/* Array type was not detected. */
	DefaultAmmoSelection=Class'ShockAI.AtlasRangedWeaponAmmoThree'
	UsesAmmunition=false
}