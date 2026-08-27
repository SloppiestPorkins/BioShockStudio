class RosieGrenadeWeaponAmmo extends StickyProjectileAmmo
	config(Weapons);

defaultproperties
{
	TimeToArm=1.0000000
	FuseTime=60.0000000
	bShouldStartFuseOnImpact=true
	OuterDamageRadius=600.0000000
	InnerDamageRadius=200.0000000
	ExplodeOnImpact=false
	InitialVelocity=1200.0000000
	ProjectileClass=Class'ShockAI.RosieGrenadeWeaponProjectile'
	CanHitAttackAngles=/* Array type was not detected. */
	DamageStimuliSetName="RosieGrenadeWeaponStimuliSet"
	AttackRange=2000.0000000
}