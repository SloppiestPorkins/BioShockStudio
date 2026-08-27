class RangedAggressorPistolMeleeWeapon extends AIMeleeWeapon
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced);

defaultproperties
{
	AttackAnimationInfos[0]=(AttackAnimation="PI_AttackMelee_A",Weight=1.0000000,SourceSocketName="None",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	AttackAnimationInfos[1]=(AttackAnimation="PI_AttackMelee_B",Weight=1.0000000,SourceSocketName="None",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	AttackAnimationInfos[2]=(AttackAnimation="PI_AttackMelee_C",Weight=1.0000000,SourceSocketName="None",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=true,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	bUseForProjectedAttackTests=false
	BaseMinTimeBetweenUsage=1.5000000
	BaseMaxTimeBetweenUsage=3.0000000
	AvailableAmmoTypes=/* Array type was not detected. */
	DefaultAmmoSelection=Class'ShockAI.RangedAggressorPistolMeleeWeaponAmmo'
	UsesAmmunition=false
}