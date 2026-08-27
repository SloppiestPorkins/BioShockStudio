class BouncerShoulderWeapon extends AIMeleeWeapon
	native
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced);

defaultproperties
{
	AttackAnimationInfos[0]=(AttackAnimation="BO_AttackShoulderSlamLONG",Weight=1.0000000,SourceSocketName="None",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	bUseForProjectedAttackTests=false
	MinTravelPercentageForFullAnimation=0.5000000
	MinTravelPercentageForAttack=0.2000000
	BaseMinTimeBetweenUsage=3.0000000
	BaseMaxTimeBetweenUsage=6.0000000
	AvailableAmmoTypes=/* Array type was not detected. */
	DefaultAmmoSelection=Class'ShockAI.BouncerShoulderWeaponAmmo'
	UsesAmmunition=false
}