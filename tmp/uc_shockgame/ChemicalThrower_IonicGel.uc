class ChemicalThrower_IonicGel extends EmitterAmmo
	config(Weapons);

defaultproperties
{
	EmitterClass=Class'ShockGame.FXClass.IonGel'
	HighPressureEmitterClass=Class'ShockGame.FXClass.IonGelUp'
	DamageStimuliSetName="IonicGelStimuliSet"
	ChanceToCrit=0.0000000
	MaximumStackSize=200
	Description="Inventable Item: 3 Distilled Water, 2 Battery, 1 Alcohol\\n\\nElectric Gel for the chemical thrower.\\n\\nElectric Gel deals electric damage to targets, and may send them into shocked convulsions.  Also good for temporarily disabling machines."
	FriendlyName="Electric Gel"
	CreditValue=1.2500000
}