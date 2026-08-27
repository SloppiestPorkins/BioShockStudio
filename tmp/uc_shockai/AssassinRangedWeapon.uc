class AssassinRangedWeapon extends AIRangedWeapon
	native
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced);

defaultproperties
{
	AttackAnimationInfos[0]=(AttackAnimation="AS_FireballThrow_A",Weight=1.0000000,SourceSocketName="Bip01_R_Hand",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	AttackAnimationInfos[1]=(AttackAnimation="AS_FireballThrow_B",Weight=1.0000000,SourceSocketName="Bip01_R_Hand",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	AttackAnimationInfos[2]=(AttackAnimation="AS_FireballThrow_C",Weight=1.0000000,SourceSocketName="Bip01_R_Hand",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	WeaponFireStartOffsetType=3
	WeaponFireStartRotationType=2
	bUseCachedCanHitRotation=false
	bVerifyAIOriginToWeaponSourceOrigin=true
	BaseAnimationForSocketOffsets="ME_Fidget_A_agg"
	UsesAmmunition=false
}