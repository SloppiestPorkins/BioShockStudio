class GrenadeLauncher_FragGrenade extends ExplosiveProjectileAmmo
	config(Weapons);

defaultproperties
{
	FuseTime=1.5000000
	bShouldStartFuseOnImpact=true
	OuterDamageRadius=650.0000000
	InnerDamageRadius=500.0000000
	ExplodeOnImpact=false
	ExplodeNearOtherPawnsRadius=40.0000000
	InitialVelocity=2200.0000000
	ProjectileClass=Class'ShockGame.ShockDesignerClasses.FragGrenadeProjectile'
	DamageStimuliSetName="FragGrenadeStimuliSet"
	ChanceToCrit=0.0000000
	VisualAmmoModel=StaticMesh'ShockGame.WP_GrenadeLauncher.Ammo_Pickup_Frag'
	AmmoSpecificDamageAmplificationPercentBonusModGroup="GrenadeLauncherDamage_PercentBonus"
	MaximumStackSize=12
	Description="Fragmentation grenades for the grenade launcher.\\n\\nThese basic frag grenades are massively damaging, and have a significant blast radius."
	FriendlyName="Frag Grenade"
	CreditValue=20.0000000
}