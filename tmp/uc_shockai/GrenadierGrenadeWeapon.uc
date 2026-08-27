class GrenadierGrenadeWeapon extends AIGrenadeWeapon
	native
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced);

defaultproperties
{
	AttackAnimationInfos[0]=(AttackAnimation="GR_AttackThrowLong_A",Weight=1.0000000,SourceSocketName="None",AttackAnimationRange=(Min=1200.0000000,Max=0.0000000),bCheckFullAnimationMotion=true,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=true,TimeBetweenUsageOverride=(Min=0.5000000,Max=1.0000000))
	AttackAnimationInfos[1]=(AttackAnimation="GR_AttackThrowMid_A",Weight=1.0000000,SourceSocketName="None",AttackAnimationRange=(Min=600.0000000,Max=1200.0000000),bCheckFullAnimationMotion=true,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=true,TimeBetweenUsageOverride=(Min=0.7500000,Max=1.5000000))
	AttackAnimationInfos[2]=(AttackAnimation="GR_AttackThrowShort_A",Weight=1.0000000,SourceSocketName="None",AttackAnimationRange=(Min=0.0000000,Max=600.0000000),bCheckFullAnimationMotion=true,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=1.5000000,Max=2.5000000))
	AttackAnimationInfos[3]=(AttackAnimation="GR_AttackThrowLong_C",Weight=0.0100000,SourceSocketName="None",AttackAnimationRange=(Min=1200.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.5000000,Max=1.0000000))
	AttackAnimationInfos[4]=(AttackAnimation="GR_AttackThrowMid_B",Weight=0.0100000,SourceSocketName="None",AttackAnimationRange=(Min=600.0000000,Max=1200.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.7500000,Max=1.5000000))
	BaseMinTimeBetweenUsage=0.5000000
	BaseMaxTimeBetweenUsage=1.0000000
	bGetReadyToUseMultiplierFromHolder=true
	FriendlyName="Grenade"
	UseVerbText="SEARCH"
	FriendlyName="Grenade"
	AvailableAmmoTypes=/* Array type was not detected. */
	DefaultAmmoSelection=Class'ShockAI.GrenadierGrenadeWeaponAmmo'
	UsesAmmunition=false
	StaticWeaponModel=StaticMesh'WP_GrenadeLauncher.Ammo_Pickup_Frag'
	StaticWeaponModelHavokDataClass=Class'ShockAI.HavokPhysics.Iron'
	bUseForDodgeTesting=false
	BaseAccuracy=0.0000000
	bHideWhileUnequipped=false
	AttachBone="Grenade"
	bHidden=false
}