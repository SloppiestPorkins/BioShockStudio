class GrenadeLauncher_RPG extends ExplosiveProjectileAmmo
	config(Weapons);

defaultproperties
{
	FuseTime=30.0000000
	OuterDamageRadius=650.0000000
	InnerDamageRadius=500.0000000
	InitialVelocity=1000.0000000
	ProjectileClass=Class'ShockGame.ShockDesignerClasses.RPGgrenadeProjectile'
	VisibilityDelay=0.1000000
	bShouldHeatSeek=true
	DamageStimuliSetName="RPGStimuliSet"
	ChanceToCrit=0.0000000
	VisualAmmoModel=StaticMesh'ShockGame.WP_GrenadeLauncher.Ammo_Pickup_RPG'
	AmmoSpecificDamageAmplificationPercentBonusModGroup="GrenadeLauncherDamage_PercentBonus"
	MaximumStackSize=6
	Description="Inventable Item: 3 Distilled Water, 2 Kerosene, 1 Brass Tube\\n\\nHeat-seeking RPGs for the grenade launcher.\\n\\nThese homing missiles are the perfect solution for moving targets, delivering a devastating payload even around corners!"
	FriendlyName="Heat-seeking RPG"
	CreditValue=20.0000000
}