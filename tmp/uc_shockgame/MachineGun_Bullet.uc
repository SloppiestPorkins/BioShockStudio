class MachineGun_Bullet extends TraceAmmo
	config(Weapons);

defaultproperties
{
	DamageStimuliSetName="MachineGunStandardBulletStimuliSet"
	ChanceToCrit=0.0000000
	UseFullAuto=true
	VisualAmmoModel=StaticMesh'ShockGame.WP_TommyGun.TG_AmmoModel'
	VisualAmmoModelSkinOverride=FacingShader'ShockGame.WP_TommyGun.ammostandard'
	AmmoSpecificDamageAmplificationPercentBonusModGroup="MachineGunDamage_PercentBonus"
	HitspangDelayRange=(Min=0.1000000,Max=0.3000000)
	MaximumStackSize=360
	Description=".45 caliber rounds for the machine gun.\\n\\nThese bullets will do the job you want, if the job is spraying death at your opponents."
	FriendlyName="Machine Gun Rounds"
	CreditValue=1.5000000
}