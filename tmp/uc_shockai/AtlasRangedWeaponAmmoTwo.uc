class AtlasRangedWeaponAmmoTwo extends ExplosiveProjectileAmmo
	config(Weapons);

defaultproperties
{
	FuseTime=1.5000000
	bShouldStartFuseOnImpact=true
	OuterDamageRadius=800.0000000
	InnerDamageRadius=500.0000000
	ExplodeNearOtherPawnsRadius=40.0000000
	InitialVelocity=2200.0000000
	ProjectileClass=Class'ShockAI.FXClass.AtlasIceProjectile'
	DamageStimuliSetName="AtlasRangedWeaponStimuliSetFrost"
	AttackRange=2000.0000000
}