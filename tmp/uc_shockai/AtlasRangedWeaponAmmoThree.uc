class AtlasRangedWeaponAmmoThree extends ExplosiveProjectileAmmo
	config(Weapons);

defaultproperties
{
	FuseTime=1.5000000
	bShouldStartFuseOnImpact=true
	OuterDamageRadius=800.0000000
	InnerDamageRadius=500.0000000
	ExplodeNearOtherPawnsRadius=40.0000000
	InitialVelocity=2800.0000000
	ProjectileClass=Class'ShockAI.FXClass.AtlasElectricProjectile'
	DamageStimuliSetName="AtlasRangedWeaponStimuliSetElectric"
	AttackRange=2000.0000000
}