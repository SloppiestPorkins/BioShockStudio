class GrenadeLauncher_StickyGrenade extends StickyProjectileAmmo
	config(Weapons);

defaultproperties
{
	TimeToArm=1.0000000
	FuseTime=3600.0000000
	OuterDamageRadius=650.0000000
	InnerDamageRadius=500.0000000
	ExplodeOnImpact=false
	InitialVelocity=2200.0000000
	ProjectileClass=Class'ShockGame.ShockDesignerClasses.ProximityProjectile'
	DamageStimuliSetName="StickyProxStimuliSet"
	ChanceToCrit=0.0000000
	VisualAmmoModel=StaticMesh'ShockGame.WP_GrenadeLauncher.Ammo_Pickup_StickyMineProx'
	AmmoSpecificDamageAmplificationPercentBonusModGroup="GrenadeLauncherDamage_PercentBonus"
	MaximumStackSize=6
	Description="Proximity mines for the grenade launcher.\\n\\nThese are effectively used as land-mines, staying primed and ready until an unwitting victim walks too close."
	FriendlyName="Proximity Mine"
	CreditValue=25.0000000
}