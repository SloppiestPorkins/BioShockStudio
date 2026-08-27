class SPFRangedWeaponAmmo extends ExplosiveProjectileAmmo
	config(Weapons);

defaultproperties
{
	FuseTime=10.0000000
	OuterDamageRadius=512.0000000
	InnerDamageRadius=128.0000000
	ExplodeOnImpact=false
	ExplodeNearOtherPawnsRadius=128.0000000
	InitialVelocity=1750.0000000
	ProjectileClass=Class'ShockAI.SPFRangedWeaponProjectile'
	DamageStimuliSetName="SPFRangedWeaponStimuliSet"
	AttackRange=2000.0000000
}