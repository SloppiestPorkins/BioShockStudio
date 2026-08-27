class GrenadierGrenadeWeaponAmmo extends ExplosiveProjectileAmmo
	config(Weapons);

defaultproperties
{
	FuseTime=2.0000000
	bShouldStartFuseOnImpact=true
	OuterDamageRadius=650.0000000
	InnerDamageRadius=500.0000000
	ExplodeOnImpact=false
	InitialVelocity=1200.0000000
	ProjectileClass=Class'ShockAI.GrenadierGrenadeWeaponProjectile'
	CanHitAttackAngles=/* Array type was not detected. */
	DamageStimuliSetName="GrenadierRangedWeaponStimuliSet"
	AttackRange=2000.0000000
}