class Shotgun_IonicBuck extends TraceAmmo
	config(Weapons);

defaultproperties
{
	NumTracesToFire=8
	SpreadOfFire=(Pitch=910,Yaw=910,Roll=0)
	DamageStimuliSetName="IonicBuckStimuliSet"
	ChanceToCrit=0.0000000
	VisualAmmoModel=StaticMesh'ShockGame.WP_Shotgun.shotgun_shell'
	AmmoSpecificDamageAmplificationPercentBonusModGroup="ShotgunDamage_PercentBonus"
	MaximumStackSize=24
	Description="Electric Buckshot for the shotgun.\\n\\nElectric buckshot is particularly effective against targets vulnerable to electricity."
	FriendlyName="Electric Buck"
	CreditValue=12.0000000
}