class IncinerationAbility extends TraceAttackAbility
	config(Abilities);

function UseAbility(ShockPlayer Instigator)
{
	super(AttackAbility).UseAbility(Instigator);
	Instigator.SetInfernoID(Instigator.Level.CreateNewInfernoID());
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	DamageModel=Class'ShockGame.TraceDamageFactory'
	DamageStimuliSetName="IncinerationStimuliSet"
	ChanceToCrit=0.0000000
	MagicBulletRadius=0.2000000
	MouseMagicBulletRadius=0.1000000
	ModGroupName="Incineration_Exists"
	BioAmmoCost=8.0000000
	FriendlyName="Incinerate!"
	FastEquipAnimationName="Incineration_Equip"
	SlowEquipAnimationName="Incineration_Equip"
	FireAnimationName="Incineration_Fire"
	FinishFireWithEveAnimationName="Incineration_FireEve"
	FinishFireWithoutEveAnimationName="Incineration_FireNoEve"
	IdlingAnimationName[0]="Incineration_Fidget"
	IdlingAnimationName[1]="Incineration_Fidget_Accent_A"
	IdlingAnimationWeight[0]=100.0000000
	IdlingAnimationWeight[1]=10.0000000
}