class Crossbow_TrapBolt extends Crossbow_Bolt
	config(Weapons);

defaultproperties
{
	InitialVelocity=3000.0000000
	ProjectileClass=Class'ShockGame.ShockDesignerClasses.CrossbowTrapBoltProjectile'
	DamageStimuliSetName="TrapBoltStimuliSet"
	VisualAmmoModelSkinOverride=Shader'ShockGame.WP_Crossbow.ammo_pickup_trap_diffuse_shader'
	MaximumStackSize=24
	Description="Inventable Item: 2 Battery, 3 Glue, 1 Alcohol\\n\\nTripwire bolts for the crossbow.\\n\\nThese ingenious bolts shoot out an electrified tripwire when fired into a wall."
	FriendlyName="Trap Bolt"
	CreditValue=10.0000000
}