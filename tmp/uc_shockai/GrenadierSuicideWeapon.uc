class GrenadierSuicideWeapon extends AIWeapon
	native
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced);

defaultproperties
{
	AttackAnimationInfos[0]=(AttackAnimation="GR_AttackSuicide",Weight=1.0000000,SourceSocketName="None",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	WeaponFireStartRotationType=2
	bUseForProjectedAttackTests=false
	BaseMinTimeBetweenUsage=0.2500000
	BaseMaxTimeBetweenUsage=0.5000000
	AvailableAmmoTypes=/* Array type was not detected. */
	DefaultAmmoSelection=Class'ShockAI.GrenadierSuicideWeaponAmmo'
	UsesAmmunition=false
}