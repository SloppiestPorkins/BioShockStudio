class MachineGun_ArmorPiercingBullet extends TraceAmmo
	config(Weapons);

defaultproperties
{
	DamageStimuliSetName="MachineGunArmorPiercingBulletStimuliSet"
	ChanceToCrit=0.0000000
	UseFullAuto=true
	VisualAmmoModel=StaticMesh'ShockGame.WP_TommyGun.TG_AmmoModel'
	VisualAmmoModelSkinOverride=FacingShader'ShockGame.WP_TommyGun.ammotypes_riot'
	AmmoSpecificDamageAmplificationPercentBonusModGroup="MachineGunDamage_PercentBonus"
	HitspangDelayRange=(Min=0.1000000,Max=0.3000000)
	MaximumStackSize=180
	Description="Inventable Item: 2 Kerosene, 3 Shell Casing, 1 Brass Tube\\n\\n.45 caliber armor-piercing rounds for the machine gun.\\n\\nThese bullets are particularly effective against metal or armored targets, like turrets, security bots and Big Daddies."
	FriendlyName="Armor-piercing Auto Rounds "
	CreditValue=2.5000000
}