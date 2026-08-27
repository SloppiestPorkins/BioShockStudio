class Pistol_AntiPersonnel extends TraceAmmo
	config(Weapons);

defaultproperties
{
	DamageStimuliSetName="AntiPersonnelStimuliSet"
	ChanceToCrit=0.0000000
	VisualAmmoModel=StaticMesh'ShockGame.WP_Pistol.PI_AmmoType'
	AmmoSpecificDamageAmplificationPercentBonusModGroup="PistolDamage_PercentBonus"
	MaximumStackSize=24
	Description="Inventable Item: 2 Rubber Hose, 3 Shell Casing, 1 Steel Screw\\n\\n .38 caliber antipersonnel rounds for the pistol.\\n\\nThese bullets are specially designed to neutralize non-armored targets -- like Splicers."
	FriendlyName="Antipersonnel Pistol Rounds"
	CreditValue=10.0000000
}