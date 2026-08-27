class GrenadierLiveGrenadeWeapon extends AIRangedWeapon
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced);

defaultproperties
{
	AttackAnimationInfos[0]=(AttackAnimation="GR_AttackThrowRun",Weight=1.0000000,SourceSocketName="None",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	WeaponFireStartOffsetType=3
	WeaponFireStartRotationType=2
	bUseForProjectedAttackTests=false
	BaseMaxTimeBetweenUsage=0.5000000
	FriendlyName="Grenade"
	UseVerbText="SEARCH"
	FriendlyName="Grenade"
	AvailableAmmoTypes=/* Array type was not detected. */
	DefaultAmmoSelection=Class'ShockAI.GrenadierLiveGrenadeWeaponAmmo'
	UsesAmmunition=false
	StaticWeaponModel=StaticMesh'WP_GrenadeLauncher.Ammo_Pickup_Frag'
	StaticWeaponModelHavokDataClass=Class'ShockAI.HavokPhysics.Iron'
	bUseForDodgeTesting=false
	bHideWhileUnequipped=false
	bHideWhileEquipped=true
	AttachBone="Grenade"
}