class AssassinMeleeWeapon extends AIMeleeWeapon
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced);

defaultproperties
{
	AttackAnimationInfos[0]=(AttackAnimation="ME_attackMelee_A",Weight=1.0000000,SourceSocketName="None",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	AttackAnimationInfos[1]=(AttackAnimation="ME_attackMelee_B",Weight=1.0000000,SourceSocketName="None",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	BaseMinTimeBetweenUsage=0.2500000
	BaseMaxTimeBetweenUsage=0.5000000
	FriendlyName="Melee Thug Club"
	UseVerbText="SEARCH"
	FriendlyName="Melee Thug Club"
	AvailableAmmoTypes=/* Array type was not detected. */
	DefaultAmmoSelection=Class'ShockAI.MeleeThugClubAmmo'
	UsesAmmunition=false
	StaticWeaponModelHavokDataClass=Class'ShockAI.HavokPhysics.Iron5pc'
	bHideWhileUnequipped=false
	AttachBone="MeleePipe"
}