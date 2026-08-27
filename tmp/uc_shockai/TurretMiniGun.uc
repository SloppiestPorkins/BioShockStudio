class TurretMiniGun extends AIRangedWeapon
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced);

defaultproperties
{
	AccuracyRangeVsPlayer=(Min=5.0000000,Max=15.0000000)
	AccuracyChangeTimeRangeVsPlayer=(Min=4.0000000,Max=4.0000000)
	AccuracyRangeVsAI=(Min=4.0000000,Max=9.0000000)
	AccuracyChangeTimeRangeVsAI=(Min=2.0000000,Max=2.0000000)
	AttackAnimationInfos[0]=(AttackAnimation="NoAttackAnimation",Weight=1.0000000,SourceSocketName="None",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	WeaponFireStartOffsetType=3
	bUseCachedCanHitRotation=false
	AvailableAmmoTypes=/* Array type was not detected. */
	DefaultAmmoSelection=Class'ShockAI.TurretMiniGunAmmo'
	UsesAmmunition=false
	WeaponModel=SkeletalMesh'ShockAI.NullSkeletalMesh.NullSkeletalMesh'
	DamageEmitterSocket="Barrel"
	FiringAnim=/* Array type was not detected. */
	BaseMagazineSize=10000
	BaseAccuracy=5.0000000
	BaseFireRate=3.0000000
	OnFiredEffects=/* Array type was not detected. */
	TracerEffects=/* Array type was not detected. */
	AttachBone="muzzle"
}