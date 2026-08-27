class ElectricBoltAbility extends TraceAttackAbility
	config(Abilities);

defaultproperties
{
	DamageModel=Class'ShockGame.TraceDamageFactory'
	DamageStimuliSetName="ElectricBoltStimuliSet"
	ChanceToCrit=0.0000000
	MagicBulletRadius=0.2000000
	MouseMagicBulletRadius=0.1000000
	ModGroupName="ElectricBolt_Exists"
	BioAmmoCost=15.0000000
	FriendlyName="Electro Bolt"
	FastEquipAnimationName="ElectrokineticBolt_Equip"
	SlowEquipAnimationName="ElectrokineticBolt_Equip"
	FireAnimationName="ElectrokineticBolt_Fire"
	FinishFireWithEveAnimationName="ElectrokineticBolt_FireEve"
	FinishFireWithoutEveAnimationName="ElectrokineticBolt_FireNoEve"
	IdlingAnimationName[0]="ElectrokineticBolt_Fidget"
	IdlingAnimationName[1]="ElectrokineticBolt_Fidget_Accent_A"
	IdlingAnimationWeight[0]=100.0000000
	IdlingAnimationWeight[1]=10.0000000
}