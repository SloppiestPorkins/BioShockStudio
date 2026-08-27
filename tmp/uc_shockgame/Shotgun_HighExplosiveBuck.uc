class Shotgun_HighExplosiveBuck extends TraceAmmo
	config(Weapons);

defaultproperties
{
	NumTracesToFire=8
	SpreadOfFire=(Pitch=910,Yaw=910,Roll=0)
	DamageStimuliSetName="HighExplosiveBuckStimuliSet"
	ChanceToCrit=0.0000000
	VisualAmmoModel=StaticMesh'ShockGame.WP_Shotgun.shotgun_shell'
	AmmoSpecificDamageAmplificationPercentBonusModGroup="ShotgunDamage_PercentBonus"
	MaximumStackSize=24
	Description="Inventable Item: 3 Kerosene, 2 Shell Casing, 1 Steel Screw\\n\\nExplosive buckshot for the shotgun.\\n\\nThis powerful buckshot explodes on contact with a target, dealing extra damage to all targets."
	FriendlyName="Exploding Buck"
	CreditValue=12.0000000
}