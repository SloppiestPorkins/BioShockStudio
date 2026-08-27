class RangedAggressorPistolWeapon extends AIRangedWeapon
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced);

defaultproperties
{
	WeaponUsesAimPoses=true
	bResetAccuracyWhenStartingBurstFire=true
	AttackAnimationInfos[0]=(AttackAnimation="PI_Fire",Weight=1.0000000,SourceSocketName="None",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	AttackAnimationInfos[1]=(AttackAnimation="PI_Fire_B",Weight=1.0000000,SourceSocketName="None",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	WeaponFireStartOffsetType=1
	WeaponFireStartRotationType=2
	bUseCachedCanHitRotation=false
	FireEffectLocationSocketName="Muzzle"
	BaseMinTimeBetweenUsage=0.1000000
	BaseMaxTimeBetweenUsage=0.5000000
	FriendlyName="Pistol"
	UseVerbText="SEARCH"
	LootSlot0TableName="RangedAggressorPistol"
	FriendlyName="Pistol"
	UsesAmmunition=false
	bHideWhileUnequipped=false
	AttachBone="Pistol"
	bHidden=false
}