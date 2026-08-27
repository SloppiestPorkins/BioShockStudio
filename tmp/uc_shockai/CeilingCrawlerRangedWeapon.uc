class CeilingCrawlerRangedWeapon extends AIRangedWeapon
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced);

defaultproperties
{
	AttackAnimationInfos[0]=(AttackAnimation="CR_AttackRangedCeiling_A",Weight=1.0000000,SourceSocketName="Bip01_R_Hand",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=true,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	AttackAnimationInfos[1]=(AttackAnimation="CR_AttackRangedCeiling_B",Weight=1.0000000,SourceSocketName="Bip01_R_Hand",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=true,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	AttackAnimationInfos[2]=(AttackAnimation="CR_AttackRangedCeiling_C",Weight=1.0000000,SourceSocketName="Bip01_R_Hand",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=true,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	AttackAnimationInfos[3]=(AttackAnimation="CR_AttackRanged_A",Weight=1.0000000,SourceSocketName="Bip01_L_Hand",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	AttackAnimationInfos[4]=(AttackAnimation="CR_AttackRanged_B",Weight=1.0000000,SourceSocketName="Bip01_L_Hand",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	AttackAnimationInfos[5]=(AttackAnimation="CR_AttackRanged_C",Weight=1.0000000,SourceSocketName="Bip01_L_Hand",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	WeaponFireStartOffsetType=3
	WeaponFireStartRotationType=2
	bUseCachedCanHitRotation=false
	BaseMinTimeBetweenUsage=0.7000000
	BaseMaxTimeBetweenUsage=1.2000000
	UsesAmmunition=false
}