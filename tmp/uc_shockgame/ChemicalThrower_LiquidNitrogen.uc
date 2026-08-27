class ChemicalThrower_LiquidNitrogen extends EmitterAmmo
	config(Weapons);

defaultproperties
{
	EmitterClass=Class'ShockGame.FXClass.LiquidNitrogen_Player'
	HighPressureEmitterClass=Class'ShockGame.FXClass.LiquidNitrogenUp_Player'
	DamageStimuliSetName="ChemLiquidNitrogenStimuliSet"
	ChanceToCrit=0.0000000
	MaximumStackSize=200
	Description="Liquid nitrogen for the chemical thrower.\\n\\nLiquid Nitrogen is particularly effective against targets vulnerable to cold, and will freeze creatures if continuously applied."
	FriendlyName="Liquid Nitrogen"
	CreditValue=1.0000000
}