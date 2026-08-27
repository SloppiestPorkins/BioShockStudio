class GrenadierSmokeGrenadeWeaponAmmo extends ExplosiveProjectileAmmo
	config(Weapons);

defaultproperties
{
	FuseTime=5.0000000
	OuterDamageRadius=5.0000000
	InnerDamageRadius=5.0000000
	InitialVelocity=600.0000000
	ProjectileClass=Class'ShockAI.GrenadierSmokeGrenadeWeaponProjectile'
	DamageStimuliSetName="GrenadierSmokeGrenadeWeaponStimuliSet"
	AttackRange=2000.0000000
}