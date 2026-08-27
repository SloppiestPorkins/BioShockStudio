class RosieRangedWeapon extends AIRangedWeapon
	native
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced);

defaultproperties
{
	WeaponUsesAimPoses=true
	bResetAccuracyWhenStartingBurstFire=true
	AttackAnimationInfos[0]=(AttackAnimation="MG_FireGun_Agg_mid",Weight=1.0000000,SourceSocketName="None",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	WeaponFireStartOffsetType=1
	WeaponFireStartRotationType=2
	bUseCachedCanHitRotation=false
	FireEffectLocationSocketName="Muzzle"
	BaseMinTimeBetweenUsage=0.5000000
	BaseMaxTimeBetweenUsage=0.7000000
	FriendlyName="Rivet Gun"
	UseVerbText="SEARCH"
	ShouldTreatAsAPickup=false
	LootSlot0TableName="RosieRailgun"
	FriendlyName="Rivet Gun"
	UsesAmmunition=false
	TracerEffects=/* Array type was not detected. */
	bHideWhileUnequipped=false
	AttachBone="RivetGunSocket"
	DrawType=2
	bHidden=false
}