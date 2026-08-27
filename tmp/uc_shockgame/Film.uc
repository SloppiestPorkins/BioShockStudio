class Film extends Ammunition
	config(Weapons);

defaultproperties
{
	DamageModel=Class'ShockGame.CameraDamageFactory'
	DamageStimuliSetName="None"
	ChanceToCrit=0.0000000
	MaximumStackSize=100
	Description="Film for the research camera.\\n\\nEach unit of film is good for a single research photograph."
	FriendlyName="Film"
	CreditValue=1.0000000
}