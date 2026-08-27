class BotMiniGun extends BotBaseGun
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced);

defaultproperties
{
	AccuracyRangeVsPlayer=(Min=7.0000000,Max=15.0000000)
	AccuracyChangeTimeRangeVsPlayer=(Min=4.0000000,Max=4.0000000)
	AccuracyRangeVsAI=(Min=0.5000000,Max=1.0000000)
	AccuracyChangeTimeRangeVsAI=(Min=1.0000000,Max=1.0000000)
	AttackAnimationInfos[0]=(AttackAnimation="SecBot_MGFire",Weight=1.0000000,SourceSocketName="None",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	UsesAmmunition=false
	WeaponModel=SkeletalMesh'ShockAI.SecBot_MG.SecBot_MG'
	FiringAnim=/* Array type was not detected. */
	FiringFinalShotAnim=/* Array type was not detected. */
	BaseMagazineSize=10000
	BaseFireRate=3.0000000
	OnFiredEffects=/* Array type was not detected. */
	TracerEffects=/* Array type was not detected. */
	IdlingAnim="SecBot_MGHover"
	AttachBone="MGattach"
	Mesh=SkeletalMesh'ShockAI.SecBot_MG.SecBot_MG'
}