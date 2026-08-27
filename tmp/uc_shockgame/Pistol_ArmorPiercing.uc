class Pistol_ArmorPiercing extends TraceAmmo
	config(Weapons);

defaultproperties
{
	DamageStimuliSetName="ArmorPiercingStimuliSet"
	ChanceToCrit=0.0000000
	VisualAmmoModel=StaticMesh'ShockGame.WP_Pistol.PI_AmmoType'
	AmmoSpecificDamageAmplificationPercentBonusModGroup="PistolDamage_PercentBonus"
	MaximumStackSize=24
	Description=".38 cailber armor-piercing rounds for the pistol.\\n\\nThese bullets are particularly effective against metal or armored targets, like turrets, security bots and Big Daddies."
	FriendlyName="Armor-piercing Pistol Rounds"
	CreditValue=10.0000000
}