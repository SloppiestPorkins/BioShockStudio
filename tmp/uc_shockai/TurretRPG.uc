class TurretRPG extends AIRangedWeapon
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced);

defaultproperties
{
	AccuracyRangeVsPlayer=(Min=0.7500000,Max=4.0000000)
	AccuracyChangeTimeRangeVsPlayer=(Min=7.0000000,Max=12.0000000)
	AccuracyRangeVsAI=(Min=0.5000000,Max=0.5000000)
	AccuracyChangeTimeRangeVsAI=(Min=0.0000000,Max=0.1000000)
	AttackAnimationInfos[0]=(AttackAnimation="NoAttackAnimation",Weight=1.0000000,SourceSocketName="None",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	WeaponFireStartOffsetType=3
	bUseCachedCanHitRotation=false
	bGetReadyToUseMultiplierFromHolder=true
	AvailableAmmoTypes=/* Array type was not detected. */
	DefaultAmmoSelection=Class'ShockAI.TurretRPGAmmo'
	UsesAmmunition=false
	WeaponModel=SkeletalMesh'ShockAI.NullSkeletalMesh.NullSkeletalMesh'
	DamageEmitterSocket="Socket"
	FiringAnim=/* Array type was not detected. */
	BaseMagazineSize=10000
	AttachBone="muzzle"
}