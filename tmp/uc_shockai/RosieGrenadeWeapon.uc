class RosieGrenadeWeapon extends AIGrenadeWeapon
	native
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced);

defaultproperties
{
	AttackAnimationInfos[0]=(AttackAnimation="MG_throwGrenade",Weight=1.0000000,SourceSocketName="None",AttackAnimationRange=(Min=500.0000000,Max=0.0000000),bCheckFullAnimationMotion=true,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	bUseForProjectedAttackTests=false
	BaseMinTimeBetweenUsage=4.0000000
	BaseMaxTimeBetweenUsage=7.0000000
	FriendlyName="Grenade"
	UseVerbText="SEARCH"
	FriendlyName="Grenade"
	AvailableAmmoTypes=/* Array type was not detected. */
	DefaultAmmoSelection=Class'ShockAI.RosieGrenadeWeaponAmmo'
	UsesAmmunition=false
	StaticWeaponModel=StaticMesh'WP_GrenadeLauncher.Ammo_Pickup_StickyMineProx'
	StaticWeaponModelHavokDataClass=Class'ShockAI.HavokPhysics.Iron'
	bUseForDodgeTesting=false
	BaseAccuracy=0.0000000
	AttachBone="Bip01_L_Hand"
}