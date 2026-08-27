class Crossbow_SuperHeatedBolt extends ProjectileAmmo
	config(Weapons);

defaultproperties
{
	InitialVelocity=6000.0000000
	ProjectileClass=Class'ShockGame.ShockDesignerClasses.CrossbowSearingBoltProjectile'
	ShouldDestroyProjectileOnImpact=false
	VisibilityDelay=0.0500000
	DamageStimuliSetName="SuperHeatedBoltStimuliSet"
	ChanceToCrit=0.0000000
	AttackRange=2000.0000000
	VisualAmmoModel=StaticMesh'ShockGame.WP_Crossbow.arrow_antipersonell'
	VisualAmmoModelSkinOverride=Shader'ShockGame.WP_Crossbow.ammo_pickup_armorpiercing_shader'
	AmmoSpecificDamageAmplificationPercentBonusModGroup="CrossbowDamage_PercentBonus"
	MaximumStackSize=24
	Description="Incendiary Bolts for the crossbow.\\n\\nThese bolts are particularly effective against targets vulnerable to fire."
	FriendlyName="Incendiary Bolt"
	CreditValue=13.3299999
}