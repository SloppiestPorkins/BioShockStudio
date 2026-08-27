class IcicleAssaultAbility extends TraceAttackAbility
	config(Abilities);

function int GetNumTracesToFire()
{
	return int(Damager.ModifyStat('IcicleAssaultFragment_Bonus', float(NumTracesToFire)));
	return;
	@NULL
	Item
}

defaultproperties
{
	DamageModel=Class'ShockGame.TraceDamageFactory'
	DamageStimuliSetName="IcicleAssaultStimuliSet"
	ChanceToCrit=0.0500000
	MagicBulletRadius=0.2000000
	MouseMagicBulletRadius=0.1000000
	ModGroupName="IcicleAssault_Exists"
	BioAmmoCost=13.0000000
	FriendlyName="Winter Blast"
	FastEquipAnimationName="Shards_Equip"
	SlowEquipAnimationName="Shards_Equip"
	FireAnimationName="Shards_Fire"
	FinishFireWithEveAnimationName="Shards_FireEve"
	FinishFireWithoutEveAnimationName="Shards_FireNoEve"
	IdlingAnimationName[0]="Shards_Fidget"
}