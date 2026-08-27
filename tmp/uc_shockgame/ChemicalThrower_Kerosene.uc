class ChemicalThrower_Kerosene extends EmitterAmmo
	config(Weapons);

defaultproperties
{
	EmitterClass=Class'ShockGame.FXClass.FlameThrower_Player'
	HighPressureEmitterClass=Class'ShockGame.FXClass.FlameThrowerUp_Player'
	DamageStimuliSetName="KeroseneStimuliSet"
	ChanceToCrit=0.0000000
	MaximumStackSize=400
	Description="Napalm for the chemical thrower.\\n\\nNapalm is particularly effective against targets vulnerable to fire, and will set things on fire if continuously applied."
	FriendlyName="Napalm"
	CreditValue=0.7500000
}