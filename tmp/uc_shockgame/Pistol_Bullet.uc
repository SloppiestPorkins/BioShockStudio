class Pistol_Bullet extends TraceAmmo
	config(Weapons);

defaultproperties
{
	DamageStimuliSetName="StandardBulletStimuliSet"
	ChanceToCrit=0.0000000
	VisualAmmoModel=StaticMesh'ShockGame.WP_Pistol.PI_AmmoType'
	AmmoSpecificDamageAmplificationPercentBonusModGroup="PistolDamage_PercentBonus"
	MaximumStackSize=48
	Description="These .38 caliber rounds for the pistol are a reliable way to deal damage to almost anything."
	FriendlyName="Pistol Rounds"
	CreditValue=4.1599998
}