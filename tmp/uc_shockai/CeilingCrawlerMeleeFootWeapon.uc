class CeilingCrawlerMeleeFootWeapon extends AIMeleeWeapon
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced);

defaultproperties
{
	AttackAnimationInfos[0]=(AttackAnimation="CR_AttackMelee_F_hit",Weight=1.0000000,SourceSocketName="None",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=true,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	bUseForProjectedAttackTests=false
	BaseMinTimeBetweenUsage=0.5000000
	BaseMaxTimeBetweenUsage=1.0000000
	AvailableAmmoTypes=/* Array type was not detected. */
	DefaultAmmoSelection=Class'ShockAI.CeilingCrawlerMeleeFootWeaponAmmo'
	UsesAmmunition=false
}