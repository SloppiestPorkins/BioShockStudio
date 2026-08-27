class BotShockGunAmmo extends RadialAmmo
	config(Weapons);

defaultproperties
{
	DamageModel=Class'ShockAI.BotShockGunDamageFactory'
	DamageStimuliSetName="BotShockStimuliSet"
	ChanceToCrit=0.0000000
	AttackRange=400.0000000
}