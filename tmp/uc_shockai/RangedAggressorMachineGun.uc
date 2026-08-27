class RangedAggressorMachineGun extends AIRangedWeapon
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced);

defaultproperties
{
	WeaponUsesAimPoses=true
	bResetAccuracyWhenStartingBurstFire=true
	AttackAnimationInfos[0]=(AttackAnimation="smg_fire",Weight=1.0000000,SourceSocketName="None",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	WeaponFireStartOffsetType=1
	WeaponFireStartRotationType=2
	bUseCachedCanHitRotation=false
	FireEffectLocationSocketName="Muzzle"
	BaseMinTimeBetweenUsage=0.2500000
	BaseMaxTimeBetweenUsage=0.5000000
	FriendlyName="Machine Gun"
	UseVerbText="SEARCH"
	LootSlot0TableName="RangedAggressorMachineGun"
	FriendlyName="Machine Gun"
	UsesAmmunition=false
	BaseFireRate=2.0000000
	bHideWhileUnequipped=false
	AttachBone="smg"
	bHidden=false
}