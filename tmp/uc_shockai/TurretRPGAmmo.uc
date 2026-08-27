class TurretRPGAmmo extends ExplosiveProjectileAmmo
	config(Weapons);

defaultproperties
{
	FuseTime=6.0000000
	OuterDamageRadius=700.0000000
	InnerDamageRadius=400.0000000
	InitialVelocity=1400.0000000
	ProjectileClass=Class'ShockAI.ShockDesignerClasses.SpawnedTurretRPGProjectile'
	bShouldHeatSeek=true
	DamageStimuliSetName="RPGTurretStimuliSet"
	ChanceToCrit=0.0000000
	AttackRange=2500.0000000
	VisualAmmoModel=StaticMesh'WP_GrenadeLauncher.Ammo_Pickup_RPG'
	MaximumStackSize=600
	FriendlyName="Heat-seeking RPG"
}